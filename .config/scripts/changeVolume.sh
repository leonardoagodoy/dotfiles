#!/usr/bin/env bash

STEP=5
SINK="@DEFAULT_AUDIO_SINK@"
NOTIFY_ID=9991

get_volume() {
  wpctl get-volume "$SINK" | awk '{printf "%d%%", $2 * 100}'
}

is_muted() {
  wpctl get-volume "$SINK" | grep -q MUTED && echo yes || echo no
}

notify() {
  local volume=$(get_volume)
  local muted=$(is_muted)

  if [ "$muted" = "yes" ]; then
    notify-send \
      -h string:x-canonical-private-synchronous:volume \
      -h boolean:transient:true \
      -i audio-volume-muted \
      "Volume" "Muted"
  else
    notify-send \
      -h string:x-canonical-private-synchronous:volume \
      -h boolean:transient:true \
      -h int:value:${volume%\%} \
      -t 1000 \
      -i audio-volume-high \
      "Volume" "$volume"
  fi
}

case "$1" in
up)
  wpctl set-volume "$SINK" ${STEP}%+
  notify
  ;;
down)
  wpctl set-volume "$SINK" ${STEP}%-
  notify
  ;;
mute)
  wpctl set-mute "$SINK" toggle
  notify
  ;;
*)
  notify
  ;;
esac
