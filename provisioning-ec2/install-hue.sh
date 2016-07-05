#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./install-hue.sh <master_hostname>"
  exit -1
fi

MASTER=$1

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "MASTER: $MASTER"

echo "Installing prerequisites..."
sudo yum install -y python26 gcc-c++ rsync gmp-devel krb5-devel \
  mysql openldap-devel \
  libtidy libxml2-devel libxslt-devel sqlite-devel \
  openssl-devel cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain

echo "All prerequisites were installed"

echo "Downloading HUE...."
cd /usr/lib
sudo aws s3 cp s3://nomis-provisioning/emr-4.7.1/hue.tar.gz .
echo "Installing HUE...."
sudo tar xzf hue.tar.gz
sudo rm -rf hue.tar.gz

sudo useradd hue
sudo chown -R hue /usr/lib/hue

sudo mkdir -p /var/log/hue /var/lib/hue
sudo chown hue /var/log/hue /var/lib/hue

echo "Configuring HUE...."

# set MASTER and other variables in template
sed -i -e "s/\${MASTER}/${MASTER}/g" $DIR/hue/conf/hue.ini

sudo cp -R $DIR/hue /etc/

sudo cp $DIR/var-lib-hue/* /var/lib/hue/
sudo chown -R hue /var/lib/hue

echo "Configuring HUE done"

echo "Creating DB"
sudo rm -rf /usr/lib/hue/desktop/desktop.db
sudo su - hue -c '/usr/lib/hue/build/env/bin/hue syncdb --noinput'
sudo su - hue -c '/usr/lib/hue/build/env/bin/hue migrate'
echo "Creating DB done"

#cat > /tmp/create_huedb.sql << EOL
#CREATE USER 'hue'@'${MASTER}' IDENTIFIED BY 'hue';
#GRANT all on *.* to 'hue'@'$MASTER' identified by 'hue';
#flush privileges;
#EOL

#sudo mysql < /tmp/create_huedb.sql

echo "Starting HUE..."
sudo su - hue -c 'nohup /usr/lib/hue/build/env/bin/supervisor > /tmp/hue-supervisor.out < /dev/null &'
echo "done"
echo "HUE               http://${MASTER}:8888"
