#!/bin/bash
VOICE=Alex

function SayMinute {
    local s=

    [ "$1" -gt 1 ] && s=s
    say -v "$VOICE" "$1" minute$s &
}

function SayMiddle {
    say -v "$VOICE" middle &
}

function PrintTimer {
    printf "\r⏰  \033[7m %02d:%02d \033[0m" $1 $2
}

trap 'echo -e "\033[?25h\033[0m\n"' EXIT

echo -e "\033[?25l"
start=$(date +%s)
echo -e 'Press ^C key to exit and any other key to memory current value.\n'
PrintTimer 0 0

while true; do
    timeout=( $( (time -p read -n1 -t1 -rs key) 2>&1) )

    [ ${timeout[1]} != "1.00" ] && printf "\n\n"

    now=$(date +%s)
    per=$(( $now - $start))
    sec=$(( $per % 60 ))
    min=$(( $per / 60))

    [ $sec = 30 ] && SayMiddle

    PrintTimer $min $sec

    [[ $min > 0 && $sec == 0 ]] && SayMinute $min
done