#!/bin/bash

set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-jdk.sh"
  exit -1
fi

# Try to install software using yum.
echo "Installing java-devel jq..."
sudo yum -y install java-devel jq
echo "Installing java-devel jq done"

echo "Installed java version is...."
java -version
javac -version
