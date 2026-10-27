import QtQuick
import qs

Item {
    id: root

    default property alias content: inner.data
    property alias spacing: inner.spacing

    property int horizontalPadding: Theme.padding
    property bool interactive: false
    property bool active: false

    readonly property bool hovered: hover.hovered

    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheel(int delta)

    implicitWidth: Theme.barVertical
        ? Theme.itemHeight
        : inner.implicitWidth + horizontalPadding * 2

    implicitHeight: Theme.barVertical
        ? inner.implicitHeight + horizontalPadding * 2
        : Theme.itemHeight

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

        HoverHandler { id: hover },

        MouseArea {
            anchors.fill: parent
            enabled: root.interactive
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: mouse => {

                Menus.clicked(root);

                if (mouse.button === Qt.RightButton) root.rightClicked();
                else if (mouse.button === Qt.MiddleButton) root.middleClicked();
                else root.clicked();
            }

            onWheel: event => root.wheel(event.angleDelta.y)
        },

        Grid {
            id: inner

            anchors.centerIn: parent
            spacing: Theme.gap

            flow: Theme.barVertical ? Grid.TopToBottom : Grid.LeftToRight

            rows: Theme.barVertical ? -1 : 1
            columns: Theme.barVertical ? 1 : -1

            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
        }
    ]
}
