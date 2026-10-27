import QtQuick
import Quickshell
import qs
import qs.widgets

BarItem {
    id: root

    required property var barScreen

    readonly property real menuProgress: menu.revealProgress

    horizontalPadding: 12
    interactive: true
    active: menu.attached

    onClicked: menu.toggle()

    function toggle(): void {
        menu.toggle();
    }

    LauncherMenu {
        id: menu
        barScreen: root.barScreen
    }

    Binding {
        target: LauncherState
        property: "opened"
        value: menu.opened
    }

    Connections {
        target: LauncherState

        function onToggleRequested(): void {
            menu.toggle();
        }
    }

    BarText {
        text: "\uf313"
        font.pixelSize: Theme.fontSize + 4
        color: Colors.primary
    }
}
