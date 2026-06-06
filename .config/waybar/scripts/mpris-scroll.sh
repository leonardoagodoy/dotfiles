#!/bin/bash

status=$(playerctl status 2>/dev/null)

# invisível quando não tem mídia ou está stopped
if [ -z "$status" ] || [ "$status" = "Stopped" ]; then
  echo ""
  exit
fi

artist=$(playerctl metadata artist 2>/dev/null)
title=$(playerctl metadata title 2>/dev/null)

text="$artist - $title"

width=40
scroll="$text   •   $text   •   $text"
offset=$(($(date +%s) % ${#text}))

case "$status" in
Playing)
  icon=""
  class="playing"
  ;;
Paused)
  icon=""
  class="paused"
  ;;
esac

echo "{\"text\":\"$icon ${scroll:$offset:$width}\",\"class\":\"$class\"}"
