#!/usr/bin/env bash

set -euo pipefail

# =========================
# CONFIG
# =========================
CACHE_DIR="${HOME}/.cache/neko"
mkdir -p "$CACHE_DIR"

RATING="safe"
VIEWER="feh"
STREAM=false

# =========================
# HELP
# =========================
usage() {
  cat <<EOF
Uso: $0 [opções]

Opções:
  -r, --rating <safe|suggestive|explicit>   Define o rating (default: safe)
  -v, --viewer <programa>                  Força viewer (swappy, imv, feh...)
  -s, --stream                             Não salva arquivo (stream direto)
  -h, --help                               Mostra ajuda

Exemplos:
  $0 --rating safe
  $0 -r explicit
  $0 -r suggestive --viewer imv
  $0 -r safe --stream
EOF
}

# =========================
# PARSE FLAGS
# =========================
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--rating)
      RATING="$2"
      shift 2
      ;;
    -v|--viewer)
      VIEWER="$2"
      shift 2
      ;;
    -s|--stream)
      STREAM=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento inválido: $1"
      usage
      exit 1
      ;;
  esac
done

# =========================
# DEPENDÊNCIAS
# =========================
for cmd in curl jq; do
  command -v "$cmd" >/dev/null || {
    echo "Erro: $cmd não instalado"
    exit 1
  }
done

# =========================
# API REQUEST
# =========================
API_URL="https://api.nekosapi.com/v4/images/random?rating=${RATING}"

JSON=$(curl -s "$API_URL")
IMG_URL=$(echo "$JSON" | jq -r '.[0].url // empty')

if [[ -z "$IMG_URL" ]]; then
  echo "Erro: resposta inválida da API"
  echo "$JSON" | jq .
  exit 1
fi

# =========================
# ESCOLHER VIEWER
# =========================
choose_viewer() {
  if [[ -n "$VIEWER" ]]; then
    echo "$VIEWER"
    return
  fi

  for v in swappy imv feh kitty; do
    if command -v "$v" >/dev/null; then
      echo "$v"
      return
    fi
  done

  echo ""
}

VIEWER_BIN=$(choose_viewer)

if [[ -z "$VIEWER_BIN" ]]; then
  echo "Nenhum visualizador encontrado (swappy, imv, feh, kitty)"
  exit 1
fi

# =========================
# EXECUÇÃO
# =========================
if $STREAM; then
  case "$VIEWER_BIN" in
    imv)
      curl -s "$IMG_URL" | imv -
      ;;
    kitty)
      curl -s "$IMG_URL" | kitty +kitten icat
      ;;
    *)
      echo "Viewer $VIEWER_BIN não suporta stream, usando download..."
      STREAM=false
      ;;
  esac
fi

if ! $STREAM; then
  FILE_NAME="${CACHE_DIR}/neko_$(date +%s).jpg"

  curl -s "$IMG_URL" -o "$FILE_NAME"

  case "$VIEWER_BIN" in
    swappy)
      swappy -f "$FILE_NAME"
      ;;
    imv)
      imv "$FILE_NAME"
      ;;
    feh)
      feh "$FILE_NAME"
      ;;
    kitty)
      kitty +kitten icat "$FILE_NAME"
      ;;
    *)
      "$VIEWER_BIN" "$FILE_NAME"
      ;;
  esac

# remove depois de usar
rm -f "$FILE_NAME"
fi