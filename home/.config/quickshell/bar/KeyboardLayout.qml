// ~/.config/quickshell/bar/KeyboardLayout.qml
// Текущая раскладка клавиатуры. Клик переключает её.

import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.widgets

BarItem {
    id: root

    property string layout: "US"

    interactive: true

    // горизонтально значок и буквы стоят почти вплотную, как было одной
    // строкой; столбиком зазор не нужен вовсе
    spacing: Theme.barVertical ? 0 : 4

    function shortName(full: string): string {
        const name = full.toLowerCase();
        if (name.includes("russian")) return "RU";
        if (name.includes("english")) return "US";
        return full.slice(0, 2).toUpperCase();
    }

    // в Lua-конфиге Hyprland нет диспатчера для раскладки, зато есть
    // отдельная команда hyprctl
    onClicked: switchLayout.running = true

    Process {
        id: switchLayout
        command: ["hyprctl", "switchxkblayout", "all", "next"]
    }

    // Hyprland шлёт activelayout при каждой смене раскладки
    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name !== "activelayout") return;
            const parts = event.data.split(",");
            root.layout = root.shortName(parts[parts.length - 1]);
        }
    }

    // начальное значение: его в событиях нет, спрашиваем у hyprctl
    Process {
        running: true
        command: ["hyprctl", "-j", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(this.text).keyboards ?? [];
                    const main = keyboards.find(k => k.main) ?? keyboards[0];
                    if (main) root.layout = root.shortName(main.active_keymap);
                } catch (e) {
                    // hyprctl недоступен — останется значение по умолчанию
                }
            }
        }
    }

    // Значок и буквы — два отдельных элемента, а не одна строка: у боковой
    // панели Grid внутри BarItem ставит их столбиком, значок сверху, буквы
    // под ним. У горизонтальной они стоят в ряд, как и раньше.
    BarText {
        color: Colors.primary
        text: "󰌌"
    }

    BarText {
        color: Colors.primary
        font.pixelSize: Theme.barVertical ? Theme.fontSize - 2 : Theme.fontSize
        text: root.layout
    }
}
