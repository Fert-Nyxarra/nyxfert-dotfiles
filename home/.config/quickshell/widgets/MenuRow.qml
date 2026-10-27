import QtQuick
import Quickshell.Widgets
import qs

Rectangle {
    id: root

    property string glyph: ""
    property string iconSource: ""
    property string label: ""
    property string trailing: ""
    property bool submenu: false
    property bool highlight: false
    property bool rowEnabled: true

    property color labelColor: root.highlight ? Colors.primary : Colors.text

    signal clicked
    signal rightClicked

    readonly property bool hasLeading: root.glyph !== "" || root.iconSource !== ""

    implicitHeight: Theme.rowHeight
    implicitWidth: 10 + (hasLeading ? 26 : 0) + labelText.implicitWidth
                 + (trailing !== "" ? trailingText.implicitWidth + 10 : 0)
                 + (submenu ? 18 : 0) + 10

    radius: Theme.rowRadius
    opacity: root.rowEnabled ? 1 : 0.4

    color: mouse.containsMouse && root.rowEnabled
        ? Theme.alpha(Colors.text, 0.10)
        : root.highlight ? Theme.alpha(Colors.primary, 0.14)
        : "transparent"

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Text {
        id: glyphText

        x: 10
        anchors.verticalCenter: parent.verticalCenter
        visible: root.glyph !== ""
        width: 18
        horizontalAlignment: Text.AlignHCenter

        text: root.glyph
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize + 1
        color: root.labelColor
    }

    IconImage {
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        implicitSize: 18
        visible: root.iconSource !== "" && root.glyph === ""
        source: root.iconSource
        asynchronous: true
    }

    Text {
        id: labelText

        x: root.hasLeading ? 36 : 10
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, (root.submenu ? arrow.x : trailingText.x) - x - 8)

        text: root.label
        elide: Text.ElideRight
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: root.highlight ? Font.DemiBold : Font.Normal
        color: root.labelColor
    }

    Text {
        id: trailingText

        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - (root.submenu ? 26 : 10)

        text: root.trailing
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
        color: Colors.subtext
    }

    Text {
        id: arrow

        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - 10
        visible: root.submenu

        text: "󰅂"
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Colors.subtext
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.rowEnabled
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) root.rightClicked();
            else root.clicked();
        }
    }
}
