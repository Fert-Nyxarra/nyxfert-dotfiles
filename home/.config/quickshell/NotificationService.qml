pragma Singleton

// ~/.config/quickshell/NotificationService.qml
// Сервер уведомлений freedesktop. До него в системе демона уведомлений не
// было вовсе, поэтому notify-send молчал.
//
// Уведомление живёт, только пока tracked: без этого сервер выбрасывает его
// сразу после показа. Список храним не сами — берём из trackedNotifications,
// тогда закрытие уведомления чистит список само.
//
// ВАЖНО: pragma Singleton первой строкой, см. README, раздел «Грабли».

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    // новые сверху
    readonly property var list: server.trackedNotifications
        ? [...server.trackedNotifications.values].reverse()
        : []

    readonly property int count: root.list.length

    // время прихода по id: в самом уведомлении его нет
    property var times: ({})

    // «Не беспокоить»: плашки молчат, но уведомления копятся в центре.
    //
    // Флаг лежит на диске, а не в памяти: matugen переписывает Colors.qml,
    // quickshell на это перезагружает конфиг, и состояние синглтона
    // обнулилось бы посреди дня.
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

    // «по умолчанию» — действие, которое вешают на клик по уведомлению
    function defaultAction(notification) {
        if (!notification) return null;
        return notification.actions.find(a => a.identifier === "default") ?? null;
    }

    // каталог состояния может ещё не существовать
    Process {
        running: true
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell"]
    }

    FileView {
        id: store

        path: Quickshell.env("HOME") + "/.local/state/quickshell/notifications.json"
        watchChanges: true
        onFileChanged: store.reload()

        // файла может не быть — это нормально, тогда просто тишина выключена
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
