#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
now=$(date +"%m_%d_%Y")

pflogsumm -q -u 0 --problems_first --no_no_msg_size -d today /var/log/mail-chase.log /var/log/mail-chase.log.1 > /var/log/reports/chase-mail-report.$now.txt
#gunzip /var/log/mail-chase.log.0.gz
#pflogsumm /var/log/mail.log.0 | formail -c -I"Subject: Mail Statistics" -I"From: pflogsumm@localhost" -I"To: postmaster@example.com" -I"Received: from www.example.com ([192.168.0.100])" | sendmail postmaster@example.com
exit 0