pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property var list: server.trackedNotifications
        ? [...server.trackedNotifications.values].reverse()
        : []

    readonly property int count: root.list.length

    property var times: ({})

    readonly property bool dnd: store.adapter
        ? store.adapter.dnd === true
        : false

    function toggleDnd(): void {
        if (!store.adapter) return;

        store.adapter.dnd = !root.dnd;
        store.writeAdapter();
    }

    signal arrived(var notification)

    function dismissAll(): void {
        for (const n of [...root.list]) n.dismiss();
    }

    function timeOf(notification): string {
        if (!notification) return "";
        const t = root.times[notification.id];
        return t ? Qt.formatDateTime(t, "HH:mm") : "";
    }

    function defaultAction(notification) {
        if (!notification) return null;
        return notification.actions.find(a => a.identifier === "default") ?? null;
    }

    Process {
        running: true
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell"]
    }

    FileView {
        id: store

        path: Quickshell.env("HOME") + "/.local/state/quickshell/notifications.json"
        watchChanges: true
        onFileChanged: store.reload()

        onLoadFailed: store.writeAdapter()

        adapter: JsonAdapter {
            property bool dnd: false
        }
    }

    NotificationServer {
        id: server

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.times[notification.id] = new Date();
            root.arrived(notification);
        }
    }
}
