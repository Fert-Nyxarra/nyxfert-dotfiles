// ~/.config/quickshell/widgets/BarItem.qml
// Элемент панели. Раньше каждый модуль был отдельным «островком» со своим
// фоном и рамкой; теперь фон один — его рисует Bar.qml, — а элементы внутри
// плоские и подсвечиваются только под курсором или когда у них открыто меню.
//
// Порядок в data важен: ряд с содержимым идёт последним, то есть лежит ПОВЕРХ
// общей MouseArea. Иначе она перехватывала бы клики у вложенных MouseArea
// (точек рабочих столов, иконок трея).

import QtQuick
import qs

Item {
    id: root

    // всё, что объявлено внутри BarItem, попадает в ряд inner
    default property alias content: inner.data
    property alias spacing: inner.spacing

    property int horizontalPadding: Theme.padding
    property bool interactive: false
    property bool active: false        // подсветка: у элемента открыто меню

    readonly property bool hovered: hover.hovered

    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(int delta)

    implicitWidth: inner.implicitWidth + horizontalPadding * 2
    implicitHeight: Theme.itemHeight

    data: [
        Rectangle {
            anchors.fill: parent
            radius: Theme.itemRadius

            color: root.active ? Theme.alpha(Colors.primary, 0.22)
                 : root.interactive && root.hovered ? Theme.alpha(Colors.text, 0.09)
                 : "transparent"

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        },

        // HoverHandler, а не MouseArea.containsMouse: обработчик получает
        // наведение даже когда курсор стоит над вложенной MouseArea
        HoverHandler { id: hover },

        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: mouse => {
                // клик мимо «своего» модуля гасит открытое меню
                Menus.clicked(root);

                if (mouse.button === Qt.RightButton) root.rightClicked();
                else if (mouse.button === Qt.MiddleButton) root.middleClicked();
                else root.clicked();
            }

            onWheel: event => root.wheel(event.angleDelta.y)
        },

        Row {
            id: inner
            anchors.centerIn: parent
            spacing: Theme.gap
        }
    ]
}
