#!/bin/bash
# График занятости каналов WiFi на bash. Евгений Степанищев http://bolknote.ru/ 2011
# Bash simple WiFi channels scanner. Copyright by Evgeny Stepanischev http://bolknote.ru/ 2011

declare -a dots

TEMP=$(mktemp -t `basename "$0"`)
trap "/bin/rm -f $TEMP" EXIT

if [ -z $1 ]; then
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s > $TEMP
else
    /bin/cp "$1" $TEMP
fi

# Если название точки содержит пробел, у нас всё поедет, надо избавиться от названия
# для этого мы меряем с каким отступом идёт первая строка
cutname=`awk 'NR==1 {l=length; gsub(/^ +/, ""); print l-length+6}' $TEMP`

# Название будет отрезано командой cut
while read line; do
    line=($line)

    chs=(${line[2]//,/ })

    # Берём только каналы 2,4ГГц
    if [ ${chs[0]} -gt 13 ]; then
        continue
    fi

    # Округляем уровень сигнала
    let lvl="(100 + ${line[1]} + 9) / 10"
    # Уровень прозрачности верхней линии
    let alpha="$lvl*10 - (100 + ${line[1]})"

    # Номера каналов
    let start="${chs[0]}-2+1"
    let end="${chs[0]}+2+${chs[1]:-0}*5+1"

    # Набор точек для рисования прямоугольника wifi-точки
    for x in $(seq $start $end); do

        # Прямоугольник закрашивается сплошным…
        for y in $(seq 0 $(($lvl - 1)) ); do 
            dots[$x+$y*100]=10
        done

        # Кроме верхней границы, она закрашивается значением
        # наибольшей насыщенности
        let xy="$x+($y+1)*100"

        if  [[ -z ${dots[$xy]} || ${dots[$xy]} -lt $alpha ]]; then
            dots[$xy]=$alpha
        fi
    done

done < <(tail -n +2 $TEMP | cut -b${cutname}- | sort -rgk2)

# Блоки по насыщенности границы
blocks=(_ ░ ░ ░ ▒ ▒ ▒ ▒ ▒ ▒ █)

# Цвета вертикальной оси
colors=(32 32 32 32 32 33 33 31 31 31 31)

# Счётчик вертикальной оси
lvl=0

declare -i alpha

# Отрисовка шкалы и данных точек
for y in {10..0}; do
    printf "\033[${colors[-$lvl/10]}m% 4d " $lvl
    let lvl="$lvl - 10"

    for x in {0..15}; do
        alpha=${dots[$x+100*$y]}

        if [ $alpha -le 0 ]; then
            echo -n '   '
        else
            b=${blocks[$alpha]}

            echo -ne "\033[37m$b$b$b"
        fi
    done

    echo
done

# Горизонтальная ось
echo -e "\033[37m     -- -- 01 02 03 04 05 06 07 08 09 10 11 12 13"

echo -e "\033[0m"

