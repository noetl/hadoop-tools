#!/bin/bash
set -e

MASTER=`hostname`
WHOAMI=`whoami`
SPARK_HOME="/usr/local/spark"

echo "MASTER: $MASTER"
echo "WHOAMI: $WHOAMI"
echo "SPARK_HOME: $SPARK_HOME"

# Control will enter here if $SPARK_HOME exists.
if [[ -d "$SPARK_HOME" || -L "$SPARK_HOME" ]]; then
  echo "SPARK_HOME folder - $SPARK_HOME already exist"
  exit -1
fi

# Update /etc/hosts if hostname does not exists.
sudo sh -c "echo `export TAB=$'\t'` && grep -q `hostname` /etc/hosts || sed -i \"\" -e \"/^127.0.0.1${TAB}localhost.*/ s/$/${TAB}`hostname`/g\" \"/etc/hosts\""

echo "Downloading Spark... ."
sudo mkdir -p $SPARK_HOME
sudo chown -R $WHOAMI $SPARK_HOME
cd $SPARK_HOME
wget -q http://www-us.apache.org/dist/spark/spark-1.6.1/spark-1.6.1-bin-hadoop2.6.tgz
echo "Installing Spark...."
tar zxf spark-1.6.1-bin-hadoop2.6.tgz
mv spark-1.6.1-bin-hadoop2.6/* ./
rm -rf spark-1.6.1-bin-hadoop2.6.tgz
rmdir spark-1.6.1-bin-hadoop2.6

echo "Configure Spark... ."
cat > $SPARK_HOME/conf/spark-defaults.conf << EOL
spark.driver.extraClassPath      /etc/hadoop/conf:/usr/local/hadoop/*:/usr/local/hadoop-hdfs/*:/usr/local/aws/aws-java-sdk/*:/usr/local/aws/emr/emrfs/conf:/usr/local/aws/emr/emrfs/lib/*:/usr/local/aws/emr/emrfs/auxlib/*
spark.executor.extraClassPath    /etc/hadoop/conf:/usr/local/hadoop/*:/usr/local/hadoop-hdfs/*:/usr/local/aws/aws-java-sdk/*:/usr/local/aws/emr/emrfs/conf:/usr/local/aws/emr/emrfs/lib/*:/usr/local/aws/emr/emrfs/auxlib/*

spark.driver.extraJavaOptions    -Dfile.encoding=UTF-8
spark.executor.extraJavaOptions  -Dfile.encoding=UTF-8
EOL

echo "Updating ~/.bashrc... ."
cat >> ~/.bashrc << EOL
export SPARK_CONF_DIR=$SPARK_HOME/conf
export SPARK_HOME=$SPARK_HOME
export PATH=\$PATH:$SPARK_HOME/bin
EOL

echo "Spark installed"


SPARK_JOBSERVER_HOME="/usr/local/spark-jobserver"
echo "SPARK_JOBSERVER_HOME: $SPARK_JOBSERVER_HOME"

if [[ -d "$SPARK_JOBSERVER_HOME" || -L "$SPARK_JOBSERVER_HOME" ]]; then
  echo "SPARK_JOBSERVER_HOME folder - $SPARK_JOBSERVER_HOME already exist"
  exit -1
fi

echo "Downloading Spark-jobserver...."
sudo mkdir -p $SPARK_JOBSERVER_HOME
sudo chown -R $WHOAMI $SPARK_JOBSERVER_HOME
cd $SPARK_JOBSERVER_HOME
wget -q http://www.noetl.io/spark-jobserver-0.6.1.tar.gz

echo "Installing Spark-jobserver... ."
tar zxf spark-jobserver-0.6.1.tar.gz
rm -rf spark-jobserver-0.6.1.tar.gz

echo "Configuring Spark-jobserver... ."
cat > $SPARK_JOBSERVER_HOME/emr.conf << EOL
spark {
 # spark.master will be passed to each job's JobContext
master = "spark://$MASTER:7077" #"local[2]"
jobserver {
 port = 8090
 jar-store-rootdir = /tmp/spark-jobserver/jars
 jobdao = spark.jobserver.io.JobFileDAO
 filedao {
   rootdir = /tmp/spark-jobserver/filedao/data
 }
}
# predefined Spark contexts
contexts {
 # test {
 #   num-cpu-cores = 1            # Number of cores to allocate.  Required.
 #   memory-per-node = 1g         # Executor memory per node, -Xmx style eg 512m, 1G, etc.
 #   spark.executor.instances = 1
 # }
 # define additional contexts here
}
# universal context configuration.  These settings can be overridden, see README.md
context-settings {
 num-cpu-cores = 2          # Number of cores to allocate.  Required.
 memory-per-node = 2g         # Executor memory per node, -Xmx style eg 512m, #1G, etc.
 spark.executor.instances = 2
 # If you wish to pass any settings directly to the sparkConf as-is, add them here in passthrough,
 # such as hadoop connection settings that don't use the "spark." prefix
 passthrough {
   #es.nodes = "192.1.1.1"
 }
}
# This needs to match SPARK_HOME for cluster SparkContexts to be created successfully
home = "$SPARK_HOME"
}
EOL

cat > $SPARK_JOBSERVER_HOME/settings.sh << EOL
INSTALL_DIR=$SPARK_JOBSERVER_HOME
LOG_DIR=/tmp/var/log/spark-jobserver
PIDFILE=spark-jobserver.pid
JOBSERVER_MEMORY=1G
SPARK_VERSION=1.6.1
SPARK_HOME=$SPARK_HOME
SPARK_CONF_DIR=$SPARK_HOME/conf
HADOOP_CONF_DIR=/etc/hadoop/conf
YARN_CONF_DIR=/etc/hadoop/conf
SCALA_VERSION=2.10.5
EOL


echo "Spark JobServer installed\n"

echo "To start spark master execute:"
echo "$SPARK_HOME/sbin/start-master.sh\n"

echo "To start spark slave run:"
echo "$SPARK_HOME/sbin/start-slave.sh spark://127.0.0.1:7077\n"

echo "To start spark job server run:"
echo "$SPARK_JOBSERVER_HOME/server_start.sh\n"

echo "To check jars in the sparkjobserver:"
echo "curl localhost:8090/jars\n"

echo "To check  existing contexts in spark-jobserver:"
echo "curl localhost:8090/contexts\n"

echo "To create a context in spark-jobserver specifying the spark monitoring port:"
echo "curl -d "" 'localhost:8090/contexts/test?num-cpu-cores=1&memory-per-node=512m&spark.executor.instances=1&spark.ui.port=4042'\n"
