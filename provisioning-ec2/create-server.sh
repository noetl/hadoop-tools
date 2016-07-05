#!/bin/bash
set -e

if [ $# -ne 3 ]; then
  echo "Usage: ./create-server.sh <json-conf> <box_type> <security_group>"
  exit -1
fi

echo ${1}

json_conf_file=$1
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh $json_conf_file

box_type=$2
security_group=$3

cat > /tmp/aws-spec.json << EOL
{
  "ImageId": "ami-f303fb93",
  "KeyName": "data-key",
  "SecurityGroupIds": [ "${security_group}" ],
  "InstanceType": "${box_type}",
  "SubnetId": "${subnet_id}",
  "Placement": {
    "AvailabilityZone": "us-west-2b",
    "GroupName": "${placement_group}"
  },
  "BlockDeviceMappings": [ {"VirtualName": "ephemeral0", "DeviceName": "/dev/xvdb"} ]
}
EOL

spot_resp=$(aws ec2 request-spot-instances \
--spot-price ${spot_price} \
--instance-count 1 \
--launch-group spark_grp \
--launch-specification file:///tmp/aws-spec.json \
--region ${region} --profile ${profile})

requesId=$(echo $spot_resp | jq -r ".SpotInstanceRequests[0].SpotInstanceRequestId")
echo "requesId: $requesId"

state="none"
while [ $state != "active" ]; do
  echo "sleep 30"
  sleep 30

  spot_desc=$(aws ec2 describe-spot-instance-requests \
  --spot-instance-request-ids $requesId \
  --region us-west-2 --profile ${profile})

  state=$(echo $spot_desc | jq -r ".SpotInstanceRequests[0].State")
  echo "SpotInstanceRequest state: $state"
done

instanceId=$(echo $spot_desc | jq -r ".SpotInstanceRequests[0].InstanceId")
echo "instanceId: $instanceId"

inst_state="none"
sleep_t=0
while [ $inst_state != "16" ]; do
  echo "sleep $sleep_t"
  sleep $sleep_t

  inst_desc=$(aws ec2 describe-instances \
  --instance-ids $instanceId \
  --region us-west-2 --profile ${profile})

  inst_state=$(echo $inst_desc | jq -r ".Reservations[0].Instances[0].State.Code")
  echo "Instance state code: $inst_state"
  sleep_t=10
done

server_pub_ip=$(echo $inst_desc | jq -r ".Reservations[0].Instances[0].PublicIpAddress")
echo "server_pub_ip: $server_pub_ip"
server_pub_name=$(echo $inst_desc | jq -r ".Reservations[0].Instances[0].PublicDnsName")
echo "server_pub_name: $server_pub_name"

server_priv_ip=$(echo $inst_desc | jq -r ".Reservations[0].Instances[0].PrivateIpAddress")
echo "server_priv_ip: $server_priv_ip"
server_priv_name=$(echo $inst_desc | jq -r ".Reservations[0].Instances[0].PrivateDnsName")
echo "server_priv_name: $server_priv_name"

set +e
ssh_code="-1"
sleep_t=0
while [ $ssh_code != "0" ]; do
  echo "sleep $sleep_t for server to settle down"
  sleep $sleep_t
  ssh -i ~/.ssh/data-key.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$server_pub_ip exit
  ssh_code=$?
  sleep_t=10
done
set -e



echo $server_pub_ip
echo $server_priv_name
