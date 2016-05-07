#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./install-hue.sh"
  exit -1
fi

MASTER=`hostname`

echo "MASTER: $MASTER"

echo "Installing prerequisites..."
yum install -y gcc-c++ rsync mariadb-devel gmp-devel ant krb5-devel \
  mysql python-devel python-simplejson python-setuptools openldap-devel \
  libtidy libxml2-devel libxslt-devel sqlite-devel \
  openssl-devel cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain

echo "All prerequisites were installed"

echo "Downloading HUE...."
cd /usr/lib
curl -f -O https://dl.dropboxusercontent.com/u/730827/hue/releases/3.9.0/hue-3.9.0.tgz
echo "Unpacking HUE...."
tar xzf hue-3.9.0.tgz
rm -rf hue-3.9.0.tgz

echo "Compiling HUE"
cd /usr/lib/hue-3.9.0
PREFIX=/usr/lib make install
useradd hue
chown -R hue /usr/lib/hue

cat > /usr/lib/hue/desktop/conf/hue.ini << EOL
[desktop]
  secret_key=219d9744d9b801633f174715dc22c3c9f6e12929
  http_host=0.0.0.0
  http_port=8888
  time_zone=America/Toronto
  django_debug_mode=false
  http_500_debug_mode=false

[hadoop]
  [[hdfs_clusters]]
    [[[default]]]
      fs_defaultfs=hdfs://${MASTER}:8020
      hadoop_conf_dir=/usr/lib/hadoop/etc/hadoop
  [[yarn_clusters]]
    [[[default]]]
      resourcemanager_host=${MASTER}
      submit_to=True
  [[mapred_clusters]]
    [[[default]]]
      submit_to=False

[beeswax]
  hive_server_host=${MASTER}
  hive_server_port=10000
  hive_conf_dir=/usr/lib/hive/conf
  use_get_log_api=false
  download_row_limit=1000000

EOL

echo "Starting HUE..."
su - hue -c 'nohup /usr/lib/hue/build/env/bin/supervisor > /tmp/hue-supervisor.out < /dev/null &'
echo "done"
echo "HUE               http://${MASTER}:8888/"
