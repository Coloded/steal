#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_URL_WAS_SET=0
if [[ -n "${REPO_RAW_URL+x}" ]]; then
  REPO_RAW_URL_WAS_SET=1
fi
REPO_RAW_URL="${REPO_RAW_URL:-https://raw.githubusercontent.com/Coloded/steal/main/check_cpu_steal}"
REPO_COMMIT_API_URL="${REPO_COMMIT_API_URL:-https://api.github.com/repos/Coloded/steal/commits/main}"
INSTALL_DIR_WAS_SET=0
if [[ -n "${INSTALL_DIR+x}" ]]; then
  INSTALL_DIR_WAS_SET=1
fi
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
BIN_NAME="${BIN_NAME:-check_cpu_steal}"
TARGET="${INSTALL_DIR}/${BIN_NAME}"
LOCAL_TARGET="${LOCAL_TARGET:-$(pwd)/${BIN_NAME}}"
SUDO_USED=0
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

read_answer() {
  local prompt_en="$1"
  local prompt_ru="$2"
  local answer=""

  if { exec 3</dev/tty; } 2>/dev/null; then
    if [[ "$lang" == "ru" ]]; then
      read -r -p "$prompt_ru" answer <&3 || answer=""
    else
      read -r -p "$prompt_en" answer <&3 || answer=""
    fi
    exec 3<&-
  elif [[ -t 0 ]]; then
    if [[ "$lang" == "ru" ]]; then
      read -r -p "$prompt_ru" answer || answer=""
    else
      read -r -p "$prompt_en" answer || answer=""
    fi
  else
    answer=""
  fi

  printf '%s\n' "$answer"
}

choose_install_scope() {
  local answer=""

  if (( INSTALL_DIR_WAS_SET )); then
    TARGET="${INSTALL_DIR}/${BIN_NAME}"
    return
  fi

  say "Install for all users? This installs to /usr/local/bin and may ask for sudo password." "Установить для всех пользователей? Это установка в /usr/local/bin и может спросить пароль sudo."
  say "Press Enter for personal install without password: $HOME/.local/bin" "Нажмите Enter для установки только себе без пароля: $HOME/.local/bin"
  answer="$(read_answer "Install for all users with sudo? [y/N]: " "Установить для всех пользователей с sudo? [y/N]: ")"

  case "$answer" in
    y|Y|yes|YES|Yes|д|Д|да|Да|ДА)
      INSTALL_DIR="/usr/local/bin"
      TARGET="${INSTALL_DIR}/${BIN_NAME}"
      say "Selected: all users. macOS/Linux may ask for your password." "Выбрано: для всех пользователей. macOS/Linux может спросить пароль."
      ;;
    *)
      INSTALL_DIR="$HOME/.local/bin"
      TARGET="${INSTALL_DIR}/${BIN_NAME}"
      say "Selected: personal install, no sudo." "Выбрано: установка только себе, без sudo."
      ;;
  esac
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

with_cache_buster() {
  local url="$1"
  case "$url" in
    http://*|https://*)
      printf '%s?ts=%s\n' "$url" "$(date +%s)"
      ;;
    *)
      printf '%s\n' "$url"
      ;;
  esac
}

resolve_install_script_url() {
  local tmp_meta sha

  if (( REPO_RAW_URL_WAS_SET )); then
    printf '%s\n' "$REPO_RAW_URL"
    return
  fi

  tmp_meta="$(mktemp)"
  if download "$(with_cache_buster "$REPO_COMMIT_API_URL")" "$tmp_meta"; then
    sha="$(awk -F\" '/"sha":/ { print $4; exit }' "$tmp_meta")"
  else
    sha=""
  fi
  rm -f "$tmp_meta"

  if [[ -n "$sha" ]]; then
    printf 'https://raw.githubusercontent.com/Coloded/steal/%s/check_cpu_steal\n' "$sha"
  else
    printf '%s\n' "$REPO_RAW_URL"
  fi
}

install_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -d "$INSTALL_DIR" ]]; then
    if ! mkdir -p "$INSTALL_DIR" 2>/dev/null; then
      if command -v sudo >/dev/null 2>&1; then
        say "sudo is needed to create install directory: $INSTALL_DIR" "Нужен sudo, чтобы создать каталог установки: $INSTALL_DIR"
        SUDO_USED=1
        sudo mkdir -p "$INSTALL_DIR"
      else
        say "Could not create install directory and sudo was not found: $INSTALL_DIR" "Не удалось создать каталог установки и sudo не найден: $INSTALL_DIR" >&2
        exit 1
      fi
    fi
  fi

  if [[ -w "$INSTALL_DIR" ]]; then
    install -m 0755 "$src" "$dst"
  else
    if command -v sudo >/dev/null 2>&1; then
      say "sudo is needed to install into: $dst" "Нужен sudo, чтобы установить в: $dst"
      SUDO_USED=1
      sudo install -m 0755 "$src" "$dst"
    else
      say "No write permission and sudo was not found: $INSTALL_DIR" "Нет прав на запись и sudo не найден: $INSTALL_DIR" >&2
      exit 1
    fi
  fi
}

path_contains_install_dir() {
  case ":$PATH:" in
    *":$INSTALL_DIR:"*) return 0 ;;
    *) return 1 ;;
  esac
}

print_path_hint() {
  if path_contains_install_dir; then
    return
  fi

  say "Note: $INSTALL_DIR is not in PATH yet." "Важно: $INSTALL_DIR пока не в PATH."
  say "Add this line to your shell profile, then reopen the terminal:" "Добавьте эту строку в профиль shell, потом откройте терминал заново:"
  if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
  else
    echo "export PATH=\"$INSTALL_DIR:\$PATH\""
  fi
}

print_shadow_hint() {
  local resolved=""

  if command -v "$BIN_NAME" >/dev/null 2>&1; then
    resolved="$(command -v "$BIN_NAME")"
  fi

  if [[ -n "$resolved" && "$resolved" != "$TARGET" ]]; then
    say "Note: your shell currently finds another copy first: $resolved" "Важно: shell сейчас первым находит другую копию: $resolved"
    say "Put $INSTALL_DIR earlier in PATH or remove the older copy." "Поставьте $INSTALL_DIR раньше в PATH или удалите старую копию."
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

choose_install_scope

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [[ -n "$SCRIPT_DIR" && -f "${SCRIPT_DIR}/check_cpu_steal" ]]; then
  cp "${SCRIPT_DIR}/check_cpu_steal" "$tmp"
else
  download "$(with_cache_buster "$(resolve_install_script_url)")" "$tmp"
fi

install_file "$tmp" "$TARGET"

say "Installed: $TARGET" "Установлено: $TARGET"
if (( SUDO_USED == 0 )); then
  say "No sudo was used." "Sudo не использовался."
fi
print_path_hint
print_shadow_hint
say "Check:" "Проверка:"
if [[ "$lang" == "ru" ]]; then
  "$TARGET" -ru --help
else
  "$TARGET" --help
fi
