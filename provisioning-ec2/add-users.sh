#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./add-users.sh"
  exit -1
fi

echo "Adding hadoop user..."
sudo useradd hadoop
sudo gpasswd -a hadoop wheel

echo "Configuring SSH for hadoop user...."
sudo su - hadoop -c "ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''"
sudo su - hadoop -c "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
sudo su - hadoop -c "chmod 644 ~/.ssh/authorized_keys"
sudo su - hadoop -c "cat > ~/.ssh/config << EOL
Host *.*.*.*
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
Host localhost
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
EOL"
sudo su - hadoop -c "chmod 644 ~/.ssh/config"
echo "done"
