#!/bin/bash
# Бинарные часы на bash. Евгений Степанищев http://bolknote.ru/ 2011
# Bash Binary clock. Copyright by Evgeny Stepanischev http://bolknote.ru/ 2011

declare -a xy

# Выключаем Enter
bind -r '\r'
# Выключаем остальную клавиатуру
ORIG=`stty -g`
stty -echo

function Restore {
    stty "$ORIG"
    bind '"\r":accept-line'
    echo -ne "\033[5B\033[?25h\033[m"
}

trap 'Restore' EXIT

# Цвета наших «стрелок»
colors=(30 34)

# Очистка графического массива
function Clear {
    xy=
}

# Подготовка маски одного разряда
function Print {
    mask=$(printf '%08d' `echo "obase=2; $1" | bc`)
    let pos="$2*4"

    for x in {0..1}; do
        for y in {0..3}; do
            xy[$pos+$x+$y*100]=${mask:$x*4+$y:1}
        done
    done
}

# Печать часов на экран
function PrintClock {
    echo -e "\033[?25l\033[1mBash Binary Clock by Evgeny Stepanischev\033[0m\n"

    for y in {0..3}; do
        for x in {0..9}; do
            c=${colors[${xy[$x+$y*100]:-0}]}
            echo -ne "\033[${c}m▣"
        done
        echo -e "\033[0m"
    done

    # после печати часов передвигаем курсов так,
    # чтобы следующий кадр выводился поверх предыдущего
    echo -en "\033[8A"
}

# Вывод часов
function Clock {
    Clear
    for i in {0..2}; do
        Print $1 $i
        shift
    done

    PrintClock

    echo -e "\n"
}

while true; do
    Clock `date "+%H %M %S"`
    sleep 1
done
