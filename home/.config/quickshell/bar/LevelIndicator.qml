import QtQuick
import qs
import qs.widgets

Item {
    id: root

    required property real value
    required property string glyph

    property bool dim: false

    implicitHeight: 32

    Text {
        id: icon

        x: 4
        width: 26
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter

        text: root.glyph
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 5
        color: root.dim ? Colors.outline : Colors.primary
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        x: 38
        width: parent.width - x - 52
        height: 6
        radius: 3
        color: Theme.alpha(Colors.outline, 0.35)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: root.dim ? Colors.outline : Colors.primary

            Behavior on width {
                NumberAnimation {
                    duration: 120
                    easing.type: Theme.animEasing
                }
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
