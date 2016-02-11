#!/bin/bash

if [ $# -ne 7 ]; then
  echo "Usage: ./create-cluster.sh <group_name> <N_of_boxes> <master_cpu> <master_mem> <slave_cpu> <slave_mem> <root_passwoed>"
  exit -1
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
group_name=$1
N=$2
master_cpu=$3
master_mem=$4
slave_cpu=$5
slave_mem=$6
root_password=$7

$DIR/login.sh

group_hash=`$DIR/create-group.sh $group_name`

$DIR/create-master.sh $group_hash $master_cpu $master_mem
