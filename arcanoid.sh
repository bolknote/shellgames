#!/bin/sh

# Выстрел
# say -v Whisper -r 1200 00

PID=$$

# Цвета блоков на уровнях
MAPCOLORS=("38;5;34" "38;5;24" "38;5;204")

# Карта уровней
declare -a MAPS

# X Y Тип (цвет) Количество
MAPS=(\
	"4 4 0 12  4 5 0 12  4 6 1 12  4 7 1 12  4 8 0 12  4 9 2 12  4 10 2 12"
	
	"13 2 1 2   8 3 1 1  24 3 1 1   5 4 1 1  27 4 1 1   5 5 1 1  27 5 1 1   8 6 1 1
	 24 6 1 1  13 7 1 2  13 4 0 2  16 5 2 1   7 1 1 1  25 1 1 1  70 2 1 1  69 3 1 1
	 33 5 1 6  35 6 1 1  35 7 1 1  33 8 1 1  44 6 1 1  44 7 1 1  42 8 1 1  68 4 1 1
	 55 6 1 1  62 6 1 1  57 7 1 1  64 7 1 1  54 8 1 1  63 8 1 1  33 4 1 6"
	
	"28 2 1 4  16 3 1 2  52 3 1 2  10 4 0 1  22 4 0 1  34 4 0 2  52 4 0 1
	 64 4 0 1   4 5 2 1  16 5 2 3  46 5 2 3  70 5 2 1   4 6 1 1  22 6 1 1
	 34 6 0 2  52 6 1 1  70 6 1 1  10 7 0 4  46 7 0 4  22 8 1 6   4 9 2 1
	 70 9 2 1  16 10 1 8"
	
	"2 1 0 1  2 2 0 1  2 3 0 1  2 4 0 1  2 5 0 1  2 6 0 1  2 7 0 1  2 8 0 1  2 9 0 2
	 16 1 1 2  16 2 1 1  16 3 1 1  16 4 1 1  16 5 1 2  16 6 1 1  16 7 1 1  16 8 1 1  16 9 1 2
	 30 1 2 1  42 1 2 1  30 2 2 1  42 2 2 1  30 3 2 1  42 3 2 1  30 4 2 1  42 4 2 1
	 30 5 2 1  42 5 2 1  30 6 2 1  42 6 2 1  32 7 2 1  40 7 2 1  32 8 2 1  40 8 2 1  36 9 2 1
	 50 1 1 2  50 2 1 1  50 3 1 1  50 4 1 1  50 5 1 2  50 6 1 1  50 7 1 1  50 8 1 1  50 9 1 2
	 64 1 0 1  64 2 0 1  64 3 0 1  64 4 0 1  64 5 0 1  64 6 0 1  64 7 0 1  64 8 0 1  64 9 0 2"	
	
	"10 2 1 10  10 9 1 10  10 3 1 1  64 3 1 1  10 4 1 1  64 4 1 1  10 5 1 1
	 64 5 1 1  10 6 1 1  64 6 1 1  10 7 1 1  64 7 1 1  10 8 1 1  64 8 1 1
	 16 4 2 8  16 7 2 8  16 5 2 1  16 6 2 1  58 5 2 1  58 6 2 1  34 5 0 2  34 6 0 2"
	
	"6 2 0 1  6 3 0 1  6 4 0 1  6 5 0 1  6 6 0 1  6 7 0 1  6 8 0 1  6 9 0 1
	 24 2 0 1  24 3 0 1  24 4 0 1  24 5 0 1  24 6 0 1  24 7 0 1  24 8 0 1  24 9 0 1
	 15 7 0 1  12 8 0 2  34 2 1 2  34 9 1 2  37 3 1 1  37 4 1 1  37 5 1 1  37 6 1 1
	 37 7 1 1  37 8 1 1  50 2 2 1  50 3 2 1  50 4 2 1  50 5 2 1  50 6 2 1  50 7 2 1
	 50 8 2 1  50 9 2 1  67 2 2 1  67 3 2 1  67 4 2 1  67 5 2 1  67 6 2 1  67 7 2 1
	 67 8 2 1  67 9 2 1  56 4 2 1  57 5 2 1  59 6 2 1  61 7 2 1"
)

# Счёт
SCORE=0

# Количество жизней
LIVES=5

# Количество блоков на уровне
MAPQUANT=

# Номер уровня
MAPNUMBER=1

