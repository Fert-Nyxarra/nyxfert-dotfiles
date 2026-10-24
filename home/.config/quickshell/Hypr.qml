pragma Singleton

// ~/.config/quickshell/Hypr.qml
// Обёртка над IPC Hyprland.
//
// Hyprland можно настраивать классическим hyprland.conf либо Lua-конфигом
// (как здесь). У них разный синтаксис команд: "workspace 2" против
// hl.dsp.focus(...). Hyprland.usingLua говорит, какой режим активен,
// поэтому панель работает в обоих.
//
// ВАЖНО: pragma Singleton стоит ПЕРВОЙ строкой. Сканер Quickshell ищет её,
// считая фигурные скобки и не пропуская комментарии: любая "{" в комментарии
// выше pragma — и файл регистрируется как обычный тип, а не синглтон.
// Именно из-за этого Hypr.focusWorkspace раньше не существовал и клики по
// рабочим столам ничего не делали.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    // перейти на рабочий стол по номеру
    function focusWorkspace(id: int): void {
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = ${id} })`
            : `workspace ${id}`);
    }

    // относительное переключение: "e+1" — следующий, "e-1" — предыдущий
    function cycleWorkspace(step: string): void {
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = "${step}" })`
            : `workspace ${step}`);
    }
}
