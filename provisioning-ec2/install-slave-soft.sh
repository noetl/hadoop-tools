#!/bin/bash

set -e

if [ $# -ne 3 ]; then
  echo "Usage: ./install-slave-soft.sh <master_hostname> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

MASTER=$1
slave_mem=60
slave_disk_cnt=1
AWS_ACCESS_KEY_ID=$2
AWS_SECRET_ACCESS_KEY=$3

LOG_DIR="/tmp/log"
DIR="/tmp/provisioning-ec2"

mkdir -p $LOG_DIR

# Install JDK
echo "Installing JDK..."
$DIR/install-jdk.sh > $LOG_DIR/install-jdk.log 2>&1
echo "done"

# Install aws cli
echo "Installing aws cli..."
$DIR/install-aws.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY > $LOG_DIR/install-aws.log 2>&1
echo "done"

# Install Zookeeper
echo "Installing Zookeeper..."
$DIR/install-zookeeper.sh > $LOG_DIR/install-zookeeper.log 2>&1
echo "done"

# Install Hadoop
echo "Installing Hadoop..."
$DIR/install-hadoop.sh slave ${MASTER} $slave_mem $slave_disk_cnt ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > $LOG_DIR/install-hadoop.log 2>&1
echo "done"

# Install HBase
#echo "Installing HBase..."
#$DIR/install-hbase.sh ${MASTER} > $LOG_DIR/install-hbase.log 2>&1
#echo "done"

echo ""
echo "All software installed successfully"
