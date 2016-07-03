#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./create-cluster.sh <json_conf_file>"
  exit -1
fi

set +e
if ! type jq ; then echo "jq not found"; exit 1; fi
echo "All required soft installed"
if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "~/.ssh/id_rsa.pub not found"; exit 1; fi
echo "RSA public key is found at ~/.ssh/id_rsa.pub"
if [ ! -f ~/.ssh/data-key.pem ]; then echo "~/.ssh/data-key.pem not found"; exit 1; fi
echo "~/.ssh/data-key.pem is found"
set -e

# copy json conf file to /tmp
json_conf_file=/tmp/$(basename $1)
if [ $json_conf_file != $1 ]; then
  echo "Copying $1 to $json_conf_file"
  cp $1 $json_conf_file
fi
echo "json conf file: $json_conf_file"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh ${json_conf_file}

cluster_name="spark${N}"

# CREATE PLACEMENT GROUP
echo "Trying to create placement group: ${placement_group}"
set +e
aws ec2 create-placement-group --strategy cluster --group-name ${placement_group} --region ${region} --profile ${profile}
set -e
echo "done"

echo "Running create-server.sh"
exec 5>&1
create_master_out=$($DIR/create-server.sh ${json_conf_file} $master_box_type $master_security_group | tee >(cat - >&5))
echo "-----------"
echo "$create_master_out"
echo "----------------"
master_pub_ip=$(echo "$create_master_out" | tail -n2 | head -n1)
master_priv_name=$(echo "$create_master_out" | tail -n1)
echo "master_pub_ip: $master_pub_ip"
echo "master_priv_name: $master_priv_name"

mkdir -p $DIR/../log-ec2

# CREATE SLAVES
echo "Schedule creating slaves"
for i in $(seq 1 $N); do
  echo "Schedule creating slave dn$i"
  cmd="$DIR/create-slave.sh ${json_conf_file} $master_priv_name"
  nohup $cmd > $DIR/../log-ec2/create-slave-$cluster_name-$i.out 2>&1 < /dev/null &
done
echo "Schedule creating slaves done"

ip=$master_pub_ip

echo "Copying provisioning scripts to $ip"
scp -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $DIR ec2-user@$ip:/tmp/
scp -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ${json_conf_file} ec2-user@$ip:${json_conf_file}
echo "done"

echo "Running mount-disks.sh"
cmd="/tmp/provisioning-ec2/mount-disks.sh"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "Running add-users.sh"
cmd="/tmp/provisioning-ec2/add-users.sh"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "Run install-master-soft.sh on background"
cmd="nohup /tmp/provisioning-ec2/install-master-soft.sh ${json_conf_file} $master_priv_name > /tmp/log/install-master-soft.log 2>&1 < /dev/null &"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "----------------------------------------------------------------------"
echo "Resource Manager  http://${master_priv_name}:8088"
echo "Namenode          http://${master_priv_name}:50070"
echo "Timeline Server   http://${master_priv_name}:8188"
echo "History Server    http://${master_priv_name}:19888"
echo "Nodes List        http://${master_priv_name}:8088/ws/v1/cluster/nodes"
echo "Hiveserver2       ${master_priv_name}:10000"
echo "Spark Jobserver   http://${master_priv_name}:8090"
echo "zookeeper.quorum  ${master_priv_name}"
echo "SSH               ssh -i ~/.ssh/data-key.pem ec2-user@${master_pub_ip}"
echo "SSH tunnel        ssh -i ~/.ssh/data-key.pem -N -D 8157 ec2-user@${master_pub_ip}"
echo "----------------------------------------------------------------------"
