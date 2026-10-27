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
install.sh — sets up the shell on NixOS.

  ./install.sh                 install everything, then ask about a rebuild
  ./install.sh --rebuild       rebuild the system at the end
  ./install.sh --dry-run       only show what would happen
  ./install.sh --no-wallpapers skip wallpapers
  ./install.sh --home-only     leave /etc/nixos alone, touch ~ only

For Arch use install-arch.sh from the same kit.
USAGE
            exit 0
            ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

. "$KIT/common.sh"

check_not_root
[ -e /etc/NIXOS ] || [ -d /nix/store ] || die "this is not NixOS — use install-arch.sh for Arch"

HOST="$(hostname)"
[ "$DRY" = 1 ] && warn "dry run: nothing is changed"

install_home_files

if [ "$HOME_ONLY" = 1 ]; then
    say "--home-only: leaving /etc/nixos alone"
else
    [ -f /etc/nixos/configuration.nix ] || die "no /etc/nixos/configuration.nix to extend"

    say "installing /etc/nixos/desktop.nix"
    tmp="$(mktemp)"
    sed "s|@USER@|$DST_USER|g" "$KIT/nix/desktop.nix" > "$tmp"
    run sudo cp "$tmp" /etc/nixos/desktop.nix
    rm -f "$tmp"

    if grep -q "./desktop.nix" /etc/nixos/configuration.nix; then
        say "the module is already imported in configuration.nix"
    else
        say "adding the module to imports in configuration.nix"
        run sudo cp /etc/nixos/configuration.nix "/etc/nixos/configuration.nix.bak-$STAMP"
        run sudo sed -i '0,/\.\/hardware-configuration\.nix/s||./hardware-configuration.nix\n      ./desktop.nix|' \
            /etc/nixos/configuration.nix
        if [ "$DRY" = 0 ] && ! grep -q "./desktop.nix" /etc/nixos/configuration.nix 2>/dev/null; then
            warn "could not edit it automatically — add ./desktop.nix to imports yourself"
        fi
    fi

    if [ -f /etc/nixos/flake.nix ]; then
        if grep -q "matugen" /etc/nixos/flake.nix; then
            say "the flake already has a matugen input"
        else
            warn "flake.nix has no matugen input — add it by hand:"
            cat <<'SNIP'

    inputs.matugen.url = "github:InioX/matugen";

  and pass inputs down to the modules:

    nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      ...
    };

SNIP
        fi
    else
        warn "no flake: matugen comes from nixpkgs (4.0). The bar survives that —"
        warn "it checks the version itself — but automatic wallpaper colors will not work."
    fi

    if [ -d /sys/bus/pci/drivers/nvidia ] || lspci 2>/dev/null | grep -qi nvidia; then
        warn "NVIDIA detected. The module does NOT configure it: on a laptop that usually"
        warn "means PRIME offloading, and the rules differ per machine."
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
                say "no rebuild was started: $CMD"
                answer=n
            else
                printf '\n'
                read -r -p "Rebuild the system now? [y/N] " answer
            fi
            case "$answer" in
                y|Y) run bash -c "$CMD" ;;
                *) say "fine, run it later: $CMD" ;;
            esac
            ;;
        yes) run bash -c "$CMD" ;;
        no)  say "rebuild skipped: $CMD" ;;
    esac
fi

final_notes
echo
echo "Rebuild the system if you have not yet: $CMD"
