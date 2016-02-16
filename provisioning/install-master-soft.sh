#!/bin/bash

set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-master-soft.sh <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

AWS_ACCESS_KEY_ID=$1
AWS_SECRET_ACCESS_KEY=$2

LOG_DIR="/root"
DIR="/root/provisioning"

master=`hostname`

# Install Hadoop
echo "Installing Hadoop..."
$DIR/install-hadoop.sh ${master} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > $LOG_DIR/install-hadoop.log 2>&1
echo "done"

# Install Spark
echo "Installing Spark..."
$DIR/install-spark.sh > $LOG_DIR/install-spark.log 2>&1
echo "done"

# Install Spark Jobserver
echo "Installing Spark Jobserver..."
$DIR/install-spark-jobserver.sh > $LOG_DIR/install-spark-jobserver.log 2>&1
echo "done"

# Try to install software using yum. For some reason first attempt might fail
echo "Installing jq..."
set +e
yum -y install jq
if [ $? -ne 0 ]; then
  sleep 10
  set -e
  yum -y install jq
fi
set -e
echo "Installing jq done"

# wait for at least one active slave because TEZ needs to put jars to HDFS
echo "Wait for at least one active slave"
set +e
nodesCnt=0
sl=0
while [ $nodesCnt == 0 ]; do
  echo "sleep $sl"
  sleep $sl
  nodesCnt=`curl -s http://${master}:8088/ws/v1/cluster/nodes | jq '.nodes.node | length'`
  echo "active slaves count: $nodesCnt"
  sl=30
done
set -e

# Install Hive and TEZ
echo "Installing Hive..."
$DIR/install-hive.sh > $LOG_DIR/install-hive.log 2>&1
echo "done"
