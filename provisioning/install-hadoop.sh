MASTER=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
echo $MASTER

echo "Installing JDK....."

yum install java-devel

echo "JDK Installation completed...."

echo "Installed java version is...."

java -version

javac -version

echo "Configuring SSH...."
cat > ~/.ssh/config << EOL
Host *.*.*.*
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
Host localhost
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOL

cat > ~/.ssh/id_rsa << EOL
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAtRGk9zNOhEDhRRlajNeVp2ely0p8xxO/tmMhdfCrYuPA+g4J
sl9kXI5foIOoVt7JXNNWUixvldGASA0ydBwG5n589akWM7976JNN4hNEz/kuUEFG
3d7ZxaRBoPaPPxnwExFJhMRAjPTdsA8+zmq5VbsJBrE2pCR4kNvjUC7avUXCN3AR
hjxzBHJ/PB55H+E4kFpZrzdoKjK9ZlPHj06CV2TRg9LUReZld5R/iBR2OZlH16ig
eyR4j7rhaG1j0JBcGigQ0+4a6cH1sLTFnOi4wZkwcHdanKydn6lp4uCF/ECESWXO
rxzVT4hQdXL7E2LfkToznGJVdxrPFqnVrOLXqwIDAQABAoIBAQCoihXtazpobCPD
N8hLVNgeDKIMSfc/LqjCUh9xMmW1FJ4poytvds9qP7PPKv1kbtcrqiOtNWNgJrOr
XW1bGkNqBM63s33RCSmC4KocByeEFkL/vOMD3k0CZNQZyaaoa7JFbU/rXuleywYW
vPoPFNQScpgCPK3Jt5Dp9WLu3c4JYfY/Bs8bfUZ6XigX6aOw7gBYiwL2dhrPMspj
Y7ZoKlgGVrIeSnY/0X52qxPDpObSZq6oLgc0HYvclh1tz57Vcurw/YF7BRjR011Z
p+x3UCUJQtMciKCk3hLC9u/QhXRYqN6JoMq39n1wjMsC7ac/bM6XzZ3tUQ0lxSCc
ryFOkwcxAoGBAN+grf8NBZUOUTH+yiZhIo5VACaWpjtbrN/x4dGJ0efndZD3kjfr
/awavPEs3g0v8UC4DCuqYYzQKHM3IxoEBSRu0rAF/VbfLJm/qMzz03pWgs95w/hD
BER/9tW39TxL+i4tgFu+ia34m0gToYoVDzsjT72yuRoCeIe+3BTcYULvAoGBAM9H
zJRwwJ2njPNXDjmjhMWd0LaTv8bmWlCMs3QpsROZIA52MVU58MnpzqQGQQ0GvvqM
AYvUNTXzptWL20Can08ew0sHxn+bpEtG4Nro74YBkbCKv7eaDAbmZhA6ta9411cQ
TuHrX9chTQ1rTtnyDBt1bUcTL7SkHwzGuHOMWAcFAoGBAN2bjHHQxLRmgL4LoOYR
oj3sK/8RkWAHRDSUrdSJQDMQ4yeqvwKd4T+ZK53QeagV13zsJltrN8pkSYGLpURV
sYbeL/lxphFdjgQ6sxuPkQWOD4ltQG+YcfUz3jcCWorLO/xg6O+BzUxSrgbqNU3x
+qr/Hjl9kAMfabQTxmMB1XyPAoGBAMwa4isE/9X+B4ASKBK/nlzNMpil0kCz0Rji
A08OQqyOqo8y+Q7398+K6AyBkAqYqvOha2BZ/G981boPdj0eRGKvYxR9uosrIlNx
nrZQipME9oXFilTrXo5ozvWKKh94OWskxtgVYpE+3FWrZcCcZCmhrpI/JUmWFnEJ
ONWmy4NVAoGAWVwkF6lMr5swEfBiAUK/EdKceD9L8hNGCtVlFeZHe0Iz91sqh8tz
ZMFubMUA/kaM/cNqDlLztiMNRdHNbeELjiQmFvZ9KLX+69XxSDDaPL1XcRNjGnXB
raDgE0/uaDI87PG1hCSw1DE9+8BNbUuavA0l/cmPQVYf3ofGBag88hc=
-----END RSA PRIVATE KEY-----
EOL

cat ~/.ssh/id_rsa.pub << EOL
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1EaT3M06EQOFFGVqM15WnZ6XLSnzHE7+2YyF18Kti48D6DgmyX2Rcjl+gg6hW3slc01ZSLG+V0YBIDTJ0HAbmfnz1qRYzv3vok03iE0TP+S5QQUbd3tnFpEGg9o8/GfATEUmExECM9N2wDz7OarlVuwkGsTakJHiQ2+NQLtq9RcI3cBGGPHMEcn88Hnkf4TiQWlmvN2gqMr1mU8ePToJXZNGD0tRF5mV3lH+IFHY5mUfXqKB7JHiPuuFobWPQkFwaKBDT7hrpwfWwtMWc6LjBmTBwd1qcrJ2fqWni4IX8QIRJZc6vHNVPiFB1cvsTYt+ROjOcYlV3Gs8WqdWs4ter root@localhost.localdomain
EOL

cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys

chmod 600 ~/.ssh/id_rsa

echo "Downloading Hadoop...."
cd /usr/lib
sudo wget http://apache.mirrors.pair.com/hadoop/common/hadoop-2.6.3/hadoop-2.6.3.tar.gz
echo "Installing Hadoop...."
tar xzf hadoop-2.6.3.tar.gz -C hadoop
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
</configuration>
EOL

echo "Formatting HDFS...."

/usr/lib/hadoop/bin/hdfs namenode -format

echo "Formatting HDFS... done"

echo "Starting HDFS...."
/usr/lib/hadoop/sbin/hadoop-daemons.sh \
  --config "/usr/lib/hadoop/etc/hadoop" \
  --script "/usr/lib/hadoop/bin/hdfs" start namenode

/usr/lib/hadoop/sbin/hadoop-daemons.sh \
  --config "/usr/lib/hadoop/etc/hadoop" \
  --script "/usr/lib/hadoop/bin/hdfs" start datanode

echo "Waiting for HDFS...."
/usr/lib/hadoop/bin/hdfs dfsadmin -safemode wait

echo "Adding HDFS dirs...."
/usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/hadoop
/usr/lib/hadoop/bin/hadoop fs -mkdir -p /user/hive

echo "Starting YARN...."
/usr/lib/hadoop/sbin/yarn-daemon.sh --config /usr/lib/hadoop/etc/hadoop start resourcemanager

/usr/lib/hadoop/sbin/yarn-daemon.sh --config /usr/lib/hadoop/etc/hadoop start nodemanager
echo "Starting YARN.... done"

echo "Testng MR..."
/usr/lib/hadoop/bin/hadoop jar /usr/lib/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.6.3.jar pi 10 1000

