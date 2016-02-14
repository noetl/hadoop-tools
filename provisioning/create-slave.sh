#!/bin/bash

if [ $# -ne 6 ]; then
  echo "Usage: ./create-slave.sh <login> <password> <group_hash> <master_hostname> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

login=$1
password=$2
group_hash=$3
master=$4
AWS_ACCESS_KEY_ID=$5
AWS_SECRET_ACCESS_KEY=$6

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

$DIR/login.sh $login $password
server_url=`$DIR/create-server.sh $group_hash dn2 Nomis123 2 8`
echo "server_url: $server_url"

is_ip=0
while [ $is_ip == 0 ]; do
  echo "sleep 30"
  sleep 30
  ip=`$DIR/get-ip.sh $server_url`
  echo "ip: $ip"
  if [[ $ip =~ ^\"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\"$ ]]; then
    is_ip=1
    ip=${ip:1:${#ip}-2}
  fi 
done

echo "final ip: $ip"

set -e

echo "Adding pub key to authorized_keys on server"
python $DIR/add-auth-key.py $ip Nomis123
echo "done"

echo "Copying provisioning scripts to $ip"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $DIR root@$ip:
echo "done"

echo "Running set-hostnames.sh"
cmd="/root/provisioning/set-hostnames.sh"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip $cmd
echo "done"

echo "Running install-hadoop.sh"
cmd="nohup /root/provisioning/install-hadoop.sh ${master} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > install-hadoop.log 2>&1 < /dev/null &"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip $cmd
echo "done"
