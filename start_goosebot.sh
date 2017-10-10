#!/bin/sh
 
export HUBOT_LCB_TOKEN=NTlkN2IyNmFjMGIwOTRkOTQ1YmJmNzExOjEwMDcyNDRhY2YxMTk5YjkyNjE1NDhlZTI2YzUwM2Q5NmEwN2NlN2U2OGNkNmIxZA==
export HUBOT_LCB_ROOMS=59d4f4fe2371047ebe68c641
 
export HUBOT_LCB_PROTOCOL=http
export HUBOT_LCB_HOSTNAME=localhost
export HUBOT_LCB_PORT=5000

echo "Enter the grant code you get from https://app.7geese.com/o/authorize/?client_id=JGZp6YU0JzgPlqnSgoOEI07KiJZYHYZET8zJMFQq&response_type=code&scope=all&redirect_uri=http://localhost:5000&state=my_state"
read GRANT_CODE
export GOOSE_CREDS=`curl https://app.7geese.com/o/token/ --data "code=$GRANT_CODE&client_id=JGZp6YU0JzgPlqnSgoOEI07KiJZYHYZET8zJMFQq&grant_type=authorization_code&state=my_state&redirect_uri=http://localhost:5000" -X POST`
bin/hubot -a lets-chat
