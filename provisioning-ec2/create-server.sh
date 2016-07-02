#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./create-server.sh <box_type> <security_group>"
  exit -1
fi

box_type=$1
security_group=$2

cat > /tmp/aws-spec.json << EOL
{
  "ImageId": "ami-f303fb93",
  "KeyName": "data-key",
  "SecurityGroupIds": [ "${security_group}" ],
  "InstanceType": "${box_type}",
  "SubnetId": "subnet-2550fe52",
  "Placement": {
    "AvailabilityZone": "us-west-2b"
  }
}
EOL

spot_resp=$(aws ec2 request-spot-instances \
--spot-price 2.99 \
--instance-count 1 \
--launch-group spark_grp \
--launch-specification file:///tmp/aws-spec.json \
--region us-west-2 --profile n_aws)

requesId=$(echo $spot_resp | jq -r ".SpotInstanceRequests[0].SpotInstanceRequestId")
echo "requesId: $requesId"

state="none"
while [ $state != "active" ]; do
  echo "sleep 30"
  sleep 30

  spot_desc=$(aws ec2 describe-spot-instance-requests \
  --spot-instance-request-ids $requesId \
  --region us-west-2 --profile n_aws)

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
  --region us-west-2 --profile n_aws)

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
