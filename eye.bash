#!/bin/bash
# Только для терминала iTerm 2 версии 2.9 и выше!
# Требует Imagemagick для работы
W=16

# Отключаем вывод на экран
ORIG=$(stty -g)
stty -echo
# Убираем курсор
printf "\033[?25l\033[2J"

# На выходе восстанавливаем параметры экраны
trap 'Restore' EXIT
function Restore {
 	stty "$ORIG"
 	printf "\033[?1003l\033[?25h"
	exit
}

# Слушаем мышь
function Listener {
	# Будем слушать перемещения, координаты в десятичном виде
	printf "\033[?1006h\e[?1003h"
	local n code=
	local -a arr

	# Собираем координаты, считывая их побайтно
	while read -n 1 n; do
		case "$n" in
		"[")
			code=
			;;
		[0-9] | ";")
			code="$code$n"
			;;
		*)
			if [ -n "$code" ]; then
				IFS=";" read -ra arr <<<"$code"
				Eye "${arr[1]}" "${arr[2]}"
			fi
			;;
		esac
	done
}

# Выводим картинку на экран
function Img {
	printf "\033]1337;File=inline=1:%s\a\n" $(base64)
}

# Рисуем глаз по зрачком
function DrawEye {
	local x="$1" y="$2" w="$3"

	# На белом фоне — круг с обводкой, потом вырезаем из этого круг
	convert -size ${W}x${W} xc: -strokewidth 2 -stroke LightBlue \
		-fill Blue -draw "circle $x,$y $(($x+2)),$(($y+2))" \
		-strokewidth 0 \
		\( +clone -negate -fill white -draw "circle $(($w-1)),$((w-1)),$w" \) \
		-alpha off -compose copy_opacity -strip -composite png:-
}

# Выводим глаз по координатам на которые надо смотреть
function Eye {
	printf "\033[0;0H"
	local mx="$1" my="$2" w=$(($W/2))

	# Считаем гипотенузу, потом sin/cos угла, а из них выводим координаты зрачка
	xy=($(/usr/bin/awk "BEGIN {c=sqrt($mx^2+$my^2); sn=$my/c; cs=$mx/c; print int(3+$w*cs), int(3+$w*sn)}"))

	DrawEye ${xy[0]} ${xy[1]} $w | Img
}

Eye 1 1
Listener
