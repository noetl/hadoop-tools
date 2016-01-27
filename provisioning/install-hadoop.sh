set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./install-hadoop.sh <master_ip>"
  exit -1
fi

MASTER=$1

myip=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`

mode="slave"
if [ "$MASTER" == "$myip" ]; then
  mode="master"
fi

echo "MASTER: $MASTER"
echo "myip: $myip"
echo "mode: $mode"

echo "Installing JDK....."

yum -y install java-devel

echo "JDK Installation completed...."

echo "Installed java version is...."

java -version

javac -version

echo "Configuring SSH...."
mkdir -p ~/.ssh

ssh-keygen -f ~/.ssh/id_rsa  -t rsa -N ''

cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys

cat > ~/.ssh/config << EOL
Host *.*.*.*
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
Host localhost
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOL

echo "Downloading Hadoop...."
cd /usr/lib
wget http://apache.mirrors.pair.com/hadoop/common/hadoop-2.6.3/hadoop-2.6.3.tar.gz
echo "Installing Hadoop...."
tar xzf hadoop-2.6.3.tar.gz
mv hadoop-2.6.3 hadoop
rm -rf hadoop-2.6.3.tar.gz

mkdir -p /hdfs/namenode
mkdir -p /hdfs/datanode

echo "Configuring Hadoop...."

cd /usr/lib/hadoop/etc/hadoop

cat >> hadoop-env.sh << EOL
export JAVA_HOME=/usr/lib/jvm/java-openjdk
EOL

cat > core-site.xml << EOL
<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://${MASTER}:8020</value>
  </property>
</configuration>
EOL

cat > mapred-site.xml << EOL
<configuration>
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.address</name>
    <value>${MASTER}:10020</value>
  </property>
  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>${MASTER}:19888</value>
  </property>
</configuration>
EOL

cat > yarn-site.xml << EOL
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>${MASTER}</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.hostname</name>
    <value>${myip}</value>
  </property>
</configuration>
EOL

cat > hdfs-site.xml << EOL
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>
  <property>
    <name>dfs.name.dir</name>
    <value>file:///hdfs/namenode</value>
  </property>
  <property>
    <name>dfs.data.dir</name>
    <value>file:///hdfs/datanode</value>
  </property>
  <property>
    <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
    <value>false</value>
  </property>
</configuration>
EOL

echo "Stop and disable firewall"
systemctl stop firewalld
systemctl disable firewalld

if [ "$mode" == "master" ]; then
  echo "Formatting HDFS...."
  /usr/lib/hadoop/bin/hdfs namenode -format
  echo "Formatting HDFS done"

  echo "Starting namenode...."
  /usr/lib/hadoop/sbin/hadoop-daemons.sh \
    --config "/usr/lib/hadoop/etc/hadoop" \
    --script "/usr/lib/hadoop/bin/hdfs" start namenode
  echo "Starting namenode done"

  echo "Starting YARN resourcemanager...."
  /usr/lib/hadoop/sbin/yarn-daemon.sh --config /usr/lib/hadoop/etc/hadoop start resourcemanager
  echo "Starting YARN resourcemanager done"

  echo "Starting JobHistory server...."
  /usr/lib/hadoop/sbin/mr-jobhistory-daemon.sh --config /usr/lib/hadoop/etc/hadoop start historyserver
  echo "Starting JobHistory server done"
else
  echo "Starting datanode...."
  /usr/lib/hadoop/sbin/hadoop-daemons.sh \
    --config "/usr/lib/hadoop/etc/hadoop" \
    --script "/usr/lib/hadoop/bin/hdfs" start datanode
  echo "Starting datanode done"

  echo "Starting YARN nodemanager...."
  /usr/lib/hadoop/sbin/yarn-daemon.sh --config /usr/lib/hadoop/etc/hadoop start nodemanager
  echo "Starting YARN nodemanager done"
fi

# echo "Waiting for HDFS...."
# /usr/lib/hadoop/bin/hdfs dfsadmin -safemode wait

# echo "Adding HDFS dirs...."
# /usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/hadoop
# /usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/hive

# echo "Testng MR..."
# /usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.3.jar pi 10 1000

