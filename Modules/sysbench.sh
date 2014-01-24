#!/bin/bash
set -e
# This is a Prototype. Sticking with Ansible i may be worth rewriting it into Python.
# 
# This script just prepares the database
# We need this variables there is no default for them!
set >/tmp/erkan
INLINE_BLOCK=1     # Not used! Sucks in Bash TODO for Python/Ruby/Perl rewrite
                   # We use for GLOBAL_STATUS and GLOBAL_VARIABLES YAML inline blocks. 
                   # It makes the log file more human readable
                   #
if [ -f $1 ]; then # if file exists then it is called from ansible else it is a standalone script
  source ${1}   
  MODULE=1         # We are run as ansible module So we are going to write
                   # output into a table to retrieve 
 else
   MODULE=1
   while [ $# != 0 ]; do
    eval $1        # TODO: Do some checks aka key=value
    shift
   done
fi
##############################################
# Check Variables/Default
##############################################
: ${log_table='/tmp/sysbench.log'}
: ${table_count=1}
: ${table_size=1000000}
: ${num_threads=1}
: ${mysql_host=localhost}
: ${mysql_user=root}
: ${mysql_passwd=""}
: ${max_time=60}
: ${max_requests=0}
: ${mysql_test=select}          # ${name}.lua
: ${distribution=gauss}           # or uniform 
if [ -z ${task} ]; then
    echo "failed=true msg=\"Task undefinde ${task}\""
    exit 0
fi

if [ "${task}" == "run" -o "${task}" == "prepare" -o  "${task}" == "sync" -o "${task}" == "initial" -o "${task}" == "warmup" ]; then
  :
else
  echo "failed=true msg=\"task need to be run,prepare,sync or inital! was: ${task}\""
fi

#############################################
# Preserve Filehandles
exec 3>&1 4>&2


#############################################
MYSQL="mysql -u ${mysql_user} -p${mysql_passwd} -h ${mysql_host}"
SYSBENCH="sysbench --mysql-host=${mysql_host} --mysql-user=${mysql_user} --mysql-password=${mysql_passwd} " 
#SYSBENCH="sysbench --mysql-host=${mysql_host} --mysql-user=${mysql_user} --mysql-password=${mysql_passwd} --max-requests=0" 
tmpfile=$(mktemp)


trap "rm ${tmpfile}" EXIT

###############################################
###### BEGIN  Functions

function error {
  if [ $? -ne 0 ]; then
    echo "failed=true msg=\"$1:  $(< ${tmpfile})\""
    exit 0
  fi
}

function check_connection {
  $MYSQL -e 'select version()' 2>${tmpfile}
  if [ $? -ne 0 ]; then
    echo "failed=true msg=\"Connection to MySQL failed: $(< ${tmpfile})\""
    exit
  fi
}

function get_status {
  if [ ${INLINE_BLOCK} -eq 1 ]; then
    echo -n  "GLOBAL_STATUS: { "
    $MYSQL -N -e 'SELECT CONCAT(" ",VARIABLE_NAME,": \"",VARIABLE_VALUE,"\"") FROM INFORMATION_SCHEMA.GLOBAL_STATUS'    | tr '\n' ','
    echo "} "
  else
    echo "GLOBAL_STATUS:"
    $MYSQL -N -e 'SELECT CONCAT("  ",VARIABLE_NAME,": ",VARIABLE_VALUE) FROM INFORMATION_SCHEMA.GLOBAL_STATUS WHERE VARIABLE_NAME NOT IN "FT_BOOLEAN_SYNTAX"'    | sed 's/^/   /'
    # Got to exclude FT_BOOLEAN_SYNTAX as it breaks the yaml. Is going to be solved with python/ruby/perl rewrite
  fi
}

function get_variables {
  if [ ${INLINE_BLOCK} -eq 1 ]; then
    echo -n "GLOBAL_VARIABLES: {"
    $MYSQL -N -e 'SELECT CONCAT(" ",VARIABLE_NAME,": \"",VARIABLE_VALUE,"\"") FROM INFORMATION_SCHEMA.GLOBAL_VARIABLES'    | tr '\n' ','
    echo "} "
  else
    echo "GLOBAL_VARIABLES:"
    $MYSQL -N -e 'SELECT CONCAT("  ",VARIABLE_NAME,": ",VARIABLE_VALUE) FROM INFORMATION_SCHEMA.GLOBAL_VARIABLES' | sed 's/^/    /'
  fi
}

function check_buffer_pool {                 # Idea from XL
  while true; do                             # Hmm I put a \inf loop there .. 
    buffer_dirty=$($MYSQL -N -e " SELECT VARIABLE_VALUE FROM INFORMATION_SCHEMA.GLOBAL_STATUS WHERE VARIABLE_NAME like 'innodb_buffer_pool_pages_dirty'")
    # Error check in here!
    [ "${buffer_dirty}" -lt 100 ] && break
    sleep 1
  done
}

###### END  Functions
###############################################

###############################################
###### BEGIN  Checks
###### END    Checks
###############################################


if [ ${task} == "warmup" ]; then

  for i in $(seq $table_count) ; do                                 # From XL!!! :)
    $MYSQL  -e "SELECT AVG(id) FROM sbtest$i FORCE KEY (PRIMARY)" sbtest > /dev/null 2>&1   &                                                  
    PIDLIST="$PIDLIST $!"                      
  done                                         
  wait $PIDLIST                                
 # echo "changed=false" 
  exit
fi

if [ ${task} == "initial" ]; then
  [ ${MODULE} -eq 1 ] && exec >${log_table}
  get_status                   || { echo "failed=true msg=\"Error Getting Status    \"\""     ; exit ; } 
  get_variables                || { echo "failed=true msg=\"Error Getting Vairiables\"\"" ; exit ; }
  # Need some Error Handling
  [ ${MODULE} -eq 1 ] && exec 1>&3
  echo "changed=true"
  exit

fi
if [ ${task} == "prepare" ]; then
  $MYSQL -e "drop schema if exists sbtest" 
  $MYSQL -e "create schema sbtest"  
  # Stolen from XL! :)
  if [ $table_count -gt 1 ] ; then
   $SYSBENCH --test=/usr/share/doc/sysbench/tests/db/parallel_prepare.lua --oltp_tables_count=${table_count} --oltp-table-size=${table_size} --num-threads=${table_count} run
  else
    $SYSBENCH --test=/usr/share/doc/sysbench/tests/db/oltp.lua --oltp_tables_count=${table_count} --oltp-table-size=${table_size} --num-threads=1  prepare
  fi
  echo "changed=true"
  exit
fi


if [ ${task} == "run" ]; then
check_buffer_pool
seqno=$(date  "+%y%m%d%H%M%S")         # We need a unique number in that BIG yaml file
status_before="$(get_status)"
head="
${seqno}: 
  sysbench settings:
      table_count:  ${table_count}
      table_size:   ${table_size}
      num_threads:  ${num_threads}
      mysql_host:   ${mysql_host}
      max_time:     ${max_time}
      mysql_test:   ${mysql_test}
      distribution: ${distribution}"
sysbench=$($SYSBENCH --test=/usr/share/doc/sysbench/tests/db/${mysql_test}.lua  --oltp_tables_count=${table_count} --oltp-dist-type=${distribution} --oltp-table-size=${table_size} --num-threads=${num_threads} --max-time=${max_time}  --max-requests=${max_requests} run|  sed -n '/./p'| grep -Ev '^Random|^Runnin|^Threads|^sysbench|^Number' |  sed 's/^/  /')
if [ $? -ne 0 ] ; then
    echo "failed=true msg=\"$sysbench\""
fi
status_after="$(get_status)"
[ ${MODULE} -eq 1 ] && exec >>${log_table}
echo "${head}"
echo " ${status_before}"
echo "${sysbench}"
echo " ${status_after}"
#get_status
[ ${MODULE} -eq 1 ] && exec 1>&3

echo "changed=false msg=\"${mysql_test} done\""
fi

if [ ${task} == "sync" ]; then
  check_buffer_pool
  echo "synced"
  exit
fi
