#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-spark.sh <json_conf_file> <master_host_name>"
  exit -1
fi

json_conf_file=$1
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh $json_conf_file

echo "yarn.nodemanager.resource.memory-mb ${yarn_mem}"
echo "spark.executor.memory               ${exec_mem}m"
echo "spark.executor.cores                ${slave_cores}"

MASTER=$2

echo "MASTER: $MASTER"

echo "Downloading Spark...."
cd /usr/lib
sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/spark.tar.gz .
echo "Installing Spark...."
sudo tar xzf spark.tar.gz
sudo rm -rf spark.tar.gz

sudo mkdir -p /mnt/var/log/spark
sudo chown hadoop:hadoop /mnt/var/log/spark

sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /var/log/spark/apps'
sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -chmod g+w /var/log/spark/apps'

echo "Configuring Spark...."

# set MASTER and other variables in template
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/spark/conf/spark-defaults.conf
sed -i -e "s/\${exec_mem}/${exec_mem}/g" $DIR/spark/conf/spark-defaults.conf
sed -i -e "s/\${exec_cores}/${exec_cores}/g" $DIR/spark/conf/spark-defaults.conf

sudo cp -R $DIR/spark /etc/

echo "Configuring Spark done"

sudo su - hadoop -c 'cat >> ~/.bashrc << EOL
export SPARK_CONF_DIR=/etc/spark/conf
export PATH=\$PATH:/usr/lib/spark/bin
EOL'

echo "Starting spark history server...."
sudo su - hadoop -c '/usr/lib/spark/sbin/start-history-server.sh'
echo "Starting spark history server done"
