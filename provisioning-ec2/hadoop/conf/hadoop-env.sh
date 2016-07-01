# tez environment, needed to enable tez
export TEZ_CONF_DIR=/etc/tez/conf
export TEZ_JARS=/usr/lib/tez

# Add tez into HADOOP_CLASSPATH
export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:${TEZ_CONF_DIR}:${TEZ_JARS}/*:${TEZ_JARS}/lib/*

export HADOOP_LIBEXEC_DIR=/usr/lib/hadoop/libexec
export HADOOP_LOG_DIR=/mnt/var/log/hadoop

export HADOOP_COMMON_HOME=/usr/lib/hadoop
export HADOOP_HDFS_HOME=/usr/lib/hadoop-hdfs
export HADOOP_MAPRED_HOME=/usr/lib/hadoop-mapreduce
export HADOOP_YARN_HOME=/usr/lib/hadoop-yarn

export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/usr/lib/hadoop-lzo/lib/*"
export JAVA_LIBRARY_PATH="$JAVA_LIBRARY_PATH:/usr/lib/hadoop-lzo/lib/native"

export HADOOP_CLASSPATH=$HADOOP_CLASSPATH:/usr/share/aws/aws-java-sdk/*

export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*"

export HADOOP_CLASSPATH="$HADOOP_CLASSPATH:/usr/share/aws/emr/goodies/lib/emr-hadoop-goodies.jar"

export HADOOP_OPTS="$HADOOP_OPTS -server -XX:OnOutOfMemoryError='kill -9 %p'"
export HADOOP_NAMENODE_HEAPSIZE=6451
export HADOOP_DATANODE_HEAPSIZE=1699
export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=3338
export HADOOP_CLIENT_OPTS="$HADOOP_CLIENT_OPTS -XX:MaxPermSize=128m"
