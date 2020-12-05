#!/bin/bash
# Информация о батарейке на bash. Евгений Степанищев http://bolknote.ru/ 2011
# Bash Battery Info. Copyright by Evgeny Stepanischev http://bolknote.ru/ 2011

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
printf '│ Battery loadcycles:                % 5d │\n' $(GetBatVal CycleCount)
printf '│ Battery temperature:             % 5s˚С |\n' `echo "scale=1;($(GetBatVal Temperature)+5)/100" | bc`
echo    └──────────────────────────────────────────┘

echo -e "\033[0m"
