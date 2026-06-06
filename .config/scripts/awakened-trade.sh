#!/usr/bin/env bash

APP_DIR="$HOME/Apps/Awakened-PoE-Trade" # ou onde você guarda o AppImage

APP=$(ls "$APP_DIR"/Awakened-PoE-Trade-*.AppImage 2>/dev/null | sort -V | tail -n1)

if [[ -z "$APP" ]]; then
  echo "AppImage não encontrado"
  exit 1
fi

exec env XDG_SESSION_TYPE=x11 "$APP"
