#!/bin/bash

set -e
#set -x

if [ -z "$1" ]
then
  echo "Dest DB is not defined"
  exit 1
fi

if [ -z "`which pv`" ]
then
  echo "PV Pipe Viewer Not installed, brew install pv OR apt-get install pv"
  exit 1
fi

DBNAME=$1
SOURCEDB=<%=mysql_restore_source_name%>

read -p "Are you sure you want to overwrite $1? " -n 1
if [[ ! $REPLY =~ ^[Yy]$ ]]
  mysql -uroot -e "DATABASE CREATE IF NOT EXISTS ${DBNAME}"
then
    exit 1
fi

PRIORITIES=( <%=mysql_restore_table_priorities%> )
for TABLE in ${PRIORITIES}
do
    echo "==========================="
    echo "  IMPORT PRIORITY ${TABLE}"
    mysql -uroot --database=${DBNAME} --execute="LOAD DATA LOCAL INFILE '${TABLE}.out' INTO TABLE ${TABLE}"
done
# The rest of the story
TABLES=`ls -tr ${SOURCEDB}`
for TABLE in ${TABLES}
do
    if [[ "${TABLE}" =~ ${PRIORITIES} ]]; then
      continue
    fi
    echo "==========================="
    echo "  IMPORT ${TABLE}"
    mysql -uroot --database=${DBNAME} --execute="LOAD DATA LOCAL INFILE '${TABLE}.out' INTO TABLE ${TABLE}"
done
