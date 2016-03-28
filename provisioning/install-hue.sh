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
wget -q https://dl.dropboxusercontent.com/u/730827/hue/releases/3.9.0/hue-3.9.0.tgz
echo "Unpacking HUE...."
tar xzf hue-3.9.0.tgz
# rm -rf hue-3.9.0.tgz

echo "Compiling HUE"
cd /usr/lib/hue-3.9.0
PREFIX=/usr/lib make install
useradd hue
chown -R hue /usr/lib/hue

echo "Starting HUE..."
su - hue -c 'nohup /usr/lib/hue/build/env/bin/supervisor > /tmp/hue-supervisor.out < /dev/null &'
echo "done"
echo "HUE               http://${MASTER}:8888/"
