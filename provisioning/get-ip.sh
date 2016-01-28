#!/bin/bash
set -e

if [ $# -ne 3 ]; then
  echo "Usage: ./create-box.sh <login> <pass> <box_href>"
  exit -1
fi

login=$1
pass=$2
box_href=$3

json="{'username':'${login}','password':'${pass}'}"

# login
btoken=`curl -k -H "Content-Type: application/json" -X POST -d ${json} https://api.ctl.io/v2/authentication/login | jq -r ".bearerToken"`
echo "-----------"
echo $btoken
echo "-----------"
curl -H "Authorization: Bearer $btoken" https://api.ctl.io${box_href} | jq ".details.ipAddresses[].internal"
