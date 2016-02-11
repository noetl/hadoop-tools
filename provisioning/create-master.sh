#!/bin/bash

if [ $# -ne 4 ]; then
  echo "Usage: ./create-master.sh <group_hash> <master_cpu> <master_mem> <password>"
  exit -1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

group_hash=$1
master_cpu=$2
master_mem=$3
password=$4

echo "Create server..."
server_url=`$DIR/create-server.sh group_hash nn $password $master_cpu $master_mem`


echo "Sleep..."
sleep 60
echo "get IP..."
server_ip=`$DIR/get-ip.sh $server_url`

echo "IP: $server_ip"

pub_key=`cat ~/.ssh/id_rsa.pub`

echo "Adding pub key to authorized_keys"
python $DIR/add-auth-key.py

