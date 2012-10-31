#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
NAME=$1
now=$(date +"%Y%m%d%H%M")

if [ "$USER" != "root" ]; then 
    echo "You are not root user, use: sudo postfix_daily_stats.sh"
    exit
fi

if [ -z "$1" ]
then
  echo "Name Not specified with command. Examples:"
  echo "sh postfix_daily_stats_report.sh error"
  echo "sh postfix_daily_stats_report.sh partner"
  exit 1
fi

pflogsumm -q -u 0 --problems_first --no_no_msg_size -d today /var/log/mail-${NAME}.log /var/log/mail-${NAME}.log.1 > /var/log/reports/postfix-stats-${NAME}.$now.txt

exit 0