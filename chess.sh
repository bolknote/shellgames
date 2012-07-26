#!/bin/bash
# Network chess by Evgeny Stepanischev http://bolknote.ru 2011

if [ $# -ne 2 ]; then
    echo Usage: $0 host-of-opponent port
    exit
fi

# Нам требуется netcat, ищем как он называется на этой системе
NC=
for i in nc netcat ncat pnetcat; do
    which $i &>/dev/null && NC=$i && break
done

[ -z "$NC" ] && echo 'Error: you have to install netcat to continue' && exit 2

# Версия bash
BASH=(${BASH_VERSION/./ })

# Хост оппонента
HOST="$1"

# Общий порт
PORT="$2"

# Клавиатурные комбинации извстной длины
SEQLEN=(1b5b4. [2-7]. [cd]... [89ab].{5} f.{7})

# Фигуры
WHITE=(♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙ ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖)
BLACK=(♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜ ♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟)

# Наш ход?
OURMOVE=

# Я чёрный или белый?
MYCOLOR=

# Доска
declare -a XY

# Курсор
CX=1 CY=7
TAKEN=

# Необходимые нам клавиатурные коды
KUP=1b5b41
KDOWN=1b5b42
KLEFT=1b5b44
KRIGHT=1b5b43
KSPACE=20

# Восстановление экрана
function Restore {
    echo -ne "\033[10B\033[?25h\033[0m"
    stty "$ORIG" 2>/dev/null
    (bind '"\r":accept-line' 2>/dev/null)
}

trap Restore EXIT

# Выключаем Enter
(bind -r '\r' 2>/dev/null)
# Выключаем остальную клавиатуру
ORIG=`stty -g`
stty -echo

# Убирам курсор
echo -e "\033[?25l"

# Ошибка в обмене через сеть
function NetworkError {
  echo Error: cannot use port $PORT
  exit 1
}

# Отдаём события клавиатуры в сеть
function ToNet {
    echo $1 | $NC "$HOST" "$PORT" 2>&- || NetworkError
}

# Реакция на клавиши курсора
function React {
    case $1 in
        $KLEFT)
              if [ $CX -gt 1 ]; then
                  CX=$(($CX-1))
                  PrintBoard
              fi
           ;;

        $KRIGHT)
              if [ $CX -lt 8 ]; then
                  CX=$(($CX+1))
                  PrintBoard
              fi
            ;;

        $KUP)
              if [ $CY -gt 1 ]; then
                  CY=$(($CY-1))
                  PrintBoard
              fi
           ;;

        $KDOWN)
              if [ $CY -lt 8 ]; then
                  CY=$(($CY+1))
                  PrintBoard
              fi
    esac

    # Отдаём события клавиатуры в сеть
    [ "$OURMOVE" ] && ToNet $1
}


# Проверка совпадения с известной клавиатурной комбинацией
function CheckCons {
    local i

    for i in ${SEQLEN[@]}; do
        if [[ $1 =~ ^$i ]]; then
            return 0
        fi
    done

    return 1
}

# Функция реакции на клавиатуру, вызывает React на каждую нажатую клавишу,
# кроме KSPACE — на неё возвращается управление

function PressEvents {
    local real code action

    # Цикл обработки клавиш, здесь считываются коды клавиш,
    # по паузам между нажатиями собираются комбинации и известные
    # обрабатываются сразу
    while true; do
        # измеряем время выполнения команды read и смотрим код нажатой клавиши
        # akw NR==1||NR==4 забирает только строку №1 (там время real) и №4 (код клавиши)
        eval $( (time -p read -r -s -n1 ch; printf 'code %d\n' "'$ch") 2>&1 |
        awk 'NR==1||NR==4 {print $1 "=" $2}' | tr '\r\n' '  ')

        # read возвращает пусто для Enter и пробела, присваиваем им код 20,
        # а так же возвращаются отрицательные коды для UTF8
        if [ "$code" = 0 ]; then
            code=20
        else
             [ $code -lt 0 ] && code=$((256+$code))

             code=$(printf '%02x' $code)
        fi

        if [ $code = $KSPACE ]; then
            [ "$OURMOVE" ] && sleep 0.2 && ToNet $KSPACE

            SpaceEvent && return
            continue
        fi

        # Если клавиши идут подряд (задержки по времени нет)
        if [ $real = 0.00 ]; then
            seq="$seq$code"

            if CheckCons $seq; then
                React $seq
                seq=
            fi

        # Клавиши идут с задержкой (пользователь не может печатать с нулевой задержкой),
        # значит последовательность собрана, надо начинать новую
        else
            [ "$seq" ] && React $seq
            seq=$code

            # возможно последовательность состоит из одного символа
            if CheckCons $seq; then
                React $seq
                seq=
            fi
        fi
    done
}

