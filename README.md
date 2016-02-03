# hadoop-tools
tools and scripts to maintain hadoop &amp; spark environment

# create cluster
To create cluster run
```
. ./login.sh <login> <pass>

./create-group.sh <group_name>

./create-server.sh <group_id> nn <root_pass> 2 8
./create-server.sh <group_id> dn2 <root_pass> 2 8

./get-ip.sh <href1>
./get-ip.sh <href2>

# set-hostnames sets box hostname, adds records to /etc/hosts for all network IPs and prints box hostname
ssh root@10.101.124.30 'bash -s' < set-hostnames.sh
ssh root@10.101.124.31 'bash -s' < set-hostnames.sh

# install hadoop needa MASTER hostname (not ip)
ssh root@10.101.124.30 'bash -s' < install-hadoop.sh ip-10-101-124-30 <AWS_KEY> <AWS_SECRET_KEY>
ssh root@10.101.124.31 'bash -s' < install-hadoop.sh ip-10-101-124-30 <AWS_KEY> <AWS_SECRET_KEY>

ssh root@10.101.124.30 'bash -s' < install-hive.sh

ssh root@10.101.124.30 'bash -s' < install-spark.sh
```
