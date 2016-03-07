#!/bin/bash

if [ -z "$BTOKEN" ]; then
  echo "Need to . ./login.sh <user> <pass>"
  exit -1
fi

if [ $# -ne 1 ]; then
  echo "Usage: ./delete-group.sh <groupid>"
  exit -1
fi

group_id=$1

curl -m 10 -s -H "Authorization: Bearer ${BTOKEN}" -X DELETE https://api.ctl.io/v2/groups/NOMS/$group_id
