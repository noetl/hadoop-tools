export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/usr/lib/spark/yarn/lib/spark-yarn-shuffle.jar"

export YARN_OPTS="$YARN_OPTS -XX:OnOutOfMemoryError='kill -9 %p'"
#export YARN_PROXYSERVER_HEAPSIZE=3338
export YARN_NODEMANAGER_HEAPSIZE=2048
export YARN_RESOURCEMANAGER_HEAPSIZE=3338

export YARN_LOG_DIR=/mnt/var/log/hadoop-yarn

export HADOOP_COMMON_HOME=/usr/lib/hadoop
export HADOOP_HDFS_HOME=/usr/lib/hadoop-hdfs
export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
export HADOOP_YARN_HOME=/usr/lib/hadoop-yarn
