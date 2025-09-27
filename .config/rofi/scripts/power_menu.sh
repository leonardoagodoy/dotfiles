#!/bin/bash

#### Options ###
power_off=" Shutdown"
reboot="󰜉 Reboot"
suspend=" Suspend"
log_out="󰍃﫼 Log Out"

# Options passed to fuzzel
options="$power_off\n$reboot\n$suspend\n$log_out"
lines="$(echo "$options" | grep -oF '\n' | wc -l)"
chosen="$(echo -e "$options" | $rofi_command )"
case $chosen in
    "$power_off")
        systemctl poweroff
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$suspend")
        $lock && systemctl suspend
        ;;
    "$log_out")
        #swaymsg exit
        loginctl terminate-session "${XDG_SESSION_ID-}"
        ;;
esac
