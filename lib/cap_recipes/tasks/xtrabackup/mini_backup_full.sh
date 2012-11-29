#!/bin/sh

set -e
TARGET="<%=mysql_backup_location%>"

innobackupex --slave-info --host=localhost --parallel=10 ${TARGET}

echo "Done Creating Package(s):"
ls -ltrh "${TARGET}"*
echo "==========================="
echo "  FINISHED                 "
echo "==========================="