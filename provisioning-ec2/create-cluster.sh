#!/bin/bash
set -e

if [ $# -ne 5 ]; then
  echo "Usage: ./create-cluster.sh <N_of_boxes> <box_type> <slave_mem> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

N=$1
box_type=$2
slave_mem=$3
AWS_ACCESS_KEY_ID=$4
AWS_SECRET_ACCESS_KEY=$5

cluster_name="spark${1}"
master_security_group="sg-707d4d15"
slave_security_group="sg-737d4d16"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set +e
if ! type jq ; then echo "jq not found"; exit 1; fi
echo "All required soft installed"
if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "~/.ssh/id_rsa.pub not found"; exit 1; fi
echo "RSA public key is found at ~/.ssh/id_rsa.pub"
if [ ! -f ~/.ssh/data-key.pem ]; then echo "~/.ssh/data-key.pem not found"; exit 1; fi
echo "~/.ssh/data-key.pem is found"
set -e

echo "Running create-server.sh"
exec 5>&1
create_master_out=$($DIR/create-server.sh ${box_type} ${master_security_group} | tee >(cat - >&5))
master_pub_ip=$(echo "$create_master_out" | tail -n2 | head -n1)
master_priv_name=$(echo "$create_master_out" | tail -n1)
echo "master_pub_ip: $master_pub_ip"
echo "master_priv_name: $master_priv_name"

mkdir -p $DIR/../log-ec2

# CREATE SLAVES
echo "Schedule creating slaves"
for i in $(seq 1 $N); do
  echo "Schedule creating slave dn$i"
  cmd="$DIR/create-slave.sh $master_priv_name $box_type $slave_mem ${slave_security_group} $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY"
  nohup $cmd > $DIR/../log-ec2/create-slave-$cluster_name-$i.out 2>&1 < /dev/null &
done
echo "Schedule creating slaves done"

ip=$master_pub_ip

echo "Copying provisioning scripts to $ip"
scp -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $DIR ec2-user@$ip:/tmp/
echo "done"

echo "Running add-users.sh"
cmd="/tmp/provisioning-ec2/add-users.sh"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "Run install-master-soft.sh on background"
cmd="nohup /tmp/provisioning-ec2/install-master-soft.sh $N $slave_mem $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY > /tmp/log/install-master-soft.log 2>&1 < /dev/null &"
ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "----------------------------------------------------------------------"
echo "Resource Manager  http://${master_priv_name}:8088"
echo "Namenode          http://${master_priv_name}:50070"
echo "Timeline Server   http://${master_priv_name}:8188"
echo "History Server    http://${master_priv_name}:19888"
echo "Nodes List        http://${master_priv_name}:8088/ws/v1/cluster/nodes"
echo "zookeeper.quorum  ${master_priv_name}"
echo "SSH               ssh -i ~/.ssh/data-key.pem ec2-user@${master_pub_ip}"
echo "SSH tunnel        ssh -i ~/.ssh/data-key.pem -N -D 8157 ec2-user@${master_pub_ip}"
echo "----------------------------------------------------------------------"
