#!/bin/bash

set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-aws.sh <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

AWS_ACCESS_KEY_ID=${1}
AWS_SECRET_ACCESS_KEY=${2}

echo "Installing aws..."
easy_install pip
pip install --upgrade awscli
echo "done"

echo "Configure aws credentials...."
su - hadoop -c 'mkdir -p ~/.aws'
su - hadoop -c 'touch ~/.aws/credentials'
cat > /home/hadoop/.aws/credentials << EOL
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOL
echo "done"

mkdir /root/.aws
cat > /root/.aws/credentials << EOL
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOL
echo "done"

echo "Configure aws alias and keys...."
cat >> /home/hadoop/.bashrc << EOL
# aws alias
alias aws="aws --endpoint-url https://canada.os.ctl.io/"

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
EOL
echo "done"

cat >> /root/.bashrc << EOL
# aws alias
alias aws="aws --endpoint-url https://canada.os.ctl.io/"

export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
EOL
echo "done"
