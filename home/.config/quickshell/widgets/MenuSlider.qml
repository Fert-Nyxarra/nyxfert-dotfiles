// ~/.config/quickshell/widgets/MenuSlider.qml
// Строка меню с ползунком громкости: значок слева (он же кнопка mute),
// полоса по центру, проценты справа.
//
// Вынесено отдельно, потому что таких строк в меню звука две — вывод и
// микрофон, — и они отличаются только значком и узлом PipeWire.

import QtQuick
import qs

Item {
    id: root

    // PwNodeAudio выбранного устройства, может быть null
    property var audio: null
    property string glyph: ""
    property string mutedGlyph: ""

    readonly property bool muted: root.audio ? root.audio.muted : false
    readonly property real value: root.audio ? root.audio.volume : 0

    implicitHeight: Theme.rowHeight

    function setVolume(level: real): void {
        if (!root.audio) return;

        root.audio.muted = false;
        root.audio.volume = Math.max(0, Math.min(1, level));
    }

    Text {
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        horizontalAlignment: Text.AlignHCenter

        text: root.muted ? root.mutedGlyph : root.glyph
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
        color: root.muted ? Colors.outline : Colors.primary

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.audio) root.audio.muted = !root.audio.muted;
            }
        }
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        x: 36
        width: parent.width - x - 52
        height: 6
        radius: 3
        color: Theme.alpha(Colors.outline, 0.35)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: root.muted ? Colors.outline : Colors.primary
        }

        Rectangle {
            x: parent.width * Math.max(0, Math.min(1, root.value)) - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            radius: 6
            color: Colors.primary
            border.width: 2
            border.color: Colors.surfaceContainer
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor

            onPressed: mouse => root.setVolume((mouse.x + 8) / track.width)
            onPositionChanged: mouse => {
                if (pressed) root.setVolume((mouse.x + 8) / track.width);
            }
            onWheel: event => {
                const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
                root.setVolume(root.value + step);
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - 10

        text: Math.round(root.value * 100) + "%"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
        color: Colors.subtext
    }
}
