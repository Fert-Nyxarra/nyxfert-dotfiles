// ~/.config/quickshell/widgets/SettingSlider.qml
// Ползунок целого значения для окна настроек: подпись слева, значение
// справа, полоса под ними. Ноль можно подписать словом («выкл»).

import QtQuick
import qs

Item {
    id: root

    property string label: ""
    property int value: 0
    property int from: 0
    property int to: 10
    property string unit: "px"
    property string zeroLabel: ""

    // ползунок двигают — наружу уходит новое значение
    signal moved(int value)

    readonly property real fraction: root.to > root.from
        ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))
        : 0

    implicitHeight: 52

    function pick(x: real): void {
        const at = Math.max(0, Math.min(1, (x - handle.width / 2) / Math.max(1, track.usable)));
        root.moved(Math.round(root.from + at * (root.to - root.from)));
    }

    Text {
        id: labelText

        text: root.label
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Colors.text
    }

    Text {
        x: root.width - width
        text: root.value === 0 && root.zeroLabel !== ""
            ? root.zeroLabel
            : root.value + " " + root.unit
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 1
        color: root.value === 0 && root.zeroLabel !== "" ? Colors.subtext : Colors.primary
    }

    Item {
        id: track

        readonly property real usable: width - handle.width

        y: labelText.height + 12
        width: parent.width
        height: 24

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: handle.width / 2
            width: track.usable
            height: 6
            radius: 3
            color: Theme.alpha(Colors.outline, 0.35)
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: handle.width / 2
            width: track.usable * root.fraction
            height: 6
            radius: 3
            color: Colors.primary
        }

        Rectangle {
            id: handle

            anchors.verticalCenter: parent.verticalCenter
            x: track.usable * root.fraction
            width: 18
            height: 18
            radius: 9
            color: Colors.primary
            scale: mouse.containsMouse || mouse.pressed ? 1.15 : 1

            Behavior on x {
                NumberAnimation {
                    duration: mouse.pressed ? 0 : 120
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                NumberAnimation { duration: 120 }
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPressed: event => root.pick(event.x)
            onPositionChanged: event => {
                if (mouse.pressed) root.pick(event.x);
            }
            onWheel: event => {
                const step = event.angleDelta.y > 0 ? 1 : -1;
                root.moved(Math.max(root.from, Math.min(root.to, root.value + step)));
            }
        }
    }
}
