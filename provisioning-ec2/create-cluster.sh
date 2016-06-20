#!/bin/bash
set -e

key_path="~/.ssh/spark2.pem"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

set +e
if ! type jq ; then echo "jq not found"; exit 1; fi
echo "All required soft installed"
if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "~/.ssh/id_rsa.pub not found"; exit 1; fi
echo "RSA public key is found at ~/.ssh/id_rsa.pub"
set -e

echo "Running create-server.sh"
$DIR/create-server.sh | tee /tmp/create-master.out
master_pub_ip=`tail -n2 /tmp/create-master.out | head -n1`
master_priv=`tail -n1 /tmp/create-master.out`
echo "master_pub_ip: $master_pub_ip"
echo "master_priv: $master_priv"

mkdir -p $DIR/../log-ec2

ip=$master_pub_ip

sleep 30

echo "Copying provisioning scripts to $ip"
scp -i $key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r $DIR ec2-user@$ip:/tmp/
echo "done"

echo "Running add-users.sh"
cmd="/tmp/provisioning-ec2/add-users.sh"
ssh -i $key_path -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "-----------------------------------------------------------"
echo "SSH               ssh -i $key_path ec2-user@${master_pub_ip}"
echo "-----------------------------------------------------------"
