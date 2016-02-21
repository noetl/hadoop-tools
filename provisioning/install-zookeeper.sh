#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-zookeeper.sh"
  exit -1
fi

echo "Downloading Zookeeper...."
cd /usr/lib
wget -q http://apache.arvixe.com/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz
echo "Installing Zookeeper...."
tar xzf zookeeper-3.4.8.tar.gz
mv zookeeper-3.4.8 zookeeper
rm -rf zookeeper-3.4.8.tar.gz

mkdir -p /var/zookeeper /var/log/zookeeper
chown hadoop:hadoop /var/zookeeper /var/log/zookeeper

echo "Configuring Zookeeper...."

cd /usr/lib/zookeeper/conf

cat > zoo.cfg << EOL
tickTime=2000
initLimit=10
syncLimit=5
dataDir=/var/zookeeper
clientPort=2181
autopurge.snapRetainCount=3
autopurge.purgeInterval=1
EOL

echo "Configuring Zookeeper done"

su - hadoop -c 'cat >> ~/.bashrc << EOL
export PATH=\$PATH:/usr/lib/zookeeper/bin
export ZOO_LOG_DIR=/var/log/zookeeper
EOL'

echo "Starting Zookeeper..."
su - hadoop -c 'ZOO_LOG_DIR=/var/log/zookeeper JAVA_HOME=/usr/lib/jvm/java-openjdk /usr/lib/zookeeper/bin/zkServer.sh start'
echo "done"
