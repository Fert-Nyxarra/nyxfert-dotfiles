pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string statePath: root.home + "/.local/state/quickshell/clipboard.json"
    readonly property string cacheDir: root.home + "/.cache/quickshell/clipboard"

    readonly property int limit: 50
    readonly property int maxLength: 20000

    readonly property var items: store.adapter && store.adapter.items
        ? store.adapter.items
        : []

    readonly property int count: root.items.length

    signal toggleRequested

    function toggle(): void {
        root.toggleRequested();
    }

    function kindOf(item): string {
        if (typeof item === "string") return "text";
        return item && item.kind === "image" ? "image" : "text";
    }

    function payloadOf(item): string {
        if (typeof item === "string") return item;
        return item && item.value !== undefined ? item.value : "";
    }

    function mimeOf(item): string {
        return typeof item === "string" ? "" : (item && item.mime ? item.mime : "");
    }

    function preview(text: string): string {
        const line = text.trim().split("\n").find(part => part.trim() !== "") ?? "";
        return line.length > 70 ? line.slice(0, 70) + "…" : line;
    }

    function lineCount(text: string): int {
        return text.trim().split("\n").length;
    }

    function remember(chunk: string): void {
        if (!store.adapter) return;
        if (chunk === undefined || chunk === null) return;

        const firstTab = chunk.indexOf("\t");
        if (firstTab < 0) return;

        const secondTab = chunk.indexOf("\t", firstTab + 1);
        if (secondTab < 0) return;

        const kind = chunk.slice(0, firstTab);
        const mime = chunk.slice(firstTab + 1, secondTab);
        let value = chunk.slice(secondTab + 1);

        if (value.trim() === "") return;
        if (kind === "text" && value.length > root.maxLength) {
            value = value.slice(0, root.maxLength);
        }

        const entry = { kind: kind, mime: mime, value: value };

        const rest = root.items.filter(item =>
            !(root.kindOf(item) === kind && root.payloadOf(item) === value));
        rest.unshift(entry);

        store.adapter.items = rest.slice(0, root.limit);
        store.writeAdapter();
    }

    function copy(item): void {
        const value = root.payloadOf(item);
        if (value === "") return;

        if (root.kindOf(item) === "image") {
            const mime = root.mimeOf(item) === "" ? "image/png" : root.mimeOf(item);
            copyProcess.command = ["sh", "-c",
                "setsid --fork wl-copy --type \"$1\" < \"$2\"", "sh", mime, value];
        } else {

            copyProcess.command = ["sh", "-c",
                "printf %s \"$1\" | setsid --fork wl-copy", "sh", value];
        }

        copyProcess.running = true;
    }

    function forget(item): void {
        if (!store.adapter) return;

        const kind = root.kindOf(item);
        const value = root.payloadOf(item);

        if (kind === "image" && value !== "") {
            cleanupProcess.command = ["rm", "-f", value];
            cleanupProcess.running = true;
        }

        store.adapter.items = root.items.filter(other =>
            !(root.kindOf(other) === kind && root.payloadOf(other) === value));
        store.writeAdapter();
    }

    function clear(): void {
        if (!store.adapter) return;

        store.adapter.items = [];
        store.writeAdapter();

        cleanupProcess.command = ["sh", "-c",
            "rm -f \"$1\"/*", "sh", root.cacheDir];
        cleanupProcess.running = true;
    }

    Process { id: copyProcess }
    Process { id: cleanupProcess }

    Process {
        running: true
        command: ["mkdir", "-p", root.home + "/.local/state/quickshell"]
    }

    readonly property string imageScript:
        'd="$1"; mime="$2"; ext="$3"; mkdir -p "$d"; '
        + 'tmp="$d/.incoming.$$"; cat > "$tmp"; '
        + '[ -s "$tmp" ] || { rm -f "$tmp"; exit 0; }; '
        + "sum=$(sha256sum < \"$tmp\" | cut -c1-16); "
        + 'file="$d/$sum.$ext"; '
        + 'if [ -s "$file" ]; then rm -f "$tmp"; else mv "$tmp" "$file"; fi; '
        + 'ls -t "$d" 2>/dev/null | tail -n +51 | while read -r old; do rm -f "$d/$old"; done; '
        + "printf 'image\\t%s\\t%s\\001' \"$mime\" \"$file\""

    Process {
        running: true
        command: ["wl-paste", "--type", "text", "--watch", "sh", "-c",
            "printf 'text\\t\\t'; cat; printf '\\001'"]

        stdout: SplitParser {
            splitMarker: "\u0001"
            onRead: data => root.remember(data)
        }
    }

    Process {
        running: true
        command: ["wl-paste", "--type", "image/png", "--watch", "sh", "-c",
            root.imageScript, "sh", root.cacheDir, "image/png", "png"]

        stdout: SplitParser {
            splitMarker: "\u0001"
            onRead: data => root.remember(data)
        }
    }

    Process {
        running: true
        command: ["wl-paste", "--type", "image/jpeg", "--watch", "sh", "-c",
            root.imageScript, "sh", root.cacheDir, "image/jpeg", "jpg"]

        stdout: SplitParser {
            splitMarker: "\u0001"
            onRead: data => root.remember(data)
        }
    }

    FileView {
        id: store

        path: root.statePath
        watchChanges: true
        onFileChanged: store.reload()

        onLoadFailed: store.writeAdapter()

        adapter: JsonAdapter {
            property var items: []
        }
    }
}
