#!/bin/bash
# Checks /tmp/lastyumcheck for status.

# If old enough it runs centos-package-cron and outputs the content to /tmp/centos-package-cron-output
# /tmp/centos-package-cron-output is then checked for Critical or Important updates.
#
# It would be worth adding this script into cron to reduce load and execution time.
#
# Please review /tmp/centos-package-cron-output for what updates are required before running a yum update.
# 
# This command will update all packages with security issues:
# yum update `awk '/Packages/,/References/' /tmp/centos-package-cron-output | grep "*" | cut -d " " -f2 | sed -e 's/\([^.]*\).*/\1/' -e 's/\(.*\)-.*/\1/' | sort | uniq`
#
# If you want to update JUST the items with Critical, Important, Moderate security issues, this command will do it, there is probably a more elegant way, but currently this just works:
# yum update `grep -E "critical|important|medium" /tmp/centos-package-cron-output | cut -d "." -f2 | sed -e 's/\([^.]*\).*/\1/' -e 's/\(.*\)-.*/\1/' -e 's/^ *//g' | sort | uniq`
#

#returncode:value:message
#0      OK
#1      WARNING
#2      System Error (e.g. a network/socket error)
#3      Protocol Error (e.g. web server returns a 404)
#4      Content Error (e.g. a web page does not contain a required word)

if [ ! -f /tmp/lastyumcheck ]; then
    echo "1970-01-01 00:00" > /tmp/lastyumcheck
    echo "9999" >> /tmp/lastyumcheck
fi

YUMCHECKLC=`wc -l /tmp/lastyumcheck | cut -d " " -f1`
if [ $YUMCHECKLC != 2 ]; then
    echo "1970-01-01 00:00" > /tmp/lastyumcheck
    echo "9999" >> /tmp/lastyumcheck
fi

DATECHECK=`head -n1 /tmp/lastyumcheck | grep "-" | wc -l`
if [ $DATECHECK != 1 ]; then
    echo "1970-01-01 00:00" > /tmp/lastyumcheck
    echo "9999" >> /tmp/lastyumcheck
fi

LASTCHECK=`head -n1 /tmp/lastyumcheck | grep "-"`
OUTSTANDING=`tail -n1 /tmp/lastyumcheck`
DAYSSINCECHECK=$(( ( $(date +%s) - $(date -d "$LASTCHECK" +%s) ) /(24 * 60 * 60 ) ))

if [ $DAYSSINCECHECK -gt 0 ]; then
        SUPDATES=`date '+%Y-%m-%d %H:%M' > /tmp/lastyumcheck; yum list-security > /tmp/centos-package-cron-output; cat /tmp/centos-package-cron-output | grep -E "critical|important|medium" | cut -d"." -f1 | sort | uniq | wc -l >> /tmp/lastyumcheck`
        OUTSTANDING=`tail -n1 /tmp/lastyumcheck`
        echo "0:$OUTSTANDING:$OUTSTANDING Outstanding Security Updates"
else
        echo "0:$OUTSTANDING:$OUTSTANDING Outstanding Security Updates"
fi
