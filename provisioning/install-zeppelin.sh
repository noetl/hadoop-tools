#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: ./install-zeppelin.sh <AWS_ACCESS_KEY_ID> <AWS_ACCESS_SECRET_KEY>"
  exit -1
fi

AWS_ACCESS_KEY_ID=$1
AWS_ACCESS_SECRET_KEY=$2
#ZEPPELIN_NOTEBOOK_S3_BUCKET=$3
#ZEPPELIN_NOTEBOOK_S3_USER=$4

MASTER=`hostname`

echo "MASTER: $MASTER"

echo "Downloading Zeppelin...."
cd /usr/lib
#curl -f -O http://download.nextag.com/apache/incubator/zeppelin/0.5.6-incubating/zeppelin-0.5.6-incubating-bin-all.tgz
aws s3 cp s3://nomis-amsterdam-datamarts/zeppelin-0.6.0/zeppelin-0.6.0-incubating-SNAPSHOT.tar.gz /usr/lib/ --endpoint-url https://canada.os.ctl.io/
echo "Installing Zeppelin...."
tar xzf zeppelin-0.6.0-incubating-SNAPSHOT.tar.gz
mv zeppelin-0.6.0-incubating-SNAPSHOT zeppelin
rm -rf zeppelin-0.6.0-incubating-SNAPSHOT.tar.gz

echo "Configuring dirs for Zeppelin...."
mkdir -p /data01/var/log/zeppelin /data01/var/lib/zeppelin/notebook /data01/var/lib/zeppelin/webapps /data01/var/run/zeppelin
chown -R hadoop:hadoop /data01/var/log/zeppelin /data01/var/lib/zeppelin /data01/var/run/zeppelin /usr/lib/zeppelin/conf
su - hadoop -c 'cp -R /usr/lib/zeppelin/notebook/* /data01/var/lib/zeppelin/notebook/'

echo "Configuring libs for Zeppelin...."
mkdir /usr/lib/zeppelin/libs3
cp /usr/lib/zeppelin/lib/aws*.jar /usr/lib/zeppelin/libs3/
cp /usr/lib/hadoop/share/hadoop/tools/lib/hadoop-aws-*.jar /usr/lib/zeppelin/libs3/
cp /usr/lib/hadoop/share/hadoop/tools/lib/jets3t*.jar /usr/lib/zeppelin/libs3/

echo "Configuring Zeppelin...."

cd /usr/lib/zeppelin/conf

