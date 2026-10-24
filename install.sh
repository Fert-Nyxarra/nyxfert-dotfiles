#!/usr/bin/env bash
# install.sh — разворачивает рабочее окружение на чистой NixOS.
#
# Ставит систему (Hyprland, панель, звук, шрифты) и раскладывает конфиги.
# Ничего не делает молча: каждый шаг печатается, чужие файлы сохраняются
# рядом с меткой времени, пересборку системы запрашивает отдельно.
#
#   ./install.sh                 разложить всё и спросить про пересборку
#   ./install.sh --rebuild       сразу пересобрать систему в конце
#   ./install.sh --dry-run       только показать, что будет сделано
#   ./install.sh --no-wallpapers не копировать обои
#   ./install.sh --home-only     не трогать /etc/nixos, только ~

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
        -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "неизвестный ключ: $1" >&2; exit 2 ;;
    esac
    shift
done

say()  { printf '\033[1;36m==\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }
run()  { if [ "$DRY" = 1 ]; then printf '   \033[2m%s\033[0m\n' "$*"; else "$@"; fi; }

#### проверки ################################################################

[ "$(id -u)" != 0 ] || die "запускай от своего пользователя, а не от root — скрипт сам позовёт sudo"
[ -e /etc/NIXOS ] || [ -d /nix/store ] || die "это не NixOS: скрипт рассчитан только на неё"

SRC_USER="$(cat "$KIT/MANIFEST_USER" 2>/dev/null || echo nyxfert)"
DST_USER="$(id -un)"
HOST="$(hostname)"

say "пользователь: $SRC_USER (откуда) -> $DST_USER (сюда), машина: $HOST"
[ "$DRY" = 1 ] && warn "холостой прогон: ничего не меняется"

#### 1. конфиги в ~/.config ##################################################

backup() {
    local target="$1"
    [ -e "$target" ] || return 0
    say "сохраняю прежний $target -> $target.bak-$STAMP"
    run mv "$target" "$target.bak-$STAMP"
}

say "раскладываю конфиги"
run mkdir -p "$HOME/.config" "$HOME/bin" "$HOME/.local/state/quickshell"

for dir in quickshell hypr matugen kitty fastfetch; do
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

if [ "$WALLPAPERS" = 1 ] && [ -d "$KIT/home/Wallpapers" ]; then
    say "копирую обои в ~/Wallpapers"
    run mkdir -p "$HOME/Wallpapers"
    run cp -r "$KIT"/home/Wallpapers/. "$HOME/Wallpapers/"
else
    run mkdir -p "$HOME/Wallpapers"
    warn "обои не копировались — положи что-нибудь в ~/Wallpapers, иначе селектор будет пуст"
fi

#### 2. чужие абсолютные пути ################################################

# В конфигах абсолютный путь ровно один — строка автозапуска swaybg в
# hyprland.lua. Остальное берёт $HOME само.
if [ "$SRC_USER" != "$DST_USER" ] && [ "$DRY" = 0 ]; then
    say "переписываю пути /home/$SRC_USER -> $HOME"
    grep -rl "/home/$SRC_USER" "$HOME/.config/quickshell" "$HOME/.config/hypr" \
        "$HOME/.config/matugen" "$HOME/bin" 2>/dev/null \
        | while read -r f; do
            sed -i "s|/home/$SRC_USER|$HOME|g" "$f"
        done
fi

# обои из автозапуска могли не приехать — подставляем первую попавшуюся
if [ "$DRY" = 0 ]; then
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

#### 3. система ##############################################################

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

    # matugen 4.2+ живёт только во флейке; в nixpkgs 4.0 без --prefer
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
        warn "флейка нет: matugen возьмётся из nixpkgs (4.0), и режим «авто» в"
        warn "селекторе обоев работать не будет — закреплённые цвета будут."
    fi

    # видеокарта
    if [ -d /sys/bus/pci/drivers/nvidia ] || lspci 2>/dev/null | grep -qi nvidia; then
        warn "замечена NVIDIA. Модуль её НЕ настраивает: на ноутбуке это обычно"
        warn "PRIME с переключением, и правила у каждой машины свои."
    fi
fi

#### 4. пересборка ###########################################################

rebuild_cmd() {
    if [ -f /etc/nixos/flake.nix ]; then
        echo "sudo nixos-rebuild switch --flake /etc/nixos#$HOST"
    else
        echo "sudo nixos-rebuild switch"
    fi
}

CMD="$(rebuild_cmd)"

if [ "$HOME_ONLY" = 0 ]; then
    case "$REBUILD" in
        ask)
            # в холостом прогоне и без терминала ничего не спрашиваем
            if [ "$DRY" = 1 ] || [ ! -t 0 ]; then
                say "пересборка не запускалась: $CMD"
                REBUILD=no
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

#### что дальше ##############################################################

cat <<EOF

Готово. Дальше:

  1. Пересобрать систему, если ещё не:  $CMD
  2. Выйти из сессии и войти в Hyprland (SDDM предложит его в списке).
  3. Super + W — выбрать обои: это задаёт и палитру, и строку автозапуска.
  4. Если значки в панели — пустые прямоугольники, шрифт не подхватился:
     fc-list | grep -i jetbrains  и перелогиниться.

Проверить панель: qs log   (ошибки QML видны там же)
Горячие клавиши: Super — лаунчер, Super+W — обои, Super+V — буфер обмена,
Super+F — полный экран, Super+M — выйти из сессии.
EOF
