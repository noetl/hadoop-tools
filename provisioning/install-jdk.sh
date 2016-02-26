#!/bin/bash

set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-jdk.sh"
  exit -1
fi

# Try to install software using yum. For some reason first attempt might fail
echo "Installing java-devel jq screen..."
set +e
yum -y install java-devel jq screen
if [ $? -ne 0 ]; then
  sleep 10
  set -e
  yum -y install java-devel jq screen
fi
set -e
echo "Installing java-devel jq screen done"

echo "Installed java version is...."
java -version
javac -version