# Проверяем чёрная или белая фигура
function CheckColor {
     echo -n ${1:0:1}
}

# Первичное заполнение доски
function FillBoard {
     local x y ch

     for y in {1..8}; do
         for x in {1..8}; do
             ch='S '

             if [ $y -le 2 ]; then
                 ch=B${BLACK[$x+8*$y-9]}
             else
                 if [ $y -ge 7 ]; then
                     ch=W${WHITE[$x+8*$y-57]}
                 fi
             fi

             XY[$x+100*$y]=$ch
         done
    done
}

# Вывод букв по краю доски
function PrintBoardLetters {
     local letters=abcdefgh

     [ -z "$OURMOVE" ] && echo -ne "\033[30m" || echo -ne "\033[0m"

     echo -n '   '

     for x in {0..7}; do
         echo -n "${letters:$x:1} "
     done
     echo
}

# Вывод цифры по краю доски
function PrintBoardDigit {
    [ -z "$OURMOVE" ] && echo -ne "\033[30m"
    echo -en " $((9-$1))\033[0m "
}

# Вывод доски
function PrintBoard {
     local x y c ch
     local colors=('48;5;209;37;1' '48;5;94;37;1')

     PrintBoardLetters

     for y in {1..8}; do
        PrintBoardDigit $y

        for x in {1..8}; do
            c=${colors[($x+$y) & 1]}
            ch=${XY[$x+100*$y]}

            if [[ $CX == $x && $CY == $y ]]; then
                c="$c;7"
                [ "$TAKEN" ] && ch=$TAKEN
                [ $MYCOLOR == B ] && c="$c;38;5;16"
            fi

            [[ $(CheckColor "$ch") == "B" ]] && c="$c;38;5;16"

            echo -en "\033[${c}m${ch:1:1} \033[m"
        done

        PrintBoardDigit $y
        echo
     done

     PrintBoardLetters

     echo -e "\033[11A"
}

# Приём событий
function NetListen {
    $NC -l $PORT 2>&- || NetworkError
}

# Готовы слушать события сети
function NetEvents {
    local code

    while true; do
        code=$(NetListen)

        [[ "$code" == "$KSPACE" ]] && SpaceEvent && return

        React $code
    done
}

# Реакция на нажатие Space и Enter — взять или положить фигуру
function SpaceEvent {
    local xy

    # Проверяем, есть ли фигура под курсором
    let xy="$CX+$CY*100"

    # Фигуры нет
    if [ "${XY[$xy]:-S }" = "S " ]; then
        if [ -z "$TAKEN" ]; then
            echo -en "\007"
        else
            # Положили фигуру
            XY[$xy]=$TAKEN
            TAKEN=
            return 0
        fi
    # Фигура есть
    else
        # Мы не должны позволять «съесть» свою фигуру
        if [[ $(CheckColor "$TAKEN") == $(CheckColor "${XY[$xy]}") ]]; then
            echo -en "\007"
        else
            # Фигура есть «в руке», мы «съедаем» противника
            if [ "$TAKEN" ]; then
                XY[$xy]=$TAKEN
                TAKEN=
                return 0    
            else
                # «В руке» ничего не было, мы взяли фигуру
                TAKEN=${XY[$xy]}
                XY[$xy]="S "
            fi
        fi
    fi

    return 1
}

# Очистка клавиатурного буфера
function ClearKeyboardBuffer {
	  # Быстро — через bash 4+
    [ $BASH -ge 4 ] && while read -t0.1 -n1 -rs; do :; done && return
	
    # Быстро — через zsh
    which zsh &>/dev/null && zsh -c 'while {} {read -rstk1 || break}' && return

    # Медленно — через bash 3-
    local delta
    while true; do
        delta=`(time -p read -rs -n1 -t1) 2>&1 | awk 'NR==1{print $2}'`
        [[ "$delta" == "0.00" ]] || break

		echo $delta
    done
}

FillBoard

# Кто будет ходить первым
ToNet HI
[[ "$(NetListen)" == "HI" ]] && OURMOVE=1
sleep 0.2
ToNet ULOOSE

[ "$OURMOVE" ] && MYCOLOR=W || MYCOLOR=B

PrintBoard

# Основной цикл — обрабатываем события из сети или с клавиатуры
while true; do
    if [ -n "$OURMOVE" ]; then
        ClearKeyboardBuffer
        PressEvents
        OURMOVE=
    else
        NetEvents
        OURMOVE=1
    fi

    PrintBoard
done
