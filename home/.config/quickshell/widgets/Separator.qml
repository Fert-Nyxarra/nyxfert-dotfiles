import QtQuick
import qs

Rectangle {
    implicitWidth: Theme.barVertical ? 16 : 1
    implicitHeight: Theme.barVertical ? 1 : 16
    color: Theme.alpha(Colors.outlineVariant, 0.7)
}
