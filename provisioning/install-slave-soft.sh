#!/bin/bash

set -e

if [ $# -ne 4 ]; then
  echo "Usage: ./install-slave-soft.sh <master_hostname> <slave_mem> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

MASTER=$1
slave_mem=$2
AWS_ACCESS_KEY_ID=$3
AWS_SECRET_ACCESS_KEY=$4

LOG_DIR="/root"
DIR="/root/provisioning"

# Try to install software using yum. For some reason first attempt might fail
echo "Installing java-devel..."
set +e
yum -y install java-devel
if [ $? -ne 0 ]; then
  sleep 10
  set -e
  yum -y install java-devel
fi
set -e
echo "Installing java-devel done"

echo "Installed java version is...."
java -version
javac -version

# Install Hadoop
echo "Installing Hadoop..."
$DIR/install-hadoop.sh ${MASTER} $slave_mem ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > $LOG_DIR/install-hadoop.log 2>&1
echo "done"

# Install HBase
echo "Installing HBase..."
$DIR/install-hbase.sh ${MASTER} > $LOG_DIR/install-hbase.log 2>&1
echo "done"

echo ""
echo "All software installed successfully"
