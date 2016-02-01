#!/bin/bash
set -e

# script generates ip addresses from a.b.c.1 to a.b.c.254 (a, b, c determined based on machine ip)
# script adds ip to name mapping to /etc/hosts, e.g.
# 10.101.124.1 ip-10-101-124-1
# 10.101.124.2 ip-10-101-124-2
# 10.101.124.3 ip-10-101-124-3
# etc.

myip=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
if [ $# -eq 1 ]; then
  myip=$1
fi

if [ -z "$myip" ]; then
  echo "Can not determine machine ip"
  exit -1
fi

p1=$(echo $myip | cut -d. -f1)
p2=$(echo $myip | cut -d. -f2)
p3=$(echo $myip | cut -d. -f3)
p4=$(echo $myip | cut -d. -f4)

if [ $# -eq 0 ]; then
  echo "set hostname ip-$p1-$p2-$p3-$p4"
  hostname ip-$p1-$p2-$p3-$p4
fi

echo "adding records to /etc/hosts..."

echo "# ip mapping for hadoop" >> /etc/hosts

for i in `seq 1 254`;do
  echo "$p1.$p2.$p3.$i    ip-$p1-$p2-$p3-$i" >> /etc/hosts
done

echo "done"
