// ~/.config/quickshell/widgets/BarText.qml
// Текст с общими для панели шрифтом и цветом.

import QtQuick
import qs

Text {
    anchors.verticalCenter: parent.verticalCenter
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Font.DemiBold
    color: Colors.text
    elide: Text.ElideRight
}
