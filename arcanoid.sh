#!/bin/sh

# Координаты каретки
CX=1

# Координаты шарика
BX=1 BY=1

# Нужно ли обновить экран
REDRAW=1

function KeyEvent {
	case $1 in
		LEFT)
			[ $CX -gt 1 ] && CX=$(($CX-1))
		;;
		RIGHT)
			[ $CX -lt 70 ] && CX=$((CX+1))
		;;
		SPACE)
		;;
	esac
	
	REDRAW=1
}

function DrawScreen {
	echo -en "\033[${CX}C ☗☗☗☗ \033[$(($CX+7))D"
	#echo -en "\033[1A\033[K\033[${BX}C ◯\033[$(($BX+2))D\033[1B"
}

function BackScene {
	BX=$((BX+1))
	REDRAW=1
}

function Alarm {
	trap exit TERM
	
	while true; do
		sleep 0.1
		kill -ALRM $1
	done	
}

function Arcanoid {
	trap 'KeyEvent LEFT'  USR1
	trap 'KeyEvent RIGHT' USR2
	trap 'KeyEvent SPACE' HUP
	trap BackScene ALRM
	trap exit TERM
	
	while true; do
		[ "$REDRAW" ] && DrawScreen && REDRAW=
	done
}

function Restore {
	[ "$CHILD" ] && kill $CHILD
	[ "$BGJOB" ] && kill $BGJOB
	wait

 	stty "$ORIG"
    echo -e "\033[?25h\033[0m"
}

# Отрисовываем коробку
function Box {
	local b=☩
	local c="\033[38;5;8m"
	local r="\033[0m"
	local line=`printf "%039s" | sed "s/0/$b /g"`

	echo -e "$c$line$r"
	for i in {1..30}; do
		printf "$c$b$r% 75s$c$b$r\n"
	done
	echo -e "$c$line\033[2A$r"
	
}

# Запрещаем печатать вводимое на экран
ORIG=`stty -g`
stty -echo

trap Restore EXIT

# Убирам курсор, очищаем экран
echo -en "\033[?25l"

Box

Arcanoid & 
CHILD=$!

Alarm $CHILD &
BGJOB=$!


#echo '  ◯'
#echo '˚    ˚'
#echo  ☱☰☰☰☰☱

while read -n1 ch; do
	#printf "%d" "'$ch"
	
	case `printf "%d" "'$ch"` in
		97) 
		kill -USR1 $CHILD
		;;
		115)
		kill -USR2 $CHILD
		;;
		0)
		kill -HUP $CHILD
		;;
	esac
done