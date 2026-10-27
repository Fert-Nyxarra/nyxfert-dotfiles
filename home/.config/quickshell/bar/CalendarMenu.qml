import QtQuick
import Quickshell
import qs
import qs.widgets

Popup {
    id: root

    readonly property int cellSize: 34

    property int monthOffset: 0

    grabFocus: false
    preferredWidth: root.cellSize * 7 + Theme.popupPadding * 2
    title: root.capitalize(clock.date.toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM yyyy"))

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function capitalize(text: string): string {
        return text.charAt(0).toUpperCase() + text.slice(1);
    }

    function sameDay(a, b): bool {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }

    readonly property string monthName: root.capitalize(
        Qt.locale("ru_RU").standaloneMonthName(root.viewDate.getMonth(), Locale.LongFormat))
        + " " + root.viewDate.getFullYear()

    readonly property var viewDate: new Date(
        clock.date.getFullYear(), clock.date.getMonth() + root.monthOffset, 1)

    readonly property var days: {
        const first = root.viewDate;
        const shift = (first.getDay() + 6) % 7;
        const list = [];

        for (let i = 0; i < 42; i++)
            list.push(new Date(first.getFullYear(), first.getMonth(), 1 - shift + i));

        return list;
    }

    onOpenedChanged: if (!root.opened) root.monthOffset = 0

    component NavButton: Rectangle {
        id: navButton

        property string glyph: ""

        signal clicked

        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: navMouse.containsMouse ? Theme.alpha(Colors.text, 0.12) : "transparent"

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            anchors.centerIn: parent
            text: navButton.glyph
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Colors.subtext
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: navButton.clicked()
        }
    }

    Item {
        width: root.contentWidth
        implicitHeight: 32

        NavButton {
            x: 4
            anchors.verticalCenter: parent.verticalCenter
            glyph: "\u{f0141}"
            onClicked: root.monthOffset--
        }

        Text {
            anchors.centerIn: parent

            text: root.monthName
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.DemiBold
            color: root.monthOffset === 0 ? Colors.text : Colors.primary

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.monthOffset !== 0
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monthOffset = 0
            }
        }

        NavButton {
            x: parent.width - width - 4
            anchors.verticalCenter: parent.verticalCenter
            glyph: "\u{f0142}"
            onClicked: root.monthOffset++
        }
    }

    Row {
        width: root.contentWidth

        Repeater {
            model: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

            Text {
                required property string modelData
                required property int index

                width: root.cellSize
                height: 22
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                text: modelData
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                font.weight: Font.DemiBold
                color: index >= 5 ? Theme.alpha(Colors.tertiary, 0.8) : Colors.subtext
            }
        }
    }

    Grid {
        width: root.contentWidth
        columns: 7

        Repeater {
            model: root.days

            Item {
                id: cell

                required property var modelData

                readonly property bool today: root.sameDay(modelData, clock.date)
                readonly property bool thisMonth: modelData.getMonth() === root.viewDate.getMonth()
                readonly property bool weekend: modelData.getDay() === 0 || modelData.getDay() === 6

                implicitWidth: root.cellSize
                implicitHeight: root.cellSize - 4

                Rectangle {
                    anchors.centerIn: parent
                    implicitWidth: 26
                    implicitHeight: 26
                    width: 26
                    height: 26
                    radius: 13

                    color: cell.today ? Colors.primary
                         : hover.hovered && cell.thisMonth ? Theme.alpha(Colors.text, 0.10)
                         : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }

                    HoverHandler { id: hover }
                }

                Text {
                    anchors.centerIn: parent

                    text: cell.modelData.getDate()
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    font.weight: cell.today ? Font.Bold : Font.Normal

                    color: cell.today ? Colors.textOnPrimary
                         : !cell.thisMonth ? Theme.alpha(Colors.outline, 0.55)
                         : cell.weekend ? Colors.tertiary
                         : Colors.text
                }
            }
        }
    }
}
