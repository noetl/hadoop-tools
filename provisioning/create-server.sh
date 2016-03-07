#!/bin/bash
set -e

if [ -z "$BTOKEN" ]; then
  echo "Need to . ./login.sh <user> <pass>"
  exit -1
fi

if [ $# -ne 8 ]; then
  echo "Usage: ./create-server.sh <group_id> <box_name> <root_pass> <num_of_cpu> <mem_gb> <disk_cnt> <disk_gb> <network_id>"
  exit -1
fi

group_id=$1
box_name=$2
root_pass=$3
cpu=$4
mem_gb=$5
disk_cnt=$6
disk_gb=$7
network_id=$8

disk_list=`for ((i=1; i<=$disk_cnt; i++)); do
  p="0"
  if [ $i -gt 9 ]; then p=""; fi
  id=$p$i
  comma=","
  if [ $i -eq $disk_cnt ]; then comma=""; fi
  adj_disk_gb=$disk_gb
  # add 50 GB to the first disk to store logs /disk01/var/log
  if [ $i -eq 1 ]; then adj_disk_gb=$[disk_gb+50]; fi
  echo "{ 'path': '/data$id', 'sizeGB': $adj_disk_gb, 'type': 'partitioned' }${comma}"
done`

body="{
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
  'storageType': 'standard',
  'additionalDisks':[
    $disk_list
  ]
}"

# echo "$body"

# create box
curl -m 10 -s -H "Authorization: Bearer $BTOKEN" -H "Content-Type: application/json" -X POST -d "$body" \
  https://api.ctl.io/v2/servers/NOMS/
