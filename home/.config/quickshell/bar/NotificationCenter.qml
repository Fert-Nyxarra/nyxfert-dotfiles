import QtQuick
import qs
import qs.widgets

Popup {
    id: root

    edgeInset: 0
    preferredWidth: 380
    maximumWidth: 380

    Item {
        width: root.contentWidth
        implicitHeight: 32

        Text {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "Уведомления"
                + (NotificationService.count > 0 ? " · " + NotificationService.count : "")
                + (NotificationService.dnd ? " · тихо" : "")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            font.weight: Font.Bold
            color: Colors.subtext
        }

        Row {
            x: parent.width - width - 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Rectangle {
                implicitWidth: 30
                implicitHeight: 24
                radius: 12

                color: NotificationService.dnd
                    ? Theme.alpha(Colors.primary, 0.22)
                    : dndMouse.containsMouse
                        ? Theme.alpha(Colors.text, 0.12)
                        : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 140 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰂛"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: NotificationService.dnd ? Colors.primary : Colors.subtext
                }

                MouseArea {
                    id: dndMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.toggleDnd()
                }
            }

            Rectangle {
                implicitWidth: clearText.implicitWidth + 18
                implicitHeight: 24
                radius: 12
                visible: NotificationService.count > 0
                color: clearMouse.containsMouse
                    ? Theme.alpha(Colors.text, 0.12)
                    : "transparent"

                Text {
                    id: clearText

                    anchors.centerIn: parent
                    text: "󰎟 Очистить"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: clearMouse.containsMouse ? Colors.error : Colors.subtext
                }

                MouseArea {
                    id: clearMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        NotificationService.dismissAll();
                        root.close();
                    }
                }
            }
        }
    }

    MenuSeparator { width: root.contentWidth }

    Repeater {
        model: NotificationService.list

        NotificationItem {
            required property var modelData

            width: root.contentWidth
            notification: modelData

            onActivated: {
                const action = NotificationService.defaultAction(modelData);
                if (action) action.invoke();
                modelData.dismiss();
            }

            onDismissed: modelData.dismiss()
        }
    }

    MenuRow {
        width: root.contentWidth
        visible: NotificationService.count === 0
        rowEnabled: false
        glyph: "󰂛"
        label: "Уведомлений нет"
    }
}
