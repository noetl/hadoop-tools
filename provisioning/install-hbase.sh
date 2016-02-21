#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./install-hbase.sh <master_hostname>"
  exit -1
fi

MASTER=$1
my_hostname=`hostname`

mode="slave"
if [ "$MASTER" == "$my_hostname" ]; then
  mode="master"
fi

echo "MASTER: $MASTER"
echo "my_hostname: $my_hostname"
echo "mode: $mode"

echo "Downloading HBase...."
cd /usr/lib
wget -q http://apache.arvixe.com/hbase/1.1.3/hbase-1.1.3-bin.tar.gz
echo "Installing HBase...."
tar xzf hbase-1.1.3-bin.tar.gz
mv hbase-1.1.3 hbase
rm -rf hbase-1.1.3-bin.tar.gz

if [ "$mode" == "master" ]; then
  su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /tmp /hbase'
fi

mkdir -p /var/log/hbase
chown hadoop:hadoop /var/log/hbase

echo "Configuring HBase...."

cd /usr/lib/hbase/conf

cat > hbase-env.sh << EOL
export JAVA_HOME=/usr/lib/jvm/java-openjdk
export HBASE_LOG_DIR=/var/log/hbase
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
  echo "HBase Master     http://${MASTER}:16010"
else
  echo "Starting HBase Regionserver..."
  su - hadoop -c '/usr/lib/hbase/bin/hbase-daemon.sh --config /usr/lib/hbase/conf start regionserver'
  echo "done"
  echo "HBase Regionserver    http://${MASTER}:16020"
fi
