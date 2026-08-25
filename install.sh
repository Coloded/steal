#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/Coloded/steal/main/check_cpu_steal}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
BIN_NAME="${BIN_NAME:-check_cpu_steal}"
TARGET="${INSTALL_DIR}/${BIN_NAME}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Не найдена команда: $1" >&2
    exit 1
  fi
}

download() {
  local url="$1"
  local dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo "Нужен curl или wget для скачивания." >&2
    exit 1
  fi
}

install_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -d "$INSTALL_DIR" ]]; then
    if mkdir -p "$INSTALL_DIR" 2>/dev/null; then
      :
    elif command -v sudo >/dev/null 2>&1; then
      sudo mkdir -p "$INSTALL_DIR"
    else
      echo "Не удалось создать $INSTALL_DIR и sudo не найден." >&2
      exit 1
    fi
  fi

  if [[ -w "$INSTALL_DIR" ]]; then
    install -m 0755 "$src" "$dst"
  elif command -v sudo >/dev/null 2>&1; then
    sudo install -m 0755 "$src" "$dst"
  else
    echo "Нет прав на запись в $INSTALL_DIR и sudo не найден." >&2
    echo "Можно указать другой каталог: INSTALL_DIR=\$HOME/.local/bin ./install.sh" >&2
    exit 1
  fi
}

case "$(uname -s)" in
  Linux|Darwin)
    ;;
  *)
    echo "Поддерживаются Debian/Ubuntu/Linux и macOS." >&2
    exit 1
    ;;
esac

need_cmd install
need_cmd ssh
need_cmd awk

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [[ -f "./check_cpu_steal" ]]; then
  cp "./check_cpu_steal" "$tmp"
else
  download "$REPO_RAW_URL" "$tmp"
fi

install_file "$tmp" "$TARGET"

echo "Установлено: $TARGET"
echo "Проверка:"
"$TARGET" --help
