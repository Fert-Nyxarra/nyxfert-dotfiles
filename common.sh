#!/usr/bin/env bash
# common.sh — то, что одинаково для любой системы: раскладывание конфигов,
# обоев и скриптов по домашнему каталогу.
#
# Сам по себе не запускается, его подключают install.sh (NixOS) и
# install-arch.sh (Arch).

say()  { printf '\033[1;36m==\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [ "${DRY:-0}" = 1 ]; then printf '   \033[2m%s\033[0m\n' "$*"; else "$@"; fi; }

backup() {
    local target="$1"
    [ -e "$target" ] || return 0
    say "сохраняю прежний $target -> $target.bak-$STAMP"
    run mv "$target" "$target.bak-$STAMP"
}

check_not_root() {
    [ "$(id -u)" != 0 ] || die "запускай от своего пользователя, а не от root — скрипт сам позовёт sudo"
}

# раскладывает конфиги, скрипты, обои и закреплённые цвета
install_home_files() {
    SRC_USER="$(cat "$KIT/MANIFEST_USER" 2>/dev/null || echo nyxfert)"
    DST_USER="$(id -un)"

    say "пользователь: $SRC_USER (откуда) -> $DST_USER (сюда)"

    run mkdir -p "$HOME/.config" "$HOME/bin" "$HOME/.local/state/quickshell"

    say "раскладываю конфиги"
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

    # закреплённые за обоями цвета — не обязательны, но без них выбор обоев
    # начнётся с чистого листа
    if [ -f "$KIT/home/state/wallpapers.json" ]; then
        run cp "$KIT/home/state/wallpapers.json" "$HOME/.local/state/quickshell/wallpapers.json"
    fi

    if [ "${WALLPAPERS:-1}" = 1 ] && [ -d "$KIT/home/Wallpapers" ]; then
        say "копирую обои в ~/Wallpapers"
        run mkdir -p "$HOME/Wallpapers"
        run cp -r "$KIT"/home/Wallpapers/. "$HOME/Wallpapers/"
    else
        run mkdir -p "$HOME/Wallpapers"
        warn "обои не копировались — положи что-нибудь в ~/Wallpapers, иначе селектор будет пуст"
    fi

    # В конфигах абсолютный путь ровно один — строка автозапуска swaybg в
    # hyprland.lua. Остальное берёт $HOME само.
    if [ "$SRC_USER" != "$DST_USER" ] && [ "${DRY:-0}" = 0 ]; then
        say "переписываю пути /home/$SRC_USER -> $HOME"
        grep -rl "/home/$SRC_USER" "$HOME/.config/quickshell" "$HOME/.config/hypr" \
            "$HOME/.config/matugen" "$HOME/bin" 2>/dev/null \
            | while read -r f; do
                sed -i "s|/home/$SRC_USER|$HOME|g" "$f"
            done
    fi

    # обои из автозапуска могли не приехать — подставляем первую попавшуюся
    if [ "${DRY:-0}" = 0 ]; then
        want="$(grep -o 'swaybg -i [^"]*' "$HOME/.config/hypr/hyprland.lua" 2>/dev/null | head -1 | sed 's|swaybg -i ||')"
        if [ -n "$want" ] && [ ! -f "$want" ]; then
            first="$(find "$HOME/Wallpapers" -maxdepth 1 -type f \
                \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort | head -1)"
            if [ -n "$first" ]; then
                warn "обоев $want нет, ставлю $first"
                sed -i "s|hl.exec_cmd(\"swaybg -i [^\"]*\")|hl.exec_cmd(\"swaybg -i $first\")|" \
                    "$HOME/.config/hypr/hyprland.lua"
            fi
        fi
    fi
}

final_notes() {
    cat <<EOF

Готово. Дальше:

  1. Выйти из сессии и войти в Hyprland (SDDM предложит его в списке).
  2. Super + W — выбрать обои: это задаёт и палитру, и строку автозапуска.
  3. Если значки в панели — пустые прямоугольники, шрифт не подхватился:
     fc-list | grep -i jetbrains  и перелогиниться.

Проверить панель: qs log   (ошибки QML видны там же)
Горячие клавиши: Super — лаунчер, Super+W — обои, Super+V — буфер обмена,
Ctrl+Super+S — настройки, Super+F — полный экран, Super+M — выйти из сессии.

Прикладной софт (браузер, мессенджеры, плеер) набор НЕ ставит — только то,
без чего не работает сама оболочка.
EOF
}
