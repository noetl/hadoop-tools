
login=$1
password=$2
group=$3

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

$DIR/login.sh $login $password
server_url=`$DIR/create-server.sh $group dn2 Nomis123 2 8`

echo $server_url

is_ip=0
while [ is_ip == 0 ]
do
  echo "sleep 10"
  sleep 10
  ip=`get-ip.sh $server_url`
  echo "ip: $ip"
  if [[ $ip =~ ^\"[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\"$ ]]; then
    is_ip=1
    ip=${ip:1:${#ip}-2}
  fi 
done

echo "final ip: $ip"


