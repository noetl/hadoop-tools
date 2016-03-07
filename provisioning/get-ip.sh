#!/bin/bash
set -e

if [ -z "$BTOKEN" ]; then
  echo "Need to . ./login.sh <user> <pass>"
  exit -1
fi

if [ $# -ne 1 ]; then
  echo "Usage: ./get-ip.sh <box_href>"
  exit -1
fi

box_href=$1

resp=`curl -m 10 -s -H "Authorization: Bearer $BTOKEN" https://api.ctl.io${box_href}`

status=`echo $resp | jq -r '.status'`

if [ $status == "active" ]; then
  echo $resp | jq -r ".details.ipAddresses[].internal"
else
  echo $status
fi
