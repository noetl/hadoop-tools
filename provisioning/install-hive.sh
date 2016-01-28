#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-hive.sh"
  exit -1
fi

MASTER=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`

echo "MASTER: $MASTER"

echo "Downloading Hive...."
cd /usr/lib
wget http://download.nextag.com/apache/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz
echo "Installing Hive...."
tar xzf apache-hive-1.2.1-bin.tar.gz
mv apache-hive-1.2.1-bin hive
rm -rf apache-hive-1.2.1-bin.tar.gz

echo "Installing mysql-connector-java...."
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz
tar zxf mysql-connector-java-5.1.38.tar.gz
cp mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar /usr/lib/hive/lib/
rm -rf mysql-connector-java-5.1.38 zxf mysql-connector-java-5.1.38.tar.gz

echo "Installing MySQL...."
yum -y install mariadb-server
echo "Installing MySQL done"

echo "Starting MySQL...."
systemctl start mariadb.service
echo "Starting MySQL done"

echo "Creating metastore DB..."
cd /usr/lib/hive/scripts/metastore/upgrade/mysql

cat > create_metastore.sql << EOL
CREATE DATABASE metastore;
USE metastore;
SOURCE hive-schema-1.2.0.mysql.sql;
CREATE USER 'hive'@'${MASTER}' IDENTIFIED BY 'hive';
GRANT all on *.* to 'hive'@'$MASTER' identified by 'hive';
flush privileges;
EOL

mysql < create_metastore.sql
echo "Creating metastore DB done"

cd -

/usr/lib/hadoop/bin/hadoop fs -mkdir -p /tmp /user/hive/warehouse
/usr/lib/hadoop/bin/hadoop fs -chmod g+w /tmp /user/hive/warehouse

echo "Configuring Hive...."

cd /usr/lib/hive/conf

cat > hive-env.sh << EOL
export HADOOP_HOME=/usr/lib/hadoop
EOL

cat > hive-site.sh << EOL
<configuration>
   <property>
      <name>javax.jdo.option.ConnectionURL</name>
      <value>jdbc:mysql://${MASTER}/metastore</value>
   </property>
   <property>
      <name>javax.jdo.option.ConnectionDriverName</name>
      <value>com.mysql.jdbc.Driver</value>
   </property>
   <property>
      <name>javax.jdo.option.ConnectionUserName</name>
      <value>hive</value>
   </property>
   <property>
      <name>javax.jdo.option.ConnectionPassword</name>
      <value>hive</value>
   </property>
</configuration>
EOL

echo "Configuring Hive done"
