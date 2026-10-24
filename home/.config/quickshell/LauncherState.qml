pragma Singleton

// ~/.config/quickshell/LauncherState.qml
// Мостик между IPC и модулем лаунчера: хоткей Super в hyprland.lua дёргает
// "qs ipc call launcher toggle", обработчик в shell.qml зовёт toggle(), а
// панель на него откликается. Через синглтон — чтобы обработчик был ОДИН на
// весь shell, а не по одному на каждый монитор.
//
// ВАЖНО: pragma Singleton первой строкой, см. README, раздел «Грабли».

import QtQuick
import Quickshell

Singleton {
    // состояние держит модуль панели: по нему IPC может проверить, открыт ли
    // лаунчер, не гадая по пикселям
    property bool opened: false

    signal toggleRequested

    function toggle(): void {
        toggleRequested();
    }
}
