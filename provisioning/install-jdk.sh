#!/bin/bash

set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-jdk.sh"
  exit -1
fi

# Try to install software using yum. For some reason first attempt might fail
echo "Installing java-devel jq..."
set +e
yum -y install java-devel jq
if [ $? -ne 0 ]; then
  sleep 10
  set -e
  yum -y install java-devel jq
fi
set -e
echo "Installing java-devel jq done"

echo "Installed java version is...."
java -version
javac -version
