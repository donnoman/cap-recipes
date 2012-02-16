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
DOWEEKLY=7                                      # Which day do you want weekly backups? (1 to 7 where 1 is Monday)
SERVER=`hostname -f || hostname 2> /dev/null`
LOCATION="<%=mysql_backup_location%>"
CURRENT="${LOCATION}/current"
LAST="${LOCATION}/last"
BUCKET="s3://<%=mysql_backup_s3_bucket%>"
DESTINATION="${BUCKET}/${SERVER}"
ROOT="<%=File.dirname(mysql_backup_script_path)%>"

<% if mysql_backup_stop_sql_thread %>
# Leave the IO_THREAD running for faster catchup
mysql -uroot -e 'STOP SLAVE SQL_THREAD'
<% end %>

# Prep LOCATION for New Backup
rm -rf "${LAST}"
mkdir -p "${CURRENT}"
mv "${CURRENT}" "${LAST}"
mkdir -p "${CURRENT}/${DATE}"

# Inject the Restore Script; You can always grab the latest for the infrastructure repo
# but this guarantees it is immediately at hand.
cp ${ROOT}/mysql_restore.sh "${CURRENT}/${DATE}"

# Start Dumping
DATABASES=`mysql -uroot --batch --skip-column-names -e 'show databases' | grep  -v 'information_schema\|mysql'`
for DBNAME in ${DATABASES}
do
    echo "==========================="
    echo "  DUMP DATABASE"
    echo "==========================="
    DUMP_PATH="${CURRENT}/${DATE}/${DBNAME}"
    echo "Database: ${DBNAME} Dump Path: ${DUMP_PATH}"
    mkdir -p "${DUMP_PATH}"
    echo "Schema:"
    mysqldump --user=root --opt --no-data ${DBNAME} > "${DUMP_PATH}/schema.sql"
    echo "Tables:"
    TABLES=`mysql -uroot --batch --skip-column-names -e "SELECT table_name FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = '${DBNAME}' ORDER BY TABLE_ROWS;"`
    for TBNAME in ${TABLES}
    do
        echo -n "${TBNAME} "
        mysqldump --user=root --opt --no-create-info ${DBNAME} ${TBNAME} > ${DUMP_PATH}/${TBNAME}.sql
    done
    echo ""
    echo "==========================="
    echo "  DUMP LISTING"
    echo "==========================="
    ls -ltrh ${DUMP_PATH}
done

<% if mysql_backup_stop_sql_thread %>
# Startup the SQL_THREAD again
mysql -uroot -e 'START SLAVE SQL_THREAD'
<% end %>

#Package CURRENT up and move it to the final DESTINATION
echo "==========================="
echo "  PACKAGING"
echo "==========================="
PACKAGE="mysql_${SERVER}_${DATE}.tar.gz"

# S3 has a 5GB limit so we break it up at 4GB.
# Rejoin later with: cat *.gz.*|tar xzf -

tar czf - --directory "${CURRENT}" "${DATE}" | split -b<%=mysql_backup_chunk_size%> - ${LOCATION}/${PACKAGE}.

echo "Done Creating Package(s):"
ls -ltrh ${LOCATION}/${PACKAGE}.*
echo "==========================="
echo "  MOVING TO S3"
echo "==========================="
s3cmd mb ${BUCKET}
# Monthly Full Backup of all Databases
if [ ${DOM} = "01" ]; then
     echo "Moving Monthly Backup"
     s3cmd put ${LOCATION}/${PACKAGE}.* ${DESTINATION}/${YEAR}/${MONTH}/${PACKAGE}/
  else

 if [ ${DNOW} = ${DOWEEKLY} ]; then
     echo "Moving Weekly Backup"
     s3cmd put ${LOCATION}/${PACKAGE}.* ${DESTINATION}/${YEAR}/${MONTH}/${WEEK}/${PACKAGE}/
  else
     echo "Moving Daily Backup"
     s3cmd put ${LOCATION}/${PACKAGE}.* ${DESTINATION}/${YEAR}/${MONTH}/${WEEK}/${DOW}/${PACKAGE}/
 fi
fi

echo "==========================="
echo "  MYSQL BACKUP FINISHED"
echo "==========================="
