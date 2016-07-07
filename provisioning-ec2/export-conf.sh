#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./export-conf.sh <json_file>"
  exit -1
fi

export N=$(jq -r ".nOfBoxes" $1)
export image_id=$(jq -r ".imageId" $1)
export master_box_type=$(jq -r ".masterBoxType" $1)
export slave_box_type=$(jq -r ".slaveBoxType" $1)
export slave_mem=$(jq -r ".slaveMem" $1)
export slave_cores=$(jq -r ".slaveCores" $1)
export spot_price=$(jq -r ".spotPrice" $1)
export subnet_id=$(jq -r ".subnetId" $1)
export placement_group=$(jq -r ".placementGroup" $1)
export AWS_ACCESS_KEY_ID=$(jq -r ".AWS_ACCESS_KEY_ID" $1)
export AWS_SECRET_ACCESS_KEY=$(jq -r ".AWS_SECRET_ACCESS_KEY" $1)
export key_name=$(jq -r ".keyName" $1)

export master_security_group=$(jq -r ".masterSecurityGroup" $1)
export slave_security_group=$(jq -r ".slaveSecurityGroup" $1)

export availability_zone=$(jq -r ".availabilityZone" $1)
export region=$(jq -r ".region" $1)
export profile=$(jq -r ".profile" $1)

export YARN_MEM=$[slave_mem*1024*87/100]
# 896 for AM + 24 for rounding issues
spark_mem=$[YARN_MEM-920]
export exec_mem=$[spark_mem*10/11]
export exec_cores=$slave_cores
