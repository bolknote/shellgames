#!/bin/sh

# Координаты каретки
CX=2

# Координаты мяча
BX=3 BY=300

# Угол приращения мяча
BAX=1 BAY=100


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
}

# Отрисовываем коробку в виртуальный экран, стирая всё
function Box {
	local x y b="\033[38;5;8m♻"
	XY=()

	for (( x=0; x<78; x+=2 )); do
		XY[$x]=$b XY[$x+3100]=$b
		XY[$x+1]=" " XY[$x+3101]=" "
	done
	
	for (( y=100; y<=3000; y+=100)) do
		XY[$y]=$b XY[$y+1]=' '
		XY[$y+76]=$b XY[$y+75]=' '
	done
}

# Перерисовка основных объектов экрана
function DrawObjects {
	Box
	
	XY[$CX+3000]="\033[38;5;160m☗"
	XY[$CX+3001]="\033[38;5;202m☰"
	XY[$CX+3002]="☰"
	XY[$CX+3003]="\033[38;5;160m☗"

}

# Рисуем экран
function DrawScreen {
	echo -ne "\033[32A"
	
	local x y
	
	for y in {0..31}; do
		for x in {0..76}; do
			echo -ne "${XY[$x+$y*100]:- }"
		done
		echo
	done
}

# Рисуем мяч
function DrawBall {
	local bx=$(($BX+$BAX))
	local by=$(($BY+$BAY))
	
	# Проверяем, не наткнулись ли мы на какое-то препятствие
	if [[ "${XY[$bx+$by]:-0}" == "0" ]]; then
		# Нет
		BX=$bx BY=$by
	else
		local wu wd wl wr
		
		if [[ "${XY[$bx+$by+100]:-0}" != "0" || $by > 100 && "${XY[$bx+$by-100]:-0}" != "0" ]]; then
			let BAX="-$BAX"
		fi
		
		if [[ "${XY[$bx+$by+1]:-0}" != "0" || $bx > 1 && "${XY[$bx+$by-1]:-0}" != "0" ]]; then
			let BAY="-$BAY"
		fi
		
		let BX="$BX+$BAX"
		let BY="$BY+$BAY"
	fi
	
	XY[$BX+$BY]="\033[38;5;15m◯"
	
	REDRAW=1
}

function Arcanoid {
	Box
	
	trap 'KeyEvent LEFT'  USR1
	trap 'KeyEvent RIGHT' USR2
	trap 'KeyEvent SPACE' HUP
	trap exit TERM
	
	while true; do
		DrawObjects
		DrawBall
		DrawScreen
	done
}

function Restore {
	[ "$CHILD" ] && kill $CHILD
	wait

 	stty "$ORIG"
    echo -e "\033[?25h\033[0m"

	(bind '"\r":accept-line') &>/dev/null
}

# Запрещаем печатать вводимое на экран
ORIG=`stty -g`
stty -echo
(bind -r '\r') &>/dev/null

trap Restore EXIT

# Убирам курсор, очищаем экран
echo -en "\033[?25l"

Arcanoid & 
CHILD=$!

while read -n1 ch; do
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