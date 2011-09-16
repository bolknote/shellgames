#!/bin/sh

# Координаты каретки
CX=2

# Координаты мяча
BX=200 BY=200

# Угол приращения мяча
BAX=100 BAY=100

# Нужно ли обновить экран
REDRAW=1

# Зарезервировано для линии коробки
LINE1=

# Координатная сетка виртуального экрана
declare -a XY

# Обработка клавиатурных событий
function KeyEvent {
	case $1 in
		LEFT)
			[ $CX -gt 2 ] && CX=$(($CX-1))
		;;
		RIGHT)
			[ $CX -lt 71 ] && CX=$((CX+1))
		;;
		SPACE)
		;;
	esac
	
	REDRAW=1
}

# Отрисовываем коробку в виртуальный экран, стирая всё
function Box {
	local x y b="\033[38;5;8m♻"
	XY=()

	for (( x=0; x<78; x+=2 )); do
		XY[$x]=$b XY[$x+3100]=$b
		XY[$x+1]=' ' XY[$x+3101]=' '
	done
	
	for y in {1..30}; do
		XY[$y*100]=$b
		XY[$y*100+76]=$b
	done
}

# Перерисовка экрана
function DrawScreen {
	Box
	
	XY[$CX+3000]="\033[38;5;160m☗"
	XY[$CX+3001]="\033[38;5;202m☰"
	XY[$CX+3002]="☰"
	XY[$CX+3003]="\033[38;5;160m☗"
	
	XY[$BX/100+$BY]="\033[0m◯"
	
	echo -ne "\033[32A"
	
	local x y
	
	for y in {0..31}; do
		for x in {0..76}; do
			echo -ne "${XY[$x+$y*100]:- }"
		done
		echo
	done
}

# Фоновые расчёты координат
function BackScene {
	local bx=$(($BX+$BAX))
	local by=$(($BY+$BAY))
	
	if [[ "${XY[$bx+$by]:- }" == " " ]]; then
		BX=$bx BY=$by
	else
		let BAX="-$BAX"
		let BAY="-$BAY"
		
		let BX="$BX+$BAX"
		let BY="$BY+$BAY"
	fi 
	
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
	Box
	
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

# Запрещаем печатать вводимое на экран
ORIG=`stty -g`
stty -echo

trap Restore EXIT

# Убирам курсор, очищаем экран
echo -en "\033[?25l"

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