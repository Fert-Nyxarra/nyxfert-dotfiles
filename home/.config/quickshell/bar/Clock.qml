// ~/.config/quickshell/bar/Clock.qml
// Часы и дата рядом, разделённые волосяной линией. Наведение открывает
// календарь.
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

    readonly property bool wantCalendar: root.hovered || calendar.hovered

    horizontalPadding: 16
    // interactive нужен ради подсветки под курсором: клик больше ничего не
    // переключает, время и дата видны сразу
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

        // У боковой панели всего 38 пикселей ширины: «󰥔 14:20» туда не
        // влезает, поэтому время идёт в две строки и без значка.
        font.pixelSize: Theme.barVertical ? Theme.fontSize - 1 : Theme.fontSize + 1
        lineHeight: Theme.barVertical ? 0.95 : 1

        text: Theme.barVertical
            ? Qt.formatDateTime(clock.date, "HH\nmm")
            : "󰥔 " + Qt.formatDateTime(clock.date, "HH:mm")
    }

    // Разделитель между временем и датой — тот же, что между модулями: у
    // боковой панели он сам ложится поперёк.
    Separator {}

    BarText {
        color: Colors.subtext
        horizontalAlignment: Text.AlignHCenter

        font.pixelSize: Theme.barVertical ? Theme.fontSize - 2 : Theme.fontSize
        lineHeight: Theme.barVertical ? 0.95 : 1

        // Полная дата занимает полпанели, поэтому короткая форма: «ср, 25 окт».
        // Боком не помещается и она — там только день и месяц цифрами.
        text: Theme.barVertical
            ? Qt.formatDateTime(clock.date, "dd\nMM")
            : "󰃭 " + clock.date.toLocaleDateString(Qt.locale("ru_RU"), "ddd, d MMM")
    }
}
