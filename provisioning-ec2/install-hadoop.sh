#!/bin/bash
set -e

if [ $# -ne 3 ]; then
  echo "Usage: ./install-hadoop.sh <json_conf_file> <mode> <master_hostname>"
  exit -1
fi

json_conf_file=$1
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh $json_conf_file

mode=$2
MASTER=$3

YARN_MEM=$[$slave_mem*1024*87/100]
echo "YARN_MEM: $YARN_MEM"

echo "mode: $mode"
echo "MASTER: $MASTER"

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

sudo mkdir -p /mnt/tmp /mnt/var/tmp /mnt/var/lib/hadoop/tmp
sudo chmod 777 /mnt/tmp /mnt/var/tmp /mnt/var/lib/hadoop/tmp

sudo mkdir -p /mnt/s3 /mnt/mapred /mnt/yarn /mnt/namenode /mnt/hdfs /mnt/var/cache /mnt/var/log /mnt/var/lib /mnt/var/log/hadoop
sudo chown hadoop:hadoop /mnt/s3 /mnt/mapred /mnt/yarn /mnt/namenode /mnt/hdfs /mnt/var/cache /mnt/var/log /mnt/var/lib /mnt/var/log/hadoop

sudo chmod 700 /mnt/namenode

# set MASTER and other variables in template
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/hadoop/conf/core-site.xml
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/hadoop/conf/yarn-site.xml
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/hadoop/conf/mapred-site.xml
sed -i -e "s/\${AWS_ACCESS_KEY_ID}/${AWS_ACCESS_KEY_ID}/g" $DIR/hadoop/conf/core-site.xml
sed -i -e "s/\${AWS_SECRET_ACCESS_KEY}/${AWS_SECRET_ACCESS_KEY}/g" $DIR/hadoop/conf/core-site.xml

sed -i -e "s/\${YARN_MEM}/${YARN_MEM}/g" $DIR/hadoop/conf/yarn-site.xml

sudo cp -R $DIR/hadoop /etc/

if [ "$mode" == "master" ]; then
  echo "Formatting HDFS...."
  sudo su - hadoop -c 'HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec /usr/lib/hadoop-hdfs/bin/hdfs namenode -format'
  echo "Formatting HDFS done"

  echo "Starting namenode...."
  sudo su - hadoop -c '/usr/lib/hadoop/sbin/hadoop-daemon.sh \
    --config /etc/hadoop/conf \
    --script /usr/lib/hadoop-hdfs/bin/hdfs start namenode'
  echo "Starting namenode done"

  echo "Starting YARN resourcemanager...."
  sudo su - hadoop -c 'HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start resourcemanager'
  echo "Starting YARN resourcemanager done"

  echo "Starting YARN timelineserver...."
  sudo su - hadoop -c 'HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start timelineserver'
  echo "Starting YARN timelineserver done"

  sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /tmp'
  sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -chmod 777 /tmp'
  sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /var/log/hadoop-yarn/apps'

  echo "Starting JobHistory server...."
  sudo su - hadoop -c 'HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec /usr/lib/hadoop-mapreduce/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop/conf start historyserver'
  echo "Starting JobHistory server done"
else
  echo "Starting datanode...."
  sudo su - hadoop -c '/usr/lib/hadoop/sbin/hadoop-daemon.sh \
    --config /etc/hadoop/conf \
    --script /usr/lib/hadoop-hdfs/bin/hdfs start datanode'
  echo "Starting datanode done"

  echo "Starting YARN nodemanager...."
  sudo su - hadoop -c 'HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec /usr/lib/hadoop-yarn/sbin/yarn-daemon.sh --config /etc/hadoop/conf start nodemanager'
  echo "Starting YARN nodemanager done"
fi

echo "Configure env vars...."
sudo su - hadoop -c 'cat >> ~/.bashrc << EOL
export HADOOP_HOME=/usr/lib/hadoop
export HADOOP_CONF_DIR=/etc/hadoop/conf
HADOOP_COMMON_HOME=/usr/lib/hadoop
export PATH=\$PATH:/usr/lib/hadoop/bin
EOL'
echo "done"

# echo "Testing MR..."
# /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop-mapreduce/hadoop-mapreduce-examples.jar pi 10 1000
# /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.4.jar teragen -D mapred.map.tasks=30 100000000 tera100
# /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.4.jar terasort -D mapred.reduce.tasks=20 tera100 tera100s
