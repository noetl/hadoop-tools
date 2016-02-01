#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-hadoop.sh <master_ip> start/stop"
  exit -1
fi

if [ "$2" == "stop" ] || [ "$2" == "start" ]; then
  echo "action $2"
else
  echo "Usage: ./install-hadoop.sh <master_ip> start/stop"
  exit -1
fi

MASTER=$1
action=$2

if [ "$MASTER" == "$myip" ]; then
  mode="master"
fi

myip=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`

mode="slave"
if [ "$MASTER" == "$myip" ]; then
  mode="master"
fi

echo "MASTER: $MASTER"
echo "myip: $myip"
echo "mode: $mode"

if [ "$mode" == "master" ]; then
  echo "${action}ing namenode...."
  /usr/lib/hadoop/sbin/hadoop-daemons.sh \
    --config "/usr/lib/hadoop/etc/hadoop" \
    --script "/usr/lib/hadoop/bin/hdfs" $action namenode
  echo "${action}ing namenode done"

  echo "${action}ing YARN resourcemanager...."
  /usr/lib/hadoop/sbin/yarn-daemon.sh --config /usr/lib/hadoop/etc/hadoop $action resourcemanager
  echo "${action}ing YARN resourcemanager done"

  echo "${action}ing JobHistory server...."
  /usr/lib/hadoop/sbin/mr-jobhistory-daemon.sh --config /usr/lib/hadoop/etc/hadoop $action historyserver
  echo "${action}ing JobHistory server done"
else
  echo "${action}ing datanode...."
  /usr/lib/hadoop/sbin/hadoop-daemons.sh \
    --config "/usr/lib/hadoop/etc/hadoop" \
    --script "/usr/lib/hadoop/bin/hdfs" $action datanode
  echo "${action}ing datanode done"

  echo "${action}ing YARN nodemanager...."
  /usr/lib/hadoop/sbin/yarn-daemon.sh --config /usr/lib/hadoop/etc/hadoop $action nodemanager
  echo "${action}ing
   YARN nodemanager done"
fi
