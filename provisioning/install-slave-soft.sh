#!/bin/bash

set -e

if [ $# -ne 5 ]; then
  echo "Usage: ./install-slave-soft.sh <master_hostname> <slave_mem> <slave_disk_cnt> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

MASTER=$1
slave_mem=$2
slave_disk_cnt=$3
AWS_ACCESS_KEY_ID=$4
AWS_SECRET_ACCESS_KEY=$5

LOG_DIR="/root"
DIR="/root/provisioning"

# Install JDK
echo "Installing JDK..."
$DIR/install-jdk.sh > $LOG_DIR/install-jdk.log 2>&1
echo "done"

# Install Hadoop
echo "Installing Hadoop..."
$DIR/install-hadoop.sh ${MASTER} $slave_mem $slave_disk_cnt ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > $LOG_DIR/install-hadoop.log 2>&1
echo "done"

# Install HBase
echo "Installing HBase..."
$DIR/install-hbase.sh ${MASTER} > $LOG_DIR/install-hbase.log 2>&1
echo "done"

echo ""
echo "All software installed successfully"
