#!/bin/sh

# Флаг для отрисованных временных объектов?

# Выстрел
# say -v Whisper -r 1200 00

# Карта уровня
declare -a MAP

# Координаты каретки
CX=2 OCX=

# Ширина средней части каретки (полная ширина минус 2)
CW=3

# Каретка, забитая пробелами и ☰, для ускорения
CSPACES='          '
CBLOCKS='☰☰☰☰☰☰☰☰☰☰'

# Координаты мяча
BX=4 BY=2900

# Угол приращения мяча
BAX=0 BAY=0

# Координатная сетка виртуального экрана
declare -a XY

# Заменяем say, если её нет
which say &>/dev/null || function say {
	:
}

# Обработка клавиатурных событий
function KeyEvent {
	case $1 in
		LEFT)
			if [ $CX -gt 2 ]; then
				[ -z "$OCX" ] && OCX=$CX
				
				let "CX--"
			fi
		;;
		RIGHT)
			if [ $CX -lt 70 ]; then
				[ -z "$OCX" ] && OCX=$CX				
				
				let "CX++"
			fi
		;;
		SPACE)
			SpaceEvent
		;;
	esac
}

# Уровень рисуем в виртуальный экран
function DrawLevel {
	local b=☲ y x
	local c=("38;5;34" "38;5;34" "38;5;24" "38;5;24" "38;5;34" "38;5;204" "38;5;204")
	
	for y in {4..10}; do
		for x in {2..74}; do
			if [ $(( ($x+1) % 3)) -ne 0 ]; then
				XY[$y*100+$x]="\033[${c[$y-4]}m$b"
			else
				XY[$y*100+$x]=' '
			fi
		done
	done
}

# Отрисовываем коробку в виртуальный экран
function DrawBox {
	local x y b="\033[38;5;8m♻"
	
	for (( x=0; x<78; x+=2 )); do
		XY[$x]=$b XY[$x+3100]=$b
		XY[$x+1]=' ' XY[$x+3101]=' '
	done
	
	for (( y=100; y<=3000; y+=100)) do
		XY[$y]=$b XY[$y+1]=' '
		XY[$y+76]=$b XY[$y+75]=' '
	done
}

function DrawСarriage {
	# Если предыдущая и текущая позиция совпадают, то надо только
	# нарисовать каретку 
	
	if [ -z "$OCX" ]; then
		echo -ne "\033[${CX}C"
	else
		# Стираем каретку с того места, где она была,
		# дополнительные пробелы по краям стирают глюки
		echo -ne "\033[$(($OCX-1))C${CSPACES:0:$CW+4}"
		echo -ne "\033[100D\033[${CX}C"
	fi
	
	echo -ne "\033[38;5;160m☗\033[38;5;202m"
	echo -n  "${CBLOCKS:0:$CW}"
	echo -ne "\033[38;5;160m☗"

	# Возвращаем курсор
	echo -ne "\033[100D"
	OCX=
}

# Нажали на space
function SpaceEvent {
	# если мяч прилеплен к каретке, стартуем
	if [ $BAX -eq 0 ]; then
		BAY=-100
		[ $CX -gt 38 ] && BAX=1 || BAX=-1
		
		say -v Whisper -r 1000 forfor &>/dev/null
				
		return
	fi
}

# Мячик ушёл в аут
function MissBall {
	(say -v Whisper -r 1000 2 uo &>/dev/null) &
	BAX=0 BAY=0
	let BX="$CX+4"
	BY=2900
}

# Рисуем виртуальный экран на экран
function PrintScreen {
	local x y xy d
	
	for y in {0..31}; do
		for x in {0..76}; do
			xy=$(($x+$y*100))
			echo -ne "${XY[$xy]:- }"
		done
		echo
	done
	
	# Курсор в нижний левый угол (по x=0, по y=линия каретки)
	echo -ne "\033[2A\033[100D"
}

# Рисуем мяч, должен рисоваться после всех объектов
function DrawBall {
	# Если мяч не двигается, следуем за кареткой
	if [ $BAX -eq 0 ]; then
		let BX="$CX+2"
	else		
		local bx=$(($BX+$BAX))
		local by=$(($BY+$BAY))
		
		# Мяч достиг дна
		[ $BY -ge 3000 ] && MissBall && return
	
		# Проверяем, не наткнулись ли мы на какое-то препятствие
		if [[ "${XY[$bx+$by]:-0}" == "0" ]]; then
			# Нет
			BX=$bx BY=$by
		else			
			(say -v Whisper -r 1000 1 &>/dev/null) &			
			
			local h=0 v=0
			declare -i h v
		
			[[ "${XY[$bx+$by+100]:-0}" != "0" ]] && v=1
			[[ $by > 100 && "${XY[$bx+$by-100]:-0}" != "0" ]] && v="1$v"
			[[ "${XY[$bx+$by+1]:-0}" != "0" ]] && h=1
			[[ $bx > 1 && "${XY[$bx+$by-1]:-0}" != "0" ]] && h="1$h"
		
			if [ $h -ge $v ]; then
				let BAY="-$BAY"
			fi

			if [ $h -le $v ]; then
				let BAX="-$BAX"
			fi
		
			let BX="$BX+$BAX"
			let BY="$BY+$BAY"
		fi
	fi
	
	XY[$BX+$BY]="\033[38;5;15m◯"
}

function Arcanoid {
	exec 2>&-
	
	DrawBox
	DrawLevel
	PrintScreen
	
	trap 'KeyEvent LEFT'  USR1
	trap 'KeyEvent RIGHT' USR2
	trap 'KeyEvent SPACE' HUP
	trap exit TERM	
	
	while true; do
		DrawСarriage
		sleep 0.02
		sleep 0.02

		#DrawObjects
		#DrawBall
		#DrawScreen
		:
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

# Убирам курсор
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