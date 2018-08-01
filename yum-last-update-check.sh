#!/bin/sh

#returncode:value:message
#0      OK
#1      WARNING
#2      System Error (e.g. a network/socket error)
#3      Protocol Error (e.g. web server returns a 404)
#4      Content Error (e.g. a web page does not contain a required word)

LASTUPDATE=`yum history | grep Update | head -n 1 | cut -d'|' -f3`
#grep U matches with Update and U
#head -n1 takes upper line
#cut sets delimiter at | and takes column 3
#OUTPUT EXAMPLE 2016-06-03 10:54

LASTUPDATEDAYSAGO=$(( ( $(date +%s) - $(date -d "$LASTUPDATE" +%s) ) /(24 * 60 * 60 ) ))
echo "0:$LASTUPDATEDAYSAGO:$LASTUPDATEDAYSAGO Days since last yum update"
