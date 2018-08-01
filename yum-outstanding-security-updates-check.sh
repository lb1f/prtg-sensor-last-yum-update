#!/bin/bash

#returncode:value:message
#0      OK
#1      WARNING
#2      System Error (e.g. a network/socket error)
#3      Protocol Error (e.g. web server returns a 404)
#4      Content Error (e.g. a web page does not contain a required word)

touch /tmp/lastyumcheck
LASTCHECK=`head -n1 /tmp/lastyumcheck`
OUTSTANDING=`tail -n1 /tmp/lastyumcheck`
DAYSSINCECHECK=$(( ( $(date +%s) - $(date -d "$LASTCHECK" +%s) ) /(24 * 60 * 60 ) ))

if [ "$DAYSSINCECHECK" = 0 ]; then
        echo "0:$OUTSTANDING:$OUTSTANDING Outstanding Security Updates"
else
        SUPDATES=`date '+%Y-%m-%d %H:%M' > /tmp/lastyumcheck; yum check-update --security | grep "needed for" | cut -d " " -f1 | sed 's/No/0/g' >> /tmp/lastyumcheck`
        echo "0:$OUTSTANDING:$OUTSTANDING Outstanding Security Updates"
fi
