#!/bin/bash

set -e

if [ $# -ne 15 ]; then
  echo "Usage: ./create-cluster.sh <ctl_login> <ctl_password> <group_name> <parent_group_id> <N_of_boxes> <master_cpu> <master_mem> <slave_cpu> <slave_mem> <slave_disk_cnt> <slave_disk_size> <root_passwoed> <network_id> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ctl_login=$1
ctl_password=$2
group_name=$3
parent_group_id=$4
N=$5
master_cpu=$6
master_mem=$7
slave_cpu=$8
slave_mem=$9
slave_disk_cnt=${10}
slave_disk_size=${11}
root_password=${12}
network_id=${13}
AWS_ACCESS_KEY_ID=${14}
AWS_SECRET_ACCESS_KEY=${15}
#ZEPPELIN_NOTEBOOK_S3_BUCKET=${16}
#ZEPPELIN_NOTEBOOK_S3_USER=${17}

echo "-----------------------------------------------"
echo "ctl_login:             $ctl_login"
echo "ctl_password:          $ctl_password"
echo "group_name:            $group_name"
echo "parent_group_id:       $parent_group_id"
echo "Number of slaves:      $N"
echo "master_cpu:            $master_cpu"
echo "master_mem_gb:         $master_mem"
echo "slave_cpu:             $slave_cpu"
echo "slave_mem_gb:          $slave_mem"
echo "slave_disk_cnt:        $slave_disk_cnt"
echo "slave_disk_size_gb:    $slave_disk_size"
echo "root_password:         $root_password"
echo "network_id:            $network_id"
echo "AWS_ACCESS_KEY_ID:     ${AWS_ACCESS_KEY_ID}"
echo "AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}"
#echo "ZEPPELIN_NOTEBOOK_S3_BUCKET: ${ZEPPELIN_NOTEBOOK_S3_BUCKET}"
#echo "ZEPPELIN_NOTEBOOK_S3_USER:   ${ZEPPELIN_NOTEBOOK_S3_USER}"
echo "-----------------------------------------------"

echo "Running login.sh"
. $DIR/login.sh $ctl_login $ctl_password
echo "done"

echo "Getting Network Gateway..."
network_gateway=`$DIR/get-network-details.sh ${network_id} | jq -r ".gateway"`
echo "Network Gateway: ${network_gateway}"

set +e
if ! type jq ; then echo "jq not found"; exit 1; fi
if ! python -c "import paramiko" ; then echo "Python module paramiko not found"; exit 1; fi
echo "All required soft installed"
if [ ! -f ~/.ssh/id_rsa.pub ]; then echo "~/.ssh/id_rsa.pub not found"; exit 1; fi
echo "RSA public key is found at ~/.ssh/id_rsa.pub"
if ! ping -c 1 ${network_gateway} ; then echo "Can not ping network gateway ${network_gateway}, check VPN connection"; exit 1; fi
echo "VPN is connected"
set -e

echo "Running create-group.sh"
group_id=`$DIR/create-group.sh $group_name $parent_group_id`
echo "-----------------------------------------------"
echo "group_id: $group_id"
echo "-----------------------------------------------"

echo "Running create-server.sh"
server_url=`$DIR/create-server.sh $group_id nn $root_password $master_cpu $master_mem 1 1 $network_id`
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

p1=$(echo $ip | cut -d. -f1)
p2=$(echo $ip | cut -d. -f2)
p3=$(echo $ip | cut -d. -f3)
p4=$(echo $ip | cut -d. -f4)

MASTER="ip-$p1-$p2-$p3-$p4"
echo "MASTER $MASTER"

mkdir -p $DIR/../log

# CREATE SLAVES
echo "Schedule creating slaves"
for i in `seq 1 $N`; do
  echo "Schedule creating slave dn$i"
  cmd="$DIR/create-slave.sh $group_id $MASTER dn$i $slave_cpu $slave_mem $slave_disk_cnt $slave_disk_size $root_password $network_id $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY"
  nohup $cmd > $DIR/../log/create-slave-$group_name-$i.out 2>&1 < /dev/null &
done
echo "Schedule creating slaves done"

# Configure master and install soft
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

echo "Run install-master-soft.sh on background"
cmd="nohup /root/provisioning/install-master-soft.sh $N $slave_mem $slave_disk_cnt ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > /root/install-master-soft.log 2>&1 < /dev/null &"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$ip $cmd
echo "done"

# URLs
echo "-----------------------------------------------------------"
echo "Resource Manager  http://${MASTER}:8088"
echo "Namenode          http://${MASTER}:50070"
echo "HBase Master      http://${MASTER}:60010"
echo "Nodes List        http://${MASTER}:8088/ws/v1/cluster/nodes"
echo "Hiveserver2       ${MASTER}:10000"
#echo "Hiveserver2 UI    ${MASTER}:10002"
echo "Zeppelin          http://${MASTER}:8080/"
echo "SSH               ssh hadoop@${MASTER}"
echo "zookeeper.quorum  ${MASTER}"
echo "Terminate cluster $DIR/delete-group.sh $group_id"
echo "-----------------------------------------------------------"
