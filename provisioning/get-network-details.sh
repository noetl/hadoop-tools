#!/bin/bash
set -e

if [ -z "$BTOKEN" ]; then
  echo "Need to . ./login.sh <user> <pass>"
  exit -1
fi

if [ $# -ne 1 ]; then
  echo "Usage: ./get-network-ips.sh <network_id>"
  exit -1
fi

network_id=$1
type=$2

curl -m 10 -s -H "Authorization: Bearer $BTOKEN" \
  https://api.ctl.io/v2-experimental/networks/NOMS/CA3/${network_id}
