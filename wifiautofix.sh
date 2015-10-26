#!/bin/bash

wifi=$(networksetup -listallhardwareports | fgrep Wi-Fi -A1 | awk 'NF==2{print $2}')

while true; do
	if networksetup -getairportpower $wifi | fgrep -q On; then
		ping -b $wifi -t2 -n 8.8.8.8 >&- 2>&- ||
			(
				networksetup -setairportpower $wifi off
				echo "$(date +%d.%m.%Y\ %R:%S) Reconnecting…"

				until networksetup -getairportpower $wifi | fgrep -q On; do
					networksetup -setairportpower $wifi on
					sleep 1
				done
				sleep 10
			)
	fi
	sleep 1
done
