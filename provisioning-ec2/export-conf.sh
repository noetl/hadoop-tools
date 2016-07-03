set -e

if [ $# -ne 1 ]; then
  echo "Usage: ./export-conf.sh <json_file>"
  exit -1
fi

export N=$(jq -r ".nOfBoxes" $1)
export master_box_type=$(jq -r ".masterBoxType" $1)
export slave_box_type=$(jq -r ".slaveBoxType" $1)
export slave_mem=$(jq -r ".slaveMem" $1)
export slave_cores=$(jq -r ".slaveCores" $1)
export placement_group=$(jq -r ".placementGroup" $1)
export AWS_ACCESS_KEY_ID=$(jq -r ".AWS_ACCESS_KEY_ID" $1)
export AWS_SECRET_ACCESS_KEY=$(jq -r ".AWS_SECRET_ACCESS_KEY" $1)

export master_security_group=$(jq -r ".masterSecurityGroup" $1)
export slave_security_group=$(jq -r ".slaveSecurityGroup" $1)

export region=$(jq -r ".region" $1)
export profile=$(jq -r ".profile" $1)
