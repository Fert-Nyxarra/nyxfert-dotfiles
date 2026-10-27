#!/usr/bin/env bash

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
REBUILD=ask
WALLPAPERS=1
HOME_ONLY=0

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY=1 ;;
        --rebuild) REBUILD=yes ;;
        --no-rebuild) REBUILD=no ;;
        --no-wallpapers) WALLPAPERS=0 ;;
        --home-only) HOME_ONLY=1; REBUILD=no ;;
        -h|--help)
            cat <<'USAGE'
install.sh — разворачивает окружение на NixOS.

  ./install.sh                 разложить всё и спросить про пересборку
  ./install.sh --rebuild       сразу пересобрать систему в конце
  ./install.sh --dry-run       только показать, что будет сделано
  ./install.sh --no-wallpapers не копировать обои
  ./install.sh --home-only     не трогать /etc/nixos, только ~

Для Arch есть отдельный install-arch.sh в том же наборе.
USAGE
            exit 0
            ;;
        *) echo "неизвестный ключ: $1" >&2; exit 2 ;;
    esac
    shift
done

. "$KIT/common.sh"

check_not_root
[ -e /etc/NIXOS ] || [ -d /nix/store ] || die "это не NixOS — для Arch есть install-arch.sh"

HOST="$(hostname)"
[ "$DRY" = 1 ] && warn "холостой прогон: ничего не меняется"

install_home_files

if [ "$HOME_ONLY" = 1 ]; then
    say "ключ --home-only: /etc/nixos не трогаю"
else
    [ -f /etc/nixos/configuration.nix ] || die "нет /etc/nixos/configuration.nix — нечего дополнять"

    say "ставлю модуль /etc/nixos/desktop.nix"
    tmp="$(mktemp)"
    sed "s|@USER@|$DST_USER|g" "$KIT/nix/desktop.nix" > "$tmp"
    run sudo cp "$tmp" /etc/nixos/desktop.nix
    rm -f "$tmp"

    if grep -q "./desktop.nix" /etc/nixos/configuration.nix; then
        say "в configuration.nix модуль уже подключён"
    else
        say "подключаю модуль в imports configuration.nix"
        run sudo cp /etc/nixos/configuration.nix "/etc/nixos/configuration.nix.bak-$STAMP"
        run sudo sed -i '0,/\.\/hardware-configuration\.nix/s||./hardware-configuration.nix\n      ./desktop.nix|' \
            /etc/nixos/configuration.nix
        if [ "$DRY" = 0 ] && ! grep -q "./desktop.nix" /etc/nixos/configuration.nix 2>/dev/null; then
            warn "не вышло вписать автоматически — добавь ./desktop.nix в imports сам"
        fi
    fi

    if [ -f /etc/nixos/flake.nix ]; then
        if grep -q "matugen" /etc/nixos/flake.nix; then
            say "вход matugen во флейке уже есть"
        else
            warn "во flake.nix нет входа matugen — добавь руками:"
            cat <<'SNIP'

    inputs.matugen.url = "github:InioX/matugen";

  и прокинь inputs в модули:

    nixosConfigurations.<хост> = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      ...
    };

SNIP
        fi
    else
        warn "флейка нет: matugen возьмётся из nixpkgs (4.0). Панель это переживёт —"
        warn "она сама спрашивает версию, — но режим «авто» в выборе обоев работать не будет."
    fi

    if [ -d /sys/bus/pci/drivers/nvidia ] || lspci 2>/dev/null | grep -qi nvidia; then
        warn "замечена NVIDIA. Модуль её НЕ настраивает: на ноутбуке это обычно"
        warn "PRIME с переключением, и правила у каждой машины свои."
    fi
fi

if [ -f /etc/nixos/flake.nix ]; then
    CMD="sudo nixos-rebuild switch --flake /etc/nixos#$HOST"
else
    CMD="sudo nixos-rebuild switch"
fi

if [ "$HOME_ONLY" = 0 ]; then
    case "$REBUILD" in
        ask)

            if [ "$DRY" = 1 ] || [ ! -t 0 ]; then
                say "пересборка не запускалась: $CMD"
                answer=n
            else
                printf '\n'
                read -r -p "Пересобрать систему сейчас? [y/N] " answer
            fi
            case "$answer" in
                y|Y|д|Д) run bash -c "$CMD" ;;
                *) say "хорошо, потом сам: $CMD" ;;
            esac
            ;;
        yes) run bash -c "$CMD" ;;
        no)  say "пересборка пропущена: $CMD" ;;
    esac
fi

final_notes
echo
echo "Пересобрать систему, если ещё не: $CMD"
