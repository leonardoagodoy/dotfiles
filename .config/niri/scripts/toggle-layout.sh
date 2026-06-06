#!/bin/bash

current=$(niri msg keyboard-layouts | awk '/\*/ {print $2}')

niri msg action switch-layout next

if [[ "$current" == "0" ]]; then
  notify-send -t 800 "  alt"
else
  notify-send -t 800 "  us"
fi
