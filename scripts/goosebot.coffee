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
fs = require 'fs'

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

credentials = JSON.parse process.env.GOOSE_CREDS 
console.log process.env
console.log credentials

request = (options, data, callback) ->
  req = https.request options, (resp) ->
    console.log 'The creds for the request:'
    console.log credentials
    console.log ''
    console.log 'The options:'
    console.log options
    console.log ''
    raw = ''
    if resp.statusCode != 200
      console.log resp.statusCode, resp.statusMessage
    if resp.statusCode == 401 && resp.statusMessage == "Unauthorized"
      console.log "Need to refresh access token"
      refreshToken( () -> 
        request(options, data, callback))
      return
    resp.on 'data', (chunk) ->
      raw += chunk.toString()
    resp.on 'end', () ->
      data = JSON.parse raw
      callback? data

   req.on 'error', (error) ->
      console.log 'request errored out'
      console.log error
      console.log error.message
   
   if data?
     req.write(data)
   req.end()

get = (path, callback) ->
  #delete require.cache[require.resolve '../credentials.json']
  #json = require '../credentials.json'
  console.log "IN GET"
  console.log credentials
  options = 
    hostname: 'app.7geese.com'
    port: 443
    path: path
    method: 'GET'
    headers:
      Authorization: 'Bearer ' + credentials.access_token
  request options, null, callback

refreshToken = (callback) ->
  console.log credentials
  console.log "Refreshing token"
  console.log typeof credentials
  console.log credentials.refresh_token
  #delete require.cache[require.resolve '../credentials.json']
  #json = require '../credentials.json'
 

  postData = querystring.stringify(
    refresh_token: credentials.refresh_token 
    client_id: 'JGZp6YU0JzgPlqnSgoOEI07KiJZYHYZET8zJMFQq'
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

   request options, postData, (response) ->
     stringResp = JSON.stringify(response)
     console.log stringResp
     credentials = response
     console.log "new creds"
     console.log credentials
     if callback?
       callback()
     #fs.writeFile 'credentials.json', stringResp, 'utf-8', (err) ->
     #  console.log "done writing"
     #  if err
     #    console.log err
     #  delete require.cache[require.resolve '../credentials.json']
     #  json = require '../credentials.json'
     #  console.log json.access_token
     #  console.log "Calling back"
     #  callback()



buildCallback = (recognition, res) ->
    return (badge) ->
       recipient = recognition.recipient
       creator = recognition.creator
       badgeEmoji = badgeEmojis[badge.name.replace(/\s+|\"/g, '')]
       recognitionMessage = "#{badgeEmoji} #{recipient.user.first_name} #{recipient.user.last_name} was recognized for *#{badge.name}* by " +
       "#{creator.user.first_name} #{creator.user.last_name} on #{recognition.created}\n" +
       "\"#{recognition.message}\"\n#{recognition.recognition_url}"
       res.send recognitionMessage

yesterdaysRecognitions = (res) ->
   res.send "Yesterdays recognitions"
   today = new Date().toISOString().split('T')[0]
   path = "/api/v/2.0/recognitions/?created__date=#{today}"
   get path, (response) ->
     if !response.results?
       res.send "There was a problem getting the recognitions"
     else if response.count == 0
       res.send "No recognitions yesterday. Go out and recognize your co-workers on what a good job they're doing"
     for recognition in response.results
       badgeUrl = url.parse(recognition.badge)
       get badgeUrl.pathname, buildCallback(recognition, res) 

invalidateToken = (res) ->
  credentials.access_token = ''
  console.log "Invalidated token"
  console.log credentials

module.exports = (robot) ->
  robot.respond /recognition/i, yesterdaysRecognitions
  robot.respond /refresh/i, refreshToken
  robot.respond /inv/i, invalidateToken
    

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
