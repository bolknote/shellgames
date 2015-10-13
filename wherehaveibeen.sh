#!/bin/bash
function coordsToAddress
{
	local x="$1" y="$2" lang=en

	[[ "$LANG" == ru* ]] && lang=ru

	curl -s "http://data.esosedi.org/geocode/v1?lng=$lang&point=$x,$y" |
	awk -F: '/"name"/ {print $2}' | xargs echo | sed 's/,$//;s/, *,/,/g'
}

function macToCoords
{
	local mac="$1"
	local where=$(curl -s "https://api.mylnikov.org/wifi/main.py/get?bssid=$mac" 2>&-)

	if [[ "$where" == *'"result":200'* ]]; then
		echo $(grep -Eo '"(lat|lon)": *[^ ",]*'<<<"$where" | xargs echo)
	fi
}

function macToAddress
{
	local mac="$1"
	local coords=$(macToCoords "$1")

	if [[ "$coords" != "" ]]; then
		if [[ "$coords" == 'lon'* ]]; then
			local xy=$(awk '{print $4" "$2}' <<< "$coords")
		else
			local xy=$(awk '{print $2" "$4}' <<< "$coords")
		fi

		local address=$(coordsToAddress $xy)
		if [[ "$address" == "" ]]; then
			address='N/A'
		fi
	else
		address='N/A'
		coords='N/A'
	fi

	echo -e "BSSID: $mac\nAddress: $address\nGeo: $coords"
}

MASK='(BSSID changed|UserEventAgent.*Probing)'

fgrep -B1 'Probing' < <(zgrep -Eh "$MASK" /var/log/system.log.*.gz ; grep -Eh "$MASK" /var/log/system.log) |
while read line; do
	case "$line" in
		*BSSID*)
			mac=$(grep -o '[^ ]*$' <<<"$line")
			;;
		*Probing*)
			name=$(sed "s/^.*Probing *'//;s/'$//" <<<"$line")
			echo "$mac $name"
			mac=
			;;
	esac
done | sort -u |
while read line; do
	line=($line)

	echo "Name: ${line[@]:1}"
	macToAddress "${line[0]}"
	echo
done