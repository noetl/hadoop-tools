#!/bin/bash

if [ -z "$BTOKEN" ]; then
  echo "Need to . ./login.sh <user> <pass>"
  exit -1
fi

if [ $# -ne 2 ]; then
  echo "Usage: ./create-group.sh <name> <parent_group_id>"
  exit -1
fi

group_name=$1
parent_group_id=$2

curl -s -k -H "Authorization: Bearer ${BTOKEN}" -H 'Content-Type: application/json' -X POST \
-d "{'name':'${group_name}','parentGroupId':'${parent_group_id}'}" \
https://api.ctl.io/v2/groups/NOMS/ | jq -r ".id"
