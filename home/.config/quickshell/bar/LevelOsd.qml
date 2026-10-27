import QtQuick
import qs
import qs.widgets

Popup {
    id: root

    required property real volume
    required property bool muted
    required property string volumeGlyph

    property string mode: "volume"

    readonly property bool brightnessMode: root.mode === "brightness"
    readonly property real level: root.brightnessMode ? Brightness.value : root.volume
    readonly property string glyph: root.brightnessMode ? Brightness.glyph : root.volumeGlyph

    preferredWidth: 240
    maximumWidth: 240
    managed: false
    grabFocus: false
    slideDuration: 200

    function showVolume(): void {
        root.mode = "volume";
        root.open();
        hideTimer.restart();
    }

    function showBrightness(): void {
        root.mode = "brightness";
        root.open();
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: root.close()
    }

    LevelIndicator {
        width: root.contentWidth
        value: root.level
        glyph: root.glyph
        dim: !root.brightnessMode && root.muted
    }
}
