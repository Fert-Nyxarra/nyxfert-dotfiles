// ~/.config/quickshell/bar/Volume.qml
// Громкость основного вывода PipeWire. В панели только значок: без звука,
// тихо, средне, громко — проценты показывает всплывающий индикатор.
//
// ЛКМ — mute, ПКМ — меню устройств вывода, колесо — громкость шагом 5%.
//
// Этот же модуль показывает индикатор ЯРКОСТИ: отдельного значка у неё нет,
// а всплывающее меню нужно к чему-то прицепить.

import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.widgets

BarItem {
    id: root

    // монитор панели и признак полного экрана приходят из Bar.qml: при
    // фуллскрине панель спрятана, и громкость показывается пилюлей снизу
    required property var barScreen
    required property bool fullscreen

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: root.sink ? root.sink.audio : null
    readonly property real volume: root.audio ? root.audio.volume : 0
    readonly property bool muted: root.audio ? root.audio.muted : false

    horizontalPadding: 10
    interactive: true
    active: outputs.opened

    // без трекера PipeWire не отдаёт подробные данные об устройстве
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

    // при запуске громкость «меняется» с нуля на текущую — индикатор на это
    // реагировать не должен
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

        // пока открыто меню устройств, громкость видна в нём самом
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

    // яркость меняют клавишами ноутбука — ловим и показываем тем же индикатором
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

    // меню открыли, пока индикатор ещё висел — убираем его
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

    // без звука / тихо / средне / громко
    BarText {
        font.pixelSize: Theme.fontSize + 3
        color: root.muted ? Colors.outline : Colors.primary
        text: root.glyph
    }
}
