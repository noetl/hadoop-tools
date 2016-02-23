#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-zeppelin.sh <AWS_ACCESS_KEY_ID> <AWS_ACCESS_SECRET_KEY>"
  exit -1
fi

AWS_ACCESS_KEY_ID=$1
AWS_ACCESS_SECRET_KEY=$2
#ZEPPELIN_NOTEBOOK_S3_BUCKET=$3
#ZEPPELIN_NOTEBOOK_S3_USER=$4

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
export ZEPPELIN_NOTEBOOK_DIR=/var/zeppelin/notebook
export ZEPPELIN_WAR_TEMPDIR=/var/zeppelin/webapps
export SPARK_HOME=/usr/lib/spark
export HADOOP_CONF_DIR=/usr/lib/hadoop/etc/hadoop
export CLASSPATH=/usr/lib/zeppelin/libs3/*
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_ACCESS_SECRET_KEY=$AWS_ACCESS_SECRET_KEY
#export ZEPPELIN_NOTEBOOK_S3_BUCKET=ZEPPELIN_NOTEBOOK_S3_BUCKET
#export ZEPPELIN_NOTEBOOK_S3_USER=ZEPPELIN_NOTEBOOK_S3_USER
EOL

#cat > zeppelin-site.xml << EOL
#<configuration>
#  <property>
#    <name>zeppelin.notebook.storage</name>
#    <value>org.apache.zeppelin.notebook.repo.S3NotebookRepo</value>
#  </property>
#</configuration>
#EOL

echo "Configuring Zeppelin done"

su - hadoop -c 'cat >> ~/.bashrc << EOL
export PATH=\$PATH:/usr/lib/zeppelin/bin
EOL'

#set +e
#echo "Trying to create s3n://${ZEPPELIN_NOTEBOOK_S3_BUCKET}/${ZEPPELIN_NOTEBOOK_S3_USER}/notebook folder"
#su - hadoop -c 'hadoop fs -mkdir -p s3n://${ZEPPELIN_NOTEBOOK_S3_BUCKET}/${ZEPPELIN_NOTEBOOK_S3_USER}/notebook'
#set -e

echo "Starting Zeppelin..."
su - hadoop -c '/usr/lib/zeppelin/bin/zeppelin-daemon.sh start'
echo "done"
echo "Zeppelin          http://${MASTER}:8080/"
