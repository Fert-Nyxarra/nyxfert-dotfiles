// ~/.config/quickshell/shell.qml
// Точка входа Quickshell. Создаёт по одной панели на каждый монитор.

import Quickshell
import Quickshell.Io
import qs
import qs.bar

ShellRoot {
    // хоткей Super в hyprland.lua зовёт "qs ipc call launcher toggle";
    // обработчик здесь, а не в панели, чтобы он был один на все мониторы
    IpcHandler {
        target: "launcher"

        function toggle(): void {
            LauncherState.toggle();
        }

        function state(): string {
            return LauncherState.opened ? "open" : "closed";
        }

        // Super + W: выбор обоев
        function wallpaper(): void {
            WallpaperService.toggle();
        }

        // Super + V: история буфера обмена
        function clipboard(): void {
            ClipboardService.toggle();
        }

        // Ctrl + Super + S: настройки оболочки
        function settings(): void {
            Settings.toggle();
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // выбор обоев — один слой на весь shell, открывается с Super + W
    WallpaperPicker {}

    // настройки оболочки — Ctrl + Super + S
    SettingsWindow {}
}
