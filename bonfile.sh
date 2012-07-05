#!/bin/bash

# Передача файлов на Баше с использованием Бонжура. Евгений Степанищев http://bolknote.ru/ 2012
# Bash file transfer using Bonjour. Copyright by Evgeny Stepanischev http://bolknote.ru/ 2012

DNSSD=/usr/bin/dns-sd
EXPECT=/usr/bin/expect
PS=/bin/ps
SORT=/usr/bin/sort
NC=/usr/bin/nc
AWK=/usr/bin/awk
KILL=/bin/kill
XARGS=/usr/bin/xargs
GZIP=/usr/bin/gzip
MD5=/sbin/md5
TEE=/usr/bin/tee
IPCONFIG=/usr/sbin/ipconfig
EGREP=/usr/bin/egrep
CUT=/usr/bin/cut
HEAD=/usr/bin/head
IFCONFIG=/sbin/ifconfig
ROUTE=/sbin/route
TR=/usr/bin/tr

GZIPLEVEL=3
PORT=1111
SNAME=_bolk-fileshare._tcp

# Получаем наш IP 
function _GetMyIP {
    local route=`$ROUTE -n get default 2>&-`

    if [ -z "$route" ]; then
        # Либо, первый попавшийся, если нет IP по-умолчанию
        $IFCONFIG |
            $AWK '/^[\t ]*inet/ {print $2}' |
            ($EGREP -v '^(127\.|::1)' || echo 127.0.0.1) |
            $HEAD -n1

    else
        # Либо IP по-умолчанию в системе, если он назначен
        echo "$route" |
            $EGREP -oi 'interface: [^ ]+' |
            $CUT -c12- |
            $XARGS $IPCONFIG getifaddr
    fi
}

function Client {
    local info=($($EXPECT <<CMDS | $AWK 'NR>2 {print $7 " " $8}' | $SORT -u | $TR -d '\r'
        spawn -noecho $DNSSD -B $SNAME
        expect Timestamp
        expect "$SNAME"
        exit
CMDS))

    local sum=${info[0]}
    local host=${info[1]}

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

function _ClearServer {
    # kill dns-sd
    $PS -f | $AWK "\$2==$1 && /$SNAME/ { print \$2 }" | $XARGS $KILL
}

function Server {
    if [ -e "$1" ]; then
        local info=$($MD5 -q "$1")" "$(_GetMyIP)

        $DNSSD -R "$info" "$SNAME" . $PORT >/dev/null &
    
        trap "_ClearServer $!" EXIT

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