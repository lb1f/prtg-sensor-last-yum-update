#!/bin/bash

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
        SUPDATES=`date '+%Y-%m-%d %H:%M' > /tmp/lastyumcheck; yum check-update --security | grep "needed for" | cut -d " " -f1 | sed 's/No/0/g' >> /tmp/lastyumcheck`
        OUTSTANDING=`tail -n1 /tmp/lastyumcheck`
        echo "0:$OUTSTANDING:$OUTSTANDING Outstanding Security Updates"
else
        echo "0:$OUTSTANDING:$OUTSTANDING Outstanding Security Updates"
fi
