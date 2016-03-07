#!/bin/bash

set -e

if [ $# -ne 5 ]; then
  echo "Usage: ./install-master-soft.sh <N_of_boxes> <slave_mem> <slave_disk_cnt> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

N=$1
slave_mem=$2
slave_disk_cnt=$3
AWS_ACCESS_KEY_ID=$4
AWS_SECRET_ACCESS_KEY=$5
#ZEPPELIN_NOTEBOOK_S3_BUCKET=$5
#ZEPPELIN_NOTEBOOK_S3_USER=$6

LOG_DIR="/root"
DIR="/root/provisioning"

MASTER=`hostname`

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
$DIR/install-hadoop.sh ${MASTER} $slave_mem $slave_disk_cnt ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > $LOG_DIR/install-hadoop.log 2>&1
echo "done"

# Install Spark
echo "Installing Spark..."
$DIR/install-spark.sh $N $slave_mem > $LOG_DIR/install-spark.log 2>&1
echo "done"

# Install Spark Jobserver
echo "Installing Spark Jobserver..."
$DIR/install-spark-jobserver.sh > $LOG_DIR/install-spark-jobserver.log 2>&1
echo "done"

# wait for at least one active slave because TEZ needs to put jars to HDFS
echo "Wait for at least one active slave"
set +e
nodesCnt=0
sl=0
while [ $nodesCnt == 0 ]; do
  echo "sleep $sl"
  sleep $sl
  nodesCnt=`curl -m 10 -s http://${MASTER}:8088/ws/v1/cluster/nodes | jq '.nodes.node | length'`
  echo "active slaves count: $nodesCnt"
  sl=30
done
set -e

# Install Hive and TEZ
echo "Installing Hive..."
$DIR/install-hive.sh > $LOG_DIR/install-hive.log 2>&1
echo "done"

# Install HBase
echo "Installing HBase..."
$DIR/install-hbase.sh ${MASTER} > $LOG_DIR/install-hbase.log 2>&1
echo "done"

# Install Zeppelin
echo "Installing Zeppelin..."
$DIR/install-zeppelin.sh $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY > $LOG_DIR/install-zeppelin.log 2>&1
echo "done"

echo ""
echo "All software installed successfully"
