#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-spark-jobserver.sh"
  exit -1
fi

MASTER=`hostname`

echo "MASTER: $MASTER"

echo "Downloading Spark-jobserver...."
cd /usr/lib
mkdir spark-jobserver
cd spark-jobserver
curl -f -O http://www.noetl.io/spark-jobserver-0.6.2.tar.gz
echo "Installing Spark-jobserver...."
tar zxf spark-jobserver-0.6.2.tar.gz
rm -rf spark-jobserver-0.6.2.tar.gz

mkdir -p /data01/var/log/spark-jobserver /data01/var/spark-jobserver
chown hadoop:hadoop /data01/var/log/spark-jobserver /data01/var/spark-jobserver

echo "Configuring Spark-jobserver...."

cat > settings.sh << EOL
APP_USER=root
APP_GROUP=root
INSTALL_DIR=/usr/lib/spark-jobserver
LOG_DIR=/data01/var/log/spark-jobserver
PIDFILE=/data01/var/spark-jobserver/spark-jobserver.pid
JOBSERVER_MEMORY=1G
SPARK_VERSION=1.6.1
SPARK_HOME=/usr/lib/spark
SPARK_CONF_DIR=/usr/lib/spark/conf
HADOOP_CONF_DIR=/usr/lib/hadoop/etc/hadoop
YARN_CONF_DIR=/usr/lib/hadoop/etc/hadoop
SCALA_VERSION=2.10.6
EOL

cat > emr.conf << EOL
spark {
 # spark.master will be passed to each job's JobContext
master = "yarn-client"
jobserver {
 port = 8090
 jar-store-rootdir = /mnt/tmp/spark-jobserver/jars
 jobdao = spark.jobserver.io.JobFileDAO
 filedao {
   rootdir = /mnt/tmp/spark-jobserver/filedao/data
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
 spark.dynamicAllocation.enabled = true
 spark.executor.memory = 48442M
 spark.yarn.executor.memoryOverhead = 4834
 #num-cpu-cores = 4          # Number of cores to allocate.  Required.
 #memory-per-node = 8g         # Executor memory per node, -Xmx style eg 512m, #1G, etc.
 #spark.executor.instances = 2
 # If you wish to pass any settings directly to the sparkConf as-is, add them here in passthrough,
 # such as hadoop connection settings that don't use the "spark." prefix
 passthrough {
   spark.dynamicAllocation.enabled = true
   spark.executor.memory = 48442M
   spark.yarn.executor.memoryOverhead = 4834
   #es.nodes = "192.1.1.1"
 }
}
# This needs to match SPARK_HOME for cluster SparkContexts to be created successfully
home = "/usr/lib/spark"
}
EOL

echo "Configuring Spark-jobserver done"

echo "Starting Spark-jobserver...."
su - hadoop -c 'nohup /usr/lib/spark-jobserver/server_start.sh > /dev/null 2> /dev/null < /dev/null &'
echo "Starting Spark-jobserver done"
