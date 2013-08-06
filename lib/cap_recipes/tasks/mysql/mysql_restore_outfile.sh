#!/bin/bash

# $1 should be supplied with the command: mysql_restore_outfile.sh <database_name>
DBNAME=$1
# For now just set the Source DB the same as DBNAME, we can change this later
SOURCEDB=${DBNAME}

if [ "$USER" != "root" ]; then
    echo "You are not root user, use: sudo backup"
    exit
fi

clear
echo "|-------------------------------------------------------------"
echo "|           Restoring MySQL Database From Backup              "
echo "|-------------------------------------------------------------"
echo ""

if [ -z "$1" ]
then
  echo "Destination DB is not defined, specify with command:"
  echo "mysql_restore_outfile.sh database_name"
  exit 1
fi

read -p "Are you sure you want to overwrite $1? " -n 1
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "==========================="
  echo "  Creating ${DBNAME}"
  mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${DBNAME}"
else
  exit 1
fi

echo "==========================="
echo "  IMPORTING SCHEMA"
mysql -uroot ${DBNAME} < ${DBNAME}/schema.sql

PRIORITIES=( <%=mysql_restore_table_priorities%> )
for TABLE in ${PRIORITIES}
do
  echo "==========================="
  echo "  IMPORT PRIORITY ${TABLE}"
  mysql -uroot --database=${DBNAME} --execute="LOAD DATA LOCAL INFILE '${DBNAME}/${TABLE}' INTO TABLE ${TABLE}"
done
# Import the rest of the tables
TABLES=`ls -tr ${SOURCEDB}`
for TABLE in ${TABLES}
do
  # I had issues with this part, still may be wrong. Issues with mysql_restore_table_priorities is an array
  if [[ ${TABLE} =~ ${PRIORITIES} ]]; then
    mysql -uroot --database=${DBNAME} --execute="LOAD DATA LOCAL INFILE '${DBNAME}/${TABLE}' INTO TABLE ${TABLE}"
    echo "==========================="
    echo "  IMPORT ${TABLE}"
  else
    exit 1
  fi
done

#clear
echo "|-------------------------------------------------------------"
echo "|      Finished Restoring MySQL Database From Backup          "
echo "|-------------------------------------------------------------"
echo ""
