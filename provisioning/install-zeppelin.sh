#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-zeppelin.sh"
  exit -1
fi

MASTER=`hostname`

echo "MASTER: $MASTER"

echo "Downloading Zeppelin...."
cd /usr/lib
wget -q http://download.nextag.com/apache/incubator/zeppelin/0.5.6-incubating/zeppelin-0.5.6-incubating-bin-all.tgz
echo "Installing Zeppelin...."
tar xzf zeppelin-0.5.6-incubating-bin-all.tgz
mv zeppelin-0.5.6-incubating-bin-all zeppelin
rm -rf zeppelin-0.5.6-incubating-bin-all.tgz

echo "Configuring dirs for Zeppelin...."
mkdir -p /var/log/zeppelin /var/zeppelin/notebook /var/zeppelin/webapps /usr/lib/zeppelin/run
chown -R hadoop:hadoop /var/log/zeppelin /var/zeppelin /usr/lib/zeppelin/conf /usr/lib/zeppelin/run
su - hadoop -c 'cp -R /usr/lib/zeppelin/notebook/* /var/zeppelin/notebook/'

echo "Configuring libs for Zeppelin...."
mkdir /usr/lib/zeppelin/libs3
cp /usr/lib/zeppelin/lib/aws*.jar /usr/lib/zeppelin/libs3/
cp /usr/lib/hadoop/share/hadoop/tools/lib/hadoop-aws-*.jar /usr/lib/zeppelin/libs3/
cp /usr/lib/hadoop/share/hadoop/tools/lib/jets3t*.jar /usr/lib/zeppelin/libs3/

echo "Configuring Zeppelin...."

cd /usr/lib/zeppelin/conf

cat > zeppelin-env.sh << EOL
export JAVA_HOME=/usr/lib/jvm/java-openjdk
export ZEPPELIN_LOG_DIR=/var/log/zeppelin
export ZEPPELIN_WAR_TEMPDIR=/var/zeppelin/webapps
export ZEPPELIN_NOTEBOOK_DIR=/var/zeppelin/notebook
export SPARK_HOME=/usr/lib/spark
export HADOOP_CONF_DIR=/usr/lib/hadoop/etc/hadoop
export CLASSPATH=/usr/lib/zeppelin/libs3/*
EOL

echo "Configuring Zeppelin done"

su - hadoop -c 'cat >> ~/.bashrc << EOL
export PATH=\$PATH:/usr/lib/zeppelin/bin
EOL'

echo "Starting Zeppelin..."
su - hadoop -c '/usr/lib/zeppelin/bin/zeppelin-daemon.sh start'
echo "done"
echo "Zeppelin          http://${MASTER}:8080/"
