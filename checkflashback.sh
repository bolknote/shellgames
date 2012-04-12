#!/bin/bash

UUID=$(/usr/sbin/system_profiler SPHardwareDataType | /usr/bin/awk '/UUID/ {print $3}')
result=$(/usr/bin/curl "http://flashbackcheck.com/check/?uuid=$UUID" 2>&-)

echo -n "Your system status is "

case "$result" in
    "")    echo NA.;;
    clean) echo -e "\033[1;32mclean.\033[0m";;
    *)     echo -e "\033[1;31minfected.\033[0m";;
esac
