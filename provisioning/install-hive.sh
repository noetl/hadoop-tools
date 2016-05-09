#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-hive.sh"
  exit -1
fi

MASTER=`hostname`

echo "MASTER: $MASTER"

echo "Downloading Hive...."
cd /usr/lib
curl -f -O http://download.nextag.com/apache/hive/hive-1.2.1/apache-hive-1.2.1-bin.tar.gz
echo "Installing Hive...."
tar xzf apache-hive-1.2.1-bin.tar.gz
mv apache-hive-1.2.1-bin hive
rm -rf apache-hive-1.2.1-bin.tar.gz

echo "Installing mysql-connector-java...."
wget -q https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.38.tar.gz
tar zxf mysql-connector-java-5.1.38.tar.gz
cp mysql-connector-java-5.1.38/mysql-connector-java-5.1.38-bin.jar /usr/lib/hive/lib/
rm -rf mysql-connector-java-5.1.38 zxf mysql-connector-java-5.1.38.tar.gz

# Try to install software using yum. For some reason first attempt might fail
echo "Installing MySQL...."
set +e
yum -y install mariadb-server
if [ $? -ne 0 ]; then
  sleep 10
  set -e
  yum -y install mariadb-server
fi
set -e
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

su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /tmp'
su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -chmod 777 /tmp'
su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/hive/warehouse'
su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -chmod g+w /user/hive/warehouse'

mkdir -p /data01/var/log/hive
chown hadoop:hadoop /data01/var/log/hive

echo "Configuring Hive...."

cd /usr/lib/hive/conf

cat > hive-env.sh << EOL
export HADOOP_HOME=/usr/lib/hadoop
export TEZ_CONF_DIR=/usr/lib/tez/conf
if [ "\$HADOOP_CLASSPATH" ]; then
  export HADOOP_CLASSPATH=\$HADOOP_CLASSPATH:/usr/lib/hadoop-s3/*:/usr/lib/hadoop/share/hadoop/tools/lib/*:/usr/lib/tez/conf:/usr/lib/tez/*:/usr/lib/tez/lib/*
else
  export HADOOP_CLASSPATH=/usr/lib/hadoop-s3/*:/usr/lib/hadoop/share/hadoop/tools/lib/*:/usr/lib/tez/conf:/usr/lib/tez/*:/usr/lib/tez/lib/*
fi
EOL

cat > hive-site.xml << EOL
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
  <property>
    <name>hive.execution.engine</name>
    <value>tez</value>
  </property>
  <property>
    <name>hive.tez.container.size</name>
    <value>1536</value>
  </property>
  <property>
    <name>hive.tez.java.opts</name>
    <value>-Xmx1120m -Xms1120m</value>
  </property>
  <property>
    <name>hive.tez.java.opts</name>
    <value>-Xmx1120m -Xms1120m</value>
  </property>
  <property>
    <name>hive.server2.authentication</name>
    <value>NONE</value>
  </property>
  <property>
    <name>hive.server2.enable.doAs</name>
    <value>false</value>
  </property>
</configuration>
EOL

mkdir -p /etc/hive
ln -s /usr/lib/hive/conf /etc/hive/conf

echo "Configuring Hive done"

# Tez
echo "Installing Tez...."
cd /usr/lib
curl -f -O http://www.noetl.io/tez-0.8.2.tar.gz
curl -f -O http://www.noetl.io/tez-0.8.2-minimal.tar.gz

mkdir tez-full
cd tez-full
tar xzf ../tez-0.8.2.tar.gz
rm -rf ../tez-0.8.2.tar.gz
cp /usr/lib/hadoop-s3/* lib/

cd ..
mkdir tez
cd tez
tar xzf ../tez-0.8.2-minimal.tar.gz
rm -rf ../tez-0.8.2-minimal.tar.gz
mkdir conf

echo "Configuring Tez...."

su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -mkdir -p /apps/'
su - hadoop -c '/usr/lib/hadoop/bin/hadoop fs -put /usr/lib/tez-full /apps/tez-0.8.2'

cd /usr/lib/tez/conf
cat > tez-site.xml << EOL
<configuration>
   <property>
      <name>tez.lib.uris</name>
      <value>hdfs:///apps/tez-0.8.2/,hdfs:///apps/tez-0.8.2/lib/</value>
   </property>
   <property>
    <name>tez.am.resource.memory.mb</name>
    <value>1536</value>
  </property>
  <property>
    <name>tez.task.resource.memory.mb</name>
    <value>1536</value>
  </property>
  <property>
    <name>tez.am.java.opts</name>
    <value>-Xmx1120m -Xmx1120m</value>
  </property>
  <property>
    <name>tez.history.logging.service.class</name>
    <value>org.apache.tez.dag.history.logging.ats.ATSHistoryLoggingService</value>
  </property>
  <property>
    <name>tez.tez-ui.history-url.base</name>
    <value>http://${MASTER}/tez-ui/</value>
  </property>
</configuration>
EOL

echo "Configuring Tez done"

su - hadoop -c 'cat >> ~/.bashrc << EOL
export HIVE_CONF_DIR=/usr/lib/hive/conf
export TEZ_CONF_DIR=/usr/lib/tez/conf
export PATH=\$PATH:/usr/lib/hive/bin
alias hivemr="hive --hiveconf hive.execution.engine=mr"
EOL'

echo "Starting Hiveserver2..."
su - hadoop -c 'nohup /usr/lib/hive/bin/hiveserver2 > /data01/var/log/hive/hiveserver2.out 2>&1 < /dev/null &'
echo "done"
echo "Hiveserver2       ${MASTER}:10000"
echo

echo "Installing Tez-UI..."
yum install -y nginx

mkdir -p /usr/share/nginx/html/tez-ui
cd /usr/share/nginx/html/tez-ui

curl -f -O https://repository.apache.org/content/repositories/releases/org/apache/tez/tez-ui/0.8.2/tez-ui-0.8.2.war
unzip tez-ui-0.8.2.war
rm -rf tez-ui-0.8.2.war

systemctl start nginx
echo "done"
echo "TEZ-UI            http://${MASTER}/tez-ui/"
