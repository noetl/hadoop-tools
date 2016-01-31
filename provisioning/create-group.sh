#!/bin/bash

if [ -z "$BTOKEN" ]; then
  echo "Need to . ./login.sh <user> <pass>"
  exit -1
fi

if [ $# -ne 1 ]; then
  echo "Usage: ./create-group.sh <name>"
  exit -1
fi

group_name=$1

CA3_CANADA_GRP="2cac06252b01e411a3fe005056820efb"
parent_group_id=$CA3_CANADA_GRP

curl -s -k -H "Authorization: Bearer ${BTOKEN}" -H 'Content-Type: application/json' -X POST \
-d "{'name':'${group_name}','parentGroupId':'${parent_group_id}'}" \
https://api.ctl.io/v2/groups/NOMS/ | jq -r ".id"
