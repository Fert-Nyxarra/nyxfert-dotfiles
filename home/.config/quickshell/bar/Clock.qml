// ~/.config/quickshell/bar/Clock.qml
// Часы. Клик переключает время <-> полную дату, наведение открывает календарь.
//
// Календарь — отдельное окно, поэтому курсор, переходя в него, перестаёт быть
// над часами. Открытым меню считается, пока курсор над часами ИЛИ над самим
// календарём; таймеры гасят дрожание на границе.

import QtQuick
import Quickshell
import qs
import qs.widgets

BarItem {
    id: root

    property bool showDate: false

    readonly property bool wantCalendar: root.hovered || calendar.hovered

    horizontalPadding: 16
    interactive: true
    active: calendar.opened

    onClicked: root.showDate = !root.showDate

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
        font.pixelSize: Theme.fontSize + 1
        text: root.showDate
            ? "󰃭 " + clock.date.toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM yyyy")
            : "󰥔 " + Qt.formatDateTime(clock.date, "HH:mm")
    }
}
