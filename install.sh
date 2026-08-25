#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/Coloded/steal/main/check_cpu_steal}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
BIN_NAME="${BIN_NAME:-check_cpu_steal}"
TARGET="${INSTALL_DIR}/${BIN_NAME}"
LOCAL_TARGET="${LOCAL_TARGET:-$(pwd)/${BIN_NAME}}"
lang="en"
SCRIPT_PATH="${BASH_SOURCE[0]:-}"
SCRIPT_DIR=""
if [[ -n "$SCRIPT_PATH" && -f "$SCRIPT_PATH" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" >/dev/null 2>&1 && pwd)"
fi

for arg in "$@"; do
  case "$arg" in
    -ru|--ru)
      lang="ru"
      break
      ;;
  esac
done

while [[ $# -gt 0 ]]; do
  case "$1" in
    -ru|--ru)
      lang="ru"
      shift
      ;;
    -h|--help)
      if [[ "$lang" == "ru" ]]; then
        echo "Использование: install.sh [-ru]"
      else
        echo "Usage: install.sh [-ru]"
      fi
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 2
      ;;
  esac
done

say() {
  local en="$1"
  local ru="$2"
  if [[ "$lang" == "ru" ]]; then
    echo "$ru"
  else
    echo "$en"
  fi
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    say "Missing command: $1" "Не найдена команда: $1" >&2
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
    say "curl or wget is required for download." "Нужен curl или wget для скачивания." >&2
    exit 1
  fi
}

install_local_file() {
  local src="$1"

  install -m 0755 "$src" "$LOCAL_TARGET"
  TARGET="$LOCAL_TARGET"
  say "Sudo was not used." "Sudo не использовался."
  say "The script was saved as a regular file: $TARGET" "Скрипт сохранен как обычный файл: $TARGET"
  say "Run it with:" "Запуск:"
  echo "$TARGET root@server"
}

ask_sudo_or_local() {
  local reason="$1"
  local answer=""

  echo "$reason"
  say "You can enter your sudo password and install the command globally: $TARGET" "Можно ввести пароль sudo и установить команду глобально: $TARGET"
  say "Or skip sudo: the script will be saved as a regular file: $LOCAL_TARGET" "Можно не вводить пароль: тогда скрипт просто сохранится как файл: $LOCAL_TARGET"
  if { exec 3</dev/tty; } 2>/dev/null; then
    if [[ "$lang" == "ru" ]]; then
      read -r -p "Использовать sudo для глобальной установки? [y/N]: " answer <&3 || answer=""
    else
      read -r -p "Use sudo for global install? [y/N]: " answer <&3 || answer=""
    fi
    exec 3<&-
  elif [[ -t 0 ]]; then
    if [[ "$lang" == "ru" ]]; then
      read -r -p "Использовать sudo для глобальной установки? [y/N]: " answer || answer=""
    else
      read -r -p "Use sudo for global install? [y/N]: " answer || answer=""
    fi
  else
    answer=""
  fi

  case "$answer" in
    y|Y|yes|YES|Yes|д|Д|да|Да|ДА)
      say "macOS/Linux will now ask for your user password." "Сейчас macOS/Linux спросит пароль вашего пользователя."
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
      if ask_sudo_or_local "$(say "sudo is needed to create install directory: $INSTALL_DIR" "Нужен sudo, чтобы создать каталог установки: $INSTALL_DIR")"; then
        sudo mkdir -p "$INSTALL_DIR"
      else
        install_local_file "$src"
        return
      fi
    else
      say "Could not create $INSTALL_DIR and sudo was not found." "Не удалось создать $INSTALL_DIR и sudo не найден." >&2
      install_local_file "$src"
      return
    fi
  fi

  if [[ -w "$INSTALL_DIR" ]]; then
    install -m 0755 "$src" "$dst"
  elif command -v sudo >/dev/null 2>&1; then
    if ask_sudo_or_local "$(say "sudo is needed to install the command into the system directory: $dst" "Нужен sudo, чтобы установить команду в системный каталог: $dst")"; then
      sudo install -m 0755 "$src" "$dst"
    else
      install_local_file "$src"
      return
    fi
  else
    say "No write permission for $INSTALL_DIR and sudo was not found." "Нет прав на запись в $INSTALL_DIR и sudo не найден." >&2
    install_local_file "$src"
    return
  fi
}

case "$(uname -s)" in
  Linux|Darwin)
    ;;
  *)
    say "Supported systems: Debian/Ubuntu/Linux and macOS." "Поддерживаются Debian/Ubuntu/Linux и macOS." >&2
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

say "Installed: $TARGET" "Установлено: $TARGET"
say "Check:" "Проверка:"
if [[ "$lang" == "ru" ]]; then
  "$TARGET" -ru --help
else
  "$TARGET" --help
fi
