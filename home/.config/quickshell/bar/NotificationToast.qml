import QtQuick
import Quickshell.Services.Notifications
import qs
import qs.widgets

Popup {
    id: root

    property var notification: null

    edgeInset: 0
    preferredWidth: 380
    maximumWidth: 380
    managed: false
    grabFocus: false

    readonly property bool critical: root.notification
        && root.notification.urgency === NotificationUrgency.Critical

    function show(notification): void {
        root.notification = notification;
        root.open();

        if (root.critical) {
            hideTimer.stop();
            return;
        }

        const timeout = notification.expireTimeout > 0 ? notification.expireTimeout : 5000;
        hideTimer.interval = Math.max(3000, Math.min(10000, timeout));
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        onTriggered: root.close()
    }

    Timer {
        id: dismissTimer

        property var target: null

        interval: root.slideDuration + 60
        onTriggered: {
            if (dismissTimer.target) dismissTimer.target.dismiss();
            dismissTimer.target = null;
        }
    }

    function hideAndDismiss(): void {
        dismissTimer.target = root.notification;
        root.close();
        dismissTimer.restart();
    }

    Connections {
        target: NotificationService

        function onListChanged(): void {
            if (root.notification && !NotificationService.list.includes(root.notification))
                root.close();
        }
    }

    Loader {
        width: root.contentWidth
        active: root.notification !== null
        visible: active

        sourceComponent: NotificationItem {
            width: root.contentWidth
            notification: root.notification

            onActivated: {
                const action = NotificationService.defaultAction(root.notification);
                if (action) action.invoke();
                root.hideAndDismiss();
            }

            onDismissed: root.hideAndDismiss()
        }
    }
}
