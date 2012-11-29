#!/bin/sh

set -e
SOURCE="<%=mysql_backup_location%>"

innobackupex --copy-back ${SOURCE}

echo "Done Creating Package(s):"
ls -ltrh "${TARGET}"*
echo "==========================="
echo "  FINISHED                 "
echo "==========================="