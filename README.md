# hadoop-tools
tools and scripts to maintain hadoop &amp; spark environment

# create cluster on ctl.io
To create cluster on ctl.io run
```
provisioning/create-cluster.sh <ctl_login> <ctl_password> <group_name> \
<N_of_boxes> <master_cpu> <master_mem> <slave_cpu> <slave_mem> \
<slave_disk_cnt> <slave_disk_size> \
<root_passwoed> <network_id> \
<AWS_ACCESS_KEY_ID> <AWS_SECRET_ACCESS_KEY>
```

# create cluster on Amazon EC2
To create cluster on Amazon EC2

create json config file in /tmp folder (e.g. /tmp/ec2-conf.json)
```
{
   "nOfBoxes": 6,
   "imageId": "ami-f303fb93",
   "masterBoxType": "r3.2xlarge",
   "slaveBoxType": "r3.2xlarge",
   "slaveMem": 61,
   "slaveCores": 8,
   "spotPrice": 2.99,
   "placementGroup": "spark",
   "subnetId": "subnet-2550fe52",
   "AWS_ACCESS_KEY_ID": "???",
   "AWS_SECRET_ACCESS_KEY": "???",
   "keyName": "data-key",
   "masterSecurityGroup": "sg-707d4d15",
   "slaveSecurityGroup": "sg-737d4d16",
   "availabilityZone": "us-west-2b",
   "region": "us-west-2",
   "profile": "default"
}
```

run create-cluster command
```
provisioning-ec2/create-cluster.sh /tmp/ec2-conf.json
```
It takes about 3-5 min to create and provision master and slave boxes

## stop EC2 cluster
To stop EC2 cluster

1. Open Spot Requests on EC2 console
2. Search for Spot Requests by clusterId TAG"
3. Select all items and hit Actions -> Cancel Spot Request
