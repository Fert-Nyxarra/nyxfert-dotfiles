import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.widgets

PanelWindow {
    id: root

    required property var barScreen
    required property real volume
    required property bool muted
    required property string volumeGlyph

    property string mode: "volume"
    property bool shown: false

    readonly property bool brightnessMode: root.mode === "brightness"
    readonly property real level: root.brightnessMode ? Brightness.value : root.volume
    readonly property string glyph: root.brightnessMode ? Brightness.glyph : root.volumeGlyph

    screen: root.barScreen

    WlrLayershell.namespace: "quickshell:level"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false

    anchors.bottom: true
    margins.bottom: 70

    implicitWidth: pill.implicitWidth + 60
    implicitHeight: pill.implicitHeight + 60

    mask: Region {}

    function showVolume(): void {
        root.mode = "volume";
        root.show();
    }

    function showBrightness(): void {
        root.mode = "brightness";
        root.show();
    }

    function show(): void {
        root.visible = true;
        root.shown = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: root.shown = false
    }

    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter

        implicitWidth: 240
        implicitHeight: 52
        width: implicitWidth
        height: implicitHeight
        radius: height / 2

        color: Theme.panelColor
        border.width: 1
        border.color: Theme.panelBorder

        y: (parent.height - height) / 2 + (root.shown ? 0 : 40)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.9

        Behavior on y {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutBack
                easing.overshoot: 1.6
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutBack
                easing.overshoot: 1.6
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 160

                onRunningChanged: if (!running && !root.shown) root.visible = false
            }
        }

        LevelIndicator {
            anchors.centerIn: parent
            width: parent.width - 16
            value: root.level
            glyph: root.glyph
            dim: !root.brightnessMode && root.muted
        }
    }
}
