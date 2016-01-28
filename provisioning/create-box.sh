#!/bin/bash
set -e

if [ $# -ne 6 ]; then
  echo "Usage: ./create-box.sh <login> <pass> <box_name> <root_pass> <num_of_cpu> <mem_gb>"
  exit -1
fi

login=$1
pass=$2
box_name=$3
root_pass=$4
cpu=$5
mem_gb=$6

groupid="c19748ac63dc4f3396765bed5e639344"
networkid="24b8eb5774ad41209462c55f18aa5017"

json="{'username':'${login}','password':'${pass}'}"

# login
btoken=`curl -k -H "Content-Type: application/json" -X POST -d ${json} https://api.ctl.io/v2/authentication/login | jq -r ".bearerToken"`

echo "---------"
echo $btoken
echo "---------"
# create box
self_href=`curl -k -H "Authorization: Bearer $btoken" -X POST -d "{
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

echo "---------"
echo $self_href
echo "---------"

curl -H "Authorization: Bearer $btoken" https://api.ctl.io${self_href}
