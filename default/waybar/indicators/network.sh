#!/bin/bash

escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

wlan=""
for dev in /sys/class/net/*/wireless; do
  [[ -e $dev ]] || continue
  wlan=${dev%/wireless}
  wlan=${wlan##*/}
  break
done

eth=""
for dev in /sys/class/net/*/carrier; do
  iface=${dev%/carrier}
  iface=${iface##*/}
  [[ $iface == "$wlan" || $iface == lo ]] && continue
  val=$(cat "$dev" 2>/dev/null)
  [[ $val =~ ^[0-9]+$ ]] && (( val == 1 )) && { eth=$iface; break; }
done

if [[ -n $eth ]]; then
  printf '{"alt":"ethernet","class":"ethernet","tooltip":"Connected"}\n'
  exit 0
fi

if [[ -z $wlan ]]; then
  printf '{"alt":"disconnected","class":"disconnected","text":"󰤮","tooltip":"Disconnected"}\n'
  exit 0
fi

link=$(iw dev "$wlan" link 2>/dev/null)
if [[ -z $link || $link == "Not connected." ]]; then
  printf '{"alt":"disconnected","class":"disconnected","text":"󰤮","tooltip":"Disconnected"}\n'
  exit 0
fi

ssid=$(awk -F': ' '/^[[:space:]]*SSID:/{print $2; exit}' <<< "$link")
freq=$(awk -F': ' '/^[[:space:]]*freq:/{print $2; exit}' <<< "$link")
signal=$(awk -F': ' '/^[[:space:]]*signal:/{print $2; exit}' <<< "$link")
signal=${signal% dBm}

if (( signal >= -50 )); then level=4
elif (( signal >= -60 )); then level=3
elif (( signal >= -67 )); then level=2
elif (( signal >= -75 )); then level=1
else level=0
fi

freq_ghz=$(awk '{printf "%.2f", $1/1000}' <<< "$freq")
tooltip="$(escape "$ssid") ($freq_ghz GHz)"

printf '{"alt":"wifi-%s","class":"wifi","tooltip":"%s"}\n' "$level" "$tooltip"
