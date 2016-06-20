#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./create-slave.sh <master_priv_name>"
  exit -1
fi

MASTER=$1

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Running create-server.sh"
exec 5>&1
create_server_out="$($DIR/create-server.sh | tee >(cat - >&5))"
server_pub_ip=$(echo "$create_server_out" | tail -n2 | head -n1)
echo "server_pub_ip: $server_pub_ip"
ip=$server_pub_ip

echo "Copying provisioning scripts to $ip"
scp -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $DIR ec2-user@$ip:/tmp/
echo "done"

echo "Running add-users.sh"
cmd="/tmp/provisioning-ec2/add-users.sh"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

#echo "Run install-slave-soft.sh on background"
#cmd="nohup /root/provisioning/install-slave-soft.sh ${MASTER} $slave_mem $slave_disk_cnt ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > /root/install-slave-soft.log 2>&1 < /dev/null &"
#ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip $cmd
#echo "done"
