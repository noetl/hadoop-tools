#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./install-hive.sh <master_hostname>"
  exit -1
fi

MASTER=$1

echo "MASTER: $MASTER"

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Downloading Hive...."
cd /usr/lib
sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/hive.tar.gz .
echo "Installing Hive...."
sudo tar xzf hive.tar.gz
sudo rm -rf hive.tar.gz

echo "Downloading Tez...."
cd /usr/lib
sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/tez.tar.gz .
echo "Installing Tez...."
sudo tar xzf tez.tar.gz
sudo rm -rf tez.tar.gz

echo "Installing mysql-connector-java...."
sudo mkdir -p /usr/share/java
cd /usr/share/java
sudo curl -f -O http://cdn.mysql.com/Downloads/Connector-J/mysql-connector-java-5.1.39.tar.gz
sudo tar zxf mysql-connector-java-5.1.39.tar.gz
sudo cp mysql-connector-java-5.1.39/mysql-connector-java-5.1.39-bin.jar /usr/lib/hive/lib/
sudo cp mysql-connector-java-5.1.39/mysql-connector-java-5.1.39-bin.jar /usr/share/aws/emr/emrfs/auxlib
sudo rm -rf mysql-connector-java-5.1.39.tar.gz

cp /usr/lib/hive/lib/mysql-connector-java-5.1.39-bin.jar /usr/lib/spark
/usr/lib/spark/yarn/lib/mysql-connector-java.jar

# Try to install software using yum. For some reason first attempt might fail
echo "Installing MySQL...."
set +e
sudo yum -y install mysql56-server
if [ $? -ne 0 ]; then
  sleep 10
  set -e
  sudo yum -y install mysql56-server
fi
set -e
echo "Installing MySQL done"

echo "Starting MySQL...."
sudo service mysqld start
echo "Starting MySQL done"

echo "Creating MySQL hive user..."

cat > /tmp/create_metastore.sql << EOL
CREATE DATABASE hive;
USE hive;
SOURCE hive-schema-0.14.0.mysql.sql;
CREATE USER 'hive'@'${MASTER}' IDENTIFIED BY 'hive';
GRANT all on *.* to 'hive'@'$MASTER' identified by 'hive';
flush privileges;
EOL

sudo cp /tmp/create_metastore.sql /usr/lib/hive/scripts/metastore/upgrade/mysql/
cd  /usr/lib/hive/scripts/metastore/upgrade/mysql/
sudo mysql < create_metastore.sql
echo "Creating MySQL hive user done"

sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/hive/warehouse'
sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -chmod g+w /user/hive/warehouse'

sudo mkdir -p /mnt/var/log/hive
sudo chown hadoop:hadoop /mnt/var/log/hive

echo "Configuring Hive...."

# set MASTER and other variables in template
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/hive/conf/hive-site.xml
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/tez/conf/tez-site.xml

sudo cp -R $DIR/hive /etc/
sudo cp -R $DIR/tez /etc/

#echo "Configuring Tez...."

#sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /apps/tez'
#cd /tmp
#sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/tez-hdfs.tar.gz .
#sudo su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -put /tmp/tez-hdfs.tar.gz /apps/tez/tez.tar.gz'

sudo su - hadoop -c 'cat >> ~/.bashrc << EOL
export HIVE_CONF_DIR=/etc/hive/conf
export TEZ_CONF_DIR=/etc/tez/conf
export PATH=\$PATH:/usr/lib/hive/bin
alias hivemr="hive --hiveconf hive.execution.engine=mr"
alias hivetez="hive --hiveconf hive.execution.engine=tez"
EOL'

echo "Starting Hiveserver2..."
sudo su - hadoop -c 'nohup /usr/lib/hive/bin/hiveserver2 > /mnt/var/log/hive/hiveserver2.out 2>&1 < /dev/null &'
echo "done"
echo "Hiveserver2       ${MASTER}:10000"
echo

#echo "Installing Tez-UI..."
#yum install -y nginx

#mkdir -p /usr/share/nginx/html/tez-ui
#cd /usr/share/nginx/html/tez-ui

#unzip /usr/lib/tez/tez-ui-0.8.3.war


#systemctl start nginx
#echo "done"
#echo "TEZ-UI            http://${MASTER}/tez-ui/"
