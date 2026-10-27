import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.widgets

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    readonly property var keyboardMenu: Menus.current && Menus.current.wantsKeyboard
        ? Menus.current
        : null

    WlrLayershell.keyboardFocus: bar.keyboardMenu
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    readonly property bool vertical: Theme.barVertical

    anchors {
        top: Theme.barPosition !== "bottom"
        bottom: Theme.barPosition !== "top"
        left: Theme.barPosition !== "right"
        right: Theme.barPosition !== "left"
    }

    margins {
        top: bar.vertical ? Theme.barSideMargin
            : Theme.barPosition === "top" ? Theme.barMargin : 0
        bottom: bar.vertical ? Theme.barSideMargin
            : Theme.barPosition === "bottom" ? Theme.barMargin : 0
        left: bar.vertical
            ? (Theme.barPosition === "left" ? Theme.barMargin : 0)
            : Theme.barSideMargin
        right: bar.vertical
            ? (Theme.barPosition === "right" ? Theme.barMargin : 0)
            : Theme.barSideMargin
    }

    implicitHeight: bar.vertical ? 0 : Theme.barThickness
    implicitWidth: bar.vertical ? Theme.barThickness : 0
    color: "transparent"

    readonly property var hyprMonitor: Hyprland.monitorFor(bar.modelData)
    readonly property bool fullscreenHere: bar.hyprMonitor && bar.hyprMonitor.activeWorkspace
        ? bar.hyprMonitor.activeWorkspace.hasFullscreen
        : false

    visible: Settings.loaded && !bar.fullscreenHere

    ClipboardMenu {
        id: clipboardMenu

        barScreen: bar.modelData
    }

    Rectangle {
        id: surface

        anchors.fill: parent

        radius: Theme.barRadius
        color: Theme.panelColor
        border.width: 1
        border.color: Theme.panelBorder

        bottomLeftRadius: Theme.barRadius
            * (1 - Math.max(launcher.menuProgress, clipboardMenu.revealProgress))
        bottomRightRadius: Theme.barRadius * (1 - notifications.menuProgress)

        Item {
            anchors.fill: parent
            focus: bar.keyboardMenu !== null

            Keys.onPressed: event => {
                if (bar.keyboardMenu) bar.keyboardMenu.keyPressed(event);
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: Menus.closeCurrent()
        }

        Grid {
            id: startGroup

            flow: bar.vertical ? Grid.TopToBottom : Grid.LeftToRight

            rows: bar.vertical ? -1 : 1
            columns: bar.vertical ? 1 : -1
            spacing: Theme.groupGap

            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            x: bar.vertical ? (parent.width - width) / 2 : Theme.barPadding
            y: bar.vertical ? Theme.barPadding : (parent.height - height) / 2

            Launcher { id: launcher; barScreen: bar.modelData }
            Separator {}
            Workspaces { screenName: bar.modelData.name }
            Separator { visible: nowPlaying.visible }
            NowPlaying { id: nowPlaying }
        }

        Clock {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
        }

        Grid {
            id: endGroup

            flow: bar.vertical ? Grid.TopToBottom : Grid.LeftToRight

            rows: bar.vertical ? -1 : 1
            columns: bar.vertical ? 1 : -1
            spacing: Theme.groupGap

            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            x: bar.vertical
                ? (parent.width - width) / 2
                : parent.width - width - Theme.barPadding

            y: bar.vertical
                ? parent.height - height - Theme.barPadding
                : (parent.height - height) / 2

            Tray { id: tray }
            Separator { visible: tray.visible }
            Volume { barScreen: bar.modelData; fullscreen: bar.fullscreenHere }
            NetworkStatus {}
            Battery { id: battery }
            Separator { visible: battery.visible }
            KeyboardLayout {}
            Separator {}
            Notifications { id: notifications }
        }
    }
}
