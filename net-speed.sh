#!/bin/sh
# Copyright (c) 2014 Zhong Jianxin <azuwis@gmail.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Thank Stefan Breunig for the original implementation, see
# contrib/measure-net-speed.bash.

# i3status.conf should contain:
# general {
#   output_format = i3bar
# }

# i3 config looks like this:
# bar {
#   status_command exec /usr/share/doc/i3status/contrib/net-speed
# }

# Single interface
#ifaces="eth0"

# Multiple interfaces
#ifaces="eth0 wlan0"

# Auto detect
ifaces=$(ls /sys/class/net | grep -E '^(enp|wlan)')

# Interval must be the same as in i3status.conf
#interval=5

# Auto detect
if [ -f ~/.i3status.conf ]; then
  i3status_conf=~/.i3status.conf
else
  i3status_conf="/etc/i3status.conf"
fi
interval=$(grep -o '^[[:space:]]*interval[[:space:]]*=[[:space:]]*[[:digit:]]\+' $i3status_conf | grep -o '[[:digit:]]\+')
if [ x"$interval" = x ]; then
  interval=5
fi

last_rx=0
last_tx=0
rate=""

readable() {
    local byte=$1
    local kib=$(( byte >> 10 ))
    if [ "$kib" -gt 1024 ]; then
        local mib_int=$(( kib >> 10 ))
        local mib_dec=$(( kib % 1024 * 976 / 10000 ))
        if [ "$mib_dec" -lt 10 ]; then
            mib_dec="0${mib_dec}"
        fi
        echo "${mib_int}.${mib_dec}M"
    else
        echo "${kib}K"
    fi
}

update_rate() {
    local rx=0
    local tx=0
    for iface in $ifaces; do
        local tmp_rx
        local tmp_tx
        local stat="/sys/class/net/${iface}/statistics"
        read tmp_rx < "${stat}/rx_bytes"
        read tmp_tx < "${stat}/tx_bytes"
        rx=$(( rx + tmp_rx ))
        tx=$(( tx + tmp_tx ))
    done
    rate="$(readable $(( (rx - last_rx) / interval )))↓ $(readable $(( (tx - last_tx) / interval )))↑"
    last_rx=$rx
    last_tx=$tx
}

# while :; do
#     update_rate
#     echo "$rate"
#     sleep "$interval"
# done

i3status | (read line && echo "$line" && read line && echo "$line" && read line && echo "$line" && update_rate && while :
do
    read line
    update_rate
    echo ",[{\"full_text\":\"${rate}\" },${line#,\[}" || exit 1
done)
