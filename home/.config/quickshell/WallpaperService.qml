pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string folder: root.home + "/Wallpapers"
    readonly property string statePath: root.home + "/.local/state/quickshell/wallpapers.json"
    readonly property string hyprlandConfig: root.home + "/.config/hypr/hyprland.lua"

    property var files: []
    property string current: ""

    readonly property var pins: store.adapter && store.adapter.colors
        ? store.adapter.colors
        : ({})

    readonly property var contrastPins: store.adapter && store.adapter.contrast
        ? store.adapter.contrast
        : ({})

    property bool matugenPrefers: true

    readonly property var monoPins: store.adapter && store.adapter.mono
        ? store.adapter.mono
        : ({})

    signal toggleRequested

    function toggle(): void {
        toggleRequested();
    }

    function colorFor(path: string): string {
        return root.pins[path] ?? "";
    }

    function contrastFor(path: string): real {
        return root.contrastPins[path] ?? 0;
    }

    function monoFor(path: string): bool {
        return root.monoPins[path] === true;
    }

    function pin(path: string, color: string, contrast: real, mono: bool): void {
        const colorCopy = Object.assign({}, root.pins);
        colorCopy[path] = color;

        const contrastCopy = Object.assign({}, root.contrastPins);
        contrastCopy[path] = contrast;

        const monoCopy = Object.assign({}, root.monoPins);
        monoCopy[path] = mono;

        store.adapter.colors = colorCopy;
        store.adapter.contrast = contrastCopy;
        store.adapter.mono = monoCopy;
        store.writeAdapter();
    }

    function matugenArgs(path: string, color: string, contrast: real, mono: bool): var {
        if (mono) return ["-t", "scheme-monochrome", "color", "hex", "#808080"];

        let args = ["-t", "scheme-content"];
        if (contrast !== 0) args = args.concat(["--contrast", String(contrast)]);

        if (color !== "") return args.concat(["color", "hex", color]);

        return root.matugenPrefers
            ? args.concat(["image", path, "--prefer", "saturation"])
            : args.concat(["image", path]);
    }

    function apply(path: string): void {
        if (path === "") return;

        root.current = path;
        const color = root.colorFor(path);

        wallpaperSwap.command = ["setsid", "--fork", "sh", "-c", root.swapScript, "sh", path];
        wallpaperSwap.running = true;

        generateColors.command = ["matugen"].concat(
            root.matugenArgs(path, color, root.contrastFor(path), root.monoFor(path)));
        generateColors.running = true;

        root.saveAutostart(path);
    }

    readonly property string swapScript:
        "old=$(pgrep swaybg | tr '\\n' ' '); "
        + 'before=$(hyprctl layers -j | grep -c \'"namespace": "wallpaper"\'); '

        + 'setsid --fork swaybg -i "$1" -m fill >/dev/null 2>&1; '
        + 'i=0; while [ "$i" -lt 50 ]; do '
        + '  now=$(hyprctl layers -j | grep -c \'"namespace": "wallpaper"\'); '
        + '  [ "$now" -gt "$before" ] && break; '
        + '  i=$((i+1)); sleep 0.1; '
        + 'done; '
        + 'sleep 0.6; '
        + '[ -n "$old" ] && kill $old 2>/dev/null; '
        + 'exit 0'

    function quote(text: string): string {
        return "'" + text.replace(/'/g, "'\\''") + "'";
    }

    function saveAutostart(path: string): void {
        const line = 'hl.exec_cmd("swaybg -i ' + path + '")';

        saveLine.command = ["setsid", "--fork", "sh", "-c",
            "sed -i 's|hl.exec_cmd(\"swaybg -i [^\"]*\")|" + line.replace(/[|&]/g, "\\\\&") + "|' "
            + root.quote(root.hyprlandConfig)];
        saveLine.running = true;
    }

    Process {
        running: true
        command: ["matugen", "--version"]

        stdout: StdioCollector {
            onStreamFinished: {

                const parts = this.text.trim().split(/\s+/);
                const numbers = (parts.length > 1 ? parts[1] : "0").split(".");
                const major = parseInt(numbers[0]) || 0;
                const minor = parseInt(numbers[1]) || 0;

                root.matugenPrefers = major > 4 || (major === 4 && minor >= 1);
            }
        }
    }

    Process { id: wallpaperSwap }
    Process { id: generateColors }
    Process { id: saveLine }

    Process {
        running: true
        command: ["sh", "-c",
            "find " + root.quote(root.folder) + " -maxdepth 1 -type f "
            + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]

        stdout: StdioCollector {
            onStreamFinished: {
                const list = this.text.trim().split("\n").filter(line => line !== "");
                root.files = list;

                if (root.current === "" && list.length > 0) root.current = list[0];
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c",
            "grep -o 'swaybg -i [^\"]*' " + root.quote(root.hyprlandConfig)
            + " | head -1 | sed 's|swaybg -i ||'"]

        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                if (path !== "") root.current = path;
            }
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.home + "/.local/state/quickshell"]
    }

    FileView {
        id: store

        path: root.statePath
        watchChanges: true
        onFileChanged: store.reload()

        onLoadFailed: store.writeAdapter()

        adapter: JsonAdapter {
            property var colors: ({})
            property var contrast: ({})
            property var mono: ({})
        }
    }
}
