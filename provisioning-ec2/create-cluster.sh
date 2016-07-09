#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./create-cluster.sh <json_conf_file>"
  exit -1
fi

# copy json conf file to /tmp
json_conf_file=/tmp/$(basename $1)
if [ $json_conf_file != $1 ]; then
  echo "Copying $1 to $json_conf_file"
  cp $1 $json_conf_file
fi
echo "json conf file: $json_conf_file"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh ${json_conf_file}

set +e
if ! type jq ; then echo "jq not found"; exit 1; fi
echo "All required soft installed"
if [ ! -f ~/.ssh/${key_name}.pem ]; then echo "~/.ssh/${key_name}.pem not found"; exit 1; fi
echo "~/.ssh/${key_name}.pem is found"
set -e

# check if aws works
aws ec2 describe-regions --region-names ${region} --region ${region} --profile ${profile}

# CREATE PLACEMENT GROUP
echo "Trying to create placement group: ${placement_group}"
set +e
aws ec2 create-placement-group --strategy cluster --group-name ${placement_group} --region ${region} --profile ${profile}
set -e
echo "done"

clusterId=$(date +%Y%m%d-%H%M%S)
echo "TAG clusterId: ${clusterId}"

echo "Running create-server.sh"
exec 5>&1
create_master_out=$($DIR/create-server.sh ${json_conf_file} $master_box_type $master_security_group $clusterId | tee >(cat - >&5))
master_pub_ip=$(echo "$create_master_out" | tail -n2 | head -n1)
master_priv_name=$(echo "$create_master_out" | tail -n1)
echo "master_pub_ip: $master_pub_ip"
echo "master_priv_name: $master_priv_name"

mkdir -p $DIR/../log-ec2

# CREATE SLAVES
echo "Schedule creating slaves"
for i in $(seq 1 $N); do
  echo "Schedule creating slave dn$i"
  cmd="$DIR/create-slave.sh ${json_conf_file} $master_priv_name $clusterId"
  nohup $cmd > $DIR/../log-ec2/create-slave-$clusterId-$i.out 2>&1 < /dev/null &
done
echo "Schedule creating slaves done"

ip=$master_pub_ip

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

echo "Run install-master-soft.sh on background"
cmd="nohup /tmp/provisioning-ec2/install-master-soft.sh ${json_conf_file} $master_priv_name > /tmp/log/install-master-soft.log 2>&1 < /dev/null &"
ssh -i ~/.ssh/${key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip $cmd
echo "done"

echo "------------------------------------------------------------------------------------------"
echo "Run SSH tunnel and use FoxyProxy in order to open private urls in browser!!!"
echo "------------------------------------------------------------------------------------------"
echo "Resource Manager  http://${master_priv_name}:8088"
echo "Namenode          http://${master_priv_name}:50070"
echo "Browse filesystem http://${master_priv_name}:50070/explorer.html#/"
echo "Timeline Server   http://${master_priv_name}:8188"
echo "History Server    http://${master_priv_name}:19888"
echo "WebHDFS REST API  http://${master_priv_name}:50070/webhdfs/v1/?op=LISTSTATUS"
echo "Nodes List        http://${master_priv_name}:8088/ws/v1/cluster/nodes"
echo "Hiveserver2       ${master_priv_name}:10000"
echo "TEZ-UI            http://${master_priv_name}/tez-ui/"
echo "Spark Jobserver   http://${master_priv_name}:8090"
echo "zookeeper.quorum  ${master_priv_name}"
echo "HBase Master      http://${master_priv_name}:16010"
echo "HBase thrift      ${master_priv_name}:9090"
echo "HUE               http://${master_priv_name}:8888"
echo "Zeppelin          http://${master_priv_name}:8890"
echo "------------------------------------------------------------------------------------------"
echo "SSH               ssh -i ~/.ssh/${key_name}.pem ec2-user@${master_pub_ip}"
echo "SSH tunnel        ssh -i ~/.ssh/${key_name}.pem -N -D 8157 ec2-user@${master_pub_ip}"
echo "TAG clusterId     ${clusterId}"
echo "------------------------------------------------------------------------------------------"
echo "Search for Spot Requests / Instances by TAG ${clusterId} to cancel / terminate them"
echo "------------------------------------------------------------------------------------------"

echo "Checking active slaves count"
set +e
nodesCnt=0
sl=120
while [ $nodesCnt -lt $N ]; do
  echo "sleep $sl"
  sleep $sl
  cmd="curl -m 10 -s http://${master_priv_name}:8088/ws/v1/cluster/nodes | jq '.nodes.node | length'"
  nodesCnt=$(ssh -q -i ~/.ssh/${key_name}.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@${master_pub_ip} $cmd)
  echo "active slaves count: $nodesCnt"
  sl=30
done
set -e

if [ $nodesCnt -eq $N ]; then
  echo "All slaves are active"
fi
