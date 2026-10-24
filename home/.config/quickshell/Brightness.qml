pragma Singleton

// ~/.config/quickshell/Brightness.qml
// Яркость подсветки через /sys/class/backlight.
//
// Устройство ищем сами (имя у каждого ноутбука своё), значение пишем через
// brightnessctl, если он есть, иначе прямо в sysfs — сработает, когда на
// файл даны права (udev-правило из пакета brightnessctl или light).
//
// На машине без подсветки available остаётся false, и ползунок яркости в
// контрол-центре просто не показывается.
//
// ВАЖНО: pragma Singleton первой строкой, см. README, раздел «Грабли».

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string device: ""
    property int maxValue: 0
    property int rawValue: 0
    property bool hasCtl: false

    readonly property bool available: root.device !== "" && root.maxValue > 0
    readonly property real value: root.available ? root.rawValue / root.maxValue : 0

    // значок по уровню — для индикатора яркости
    readonly property string glyph: root.value < 0.34 ? "󰃞"
        : root.value < 0.67 ? "󰃟"
        : "󰃠"

    function setValue(fraction: real): void {
        if (!root.available) return;

        const clamped = Math.max(0.02, Math.min(1, fraction));
        const raw = Math.max(1, Math.round(clamped * root.maxValue));

        root.rawValue = raw;

        apply.command = root.hasCtl
            ? ["brightnessctl", "--device", root.device, "--quiet", "set", raw + ""]
            : ["sh", "-c", "echo " + raw + " > /sys/class/backlight/" + root.device + "/brightness"];
        apply.running = true;
    }

    Process {
        id: apply
        command: ["true"]
    }

    // какое устройство подсветки в системе
    Process {
        running: true
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -1"]

        stdout: StdioCollector {
            onStreamFinished: root.device = this.text.trim()
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v brightnessctl >/dev/null && echo yes || true"]

        stdout: StdioCollector {
            onStreamFinished: root.hasCtl = this.text.trim() === "yes"
        }
    }

    FileView {
        path: root.device === "" ? "" : "/sys/class/backlight/" + root.device + "/max_brightness"
        onLoaded: root.maxValue = parseInt(this.text()) || 0
    }

    FileView {
        id: currentFile

        path: root.device === "" ? "" : "/sys/class/backlight/" + root.device + "/brightness"
        // яркость меняют и мимо нас — клавишами ноутбука; следим за файлом,
        // чтобы индикатор всплывал сразу, а не через опрос
        watchChanges: true

        onLoaded: root.rawValue = parseInt(this.text()) || 0
        onFileChanged: currentFile.reload()
    }

    // яркость могут менять и мимо нас — клавишами или другой программой
    Timer {
        interval: 2000
        running: root.available
        repeat: true
        onTriggered: currentFile.reload()
    }
}