# Прилипает ли мяч к ракетке
STICKY=

# Создание каретки заданной длины, заполняем глобальные
# переменные
function CreateСarriage {
	CW=$1
	# Каретка, забитая пробелами и ☰, для ускорения
	CSPACES=$(printf "% $(($CW+2))s")
	CBLOCKS=$(printf "%0$(($CW-2))s" | sed 's/0/☰/g')
}

CreateСarriage 5

# Координаты каретки
CX=2 OCX=

# Координаты падающего подарка и тип
GX= GY= GT=

# Координаты мяча
BX=5 BY=2900

# Угол приращения мяча
BAX=0 BAY=0

# Координатная сетка виртуального экрана
declare -a XY

# Заменяем say, если её нет
which say &>/dev/null || function say {
	:
}

# Отрисовка уровня по номеру
function DrawMap {
	local i j x y t q map=(${MAPS[$1]}) c

	MAPQUANT=0

	for ((i=0; i<${#map[@]}; i+=4)); do
		x=${map[$i]}   y=${map[$i+1]}
		t=${map[$i+2]} q=${map[$i+3]}

		let "MAPQUANT+=$q"
		
		c="\033[${MAPCOLORS[$t]}m☲"

		while [ $q -gt 0 ]; do
			for j in {0..3}; do
				XY[$x+100*$y+$j]=$c
			done
			let 'x+=6, q--'
		done
	done
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
			if [ $CX -lt $((75-$CW)) ]; then
				[ -z "$OCX" ] && OCX=$CX				
				
				let "CX++"
			fi
		;;
		SPACE)
			SpaceEvent
		;;
	esac
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

function PrintСarriage {
	# Если предыдущая и текущая позиция совпадают, то надо только
	# нарисовать каретку 
	
	if [ -z "$OCX" ]; then
		echo -ne "\033[$(($CX+1))G"
	else
		# Стираем каретку с того места, где она была,
		# дополнительные пробелы по краям стирают глюки
		echo -ne "\033[${OCX}G${CSPACES}"
		echo -ne "\033[$(($CX+1))G"
	fi
	
	echo -ne "\033[38;5;160m☗\033[38;5;202m$CBLOCKS\033[38;5;160m☗"

	OCX=
}

# Нажали на space
function SpaceEvent {
	# если мяч прилеплен к каретке, стартуем
	if [ $BAX -eq 0 ]; then
		BAY=-100
		[ $CX -gt 38 ] && BAX=1 || BAX=-1
		
		SoundSpace
				
		return
	fi
}

# Мячик ушёл в аут
function MissBall {
	SoundOut
	BAX=0 BAY=0
	let BX="$CX+4"
	BY=2900
	
	# Сбрасываем размер ракетки
	CreateСarriage 5	
	
	# Очищаем каретку
	echo -ne "\033[2G"
	printf "% 75s"
	
	STICKY=
	
	let 'LIVES--'
	PrintLives
	
	if [ $LIVES -le 0 ]; then
		SoundGameover
		
		echo -ne "\033[18A\033[29G\033[48;5;15;38;5;16m  G A M E  O V E R  "
		echo -ne "\033[20B\033[1G\033[0m"
		kill -HUP $PID
		while true; do
			sleep 0.3
		done
	fi
}

# Игрок победил
function YouWin {
	SoundWin
	DrawBox
	DrawMap $(($MAPNUMBER-1))
	PrintScreen	WIN
	
	echo -ne "\033[18A\033[31G\033[48;5;15;38;5;16m  Y O U  W I N  "
	echo -ne "\033[20B\033[1G\033[0m"
	kill -HUP $PID
	while true; do
		sleep 0.3
	done
}

# Рисуем виртуальный экран на экран
function PrintScreen {
	local x y xy
	
	[ -z "$1" ] && SoundWelcome
	
	for y in {0..31}; do
		for x in {0..76}; do
			xy=$(($x+$y*100))
			echo -ne "${XY[$xy]:- }"
		done
		echo
	done
	
	if [ -z "$1" ]; then	
		# Пишем и стираем номер уровня
		echo -ne "\033[20A\033[31G\033[48;5;15;38;5;16m  L E V E L  $MAPNUMBER  "
		sleep 1.3
		echo -ne "\033[31G\033[0m                             "
	fi
	
	# Курсор в нижний угол (по y=линия каретки)
	echo -ne "\033[2A\033[20B"
}

# Игра окончена
function SoundGameover {
	(say -v Zarvox "Loo Loo Loo" &>/dev/null) &
}

# Нажатие на Space
function SoundSpace {
	(say -v Whisper -r 1000 forfor &>/dev/null) &
}

# Столкновение мяча
function SoundBoom {
	(say -v Whisper -r 1000 1 &>/dev/null) &
}

# Звук прилипания
function SoundStick {
	(say -v Junior -r 1200 chpock &>/dev/null) &
}

# Звук ракетка стала длинее
function SoundWide {
	(say -v Whisper -r 400 heh &>/dev/null) &
}

# Звук шарик в аут
function SoundOut {
	(say -v Whisper -r 1000 2 uo &>/dev/null) &
}

# Звук заставки
function SoundWelcome {
	(say -v Zarvox "eueir" &>/dev/null) &
}

# Звук, когда жизнь увеличивается
function SoundLives {
	(say -r 1200 -v  Princess yes &>/dev/null ) &
}

# Победитель
function SoundWin {
	(say -v Hysterical 'Das kewl man!' &>/dev/null) &
}

# Очистка уровня
function ClearLevel {
	local i
	for i in {1..30}; do
		printf "\033[1G% 75s\033[1A"
	done
	
	echo -ne "\033[1G"
}

# Убрать блок
function RemoveBlock {
	local y
	
	for y in {0..3}; do
		unset XY[$1+$2+$y]
	done

	y=$((30-$2/100))

	echo -ne "\033[$(($1+1))G\033[${y}A    \033[${y}B"
	
	let 'MAPQUANT--'
	
	# Разбили все блоки, следующий уровень
	if [ $MAPQUANT -le 0 ]; then
		let 'MAPNUMBER++'
		ClearLevel
		
		if [ $MAPNUMBER -ge ${#MAPS[@]} ]; then
			# Игра окончена, игрок выиграл
			YouWin !
		else
			NextLevel
		fi
	fi
}

# Роняем подарок
function StartGift {
	local r=$(( $RANDOM % 20 ))
	
	if [ $r -ge 17 ]; then
		GX=$1
		GY=$((30-$2/100+1))
		
		local gifts=(S W L)	
		GT=${gifts[$r-18]}
	fi
}

# Рисуем мяч, должен рисоваться после всех объектов
function PrintBall {
	# Чистим предыдущую позицию
	local y=$((30-$BY/100))
	echo -ne "\033[$(($BX+1))G\033[${y}A${XY[$BX+$BY]:- }\033[${y}B"
	
	# Если мяч не двигается, следуем за кареткой
	if [ $BAX -eq 0 ]; then
		let BX="$CX+$CW/2"
	else		
		local bx=$(($BX+$BAX))
		local by=$(($BY+$BAY))
		
		# Мяч коснулся каретки или дна
		if [[ $by -eq 3000 ]]; then
			# Каретки
			if [[ $bx -ge $CX && $bx -le $(($CX+$CW)) ]]; then
				if [ -z "$STICKY" ]; then
					let BAY="-$BAY"
					let "BX+=$BAX"
					let "BY+=$BAY"
				# Ракетка «липкая»
				else
					BAX=0 BAY=0
					let BX="$CX+4"
					BY=2900
					
					SoundStick
				fi
			# Дна
			else
				MissBall
				return
			fi
		else	
			# Проверяем, не наткнулись ли мы на какое-то препятствие
			local c=${XY[$bx+$by]:-0}
			
			if [[ "$c" == "0" ]]; then
				# Нет
				BX=$bx BY=$by
			else
				SoundBoom
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
		
				let "BX+=$BAX"
				let "BY+=$BAY"
				
				# Проверка на столкновение с блоком
				if [[ $c =~ ☲ ]]; then
					# Ищем начало блока
					while [[ ${XY[$bx+$by-1]} =~ ☲ ]]; do
						let 'bx--'
					done
					
					# Выясняем цвет блока
					case ${XY[$bx+$by]} in
						
						# Этот блок будет преобразован в другой цвет
						*${MAPCOLORS[1]}* )
							for y in {0..3}; do
								XY[$bx+$by+$y]="\033[${MAPCOLORS[2]}m☲"
							done
							
							y=$((30-$by/100))
							
							echo -ne "\033[$(($bx+1))G\033[${y}A\033[${MAPCOLORS[2]}m☲☲☲☲\033[${y}B"
							
							PrintScores 2
							;;

							# Этот блок исчезает
							*${MAPCOLORS[2]}* )
								RemoveBlock $bx $by
								PrintScores
							;;
							
							# Этот блок исчезает, но даёт подарки
							*${MAPCOLORS[0]}* )
								RemoveBlock $bx $by
								
								[ -z "$GT" ] && StartGift $BX $by
								PrintScores
							;;
					esac
				fi
			fi
		fi
	fi
	
	local y=$((30-$BY/100))
	echo -ne "\033[$(($BX+1))G\033[${y}A\033[38;5;15m◯\033[${y}B"
}

# Рисуем падающий подарок
function PrintGift {
	echo -en "\033[$(($GX+1))G\033[${GY}A${XY[$GX+(30-$GY)*100]:- }"

	if [ $GY -le 1 ]; then
		echo -ne "\033[${GY}B"
		
		# Поймали подарок
		if [[ $GX -ge $CX && $GX -le $(($CX+$CW)) ]]; then
			PrintScores 5
			
			case $GT in
				W)
					CreateСarriage 7
					if [ $CX -gt $((75-$CW)) ]; then
						CX=$((75-$CW))
					fi
					
					PrintLives
					
					SoundWide

				;;
				
				S)
					STICKY=1
					SoundStick
				;;
				
				L)
					SoundLives
					let 'LIVES++'
					PrintLives	
			esac
		fi
		GT=
	else
		let 'GY--'
		echo -ne "\n\033[38;5;34m\033[$(($GX+1))G☲\033[${GY}B"
	fi
}

