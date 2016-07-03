#!/bin/bash

set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-master-soft.sh <json_conf_file> <master_host_name>"
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

# Install Zookeeper
echo "Installing Zookeeper..."
$DIR/install-zookeeper.sh > $LOG_DIR/install-zookeeper.log 2>&1
echo "done"

# Install Hadoop
echo "Installing Hadoop..."
$DIR/install-hadoop.sh ${json_conf_file} master ${MASTER} > $LOG_DIR/install-hadoop.log 2>&1
echo "done"

# wait for at least one active slave because TEZ needs to put jars to HDFS
echo "Wait for at least one active slave"
set +e
nodesCnt=0
sl=0
while [ $nodesCnt == 0 ]; do
  echo "sleep $sl"
  sleep $sl
  nodesCnt=$(curl -m 10 -s http://${MASTER}:8088/ws/v1/cluster/nodes | jq '.nodes.node | length')
  echo "active slaves count: $nodesCnt"
  sl=30
done
set -e

# Install Hive and TEZ
echo "Installing Hive..."
$DIR/install-hive.sh ${MASTER} > $LOG_DIR/install-hive.log 2>&1
echo "done"

# Install Spark
echo "Installing Spark..."
$DIR/install-spark.sh ${json_conf_file} ${MASTER} > $LOG_DIR/install-spark.log 2>&1
echo "done"

# Install Spark Jobserver
echo "Installing Spark Jobserver..."
$DIR/install-spark-jobserver.sh ${json_conf_file} > $LOG_DIR/install-spark-jobserver.log 2>&1
echo "done"

echo ""
echo "All software installed successfully"
