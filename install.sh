#!/usr/bin/env bash
# install.sh - instaluje ncd (nawigator katalogow) dla bash / zsh na Linux i macOS
#
# Uzycie:
#   chmod +x install.sh
#   ./install.sh
#
# Skrypt kopiuje ncd.sh do ~/.local/share/ncd/ncd.sh i dopisuje jego
# zaladowanie do ~/.bashrc oraz ~/.zshrc (jesli istnieja lub sa uzywanym shellem).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/ncd.sh"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ncd"
DEST="$INSTALL_DIR/ncd.sh"

if [[ ! -f "$SRC" ]]; then
    echo "Blad: nie znaleziono $SRC (uruchom install.sh z tego samego folderu co ncd.sh)" >&2
    exit 1
fi

mkdir -p "$INSTALL_DIR"
cp -f "$SRC" "$DEST"
chmod +x "$DEST"

LINE=". \"$DEST\""
MARKER="# ncd - nawigator katalogow (dodane przez install.sh)"

add_to_rc() {
    local rc="$1"
    [[ -f "$rc" ]] || touch "$rc"
    if grep -qF "$DEST" "$rc" 2>/dev/null; then
        echo "Juz skonfigurowano: $rc"
    else
        {
            echo ""
            echo "$MARKER"
            echo "$LINE"
        } >> "$rc"
        echo "Zaktualizowano: $rc"
    fi
}

updated_any=0

# bash
if [[ -f "$HOME/.bashrc" || "${SHELL:-}" == *bash* ]]; then
    add_to_rc "$HOME/.bashrc"
    updated_any=1
fi

# zsh
if [[ -n "${ZSH_VERSION:-}" || "${SHELL:-}" == *zsh* || -f "$HOME/.zshrc" ]]; then
    add_to_rc "$HOME/.zshrc"
    updated_any=1
fi

# macOS domyslnie uruchamia .bash_profile dla bash w terminalach logowania
if [[ "$(uname -s)" == "Darwin" && -f "$HOME/.bash_profile" ]]; then
    add_to_rc "$HOME/.bash_profile"
fi

if (( ! updated_any )); then
    echo "Nie wykryto pliku .bashrc/.zshrc - dopisz recznie do konfiguracji swojego shella:"
    echo "  $LINE"
fi

echo ""
echo "Zainstalowano ncd do: $DEST"
echo "Otworz nowy terminal (lub uruchom: source $DEST) i wpisz: ncd"
echo 'W programie nacisnij [S] -> "Edytuj kolory", aby dostosowac kazdy element (RGB lub hex), albo wybierz gotowy motyw w "Motyw".'
