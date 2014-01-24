#!/bin/bash
# The script just strips the yaml files from sysbench runs
# Strips out all information but:

# Format
#       num_threads: 
#       mysql_test: 
#       transactions: 
#       deadlocks: 
#       read/write requests: 
# 

function help {
  echo "Usage: simpleparser.sh [FILES]"
  exit
}
if [ $# -eq 0 ] ; then
  help
fi

while [ $# -ne 0 ]
do
  if [ ! -f $1 -o ! -r $1 ] ; then
    echo "$1 is not a file or readable. Aborting"
    exit 1
  fi
  echo " ###############################################################"
  echo " File: $1"
  sed -n 's/GLOBAL_VARIABLES.*\(gcs.fc_limit = [^;]*\).*\(WSREP_SLAVE[^,]*\).*/\1 \2/p' $1
  # This is silly, but we are going to rewrite it anyway
  sed -n 's/^ GLOBAL_STATUS.*\(WSREP_FLOW_CONTROL_PAUSED:[^,]*\).*/\1/p'  $1
  echo " num_threads:     mysql_test:    transactions:    deadlocks:        read/write requests:" 
  cat $1 |  grep -v '^GLOBAL'|grep -E 'num_threads:|mysql_test:|transactions:|deadlocks:|read/write requests:' | sed 's/transactions:.*(\(.*\) per.*/\1/'| sed 's#read/write requests:.*(\(.*\) per.*#\1#' | sed 's/deadlocks:.*(\(.*\) per.*/\1/' | sed 's/mysql_test:.* //'| tr -d '\n'| sed "s/num_threads:/\\n/g"
  shift
  echo 
done
# We need another newline
