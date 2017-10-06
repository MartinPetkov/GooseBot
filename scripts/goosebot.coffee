# Description:
#   Relay and create recognitions in 7Geese
#
# Commands:
#   goosebot recognize - Recognize someone
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md
http = require 'http'
https = require 'https'
url = require 'url'
querystring = require 'querystring'

badgeEmojis =
  Excellence: ':star:'
  CustomerFocus: ':bow:'
  Growth: ':seedling:'
  Initiative: ':running:'
  Innovation: ':bulb:'
  Empowering: ':muscle:'
  Leadership: ':crown:'
  Passion: ':sparkling_heart:'
  Teamwork: ':two_men_holding_hands:'
  SCNinjaAward: ':octocat:'
  SCCallofDutyAward: ':construction_worker:'
  SCMyHeroAward: ':sunglasses:'
  SCModelCitizenAward: ':innocent:'
  SCShowMeTheMoneyAward: ':moneybag:'


  

request = (options, callback) ->
  req = https.request options, (resp) ->
    raw = ''
    if resp.statusCode != 200
      console.log resp.statusCode, resp.statusMessage
    resp.on 'data', (chunk) ->
      raw += chunk.toString()
    resp.on 'end', () ->
      data = JSON.parse raw
      callback? data

   req.on 'error', (error) ->
      console.log 'request errored out'
      console.log error
      console.log error.message
    
    req.end()

get = (path, callback) ->
  options = 
    hostname: 'app.7geese.com'
    port: 443
    path: path
    method: 'GET'
    headers:
      Authorization: 'Bearer AUTH_TOKEN'
  request options, callback

post = (path, callback) ->

refreshToken = () ->
  postData = querystring.stringify(
    refresh_token: ''
    client_id: 'CLIENT_ID'
    grant_type: 'refresh_token'
    state: 'my_state'
  )

  options =
    hostname: 'app.7geese.com'
    port: 443
    path: '/o/token/'
    method: 'POST'
    headers:
      'Content-Type': 'application/x-www-form-urlencoded'
      'Content-Length': Buffer.byteLength(postData)
   request options, callback



buildCallback = (recognition, res) ->
    return (badge) ->
       recipient = recognition.recipient
       creator = recognition.creator
       badgeEmoji = badgeEmojis[badge.name.replace(/\s+|\"/g, '')]
       recognitionMessage = "#{badgeEmoji} #{recipient.user.first_name} #{recipient.user.last_name} was recognized for *#{badge.name}* by " +
       "#{creator.user.first_name} #{creator.user.last_name} on #{recognition.created}\n" +
       "\"#{recognition.message}\"\n#{recognition.recognition_url}"
       res.send recognitionMessage

todaysRecognitions = (res) ->
   res.send "Todays recognitions"
   today = new Date().toISOString().split('T')[0]
   path = "/api/v/2.0/recognitions/?created__date=#{today}"
   get path, (response) ->
     console.log "response"
     console.log response
     if !response.results?
       res.send "There was a problem getting the recognitions"
     for recognition in response.results
       badgeUrl = url.parse(recognition.badge)
       get badgeUrl.pathname, buildCallback(recognition, res) 

module.exports = (robot) ->
  robot.respond /r/i, todaysRecognitions
  schedule.scheduleJob "10 * * * * *", refreshToken
    

  # robot.hear /badger/i, (res) ->
  #   res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"
  #
  # robot.respond /open the (.*) doors/i, (res) ->
  #   doorType = res.match[1]
  #   if doorType is "pod bay"
  #     res.reply "I'm afraid I can't let you do that."
  #   else
  #     res.reply "Opening #{doorType} doors"
  #
  # robot.hear /I like pie/i, (res) ->
  #   res.emote "makes a freshly baked pie"
  #
  # lulz = ['lol', 'rofl', 'lmao']
  #
  # robot.respond /lulz/i, (res) ->
  #   res.send res.random lulz
  #
  # robot.topic (res) ->
  #   res.send "#{res.message.text}? That's a Paddlin'"
  #
  #
  # enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  # leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  #
  # robot.enter (res) ->
  #   res.send res.random enterReplies
  # robot.leave (res) ->
  #   res.send res.random leaveReplies
  #
  # answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  #
  # robot.respond /what is the answer to the ultimate question of life/, (res) ->
  #   unless answer?
  #     res.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
  #     return
  #   res.send "#{answer}, but what is the question?"
  #
  # robot.respond /you are a little slow/, (res) ->
  #   setTimeout () ->
  #     res.send "Who you calling 'slow'?"
  #   , 60 * 1000
  #
  # annoyIntervalId = null
  #
  # robot.respond /annoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #     return
  #
  #   res.send "Hey, want to hear the most annoying sound in the world?"
  #   annoyIntervalId = setInterval () ->
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #   , 1000
  #
  # robot.respond /unannoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "GUYS, GUYS, GUYS!"
  #     clearInterval(annoyIntervalId)
  #     annoyIntervalId = null
  #   else
  #     res.send "Not annoying you right now, am I?"
  #
  #
  # robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
  #   room   = req.params.room
  #   data   = JSON.parse req.body.payload
  #   secret = data.secret
  #
  #   robot.messageRoom room, "I have a secret: #{secret}"
  #
  #   res.send 'OK'
  #
  # robot.error (err, res) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if res?
  #     res.reply "DOES NOT COMPUTE"
  #
  # robot.respond /have a soda/i, (res) ->
  #   # Get number of sodas had (coerced to a number).
  #   sodasHad = robot.brain.get('totalSodas') * 1 or 0
  #
  #   if sodasHad > 4
  #     res.reply "I'm too fizzy.."
  #
  #   else
  #     res.reply 'Sure!'
  #
  #     robot.brain.set 'totalSodas', sodasHad+1
  #
  # robot.respond /sleep it off/i, (res) ->
  #   robot.brain.set 'totalSodas', 0
  #   res.reply 'zzzzz'
