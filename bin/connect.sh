#!/bin/bash

source "$1"
host=$2
port=$3
tunnel_host=$4
tunnel_user=$5
pass_script=$6

#sprawdzanie warunkow
if [ "$tunnel_host" = "" ]; then
  tunnel_host=$host
fi

if [ "$tunnel_user" != "" ]; then
  tunnel_host="$tunnel_user"@"$tunnel_host"
fi

echo `date $LOGDATEFORMAT`" Establishing tunnel to $host:$port via $tunnel_host"

$pass_script $SSH -gf -L $port:$host:$port $tunnel_host sleep $TUNNELTIMEOUT

echo `date $LOGDATEFORMAT`" Establishing tunnel to $host:$port via $tunnel_host - done"
