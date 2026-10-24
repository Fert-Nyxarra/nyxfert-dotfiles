// ~/.config/quickshell/bar/LevelOsd.qml
// Всплывающий индикатор громкости и яркости — меню под модулем громкости.
// Отдельного значка у яркости нет намеренно: индикатор общий, а показывает
// то, что сейчас меняли.
//
// managed: false — не участвует в правиле «одно меню за раз»: крутить
// громкость можно и при открытом меню. grabFocus: false — и ввод не крадёт.

import QtQuick
import qs
import qs.widgets

Popup {
    id: root

    // живые значения громкости приходят из модуля; яркость берём сами
    required property real volume
    required property bool muted
    required property string volumeGlyph

    // что показываем: "volume" или "brightness"
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
