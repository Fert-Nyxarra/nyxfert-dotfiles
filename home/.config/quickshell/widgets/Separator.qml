// ~/.config/quickshell/widgets/Separator.qml
// Волосяная линия между модулями внутри общего острова. У боковой панели
// ложится поперёк — иначе отделяла бы не то.
//
// Без anchors намеренно: модули лежат в Grid, а он не терпит привязок у
// своих детей и просто перестаёт работать.

import QtQuick
import qs

Rectangle {
    implicitWidth: Theme.barVertical ? 16 : 1
    implicitHeight: Theme.barVertical ? 1 : 16
    color: Theme.alpha(Colors.outlineVariant, 0.7)
}
