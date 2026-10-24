// ~/.config/quickshell/bar/Notifications.qml
// Центр уведомлений в панели: колокольчик со счётчиком.
// ЛКМ — открыть центр, ПКМ — убрать все уведомления.

import QtQuick
import qs
import qs.widgets

BarItem {
    id: root

    // по этому числу Bar гасит свой угол — синхронно с выездом меню; к краю
    // прижаты и центр, и плашка нового уведомления
    readonly property real menuProgress: Math.max(center.revealProgress, toast.revealProgress)

    readonly property int count: NotificationService.count

    horizontalPadding: 12
    interactive: true
    active: center.attached

    onClicked: center.toggle()
    onRightClicked: NotificationService.dismissAll()

    NotificationCenter {
        id: center
        anchorItem: root
    }

    NotificationToast {
        id: toast
        anchorItem: root
    }

    // пока центр открыт, плашки не нужны — уведомление и так видно в списке
    Connections {
        target: NotificationService

        function onArrived(notification): void {
            if (NotificationService.dnd) return; // тишина: уведомление уйдёт в центр
            if (!center.opened) toast.show(notification);
        }
    }

    BarText {
        color: NotificationService.dnd
            ? Colors.subtext
            : root.count > 0 ? Colors.primary : Colors.subtext

        // в тишине колокольчик перечёркнут, но счётчик остаётся — иначе
        // непонятно, что за время молчания что-то пришло
        text: (NotificationService.dnd
                ? "󰂛 "
                : root.count > 0 ? "󱅫 " : "󰂚 ")
            + (root.count > 0 ? root.count : "")
    }
}
