#!/bin/sh

#returncode:value:message
#0      OK
#1      WARNING
#2      System Error (e.g. a network/socket error)
#3      Protocol Error (e.g. web server returns a 404)
#4      Content Error (e.g. a web page does not contain a required word)

SUPDATES=`yum check-update --security | grep "needed for" | cut -d " " -f1`
#grep U matches with Update and U
#head -n1 takes upper line
#cut sets delimiter on spaces and takes first column
#OUTPUT EXAMPLE 2

echo "0:$SUPDATES:$SUPDATES Outstanding Security Updates"
