// ~/.config/quickshell/widgets/Separator.qml
// Вертикальная волосяная линия между модулями внутри общего острова.

import QtQuick
import qs

Rectangle {
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    implicitWidth: 1
    implicitHeight: 16
    color: Theme.alpha(Colors.outlineVariant, 0.7)
}
