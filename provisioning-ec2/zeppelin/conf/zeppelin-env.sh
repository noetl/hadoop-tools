# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export ZEPPELIN_PORT=8890
export ZEPPELIN_CONF_DIR=/etc/zeppelin/conf
export ZEPPELIN_LOG_DIR=/mnt/var/log/zeppelin
export ZEPPELIN_PID_DIR=/mnt/var/run/zeppelin
export ZEPPELIN_PID=$ZEPPELIN_PID_DIR/zeppelin.pid
export ZEPPELIN_NOTEBOOK_DIR=/mnt/var/lib/zeppelin/notebook
export ZEPPELIN_WAR_TEMPDIR=/mnt/var/run/zeppelin/webapps
export MASTER=yarn-client
export SPARK_HOME=/usr/lib/spark
export HADOOP_CONF_DIR=/etc/hadoop/conf
export CLASSPATH=":/etc/hive/conf:/usr/lib/hadoop-lzo/lib/*:/usr/lib/hadoop/hadoop-aws.jar:/usr/share/aws/aws-java-sdk/*:/usr/share/aws/emr/emrfs/conf:/usr/share/aws/emr/emrfs/lib/*:/usr/share/aws/emr/emrfs/auxlib/*"

export SPARK_SUBMIT_OPTIONS="$SPARK_SUBMIT_OPTIONS --conf spark.executorEnv.PYTHONPATH=/usr/lib/spark/python/lib/py4j-0.9-src.zip:/usr/lib/spark/python/:<CPS>{{PWD}}/pyspark.zip<CPS>{{PWD}}/py4j-0.9-src.zip --conf spark.yarn.isPython=true"
