import QtQuick
import qs

Item {
    implicitHeight: 9
    implicitWidth: 1

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: 8
        width: parent.width - 16
        height: 1
        color: Theme.alpha(Colors.outlineVariant, 0.7)
    }
}
