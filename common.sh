#!/usr/bin/env bash

say()  { printf '\033[1;36m==\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [ "${DRY:-0}" = 1 ]; then printf '   \033[2m%s\033[0m\n' "$*"; else "$@"; fi; }

backup() {
    local target="$1"
    [ -e "$target" ] || return 0
    say "keeping the old $target as $target.bak-$STAMP"
    run mv "$target" "$target.bak-$STAMP"
}

check_not_root() {
    [ "$(id -u)" != 0 ] || die "run as your own user, not root — the script calls sudo when it needs to"
}

install_home_files() {
    SRC_USER="$(cat "$KIT/MANIFEST_USER" 2>/dev/null || echo nyxfert)"
    DST_USER="$(id -un)"

    say "user: $SRC_USER (from) -> $DST_USER (to)"

    run mkdir -p "$HOME/.config" "$HOME/bin" "$HOME/.local/state/quickshell"

    say "installing configs"
    for dir in quickshell hypr matugen kitty fastfetch nixos-setup; do
        [ -d "$KIT/home/.config/$dir" ] || continue
        backup "$HOME/.config/$dir"
        run cp -r "$KIT/home/.config/$dir" "$HOME/.config/$dir"
    done

    if [ -d "$KIT/home/bin" ]; then
        for f in "$KIT"/home/bin/*; do
            [ -e "$f" ] || continue
            run cp "$f" "$HOME/bin/$(basename "$f")"
            run chmod +x "$HOME/bin/$(basename "$f")"
        done
    fi

    if [ -f "$KIT/home/state/wallpapers.json" ]; then
        run cp "$KIT/home/state/wallpapers.json" "$HOME/.local/state/quickshell/wallpapers.json"
    fi

    if [ "${WALLPAPERS:-1}" = 1 ] && [ -d "$KIT/home/Wallpapers" ]; then
        say "copying wallpapers to ~/Wallpapers"
        run mkdir -p "$HOME/Wallpapers"
        run cp -r "$KIT"/home/Wallpapers/. "$HOME/Wallpapers/"
    else
        run mkdir -p "$HOME/Wallpapers"
        warn "no wallpapers copied — put some in ~/Wallpapers or the picker stays empty"
    fi

    if [ "$SRC_USER" != "$DST_USER" ] && [ "${DRY:-0}" = 0 ]; then
        say "rewriting paths /home/$SRC_USER -> $HOME"
        grep -rl "/home/$SRC_USER" "$HOME/.config/quickshell" "$HOME/.config/hypr" \
            "$HOME/.config/matugen" "$HOME/bin" 2>/dev/null \
            | while read -r f; do
                sed -i "s|/home/$SRC_USER|$HOME|g" "$f"
            done
    fi

    if [ "${DRY:-0}" = 0 ]; then
        want="$(grep -o 'swaybg -i [^"]*' "$HOME/.config/hypr/hyprland.lua" 2>/dev/null | head -1 | sed 's|swaybg -i ||')"
        if [ -n "$want" ] && [ ! -f "$want" ]; then
            first="$(find "$HOME/Wallpapers" -maxdepth 1 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -1)"
            if [ -n "$first" ]; then
                warn "$want is missing, using $first instead"
                sed -i "s|hl.exec_cmd(\"swaybg -i [^\"]*\")|hl.exec_cmd(\"swaybg -i $first\")|" \
                    "$HOME/.config/hypr/hyprland.lua"
            fi
        fi
    fi
}

final_notes() {
    cat <<EOF

Done. Next steps:

  1. Log out and log into Hyprland (SDDM lists it).
  2. Super + W picks a wallpaper: that sets both the palette and the
     autostart line.
  3. If the bar shows empty boxes instead of icons, the font did not load:
     check fc-list | grep -i jetbrains and log in again.

Check the bar with: qs log   (QML errors show up there)
Keys: Super — launcher, Super+W — wallpapers, Super+V — clipboard,
Ctrl+Super+S — settings, Super+F — fullscreen, Super+M — log out.

Applications (browser, messengers, media players) are NOT installed — only
what the shell itself needs.
EOF
}
