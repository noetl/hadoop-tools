#!/bin/bash

set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./install-aws.sh <json_conf_file>"
  exit -1
fi

json_conf_file=$1
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh $json_conf_file

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
