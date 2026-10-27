import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs
import qs.widgets

Rectangle {
    id: root

    required property var notification

    readonly property bool critical: root.notification
        && root.notification.urgency === NotificationUrgency.Critical

    signal activated
    signal dismissed

    implicitHeight: column.implicitHeight + 20
    radius: Theme.rowRadius

    color: mouse.containsMouse
        ? Theme.alpha(Colors.text, 0.10)
        : Theme.alpha(Colors.surfaceContainerHigh, 0.7)

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Rectangle {
        x: 0
        y: 8
        width: 3
        height: parent.height - 16
        radius: 1.5
        visible: root.critical
        color: Colors.error
    }

    readonly property string iconSource: {
        const n = root.notification;
        if (!n) return "";
        if (n.image !== "") return n.image;

        if (n.appIcon !== "") {
            const path = Quickshell.iconPath(n.appIcon, true);
            if (path !== "") return path;
        }

        if (n.desktopEntry !== "") {
            const path = Quickshell.iconPath(n.desktopEntry, true);
            if (path !== "") return path;
        }

        return "";
    }

    IconImage {
        id: icon

        x: 12
        y: 12
        implicitSize: 26
        asynchronous: true
        visible: root.iconSource !== ""
        source: root.iconSource
    }

    Text {
        x: 12
        y: 12
        width: 26
        height: 26
        visible: root.iconSource === ""
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: root.critical ? "󰀪" : "󰂚"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 6
        color: root.critical ? Colors.error : Colors.primary
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.dismissed();
            else root.activated();
        }
    }

    Text {
        id: closeButton

        x: parent.width - width - 10
        y: 10
        opacity: mouse.containsMouse || closeMouse.containsMouse ? 1 : 0

        text: "󰅖"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: closeMouse.containsMouse ? Colors.error : Colors.subtext

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        MouseArea {
            id: closeMouse
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dismissed()
        }
    }

    Column {
        id: column

        x: 48
        y: 10
        width: parent.width - x - 34
        spacing: 2

        Row {
            width: parent.width
            spacing: 6

            Text {
                width: Math.min(implicitWidth, parent.width - timeText.width - 6)
                text: root.notification ? root.notification.appName : ""
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                font.weight: Font.DemiBold
                color: root.critical ? Colors.error : Colors.primary
            }

            Text {
                id: timeText
                text: root.notification ? NotificationService.timeOf(root.notification) : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                color: Colors.outline
            }
        }

        Text {
            width: parent.width
            visible: root.notification && root.notification.summary !== ""
            text: root.notification ? root.notification.summary : ""
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.DemiBold
            color: Colors.text
        }

        Text {
            width: parent.width
            visible: root.notification && root.notification.body !== ""
            text: root.notification ? root.notification.body : ""
            textFormat: Text.StyledText
            elide: Text.ElideRight
            maximumLineCount: 4
            wrapMode: Text.Wrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Colors.subtext
        }

        Row {
            spacing: 6
            topPadding: 4
            visible: repeater.count > 0

            Repeater {
                id: repeater
                model: root.notification
                    ? root.notification.actions.filter(a => a.identifier !== "default")
                    : []

                Rectangle {
                    required property var modelData

                    implicitWidth: actionText.implicitWidth + 20
                    implicitHeight: 24
                    radius: 12
                    color: actionMouse.containsMouse
                        ? Theme.alpha(Colors.primary, 0.3)
                        : Theme.alpha(Colors.primary, 0.16)

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        color: Colors.primary
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.invoke();
                            root.dismissed();
                        }
                    }
                }
            }
        }
    }
}
