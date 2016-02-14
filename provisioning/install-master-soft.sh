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

$DIR/install-hadoop.sh ${master} ${AWS_ACCESS_KEY_ID} ${AWS_SECRET_ACCESS_KEY} > $LOG_DIR/install-hadoop.log 2>&1

#$DIR/install-hive.sh > $LOG_DIR/install-hive.log 2>&1

$DIR/install-spark.sh > $LOG_DIR/install-spark.log 2>&1

$DIR/install-spark-jobserver.sh > $LOG_DIR/install-spark-jobserver.log 2>&1
