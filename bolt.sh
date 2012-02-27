#!/usr/bin/env bash
# bolt — программа, которая следит за изменением папки с сайтами
# на Маке и добавляет сайты в конфиг Апача и в hosts
# Evgeny Stepanischev http://bolknote.ru Feb 2012

# Запуск: ./bolt.sh &

MYSITES=~/Sites/
HOSTS=/etc/hosts
HTTPDCONF=/etc/apache2/other/bolt-httpd.conf

MD5CURRENT=
MAGIC='# bolt' # mark regexp
MYIP='127.0.0.1'

HOSTPATT=$(/bin/cat <<PATTERN
NameVirtualHost %host%:80\n
\n
<VirtualHost %host%:80>\n
\tServerAdmin $(/usr/bin/whoami)@%host%\n
\tDocumentRoot "$MYSITES%host%"\n
\tServerName %host%\n
</VirtualHost>\n
PATTERN
)

# вызывается, чтобы убрать из /etc/hosts старые хосты
function ClearHosts {
    /usr/bin/sed -iE "/${MAGIC}$/d" "$HOSTS"
}

# скан папки Apache и высеивание того, что на имена доменов не тянет
function NewSites {
    local host

    for host in `/bin/ls -1d "$MYSITES"*/ 2>&- | /usr/bin/egrep -o '/([a-z0-9]+\.)*[a-z0-9]+/$'`; do
        echo "$MYIP ${host:1:-1} $MAGIC"
    done
}

# Обновление файла hosts из папки Apache
function RenewHosts {
    ClearHosts
    NewSites >> "$HOSTS"
}

# Убиваем старую конфигурацию
function ClearConfig {
    /bin/rm -f "$HTTPDCONF"
}

# Обновление конфигурации 
function RenewConfigFromHosts {
    local host

    ClearConfig

    for host in `/usr/bin/awk "/$MAGIC/ {print \\$2}" "$HOSTS"`; do
        echo -e ${HOSTPATT//%host%/$host} >> "$HTTPDCONF"
    done
}

# говорим Apache, что конфигурация изменилась
function TouchApache {
    /usr/bin/killall -HUP httpd 2>&-
}

# Обновление всего
# вызывается, если в папке Apache изменились папки
function SmthChanged {
    RenewHosts
    RenewConfigFromHosts
    TouchApache
}

# Подсчёт контрольной суммы папок в домашней папке Apache
function CheckNew {
    /bin/ls -1d "$MYSITES"*/ 2>&- | /sbin/md5
}

# Убираем всё, что записали на выходе
function Restore {
    ClearHosts
    ClearConfig
    TouchApache
}

# Подсчёт суммы в цикле и инициация события, если что-то сменилось
function CheckLoop {
    local md5

    while :; do
        md5=$(CheckNew)

        if [[ $md5 != "$MD5CURRENT" ]]; then
            SmthChanged

            MD5CURRENT=$md5
        fi

        /bin/sleep 1
    done
}

if [[ `/usr/bin/whoami` == root ]]; then
    trap Restore EXIT
    CheckLoop
else
    /usr/bin/sudo "$0"
fi

