#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./create-cluster.sh <N_of_boxes>"
  exit -1
fi

N=$1
cluster_name="spark${1}"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set +e
if ! type jq ; then echo "jq not found"; exit 1; fi
echo "All required soft installed"
if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "~/.ssh/id_rsa.pub not found"; exit 1; fi
echo "RSA public key is found at ~/.ssh/id_rsa.pub"
set -e

echo "Running create-server.sh"
exec 5>&1
create_master_out=$($DIR/create-server.sh | tee >(cat - >&5))
master_pub_ip=$(echo "$create_master_out" | tail -n2 | head -n1)
master_priv_name=$(echo "$create_master_out" | tail -n1)
echo "master_pub_ip: $master_pub_ip"
echo "master_priv_name: $master_priv_name"

mkdir -p $DIR/../log-ec2

# CREATE SLAVES
echo "Schedule creating slaves"
for i in $(seq 1 $N); do
  echo "Schedule creating slave dn$i"
  cmd="$DIR/create-slave.sh $master_priv_name"
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

echo "----------------------------------------------------------------------"
echo "SSH               ssh -i ~/.ssh/data-key.pem ec2-user@${master_pub_ip}"
echo "----------------------------------------------------------------------"
