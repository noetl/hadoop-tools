#!/bin/bash
set -e

if [ $# -ne 0 ]; then
  echo "Usage: ./mount-disks.sh"
  exit -1
fi

sudo mkdir -p /mnt

echo "Formatting /dev/xvdb..."
sudo mkfs -t ext4 /dev/xvdb
echo "Mounting /dev/xvdb..."
sudo mount /dev/xvdb /mnt
echo "done"
