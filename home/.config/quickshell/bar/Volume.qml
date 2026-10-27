import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.widgets

BarItem {
    id: root

    required property var barScreen
    required property bool fullscreen

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: root.sink ? root.sink.audio : null
    readonly property real volume: root.audio ? root.audio.volume : 0
    readonly property bool muted: root.audio ? root.audio.muted : false

    horizontalPadding: 10
    interactive: true
    active: outputs.opened

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    onClicked: {
        if (root.audio) root.audio.muted = !root.audio.muted;
    }

    onRightClicked: outputs.toggle()

    onWheel: delta => {
        if (!root.audio) return;
        const step = delta > 0 ? 0.05 : -0.05;
        root.audio.muted = false;
        root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + step));
    }

    property bool indicatorReady: false

    Timer {
        interval: 1200
        running: true
        onTriggered: root.indicatorReady = true
    }

    readonly property string glyph: root.muted || root.volume <= 0.001 ? "󰝟"
        : root.volume < 0.34 ? "󰕿"
        : root.volume < 0.67 ? "󰖀"
        : "󰕾"

    function showVolume(): void {
        if (!root.indicatorReady) return;

        if (outputs.opened) return;

        if (root.fullscreen) pill.showVolume();
        else osd.showVolume();
    }

    function showBrightness(): void {
        if (!root.indicatorReady) return;

        if (root.fullscreen) pill.showBrightness();
        else osd.showBrightness();
    }

    onVolumeChanged: root.showVolume()
    onMutedChanged: root.showVolume()

    Connections {
        target: Brightness

        function onValueChanged(): void {
            if (Brightness.available) root.showBrightness();
        }
    }

    OutputMenu {
        id: outputs
        anchorItem: root
    }

    Connections {
        target: outputs

        function onOpenedChanged(): void {
            if (outputs.opened) osd.close();
        }
    }

    LevelOsd {
        id: osd
        anchorItem: root
        volume: root.volume
        muted: root.muted
        volumeGlyph: root.glyph
    }

    LevelPill {
        id: pill
        barScreen: root.barScreen
        volume: root.volume
        muted: root.muted
        volumeGlyph: root.glyph
    }

    BarText {
        font.pixelSize: Theme.fontSize + 3
        color: root.muted ? Colors.outline : Colors.primary
        text: root.glyph
    }
}
