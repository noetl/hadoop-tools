#!/bin/bash
set -e

if [ $# -ne 7 ]; then
  echo "Usage: ./create-slave.sh <master_priv_name> <box_type> <slave_mem> <slave_security_group> <placement_group> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

MASTER=$1
box_type=$2
slave_mem=$3
slave_security_group=$4
placement_group=$5
AWS_ACCESS_KEY_ID=$6
AWS_SECRET_ACCESS_KEY=$7

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
LOG_DIR=/tmp/log

echo "Running create-server.sh"
exec 5>&1
create_server_out="$($DIR/create-server.sh ${box_type} ${slave_security_group} ${placement_group} | tee >(cat - >&5))"
server_pub_ip=$(echo "$create_server_out" | tail -n2 | head -n1)
echo "server_pub_ip: $server_pub_ip"
ip=$server_pub_ip

echo "Copying provisioning scripts to $ip"
scp -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $DIR ec2-user@$ip:/tmp/
echo "done"

echo "Running mount-disks.sh"
cmd="/tmp/provisioning-ec2/mount-disks.sh"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "Running add-users.sh"
cmd="/tmp/provisioning-ec2/add-users.sh"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "Run install-slave-soft.sh on background"
cmd="nohup /tmp/provisioning-ec2/install-slave-soft.sh ${MASTER} ${slave_mem} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > /tmp/log/install-slave-soft.log 2>&1 < /dev/null &"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"
