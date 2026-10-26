// ~/.config/quickshell/bar/Tray.qml
// Системный трей (StatusNotifierItem).
// ЛКМ — активировать, ПКМ — контекстное меню приложения, СКМ — вторичное действие.

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs
import qs.widgets

BarItem {
    id: root

    // пустой модуль не показываем
    visible: SystemTray.items.values.length > 0

    horizontalPadding: 10
    spacing: 10

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property var modelData

            implicitWidth: 18
            implicitHeight: 18
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

            onClicked: mouse => {
                Menus.clicked(item);

                if (mouse.button === Qt.MiddleButton) {
                    item.modelData.secondaryActivate();
                } else if (mouse.button === Qt.RightButton || item.modelData.onlyMenu) {
                    if (item.modelData.hasMenu) menu.toggle();
                } else {
                    item.modelData.activate();
                }
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
                asynchronous: true
                opacity: menu.opened ? 0.6 : 1

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animDuration }
                }
            }

            TrayMenu {
                id: menu
                anchorItem: item
                trayItem: item.modelData
                preferredWidth: 240
            }
        }
    }
}
