#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./create-slave.sh <json_conf_file> <master_priv_name>"
  exit -1
fi

json_conf_file=$1
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh $json_conf_file

MASTER=$2
LOG_DIR=/tmp/log

echo "Running create-server.sh"
exec 5>&1
create_server_out="$($DIR/create-server.sh ${json_conf_file} ${slave_box_type} ${slave_security_group} | tee >(cat - >&5))"
server_pub_ip=$(echo "$create_server_out" | tail -n2 | head -n1)
echo "server_pub_ip: $server_pub_ip"
ip=$server_pub_ip

echo "Copying provisioning scripts to $ip"
scp -i ~/.ssh/${key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $DIR ec2-user@$ip:/tmp/
scp -i ~/.ssh/${key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ${json_conf_file} ec2-user@$ip:${json_conf_file}
echo "done"

echo "Running mount-disks.sh"
cmd="/tmp/provisioning-ec2/mount-disks.sh"
ssh -i ~/.ssh/${key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "Running add-users.sh"
cmd="/tmp/provisioning-ec2/add-users.sh"
ssh -i ~/.ssh/${key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "Run install-slave-soft.sh on background"
cmd="nohup /tmp/provisioning-ec2/install-slave-soft.sh ${json_conf_file} ${MASTER} > /tmp/log/install-slave-soft.log 2>&1 < /dev/null &"
ssh -i ~/.ssh/${key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"
