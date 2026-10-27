pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string statePath: root.stateDir + "/settings.json"

    readonly property var barPositions: ["top", "bottom", "left", "right"]
    readonly property var barModes: ["island", "panel"]

    readonly property var windowAnimations: ["off", "slide", "popin", "fast"]

    readonly property var windowLayouts: ["tiling", "scrolling"]

    readonly property int windowBorderMax: 12
    readonly property int windowRoundingMax: 24

    readonly property string barPosition: store.adapter
        && root.barPositions.indexOf(store.adapter.barPosition) >= 0
        ? store.adapter.barPosition
        : "top"

    readonly property string barMode: store.adapter
        && root.barModes.indexOf(store.adapter.barMode) >= 0
        ? store.adapter.barMode
        : "island"

    readonly property bool barVertical: root.barPosition === "left" || root.barPosition === "right"

    readonly property bool barFlipped: root.barPosition === "bottom" || root.barPosition === "right"

    readonly property bool barIsland: root.barMode === "island"

    readonly property int windowBorder: store.adapter
        ? Math.max(0, Math.min(root.windowBorderMax, store.adapter.windowBorder))
        : 3

    readonly property int windowRounding: store.adapter
        ? Math.max(0, Math.min(root.windowRoundingMax, store.adapter.windowRounding))
        : 0

    readonly property string windowLayout: store.adapter
        && root.windowLayouts.indexOf(store.adapter.windowLayout) >= 0
        ? store.adapter.windowLayout
        : "tiling"

    readonly property string windowAnimation: store.adapter
        && root.windowAnimations.indexOf(store.adapter.windowAnimation) >= 0
        ? store.adapter.windowAnimation
        : "slide"

    property bool loaded: false

    signal toggleRequested

    function toggle(): void {
        root.toggleRequested();
    }

    function setBarPosition(value: string): void {
        if (root.barPositions.indexOf(value) < 0) return;
        if (!store.adapter) return;

        store.adapter.barPosition = value;
        store.writeAdapter();
    }

    function setWindowBorder(value: int): void {
        if (!store.adapter) return;

        store.adapter.windowBorder = Math.max(0, Math.min(root.windowBorderMax, value));
        store.writeAdapter();
        root.applyWindowStyle();
    }

    function setWindowRounding(value: int): void {
        if (!store.adapter) return;

        store.adapter.windowRounding = Math.max(0, Math.min(root.windowRoundingMax, value));
        store.writeAdapter();
        root.applyWindowStyle();
    }

    function setWindowLayout(value: string): void {
        if (root.windowLayouts.indexOf(value) < 0) return;
        if (!store.adapter) return;

        store.adapter.windowLayout = value;
        store.writeAdapter();
        root.applyWindowStyle();
    }

    function setWindowAnimation(value: string): void {
        if (root.windowAnimations.indexOf(value) < 0) return;
        if (!store.adapter) return;

        store.adapter.windowAnimation = value;
        store.writeAdapter();
        root.applyWindowStyle();
    }

    function animationSnippet(kind: string): string {
        if (kind === "off") {
            return 'hl.animation({ leaf = "windowsIn", enabled = false }) '
                + 'hl.animation({ leaf = "windowsOut", enabled = false })';
        }

        if (kind === "popin") {
            return 'hl.animation({ leaf = "windowsIn", enabled = true, speed = 4,'
                + ' bezier = "overshoot", style = "popin 80%" }) '
                + 'hl.animation({ leaf = "windowsOut", enabled = true, speed = 3,'
                + ' bezier = "smooth", style = "popin 80%" })';
        }

        if (kind === "fast") {
            return 'hl.animation({ leaf = "windowsIn", enabled = true, speed = 2,'
                + ' bezier = "smooth", style = "popin 95%" }) '
                + 'hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.6,'
                + ' bezier = "smooth", style = "popin 95%" })';
        }

        return 'hl.animation({ leaf = "windowsIn", enabled = true, speed = 3.5,'
            + ' bezier = "overshoot", style = "slide" }) '
            + 'hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5,'
            + ' bezier = "smooth", style = "slide" })';
    }

    function layoutName(): string {
        return root.windowLayout === "scrolling" ? "scrolling" : "dwindle";
    }

    function applyWindowStyle(): void {
        applyProcess.command = ["hyprctl", "eval",
            "hl.config({ general = { border_size = " + root.windowBorder + ","
            + " layout = \"" + root.layoutName() + "\" },"
            + " decoration = { rounding = " + root.windowRounding + " } }) "
            + root.animationSnippet(root.windowAnimation)];
        applyProcess.running = true;
    }

    function setBarMode(value: string): void {
        if (root.barModes.indexOf(value) < 0) return;
        if (!store.adapter) return;

        store.adapter.barMode = value;
        store.writeAdapter();
    }

    Process { id: applyProcess }

    onLoadedChanged: if (root.loaded) root.applyWindowStyle()

    onWindowBorderChanged: if (root.loaded) root.applyWindowStyle()
    onWindowRoundingChanged: if (root.loaded) root.applyWindowStyle()
    onWindowAnimationChanged: if (root.loaded) root.applyWindowStyle()

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "configreloaded") root.applyWindowStyle();
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.stateDir]
    }

    FileView {
        id: store

        path: root.statePath

        blockLoading: true

        watchChanges: true
        onFileChanged: store.reload()

        onLoaded: root.loaded = true

        onLoadFailed: {
            store.writeAdapter();
            root.loaded = true;
        }

        adapter: JsonAdapter {
            property string barPosition: "top"
            property string barMode: "island"

            property string windowLayout: "tiling"
            property int windowBorder: 3
            property int windowRounding: 0
            property string windowAnimation: "slide"
        }
    }
}
