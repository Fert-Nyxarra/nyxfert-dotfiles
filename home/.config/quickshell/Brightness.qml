pragma Singleton

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

        watchChanges: true

        onLoaded: root.rawValue = parseInt(this.text()) || 0
        onFileChanged: currentFile.reload()
    }

    Timer {
        interval: 2000
        running: root.available
        repeat: true
        onTriggered: currentFile.reload()
    }
}
