#!/usr/bin/env bash

if systemctl --user restart mako.service; then
  notify-send "Mako" "Reloaded!"
else
  notify-send "Mako" "Failed!"
fi
