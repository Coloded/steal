#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/Coloded/steal/main/check_cpu_steal}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
BIN_NAME="${BIN_NAME:-check_cpu_steal}"
TARGET="${INSTALL_DIR}/${BIN_NAME}"
LOCAL_TARGET="${LOCAL_TARGET:-$(pwd)/${BIN_NAME}}"
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" >/dev/null 2>&1 && pwd)"
fi

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

install_local_file() {
  local src="$1"

  install -m 0755 "$src" "$LOCAL_TARGET"
  TARGET="$LOCAL_TARGET"
  echo "Sudo не использовался."
  echo "Скрипт сохранен как обычный файл: $TARGET"
  echo "Запуск:"
  echo "$TARGET root@server"
}

ask_sudo_or_local() {
  local reason="$1"
  local answer=""

  echo "$reason"
  echo "Можно ввести пароль sudo и установить команду глобально: $TARGET"
  echo "Можно не вводить пароль: тогда скрипт просто сохранится как файл: $LOCAL_TARGET"
  if { exec 3</dev/tty; } 2>/dev/null; then
    read -r -p "Использовать sudo для глобальной установки? [y/N]: " answer <&3 || answer=""
    exec 3<&-
  elif [[ -t 0 ]]; then
    read -r -p "Использовать sudo для глобальной установки? [y/N]: " answer || answer=""
  else
    answer=""
  fi

  case "$answer" in
    y|Y|yes|YES|Yes|д|Д|да|Да|ДА)
      echo "Сейчас macOS/Linux спросит пароль вашего пользователя."
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

install_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -d "$INSTALL_DIR" ]]; then
    if mkdir -p "$INSTALL_DIR" 2>/dev/null; then
      :
    elif command -v sudo >/dev/null 2>&1; then
      if ask_sudo_or_local "Нужен sudo, чтобы создать каталог установки: $INSTALL_DIR"; then
        sudo mkdir -p "$INSTALL_DIR"
      else
        install_local_file "$src"
        return
      fi
    else
      echo "Не удалось создать $INSTALL_DIR и sudo не найден." >&2
      install_local_file "$src"
      return
    fi
  fi

  if [[ -w "$INSTALL_DIR" ]]; then
    install -m 0755 "$src" "$dst"
  elif command -v sudo >/dev/null 2>&1; then
    if ask_sudo_or_local "Нужен sudo, чтобы установить команду в системный каталог: $dst"; then
      sudo install -m 0755 "$src" "$dst"
    else
      install_local_file "$src"
      return
    fi
  else
    echo "Нет прав на запись в $INSTALL_DIR и sudo не найден." >&2
    install_local_file "$src"
    return
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

if [[ -n "$SCRIPT_DIR" && -f "${SCRIPT_DIR}/check_cpu_steal" ]]; then
  cp "${SCRIPT_DIR}/check_cpu_steal" "$tmp"
else
  download "$REPO_RAW_URL" "$tmp"
fi

install_file "$tmp" "$TARGET"

echo "Установлено: $TARGET"
echo "Проверка:"
"$TARGET" --help
