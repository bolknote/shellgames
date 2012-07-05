#!/bin/bash

# Передача файлов на Баше с использованием Бонжура. Евгений Степанищев http://bolknote.ru/ 2012
# Bash file transfer using Bonjour. Copyright by Evgeny Stepanischev http://bolknote.ru/ 2012

DNSSD=/usr/bin/dns-sd
EXPECT=/usr/bin/expect
BASE64=/usr/bin/base64
PS=/bin/ps
SORT=/usr/bin/sort
NC=/usr/bin/nc
AWK=/usr/bin/awk
KILL=/bin/kill
XARGS=/usr/bin/xargs
GZIP=/usr/bin/gzip
MD5=/sbin/md5
TEE=/usr/bin/tee

GZIPLEVEL=3
PORT=1111
SNAME=_bolk-fileshare._tcp


function Client {
    local info=($($EXPECT <<CMDS | $AWK 'NR>2 {print $5 " " $7}' | $SORT -u 
        spawn -noecho $DNSSD -B $SNAME
        expect Timestamp
        expect "$SNAME"
        exit
CMDS))

    local host=${info[0]}
    local sum=${info[1]}

    [ "$host"=="local." ] && host=localhost

    echo -n "Found file server on $host:$PORT. Getting file... " >&2

    exec 3>&1
    local filesum=$($NC $host $PORT | $GZIP -d | $TEE >&3 | $MD5 -q)

    if [ "$filesum"=="$sum" ]; then
        echo done. >&2
    else
        echo 'error (incorrect checksum)' >&2
        exit 1
    fi
}

function ClearServer {
    # kill dns-sd
    $PS -f | $AWK "\$2==$1 && /$SNAME/ { print \$2 }" | $XARGS $KILL
}

function Server {
    if [ -e "$1" ]; then
        local sum=$($MD5 -q "$1")

        $DNSSD -R "$sum" "$SNAME" . $PORT >/dev/null &
    
        trap "ClearServer $!" EXIT

        $GZIP -nc$GZIPLEVEL "$1" | $NC -l $PORT
    else
        echo "File '$1' not found!"
        exit 1
    fi
}

if [ -z $1 ]; then
    Client
else
    Server "$1"
fi