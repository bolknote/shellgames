#!/bin/bash
# Информация о батарейке на bash. Евгений Степанищев http://bolknote.ru/ 2011
# Bash Battery Info. Copyright by Evgeny Stepanischev http://bolknote.ru/ 2011


# Хост для информации о серийнике
HOST='www.chipmunk.nl'

# Выбираем информацию о батарее, получится что-то вроде
# Amperage 18446744073709550574 Flags 4 Capacity 6632 Current 6338 Voltage 8192 CycleCount 14 и тд

BATTERY=( $(\
    ioreg -w0 -l |
    egrep '(Max|Design)Capacity|(Legacy|IO)BatteryInfo|product-name|Temperature|PlatformSerialNumber' |
    tee >(awk -F{ '/(Legacy|IO)BatteryInfo/ { gsub(/ |\}|"/, ""); gsub(/,|=/, " "); print $2 }') |
    tee >(awk -F'"' '/(Max|Design)Capacity|product-name|Temperature|PlatformSerialNumber/ { gsub(/[=<>-]/, ""); print $2 $3 $4}') |
    grep -vF '"' |
    tr '\n' ' '
))

# Достаём значение по ключу из BATTERY
function GetBatVal {
    local i

    for ((i=0; i<${#BATTERY[@]}; i+=2)); do
        if [ $1 = ${BATTERY[$i]} ]; then
            echo ${BATTERY[$i+1]}
            break
        fi
    done
}

# Получаем информацию о неделе выпуска
function GetPlatform {
    local tmpfile="$TMPDIR/battery-age-mac"

    # Файл с кешем, чтобы не дёргать сервис каждый раз
    if [ -e $tmpfile ]; then
        # проверим время создания файла
        eval $(stat -s $tmpfile)

        # Если кеш устарел, то удаляем его
        if [ $((`date +%s` - $st_mtime)) -gt 86400 ]; then
            rm -f $tmpfile
        else
            cat $tmpfile
            return
        fi
    fi

    getprg=`builtin type -p curl 2>&-` || getprg=`builtin type -p wget 2>&-`

    if [ -z "$getprg" ]; then
        echo NA
        return
    fi

    local date=($(\
        $getprg --connect-timeout 3 "http://$HOST/cgi-fast/applemodel.cgi?serienummer=$1" 2>/dev/null |
        sed 's/<BR>/`/g' | awk 'BEGIN {RS="`"} /Production (year|week)/{gsub("<[^>]+>", ""); print $2 $3}' |
        sort | cut -d: -f2 | tr "\r\n" '  '
    ))

    if [ ${#date[@]} -le 1 ]; then
        echo NA
        return
    fi

    local scale
    local diff

    # Считаем количество недель
    let diff="($(date +%Y)-${date[1]})*52177 + ( $(date +%V) - ${date[0]}) * 1000"

    # Выбираем что будем отображать — недели, месяцы, годы
    if [ $diff -gt 5 ]; then
        diff=$(( $diff / 4340 ))
        scale=Month

        if [ $diff -gt 12 ]; then
            diff=$(( $diff / 12 ))
            scale=Year
        fi
    else
        diff=$(( $diff / 1000 ))
        scale=Week
    fi

    [ $diff -gt 1 ] && scale=${scale}s

    echo $diff $scale | tee $tmpfile
}

# Фоновый процесс — выводим возраст модели в определённые координаты
function PrintAgeAt {
    echo -en '\033[5A\033[26G\033[K'

    printf "% 17s |" "$1"

    echo -en '\033[5B\033[0G'
}

# Рисуем прогрессбар
function PrintBat {
    # Если терминал поддерживает 256 цветов, покажем красиво
    if [[ $TERM =~ 256 ]]; then
       local colors=("38;5;160" "38;5;220" "38;5;34")
    else
       # Иначе, увы, цвета попроще
       local colors=(31 33 32)
    fi

    local c=${colors[0]}

    [ $1 -ge 13 ] && c=${colors[1]}
    [ $1 -ge 20 ] && c=${colors[2]}

    local bar=$(cat)
    local prg=$(printf "%0$1s" | tr 0 ${bar:2:1})
    local rep="\033[${c}m$prg\033[30m"

    echo -e ${bar/$prg/$rep}
}

# Всё достаточно очевидно: боксы с информацией
cur=$(GetBatVal Current)
max=$(GetBatVal Capacity)
let percent="($cur*40/$max)"

echo -e '\033[1m\n  Bashnut Battery by Evgeny Stepanischev\033[0m'

echo
echo   '  Battery charge'
echo    ┌──────────────────────────────────────────┐
printf '│ Current charge:                % 5d mAh │\n' $cur
printf '│ Maximum charge:                % 5d mAh │\n' $max
echo   '│                                          │'
echo -e '│ ████████████████████████████████████████ \033[0m│' | PrintBat $percent
echo    └──────────────────────────────────────────┘

des=$(GetBatVal DesignCapacity)
max=$(GetBatVal MaxCapacity)
let percent="($max*40/$des)"

echo   '  Battery capacity'
echo    ┌──────────────────────────────────────────┐
printf '│ Current capacity:              % 5d mAh │\n' $max
printf '│ Design capacity:               % 5d mAh │\n' $des
echo   '│                                          │'
echo -e '│ ████████████████████████████████████████ \033[0m│' | PrintBat $percent
echo    └──────────────────────────────────────────┘

echo  '  Details'
echo    ┌──────────────────────────────────────────┐
printf '│ Mac model:             % 17s │\n' $(GetBatVal productname)
echo -e '│ Age of your Mac:              \033[1m…loading…\033[0m  |'
printf '│ Battery loadcycles:                % 5d │\n' $(GetBatVal CycleCount)
printf '│ Battery temperature:             % 5s˚С |\n' `echo "scale=1;($(GetBatVal Temperature)+5)/100" | bc`
echo    └──────────────────────────────────────────┘

echo -e "\033[0m"

# Возраст Мака
PrintAgeAt "$(GetPlatform `GetBatVal IOPlatformSerialNumber`)" &

wait
