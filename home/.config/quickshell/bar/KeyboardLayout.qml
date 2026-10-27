import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.widgets

BarItem {
    id: root

    property string layout: "US"

    interactive: true

    spacing: Theme.barVertical ? 0 : 4

    function shortName(full: string): string {
        const name = full.toLowerCase();
        if (name.includes("russian")) return "RU";
        if (name.includes("english")) return "US";
        return full.slice(0, 2).toUpperCase();
    }

    onClicked: switchLayout.running = true

    Process {
        id: switchLayout
        command: ["hyprctl", "switchxkblayout", "all", "next"]
    }

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name !== "activelayout") return;
            const parts = event.data.split(",");
            root.layout = root.shortName(parts[parts.length - 1]);
        }
    }

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

                }
            }
        }
    }

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
