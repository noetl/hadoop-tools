#!/bin/bash

set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-aws.sh <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

AWS_ACCESS_KEY_ID=${1}
AWS_SECRET_ACCESS_KEY=${2}

cat > /tmp/credentials << EOL
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOL
echo "done"

echo "Configure aws credentials...."
mkdir -p ~/.aws
cp /tmp/credentials ~/.aws/

sudo su - hadoop -c 'mkdir -p ~/.aws'
sudo su - hadoop -c 'cp /tmp/credentials ~/.aws/'

sudo mkdir -p /root/.aws
sudo cp /tmp/credentials /root/.aws/

rm -rf /tmp/credentials

echo "done"
