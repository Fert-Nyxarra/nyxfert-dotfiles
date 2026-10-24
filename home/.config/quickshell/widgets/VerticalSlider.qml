// ~/.config/quickshell/widgets/VerticalSlider.qml
// Вертикальный ползунок: заливка снизу, значок внизу, проценты сверху.
// Используется в контрол-центре для яркости и громкости.

import QtQuick
import qs

Item {
    id: root

    property real value: 0
    property string glyph: ""
    property bool muted: false

    // сюда приходит новое значение 0..1
    signal moved(real value)

    implicitWidth: 66
    implicitHeight: 150

    Rectangle {
        id: track

        anchors.fill: parent
        radius: width / 2
        color: Theme.alpha(Colors.surfaceContainerHigh, 0.85)
        border.width: 1
        border.color: Theme.alpha(Colors.outlineVariant, 0.6)
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.max(0, Math.min(1, root.value))

            color: root.muted
                ? Theme.alpha(Colors.outline, 0.5)
                : Theme.alpha(Colors.primary, 0.55)

            Behavior on height {
                NumberAnimation {
                    duration: 110
                    easing.type: Theme.animEasing
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 12

            text: Math.round(root.value * 100) + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            color: Colors.subtext
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12

            text: root.glyph
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            color: root.muted ? Colors.outline : Colors.text
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        function apply(y: real): void {
            root.moved(Math.max(0, Math.min(1, 1 - y / root.height)));
        }

        onPressed: mouse => apply(mouse.y)
        onPositionChanged: mouse => {
            if (pressed) apply(mouse.y);
        }

        onWheel: event => {
            const step = event.angleDelta.y > 0 ? 0.05 : -0.05;
            root.moved(Math.max(0, Math.min(1, root.value + step)));
        }
    }
}
