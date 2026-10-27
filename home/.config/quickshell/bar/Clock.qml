import QtQuick
import Quickshell
import qs
import qs.widgets

BarItem {
    id: root

    readonly property bool wantCalendar: root.hovered || calendar.hovered

    horizontalPadding: 16

    interactive: true
    active: calendar.opened

    onWantCalendarChanged: {
        if (root.wantCalendar) {
            closeTimer.stop();
            if (!calendar.opened) openTimer.restart();
        } else {
            openTimer.stop();
            closeTimer.restart();
        }
    }

    Timer {
        id: openTimer
        interval: 260
        onTriggered: if (root.wantCalendar) calendar.open()
    }

    Timer {
        id: closeTimer
        interval: 260
        onTriggered: if (!root.wantCalendar) calendar.close()
    }

    CalendarMenu {
        id: calendar
        anchorItem: root
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BarText {
        color: Colors.text
        horizontalAlignment: Text.AlignHCenter

        font.pixelSize: Theme.barVertical ? Theme.fontSize - 1 : Theme.fontSize + 1
        lineHeight: Theme.barVertical ? 0.95 : 1

        text: Theme.barVertical
            ? Qt.formatDateTime(clock.date, "HH\nmm")
            : "󰥔 " + Qt.formatDateTime(clock.date, "HH:mm")
    }

    Separator {}

    BarText {
        color: Colors.subtext
        horizontalAlignment: Text.AlignHCenter

        font.pixelSize: Theme.barVertical ? Theme.fontSize - 2 : Theme.fontSize
        lineHeight: Theme.barVertical ? 0.95 : 1

        text: Theme.barVertical
            ? Qt.formatDateTime(clock.date, "dd\nMM")
            : "󰃭 " + clock.date.toLocaleDateString(Qt.locale("ru_RU"), "ddd, d MMM")
    }
}
