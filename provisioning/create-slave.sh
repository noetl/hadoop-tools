#!/bin/bash

set -e

if [ $# -ne 11 ]; then
  echo "Usage: ./create-slave.sh <group_hash> <master_hostname> <slave_name> <slave_cpu> <slave_mem> <slave_disk_cnt> <slave_disk_size> <root_password> <network_id> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

group_hash=$1
MASTER=$2
slave_name=$3
slave_cpu=$4
slave_mem=$5
slave_disk_cnt=$6
slave_disk_size=$7
root_password=$8
network_id=$9
AWS_ACCESS_KEY_ID=${10}
AWS_SECRET_ACCESS_KEY=${11}

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Running create-server.sh"
create_server_resp=`$DIR/create-server.sh $group_hash $slave_name $root_password $slave_cpu $slave_mem $slave_disk_cnt $slave_disk_size $network_id`
echo $create_server_resp
server_url=`echo $create_server_resp | jq -r '.links[] | select(.rel=="self") | .href'`
if [ $server_url == "null" ]; then
  echo "Can not extract server href from create_server_resp"
  exit 1;
fi
echo "server_url: $server_url"

echo "Getting ip address..."
set +e
is_ip=0
while [ $is_ip == 0 ]; do
  echo "sleep 30"
  sleep 30
  echo "Running get-ip.sh"
  ip=`$DIR/get-ip.sh $server_url`
  echo "ip: $ip"
  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    is_ip=1
  fi 
done

set -e

echo "final ip: $ip"

echo "sleep 30 for server to settle down"
sleep 30

echo "Adding pub key to authorized_keys on server"
python $DIR/add-auth-key.py $ip $root_password
echo "done"

echo "Copying provisioning scripts to $ip"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $DIR root@$ip:
echo "done"

echo "Running set-hostnames.sh"
cmd="/root/provisioning/set-hostnames.sh"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip $cmd
echo "done"

echo "Running add-users.sh"
cmd="/root/provisioning/add-users.sh"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip $cmd
echo "done"

echo "Run install-slave-soft.sh on background"
cmd="nohup /root/provisioning/install-slave-soft.sh ${MASTER} $slave_mem $slave_disk_cnt ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > /root/install-slave-soft.log 2>&1 < /dev/null &"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip $cmd
echo "done"
