#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-hbase.sh <mode> <master_hostname>"
  exit -1
fi

mode=$1
MASTER=$2

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "MASTER: $MASTER"
echo "mode: $mode"

echo "Downloading HBase...."
cd /usr/lib
sudo aws s3 cp s3://noetl-provisioning-us-west-2/emr-4.7.1/hbase.tar.gz .
echo "Installing HBase...."
sudo tar xzf hbase.tar.gz
sudo rm -rf hbase.tar.gz

if [ "$mode" == "master" ]; then
  sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /tmp /user/hbase'
fi

sudo mkdir -p /mnt/var/log/hbase
sudo chown hadoop:hadoop /mnt/var/log/hbase

echo "Configuring HBase...."

# set MASTER and other variables in template
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/hbase/conf/hbase-site.xml

sudo cp -R $DIR/hbase /etc/

echo "Configuring HBase done"

sudo su - hadoop -c 'cat >> ~/.bashrc << EOL
export PATH=\$PATH:/usr/lib/hbase/bin
EOL'

if [ "$mode" == "master" ]; then
  echo "Starting HBase Master..."
  sudo su - hadoop -c '/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start master'
  echo "done"
  echo "HBase Master      http://${MASTER}:16010"

  echo "Starting HBase thrift"
  sudo su - hadoop -c '/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start thrift'
  echo "HBase thrift      ${MASTER}:9090"
  echo "done"
else
  echo "Starting HBase Regionserver..."
  sudo su - hadoop -c '/usr/lib/hbase/bin/hbase-daemon.sh --config /etc/hbase/conf start regionserver'
  echo "done"
  echo "HBase Regionserver    http://${MASTER}:16020"
fi
