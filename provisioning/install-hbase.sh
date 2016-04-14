#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./install-hbase.sh <master_hostname>"
  exit -1
fi

MASTER=$1
my_hostname=`hostname`
version="0.98.18"

mode="slave"
if [ "$MASTER" == "$my_hostname" ]; then
  mode="master"
fi

echo "MASTER: $MASTER"
echo "my_hostname: $my_hostname"
echo "mode: $mode"

echo "Downloading HBase...."
cd /usr/lib
wget -q http://download.nextag.com/apache/hbase/${version}/hbase-${version}-hadoop2-bin.tar.gz
echo "Installing HBase...."
tar xzf hbase-${version}-hadoop2-bin.tar.gz
mv hbase-${version}-hadoop2 hbase
rm -rf hbase-${version}-hadoop2-bin.tar.gz

if [ "$mode" == "master" ]; then
  su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /tmp /hbase'
fi

mkdir -p /data01/var/log/hbase
chown hadoop:hadoop /data01/var/log/hbase

# add links without version to common hbase jars
cd /usr/lib/hbase/lib
ln -s hbase-common-${version}-hadoop2.jar hbase-common.jar
ln -s hbase-client-${version}-hadoop2.jar hbase-client.jar
ln -s hbase-protocol-${version}-hadoop2.jar hbase-protocol.jar

echo "Configuring HBase...."

cd /usr/lib/hbase/conf

cat > hbase-env.sh << EOL
export JAVA_HOME=/usr/lib/jvm/java-openjdk
export HBASE_LOG_DIR=/data01/var/log/hbase
export HADOOP_CONF_DIR=/usr/lib/hadoop/etc/hadoop
EOL

cat > hbase-site.xml << EOL
<configuration>
  <property>
    <name>hbase.rootdir</name>
    <value>hdfs://${MASTER}:8020/hbase</value>
  </property>
  <property>
    <name>hbase.cluster.distributed</name>
    <value>true</value>
  </property>
  <property>
    <name>hbase.zookeeper.quorum</name>
    <value>${MASTER}</value>
  </property>
  <property>
    <name>hbase.client.retries.number</name>
    <value>2</value>
  </property>
  <property>
    <name>hbase.rpc.timeout</name>
    <value>10000</value>
  </property>
  <property>
    <name>zookeeper.recovery.retry</name>
    <value>2</value>
  </property>
</configuration>
EOL

echo "Configuring HBase done"

su - hadoop -c 'cat >> ~/.bashrc << EOL
export PATH=\$PATH:/usr/lib/hbase/bin
EOL'

if [ "$mode" == "master" ]; then
  echo "Starting HBase Master..."
  su - hadoop -c '/usr/lib/hbase/bin/hbase-daemon.sh --config /usr/lib/hbase/conf start master'
  echo "done"
  echo "HBase Master     http://${MASTER}:60010"
else
  echo "Starting HBase Regionserver..."
  su - hadoop -c '/usr/lib/hbase/bin/hbase-daemon.sh --config /usr/lib/hbase/conf start regionserver'
  echo "done"
  echo "HBase Regionserver    http://${MASTER}:60020"
fi
