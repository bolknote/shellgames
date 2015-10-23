#!/bin/bash

wifi=$(networksetup -listallhardwareports | fgrep Wi-Fi -A1 | awk 'NF==2{print $2}')

while true; do
	ping -b $wifi -t1 -n 8.8.8.8 >&- 2>&- ||
		(
			networksetup -setairportpower $wifi off;
			echo "$(date +%d.%m.%Y\ %R:%S) Reconnecting…";
			networksetup -setairportpower $wifi on;
			sleep 10
		)
	sleep 1
done