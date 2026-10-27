#!/usr/bin/env bash

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
PACKAGES=1
WALLPAPERS=1

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY=1 ;;
        --no-packages) PACKAGES=0 ;;
        --no-wallpapers) WALLPAPERS=0 ;;
        -h|--help)
            cat <<'USAGE'
install-arch.sh — sets up the shell on Arch Linux.

  ./install-arch.sh                 install packages and configs
  ./install-arch.sh --dry-run       only show what would happen
  ./install-arch.sh --no-packages   configs only, install nothing
  ./install-arch.sh --no-wallpapers skip wallpapers

For NixOS use install.sh from the same kit.
USAGE
            exit 0
            ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

. "$KIT/common.sh"

check_not_root
command -v pacman >/dev/null || die "this is not Arch — use install.sh for NixOS"

[ "$DRY" = 1 ] && warn "dry run: nothing is changed"

REPO_PACKAGES=(
    hyprland
    xdg-desktop-portal-hyprland
    hyprlock hypridle
    sddm
    pipewire wireplumber pipewire-pulse pipewire-alsa
    networkmanager
    upower power-profiles-daemon
    brightnessctl
    swaybg
    wl-clipboard
    grim slurp swappy
    wf-recorder
    kitty
    thunar
    jq inotify-tools
    glib2
    fastfetch
    polkit-gnome
    ttf-jetbrains-mono-nerd
    noto-fonts noto-fonts-emoji
    qt6-declarative qt6-wayland
)

AUR_PACKAGES=(
    quickshell
    matugen-bin
    hyprshot
)

aur_helper() {
    for helper in paru yay; do
        command -v "$helper" >/dev/null && { echo "$helper"; return; }
    done
}

install_packages() {
    say "installing ${#REPO_PACKAGES[@]} packages from the repositories"
    run sudo pacman -S --needed --noconfirm "${REPO_PACKAGES[@]}"

    local helper
    helper="$(aur_helper || true)"

    if [ -z "$helper" ]; then
        warn "no AUR helper found (paru or yay)."
        warn "quickshell, matugen and hyprshot live there — the bar will not start without them."
        warn "Install paru with:"
        cat <<'SNIP'

    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru && makepkg -si

SNIP
        warn "then run this script again"
        return
    fi

    say "installing ${#AUR_PACKAGES[@]} packages from the AUR via $helper"
    run "$helper" -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

enable_services() {
    say "enabling system services"

    for unit in NetworkManager sddm power-profiles-daemon; do
        run sudo systemctl enable "$unit"
    done
}

if [ "$PACKAGES" = 1 ]; then
    install_packages
    enable_services
else
    say "--no-packages: leaving packages alone"
fi

install_home_files

final_notes

cat <<'EOF'

Differences from NixOS worth knowing:

  * matugen comes from the AUR (matugen-bin). Version 4.2+ is required:
    older builds lack --prefer, so automatic wallpaper colors fail on
    images with several candidate colors. The bar survives that — it checks
    the version itself — but automatic colors will not work.
  * NVIDIA is not configured: on a laptop that usually means PRIME, and the
    rules differ per machine.
  * The us,ru layout with Win+Space switching is set in hyprland.lua, no
    separate X11 configuration is needed.
EOF
