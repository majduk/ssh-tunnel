#!/bin/bash

source "$1"
host=$2
port=$3
n=""

command="$port:$host:$port"

echo `date $LOGDATEFORMAT`" Checking tunnel to $command"
n=`ps -ef | grep "$SSH" | grep "$command" | wc -l`
echo `date $LOGDATEFORMAT`" Checked tunnel to $command: $n tunnel established"
exit $n
