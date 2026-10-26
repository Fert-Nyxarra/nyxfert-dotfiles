// ~/.config/quickshell/widgets/BarText.qml
// Текст с общими для панели шрифтом и цветом.

import QtQuick
import qs

Text {
    // Без anchors намеренно: текст лежит в Grid (BarItem), а тот не терпит
    // привязок у своих детей и просто перестаёт раскладывать.
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Font.DemiBold
    color: Colors.text
    elide: Text.ElideRight
}
