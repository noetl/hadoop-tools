#!/usr/bin/env bash

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

aws ec2 request-spot-instances \
--spot-price 2.99 \
--instance-count 1 \
--launch-group alex_grp \
--launch-specification file:///tmp/aws-spec.json \
--region us-west-2 \
--profile n_aws