cat > zeppelin-env.sh << EOL
export JAVA_HOME=/usr/lib/jvm/java-openjdk
export ZEPPELIN_LOG_DIR=/data01/var/log/zeppelin
export ZEPPELIN_PID_DIR=/data01/var/run/zeppelin
export ZEPPELIN_NOTEBOOK_DIR=/data01/var/lib/zeppelin/notebook
export ZEPPELIN_WAR_TEMPDIR=/data01/var/lib/zeppelin/webapps
export SPARK_HOME=/usr/lib/spark
export HADOOP_CONF_DIR=/usr/lib/hadoop/etc/hadoop
export CLASSPATH=/usr/lib/hadoop/etc/hadoop:/usr/lib/hive/conf:/usr/lib/zeppelin/libs3/*:/usr/lib/hadoop-s3/*
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_ACCESS_SECRET_KEY=$AWS_ACCESS_SECRET_KEY
#export ZEPPELIN_NOTEBOOK_S3_BUCKET=ZEPPELIN_NOTEBOOK_S3_BUCKET
#export ZEPPELIN_NOTEBOOK_S3_USER=ZEPPELIN_NOTEBOOK_S3_USER
EOL

cat > interpreter.json << EOL
{
  "interpreterSettings": {
    "2BBSWVMF2": {
      "id": "2BBSWVMF2",
      "name": "spark",
      "group": "spark",
      "properties": {
        "spark.cores.max": "",
        "spark.driver.extraClassPath": "/usr/lib/hadoop/etc/hadoop:/usr/lib/hadoop-s3/*",
        "spark.yarn.jar": "",
        "master": "yarn-client",
        "zeppelin.spark.maxResult": "1000",
        "zeppelin.dep.localrepo": "local-repo",
        "spark.executor.extraJavaOptions": "-Dfile.encoding=UTF-8",
        "spark.app.name": "Zeppelin",
        "spark.executor.extraClassPath": "/usr/lib/hadoop/etc/hadoop:/usr/lib/hadoop-s3/*",
        "spark.executor.memory": "2048m",
        "zeppelin.spark.useHiveContext": "true",
        "zeppelin.spark.concurrentSQL": "false",
        "args": "",
        "spark.home": "/usr/lib/spark",
        "zeppelin.pyspark.python": "python",
        "zeppelin.dep.additionalRemoteRepository": "spark-packages,http://dl.bintray.com/spark-packages/maven,false;",
        "spark.driver.extraJavaOptions": "-Dfile.encoding=UTF-8"
      },
      "interpreterGroup": [
        {
          "class": "org.apache.zeppelin.spark.SparkInterpreter",
          "name": "spark"
        },
        {
          "class": "org.apache.zeppelin.spark.PySparkInterpreter",
          "name": "pyspark"
        },
        {
          "class": "org.apache.zeppelin.spark.SparkSqlInterpreter",
          "name": "sql"
        },
        {
          "class": "org.apache.zeppelin.spark.DepInterpreter",
          "name": "dep"
        }
      ],
      "dependencies": [],
      "option": {
        "remote": true
      }
    },
    "2BC9GXJK4": {
      "id": "2BC9GXJK4",
      "name": "hive",
      "group": "hive",
      "properties": {
        "default.password": "",
        "default.user": "hadoop",
        "hive.hiveserver2.url": "jdbc:hive2://localhost:10000",
        "default.driver": "org.apache.hive.jdbc.HiveDriver",
        "default.url": "jdbc:hive2://localhost:10000",
        "common.max_count": "1000",
        "hive.hiveserver2.password": "",
        "hive.hiveserver2.user": "hadoop"
      },
      "interpreterGroup": [
        {
          "class": "org.apache.zeppelin.hive.HiveInterpreter",
          "name": "hql"
        }
      ],
      "dependencies": [],
      "option": {
        "remote": true
      }
    }
  },
  "interpreterBindings": {
    "2BEEMXJNB": [
      "2BBSWVMF2",
      "2BC9GXJK4"
    ],
    "2BF95A9CJ": [
      "2BBSWVMF2",
      "2BC9GXJK4"
    ],
    "2BDH37QXD": [
      "2BBSWVMF2",
      "2BC9GXJK4"
    ]
  },
  "interpreterRepositories": [
    {
      "id": "central",
      "type": "default",
      "url": "http://repo1.maven.org/maven2/",
      "releasePolicy": {
        "enabled": true,
        "updatePolicy": "daily",
        "checksumPolicy": "warn"
      },
      "snapshotPolicy": {
        "enabled": true,
        "updatePolicy": "daily",
        "checksumPolicy": "warn"
      },
      "mirroredRepositories": [],
      "repositoryManager": false
    },
    {
      "id": "local",
      "type": "default",
      "url": "file:///home/hadoop/.m2/repository",
      "releasePolicy": {
        "enabled": true,
        "updatePolicy": "daily",
        "checksumPolicy": "warn"
      },
      "snapshotPolicy": {
        "enabled": true,
        "updatePolicy": "daily",
        "checksumPolicy": "warn"
      },
      "mirroredRepositories": [],
      "repositoryManager": false
    }
  ]
}
EOL

chown hadoop:hadoop /usr/lib/zeppelin/conf/interpreter.json

#cat > zeppelin-site.xml << EOL
#<configuration>
#  <property>
#    <name>zeppelin.notebook.storage</name>
#    <value>org.apache.zeppelin.notebook.repo.S3NotebookRepo</value>
#  </property>
#</configuration>
#EOL

echo "Configuring Zeppelin done"

su - hadoop -c 'cat >> ~/.bashrc << EOL
export PATH=\$PATH:/usr/lib/zeppelin/bin
EOL'

#set +e
#echo "Trying to create s3n://${ZEPPELIN_NOTEBOOK_S3_BUCKET}/${ZEPPELIN_NOTEBOOK_S3_USER}/notebook folder"
#su - hadoop -c 'hadoop fs -mkdir -p s3n://${ZEPPELIN_NOTEBOOK_S3_BUCKET}/${ZEPPELIN_NOTEBOOK_S3_USER}/notebook'
#set -e

echo "Starting Zeppelin..."
su - hadoop -c '/usr/lib/zeppelin/bin/zeppelin-daemon.sh start'
echo "done"
echo "Zeppelin          http://${MASTER}:8080/"
