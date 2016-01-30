#!/bin/bash
set -e

if [ -z "$BTOKEN" ]; then
  echo "Need to . ./login.sh <user> <pass>"
  exit -1
fi

if [ $# -ne 4 ]; then
  echo "Usage: ./create-box.sh <box_name> <root_pass> <num_of_cpu> <mem_gb>"
  exit -1
fi

box_name=$1
root_pass=$2
cpu=$3
mem_gb=$4

groupid="c19748ac63dc4f3396765bed5e639344"
networkid="24b8eb5774ad41209462c55f18aa5017"

echo "creating box...."

# create box
self_href=`curl -k -H "Authorization: Bearer $BTOKEN" -X POST -d "{
  'name': '${box_name}',
  'description': '${box_name}',
  'groupId': '${groupid}',
  'sourceServerId': 'CENTOS-7-64-TEMPLATE',
  'isManagedOS': false,
  'networkId': '${networkid}',
  'password': '${root_pass}',
  'cpu': ${cpu},
  'memoryGB': ${mem_gb},
  'type': 'standard',
  'storageType': 'standard'
}" \
https://api.ctl.io/v2/servers/NOMS/ | jq -r ".links[1].href"`

echo "---------------------------------------------"
echo $self_href
echo "---------------------------------------------"

# curl -H "Authorization: Bearer $btoken" https://api.ctl.io${self_href}
