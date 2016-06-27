#!/bin/bash
set -e

if [ $# -ne 6 ]; then
  echo "Usage: ./install-hadoop.sh <mode> <master_hostname> <slave_mem> <slave_disk_cnt> <AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>"
  exit -1
fi

mode=$1
MASTER=$2
slave_mem=$3
slave_disk_cnt=$4
AWS_ACCESS_KEY_ID=$5
AWS_SECRET_ACCESS_KEY=$6

yarn_mem=$[$slave_mem*1024*87/100]

my_hostname=$(hostname -f)

host_disk_cnt=$slave_disk_cnt
if [ "$mode" == "master" ]; then
  host_disk_cnt=1
fi

echo "MASTER: $MASTER"
echo "my_hostname: $my_hostname"
echo "mode: $mode"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Downloading Hadoop...."
cd /usr/lib
sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/hadoop.tar.gz .
echo "Installing Hadoop...."
sudo tar xzf hadoop.tar.gz
sudo rm -rf hadoop.tar.gz

echo "Downloading EMR"
sudo mkdir -p /usr/share/aws/emr
cd /usr/share/aws/emr
sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/emrfs.tar.gz .
sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/goodies.tar.gz .
sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/s3-dist-cp.tar.gz .
sudo tar xzf emrfs.tar.gz
sudo tar xzf goodies.tar.gz
sudo tar xzf s3-dist-cp.tar.gz
sudo rm -rf emrfs.tar.gz goodies.tar.gz s3-dist-cp.tar.gz

echo "Configure env vars...."
sudo su - hadoop -c 'cat >> ~/.bashrc << EOL
export HADOOP_HOME=/usr/lib/hadoop
export HADOOP_CONF_DIR=/etc/hadoop/conf
export PATH=\$PATH:/usr/lib/hadoop/bin
EOL'
echo "done"

# echo "Testing MR..."
# /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.4.jar pi 10 1000
# /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.4.jar teragen -D mapred.map.tasks=30 100000000 tera100
# /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.4.jar terasort -D mapred.reduce.tasks=20 tera100 tera100s
