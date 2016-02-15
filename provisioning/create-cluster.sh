#!/bin/bash

set -e

if [ $# -ne 11 ]; then
  echo "Usage: ./create-cluster.sh <ctl_login> <ctl_password> <group_name> <N_of_boxes> <master_cpu> <master_mem> <slave_cpu> <slave_mem> <root_passwoed> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ctl_login=$1
ctl_password=$2
group_name=$3
N=$4
master_cpu=$5
master_mem=$6
slave_cpu=$7
slave_mem=$8
root_password=$9
AWS_ACCESS_KEY_ID=$10
AWS_SECRET_ACCESS_KEY=$11

echo "Running login.sh"
. $DIR/login.sh $ctl_login $ctl_password
echo "done"

echo "Running create-group.sh"
group_hash=`$DIR/create-group.sh $group_name`
echo "done $group_hash"

echo "Running create-server.sh"
server_url=`$DIR/create-server.sh $group_hash dn2 Nomis123 2 8`
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
  if [[ $ip =~ ^\"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\"$ ]]; then
    is_ip=1
    ip=${ip:1:${#ip}-2}
  fi
done

set -e

echo "final ip: $ip"

p1=$(echo $ip | cut -d. -f1)
p2=$(echo $ip | cut -d. -f2)
p3=$(echo $ip | cut -d. -f3)
p4=$(echo $ip | cut -d. -f4)

master_hostname="ip-$p1-$p2-$p3-$p4"
echo "master_hostname $master_hostname"

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

echo "Run install-master-soft.sh on background"
cmd="nohup /root/provisioning/install-master-soft.sh ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > /root/install-master-soft.log 2>&1 < /dev/null &"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip $cmd
echo "done"

# CREATE SLAVES

mkdir -p $DIR/../log

for i in `seq 1 $N`; do
  cmd="$DIR/create-slave.sh $group_hash $master_hostname dn$i $slave_cpu $slave_mem $root_password $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY"
  nohup $cmd > $DIR/../log/create-slave-$group_name-$i.out 2>&1 < /dev/null &
done

# URLs
echo "Resource Manager http://${master_hostname}:8088"
echo "Namenode         http://${master_hostname}:50070"
echo "Nodes List       http://ip-10-101-124-30:8088/ws/v1/cluster/nodes"
