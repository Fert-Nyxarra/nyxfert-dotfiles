import QtQuick
import qs
import qs.widgets

BarItem {
    id: root

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

    Connections {
        target: NotificationService

        function onArrived(notification): void {
            if (NotificationService.dnd) return;
            if (!center.opened) toast.show(notification);
        }
    }

    BarText {
        color: NotificationService.dnd
            ? Colors.subtext
            : root.count > 0 ? Colors.primary : Colors.subtext

        text: (NotificationService.dnd
                ? "󰂛 "
                : root.count > 0 ? "󱅫 " : "󰂚 ")
            + (root.count > 0 && !Theme.barVertical ? root.count : "")
    }
}