# Печать жизней
function PrintLives {
	echo -ne "\033[31A\033[3G\033[0;1m${LIVES} "
	echo -ne "\033[38;5;160m☗\033[38;5;202m$CBLOCKS\033[38;5;160m☗       \033[31B"
}

# Copyright
function PrintCopy {
	echo -ne "\033[2B\033[52G\033[0;1mhttp://bolknote.ru © 2011\033[2A"
}

# Печать счёта
function PrintScores {
	let "SCORE+=${1:-1}"
	
	PrintCopy
	
	echo -ne "\033[31A\033[$((69-${#SCORE}))G\033[0mScore: \033[1m$SCORE\033[31B"
}

# Переход на следующий уровень
function NextLevel {
	XY=()
    CreateСarriage 5
	CX=2 OCX=
	GX= GY= GT=
	BX=5 BY=2900
	BAX=0 BAY=0	
	STICKY=
	
	DrawBox
	DrawMap $(($MAPNUMBER-1))
	PrintScreen
	PrintLives
	PrintScores 0
}

# Очистка клавиатурного буфера
function ClearKeyboardBuffer {
    # Быстро — через zsh
    which zsh &>/dev/null && zsh -c 'while {} {read -rstk1 || break}' && return

    # Медленно — через bash
    local delta
    while true; do
        delta=`(time -p read -rs -n1 -t1) 2>&1 | awk 'NR==1{print $2}'`
        [[ "$delta" == "0.00" ]] || break
    done
}

function Arcanoid {
	exec 2>&-
	CHLD=
	
	trap 'KeyEvent LEFT'  USR1
	trap 'KeyEvent RIGHT' USR2
	trap 'KeyEvent SPACE' HUP
	trap "kill $PID" EXIT
	trap exit TERM
	
	echo -e "\033[J\n\n"
	
	NextLevel	
	
	local i j
	
	while true; do
		[ -n "$GT" ] && PrintGift
		
		for i in {1..2}; do
			PrintСarriage
			PrintBall
			for j in {1..4}; do
				sleep 0.02; PrintСarriage
			done
			sleep 0.02
		done
	done
}

function Restore {
	[ -n "$CHILD" ] && kill $CHILD
	wait

 	stty "$ORIG"
    echo -e "\033[?25h\033[0m"

	(bind '"\r":accept-line') &>/dev/null
	CHILD=
	
	trap '' EXIT HUP
	
	ClearKeyboardBuffer	
	
	exit
}


# Запрещаем печатать вводимое на экран
ORIG=`stty -g`
stty -echo
(bind -r '\r') &>/dev/null

trap 'Restore' EXIT HUP
trap '' TERM

# Убирам курсор
echo -en "\033[?25l\033[0m"

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
	esac  &>/dev/null
done