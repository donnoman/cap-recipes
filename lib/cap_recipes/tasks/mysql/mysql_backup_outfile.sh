#!/bin/sh

set -e
DATEC="`which date`"
DATE=`${DATEC} +%Y-%m-%d_%Hh%Mm`                # Datestamp e.g 2002-09-21
YEAR=`${DATEC} +%Y`
DOW=`${DATEC} +%A`                              # Day of the week e.g. Monday
DNOW=`${DATEC} +%u`                             # Day number of the week 1 to 7 where 1 represents Monday
DOM=`${DATEC} +%d`                              # Date of the Month e.g. 27
MONTH=`${DATEC} +%B`                                # Month e.g January
WEEK=`${DATEC} +%V`                                # Week Number e.g 37
DOWEEKLY=5                                      # Which day do you want weekly backups? (1 to 7 where 1 is Monday)
SERVER=`hostname -f || hostname 2> /dev/null`
LOCATION="<%=mysql_backup_location%>"
CURRENT="${LOCATION}/current"
LAST="${LOCATION}/last"
BUCKET="s3://<%=mysql_backup_s3_bucket%>"
DESTINATION="${BUCKET}/${SERVER}"
ROOT="<%=File.dirname(mysql_backup_script_path)%>"

# Only run if mysql_backup_stop_sql_thread is true
<% if mysql_backup_stop_sql_thread %>
  # Leave the IO_THREAD running for faster catch up
  mysql -uroot -e 'STOP SLAVE SQL_THREAD'
  echo "==========================="
  echo " STOPPING MYSQL SLAVE REPL."
  echo "==========================="
<% end %>

# Prep LOCATION for New Backup
rm -rf "${LAST}"
mkdir -p "${CURRENT}" && chown -R mysql:mysql "${CURRENT}"
mv "${CURRENT}" "${LAST}" && chown -R mysql:mysql "${LAST}"
mkdir -p "${CURRENT}/${DATE}" && chown -R mysql:mysql "${CURRENT}"

# Inject the Restore Script; You can always grab the latest for the infrastructure repo
# but this guarantees it is immediately at hand.
cp ${ROOT}/mysql_restore_outfile.sh "${CURRENT}/${DATE}"

# Only run if mysql_backup_stop_sql_thread is true
<% if mysql_backup_stop_sql_thread %>
  # Here we are grabbing a copy of the slave and master status before we grab a snapshot
  mysql -uroot -e 'SHOW SLAVE STATUS\G' > "${CURRENT}/${DATE}/slave_status.txt"
  mysql -uroot -e 'SHOW MASTER STATUS\G' > "${CURRENT}/${DATE}/master_status.txt"
<% end %>

# Start the export process
# Get list of Databases
DATABASES=`mysql -uroot --batch --skip-column-names -e 'show databases' | grep  -v 'information_schema\|mysql'`
for DBNAME in ${DATABASES}
do
  echo "==========================="
  echo "  DUMP DATABASE            "
  echo "==========================="
  DUMP_PATH="${CURRENT}/${DATE}/${DBNAME}"
  echo "Database: ${DBNAME} Dump Path: ${DUMP_PATH}"
  mkdir -p "${DUMP_PATH}" && chown -R mysql:mysql "${DUMP_PATH}"
  # Dump Schema First
  echo "Schema:"
  mysqldump --user=root --opt --no-data ${DBNAME} > "${DUMP_PATH}/schema.sql"
  # Grab list of tables and sort by most rows, for each, select table into outfile 
  echo "Tables:"
  TABLES=`mysql -uroot --batch --skip-column-names -e "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '${DBNAME}' ORDER BY TABLE_ROWS;"`
  for TBNAME in ${TABLES}
  do
    echo -n "${TBNAME}"
    mysql -uroot --database=${DBNAME} --execute="SELECT * FROM ${TBNAME} INTO OUTFILE '${DUMP_PATH}/${TBNAME}'"
  done
  ls -ltrh ${DUMP_PATH}
done

# Only run if mysql_backup_stop_sql_thread is true
<% if mysql_backup_stop_sql_thread %>
  # Startup the SQL_THREAD again
  mysql -uroot -e 'START SLAVE SQL_THREAD'
  echo "==========================="
  echo " STARTING MYSQL SLAVE REPL."
  echo "==========================="
<% end %>

#Package newly created CURRENT dir 
echo "==========================="
echo "  PACKAGING                "
echo "==========================="
PACKAGE="${LOCATION}/${SERVER}-${DATE}.tar.bz2"

# Switch to using lbzip2 for faster threaded compression
# The reason I'm not using a variable for current at the end is I spent too much
# time trying to figure out a clean way of removing most of the directory 
# structure in the archive, and i wanted to avoid the posibility of overwriting 
# existing directories
cd ${LOCATION} && tar --use=lbzip2 -cf "${PACKAGE}" "current"

echo "Done Creating Package(s):"
ls -ltrh "${PACKAGE}"*
echo "==========================="
echo "  FINISHED                 "
echo "==========================="