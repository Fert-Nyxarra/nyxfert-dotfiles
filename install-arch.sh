#!/usr/bin/env bash
# install-arch.sh — разворачивает то же окружение на Arch Linux.
#
# Ставит только то, без чего не работает оболочка и на что ссылаются конфиги:
# Hyprland с окружением, quickshell, matugen, звук, шрифты. Браузеров,
# мессенджеров и плееров тут нет намеренно.
#
#   ./install-arch.sh                 поставить пакеты и разложить конфиги
#   ./install-arch.sh --dry-run       только показать, что будет сделано
#   ./install-arch.sh --no-packages   ничего не ставить, только конфиги
#   ./install-arch.sh --no-wallpapers не копировать обои
#
# Для NixOS есть отдельный install.sh в том же наборе.

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
        -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "неизвестный ключ: $1" >&2; exit 2 ;;
    esac
    shift
done

. "$KIT/common.sh"

check_not_root
command -v pacman >/dev/null || die "это не Arch — для NixOS есть install.sh"

[ "$DRY" = 1 ] && warn "холостой прогон: ничего не меняется"

#### пакеты ###################################################################

# Из официальных репозиториев: всё, кроме quickshell и matugen.
REPO_PACKAGES=(
    hyprland                 # сам компоновщик
    xdg-desktop-portal-hyprland
    hyprlock hypridle
    sddm                     # вход в сессию
    pipewire wireplumber pipewire-pulse pipewire-alsa
    networkmanager
    upower power-profiles-daemon   # батарея и профили в панели
    brightnessctl            # яркость без root
    swaybg                   # обои
    wl-clipboard             # буфер обмена
    grim slurp swappy        # скриншоты
    wf-recorder              # запись экрана, ~/bin/screenrec
    kitty                    # терминал из биндов
    thunar                   # файловый менеджер из биндов
    jq inotify-tools         # разбор вывода hyprctl в скриптах
    glib2                    # gdbus — им шлются уведомления
    fastfetch
    polkit-gnome             # агент авторизации
    ttf-jetbrains-mono-nerd  # ВСЕ значки панели берутся отсюда
    noto-fonts noto-fonts-emoji
    qt6-declarative qt6-wayland
)

# Из AUR: их нет в официальных репозиториях.
AUR_PACKAGES=(
    quickshell               # сама панель
    matugen-bin              # палитра по обоям, нужна 4.2+
    hyprshot                 # скриншоты из биндов
)

aur_helper() {
    for helper in paru yay; do
        command -v "$helper" >/dev/null && { echo "$helper"; return; }
    done
}

install_packages() {
    say "ставлю пакеты из репозиториев (${#REPO_PACKAGES[@]} шт.)"
    run sudo pacman -S --needed --noconfirm "${REPO_PACKAGES[@]}"

    local helper
    helper="$(aur_helper || true)"

    if [ -z "$helper" ]; then
        warn "не найден помощник AUR (paru или yay)."
        warn "quickshell, matugen и hyprshot оттуда — без них панель не запустится."
        warn "Поставить paru:"
        cat <<'SNIP'

    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    cd /tmp/paru && makepkg -si

SNIP
        warn "после этого запусти скрипт ещё раз"
        return
    fi

    say "ставлю из AUR через $helper (${#AUR_PACKAGES[@]} шт.)"
    run "$helper" -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

enable_services() {
    say "включаю системные службы"

    # Звук и портал поднимаются сами по сессии, им systemctl --user не нужен.
    for unit in NetworkManager sddm power-profiles-daemon; do
        run sudo systemctl enable "$unit"
    done
}

if [ "$PACKAGES" = 1 ]; then
    install_packages
    enable_services
else
    say "ключ --no-packages: пакеты не трогаю"
fi

#### конфиги ##################################################################

install_home_files

#### что дальше ###############################################################

final_notes

cat <<'EOF'

Отличия от NixOS, про которые стоит знать:

  * matugen ставится из AUR (matugen-bin). Нужна версия 4.2+: в более
    старых нет ключа --prefer, и режим «авто» в выборе обоев падает на
    картинках с несколькими цветами. Панель это переживёт — она сама
    спрашивает версию, — но «авто» работать не будет.
  * NVIDIA скрипт не настраивает: на ноутбуке это обычно PRIME, и правила
    у каждой машины свои.
  * Раскладка us,ru с переключением по Win+Space задаётся в hyprland.lua,
    отдельной настройки X11 не нужно.
EOF
