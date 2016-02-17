#!/bin/bash
set -e

if [ -z "$BTOKEN" ]; then
  echo "Need to . ./login.sh <user> <pass>"
  exit -1
fi

if [ $# -ne 6 ]; then
  echo "Usage: ./create-server.sh <group_id> <box_name> <root_pass> <num_of_cpu> <mem_gb> <network_id>"
  exit -1
fi

group_id=$1
box_name=$2
root_pass=$3
cpu=$4
mem_gb=$5
network_id=$6

# create box
self_href=`curl -s -k -H "Authorization: Bearer $BTOKEN" -H "Content-Type: application/json" -X POST -d "{
  'name': '${box_name}',
  'description': '${box_name}',
  'groupId': '${group_id}',
  'sourceServerId': 'CENTOS-7-64-TEMPLATE',
  'isManagedOS': false,
  'networkId': '${network_id}',
  'password': '${root_pass}',
  'cpu': ${cpu},
  'memoryGB': ${mem_gb},
  'type': 'standard',
  'storageType': 'standard'
}" \
https://api.ctl.io/v2/servers/NOMS/ | jq -r ".links[1].href"`

echo $self_href

# curl -H "Authorization: Bearer $btoken" https://api.ctl.io${self_href}
