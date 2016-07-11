#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./install-spark-jobserver.sh <json_conf_file>"
  exit -1
fi

json_conf_file=$1
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
. $DIR/export-conf.sh $json_conf_file

echo "Downloading Spark-jobserver...."
sudo mkdir /usr/lib/spark-jobserver
cd /usr/lib/spark-jobserver
sudo curl -O https://s3-us-west-2.amazonaws.com/noetl-provisioning-us-west-2/emr-4.7.1/spark-jobserver-0.6.2.tar.gz
echo "Installing Spark-jobserver...."
sudo tar zxf spark-jobserver-0.6.2.tar.gz
sudo rm -rf spark-jobserver-0.6.2.tar.gz

sudo mkdir -p /mnt/var/log/spark-jobserver /mnt/var/spark-jobserver
sudo chown hadoop:hadoop /mnt/var/log/spark-jobserver /mnt/var/spark-jobserver

echo "Configuring Spark-jobserver...."

sed -i -e "s/\${exec_mem}/${exec_mem}/g" $DIR/spark-jobserver/emr.conf
sed -i -e "s/\${exec_cores}/${exec_cores}/g" $DIR/spark-jobserver/emr.conf

sudo cp -rf $DIR/spark-jobserver/* /usr/lib/spark-jobserver/

echo "Configuring Spark-jobserver done"

echo "Starting Spark-jobserver...."
sudo su - hadoop -c 'nohup /usr/lib/spark-jobserver/server_start.sh > /dev/null 2> /dev/null < /dev/null &'
echo "Starting Spark-jobserver done"
