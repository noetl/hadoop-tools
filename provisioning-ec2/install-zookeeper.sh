#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-zookeeper.sh"
  exit -1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Downloading Zookeeper...."
cd /usr/lib
sudo aws s3 cp s3://noetl-provisioning-us-west-2/emr-4.7.1/zookeeper.tar.gz .
echo "Installing Zookeeper...."
sudo tar xzf zookeeper.tar.gz
sudo rm -rf zookeeper.tar.gz

sudo mkdir -p /mnt/var/zookeeper /mnt/var/log/zookeeper
sudo chown hadoop:hadoop /mnt/var/zookeeper /mnt/var/log/zookeeper

echo "Configuring Zookeeper...."

sudo cp -R $DIR/zookeeper /etc/

echo "Configuring Zookeeper done"

sudo su - hadoop -c 'cat >> ~/.bashrc << EOL
export PATH=\$PATH:/usr/lib/zookeeper/bin
export ZOO_LOG_DIR=/mnt/var/log/zookeeper
EOL'

echo "Starting Zookeeper..."
sudo su - hadoop -c 'ZOO_LOG_DIR=/mnt/var/log/zookeeper JAVA_HOME=/usr/lib/jvm/java-openjdk /usr/lib/zookeeper/bin/zkServer.sh start'
echo "done"
