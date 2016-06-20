#!/bin/bash
set -e

cat > /tmp/aws-spec.json << EOL
{
  "ImageId": "ami-f303fb93",
  "KeyName": "spark2",
  "SecurityGroupIds": [ "sg-737d4d16" ],
  "InstanceType": "r3.large",
  "SubnetId": "subnet-2550fe52",
  "Placement": {
    "AvailabilityZone": "us-west-2b"
  }
}
EOL

spot_resp=`aws ec2 request-spot-instances \
--spot-price 2.99 \
--instance-count 1 \
--launch-group alex_grp \
--launch-specification file:///tmp/aws-spec.json \
--region us-west-2 --profile n_aws`

requesId=`echo $spot_resp | jq -r ".SpotInstanceRequests[0].SpotInstanceRequestId"`
echo "requesId: $requesId"

state="none"
while [ $state != "active" ]; do
  echo "sleep 30"
  sleep 30

  spot_desc=`aws ec2 describe-spot-instance-requests \
  --spot-instance-request-ids $requesId \
  --region us-west-2 --profile n_aws`

  state=`echo $spot_desc | jq -r ".SpotInstanceRequests[0].State"`
  echo "SpotInstanceRequest state: $state"
done

instanceId=`echo $spot_desc | jq -r ".SpotInstanceRequests[0].InstanceId"`
echo "instanceId: $instanceId"

inst_state="none"
while [ $inst_state != "16" ]; do
  echo "sleep 20"
  sleep 20

  inst_desc=`aws ec2 describe-instances \
  --instance-ids $instanceId \
  --region us-west-2 --profile n_aws`

  inst_state=`echo $inst_desc | jq -r ".Reservations[0].Instances[0].State.Code"`
  echo "Instance state code: $inst_state"
done

server_pub_ip=`echo $inst_desc | jq -r ".Reservations[0].Instances[0].PublicIpAddress"`
echo "server_pub_ip: $server_pub_ip"
server_pub_name=`echo $inst_desc | jq -r ".Reservations[0].Instances[0].PublicDnsName"`
echo "server_pub_name: $server_pub_name"

server_ip=`echo $inst_desc | jq -r ".Reservations[0].Instances[0].PrivateIpAddress"`
echo "server_ip: $server_ip"
server_name=`echo $inst_desc | jq -r ".Reservations[0].Instances[0].PrivateDnsName"`
echo "server_name: $server_name"

echo $server_pub_ip
echo $server_name
