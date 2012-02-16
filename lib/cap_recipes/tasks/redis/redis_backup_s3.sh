#!/bin/bash
set -e
#set -x

DATEC="`which date`"
DATE=`${DATEC} +%Y-%m-%d_%Hh%Mm`                # Datestamp e.g 2002-09-21
YEAR=`${DATEC} +%Y`
DOW=`${DATEC} +%A`                              # Day of the week e.g. Monday
DNOW=`${DATEC} +%u`                             # Day number of the week 1 to 7 where 1 represents Monday
DOM=`${DATEC} +%d`                              # Date of the Month e.g. 27
MONTH=`${DATEC} +%B`                                # Month e.g January
WEEK=`${DATEC} +%V`                                # Week Number e.g 37
DOWEEKLY=7                                      # Which day do you want weekly backups? (1 to 7 where 1 is Monday)
SERVER=`hostname`
LOCATION="<%=redis_backup_location%>"
CURRENT="${LOCATION}/current"
LAST="${LOCATION}/last"
SOURCE="<%=redis_backup_source_spec%>"
DUMP_PATH="${CURRENT}/${DATE}"
BUCKET="s3://<%=redis_backup_s3_bucket%>"
DESTINATION="${BUCKET}/${SERVER}"
PACKAGE="redis_${SERVER}_${DATE}.tar.gz"

# Prep LOCATION for New Backup
rm -rf "${LAST}"
mkdir -p "${CURRENT}"
mv "${CURRENT}" "${LAST}"
mkdir -p "${CURRENT}/${DATE}"
rm -rf ${LOCATION}/redis_${SERVER}*


<% redis.with_layout do %>
<% if redis_backup %>
echo "==========================="
echo "  REDIS BACKING UP <%=redis_name%>"
echo "==========================="
mkdir -p ${DUMP_PATH}/<%=redis_name%>
echo "Redis Backup destination: ${DUMP_PATH}/<%=redis_name%>"
echo "Force a synchronous save"
<%=redis_path%>/bin/redis-cli -h <%=redis_bind%> -p <%=redis_port%> save
<%=redis_path%>/bin/redis-cli -h <%=redis_bind%> -p <%=redis_port%> info > ${DUMP_PATH}/<%=redis_name%>/info.log
echo ''
cp <%=redis_rdb_file%> ${DUMP_PATH}/<%=redis_name%>
<% end %>
<% end %>
echo "==========================="
echo "  PACKAGING"
echo "==========================="

# S3 has a 5GB limit so we break it up at 4GB.
# Rejoin later with: cat *.gz.*|tar xzf -

tar czf - --directory "${CURRENT}" "${DATE}" | split -b<%=redis_backup_chunk_size%> - ${LOCATION}/${PACKAGE}.

echo "==========================="
echo "  PACKAGE LISTING"
echo "==========================="
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
echo "  REDIS BACKUP FINISHED"
echo "==========================="
