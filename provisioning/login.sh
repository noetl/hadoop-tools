#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: . ./login.sh <login> <pass>"
  exit -1
fi

# login
export BTOKEN=`curl -s -k -H "Content-Type: application/json" -X POST -d "{'username':'${1}','password':'${2}'}" https://api.ctl.io/v2/authentication/login | jq -r ".bearerToken"`
echo $BTOKEN
