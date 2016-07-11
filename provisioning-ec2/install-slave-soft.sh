#!/bin/bash

set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-slave-soft.sh <json_conf_file> <master_hostname>"
  exit -1
fi

echo "Installing jq..."
sudo yum -y install jq
echo "Installing jq done"

json_conf_file=$1
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh $json_conf_file

MASTER=$2

LOG_DIR="/tmp/log"
DIR="/tmp/provisioning-ec2"

mkdir -p $LOG_DIR

# Install JDK
echo "Installing JDK..."
$DIR/install-jdk.sh > $LOG_DIR/install-jdk.log 2>&1
echo "done"

# Install aws cli
echo "Installing aws cli..."
$DIR/install-aws.sh ${json_conf_file} > $LOG_DIR/install-aws.log 2>&1
echo "done"

echo "Installing Spark on slave..."
echo "Downloading Spark...."
cd /usr/lib
sudo curl -O https://s3-us-west-2.amazonaws.com/noetl-provisioning-us-west-2/emr-4.7.1/spark-slave.tar.gz
echo "Installing Spark...."
sudo tar xzf spark-slave.tar.gz
sudo rm -rf spark-slave.tar.gz
echo "done"

# Install Hadoop
echo "Installing Hadoop..."
$DIR/install-hadoop.sh ${json_conf_file} slave ${MASTER} > $LOG_DIR/install-hadoop.log 2>&1
echo "done"

# Install HBase
echo "Installing HBase..."
$DIR/install-hbase.sh slave ${MASTER} > $LOG_DIR/install-hbase.log 2>&1
echo "done"

echo ""
echo "All software installed successfully"
