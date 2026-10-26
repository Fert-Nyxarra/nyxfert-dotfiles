pragma Singleton

// ~/.config/quickshell/Settings.qml
// Пользовательские настройки оболочки — то, что выбрано в окне CTRL + SUPER + S
// (bar/SettingsWindow.qml).
//
// Хранятся ВНЕ конфига, в ~/.local/state/quickshell/settings.json: matugen
// переписывает Colors.qml, quickshell на это перезагружает конфиг, и всё
// состояние синглтона обнулилось бы. Поэтому значения читаются прямо из файла,
// как и у обоев.
//
// ВАЖНО: pragma Singleton первой строкой, см. README, раздел «Грабли».

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string statePath: root.stateDir + "/settings.json"

    readonly property var barPositions: ["top", "bottom", "left", "right"]
    readonly property var barModes: ["island", "panel"]

    // Читаем прямо из адаптера: отдельное свойство со встречной записью
    // замыкает круг «изменилось здесь → изменилось там» и валит QML —
    // см. README, грабли про JsonAdapter.
    //
    // Значение из файла ещё и проверяется: в settings.json могли вписать
    // руками что угодно, а панель без положения не нарисуется вовсе.
    readonly property string barPosition: store.adapter
        && root.barPositions.indexOf(store.adapter.barPosition) >= 0
        ? store.adapter.barPosition
        : "top"

    readonly property string barMode: store.adapter
        && root.barModes.indexOf(store.adapter.barMode) >= 0
        ? store.adapter.barMode
        : "island"

    // панель стоит боком: модули идут столбиком, меню выезжают сбоку
    readonly property bool barVertical: root.barPosition === "left" || root.barPosition === "right"
    // панель у дальнего края: меню выезжают в обратную сторону
    readonly property bool barFlipped: root.barPosition === "bottom" || root.barPosition === "right"
    // «остров» — со скруглением и отступами, «панель» — во всю кромку
    readonly property bool barIsland: root.barMode === "island"

    // Настройки прочитаны (или точно не будут). Панель ждёт этого флага,
    // прежде чем показаться: слой wlr-layer-shell коммитит свои отступы при
    // первом показе, и пришедшее следом значение их уже не переставит —
    // получался остров с прямыми углами.
    property bool loaded: false

    // хоткей CTRL + SUPER + S приходит через IPC в shell.qml
    signal toggleRequested

    function toggle(): void {
        root.toggleRequested();
    }

    function setBarPosition(value: string): void {
        if (root.barPositions.indexOf(value) < 0) return;
        if (!store.adapter) return;

        store.adapter.barPosition = value;
        store.writeAdapter();
    }

    function setBarMode(value: string): void {
        if (root.barModes.indexOf(value) < 0) return;
        if (!store.adapter) return;

        store.adapter.barMode = value;
        store.writeAdapter();
    }

    // каталог для состояния может ещё не существовать
    Process {
        running: true
        command: ["mkdir", "-p", root.stateDir]
    }

    FileView {
        id: store

        path: root.statePath

        // Читаем СИНХРОННО: иначе панель успевает родиться со значениями по
        // умолчанию, слой коммитит островные отступы, а приехавший следом
        // «panel» меняет только то, что рисует QML. Получается остров с
        // прямыми углами — отступы уже не переставить.
        blockLoading: true

        watchChanges: true
        onFileChanged: store.reload()

        onLoaded: root.loaded = true

        // файла может не быть — это нормально, тогда остаются значения по
        // умолчанию, и они же сразу записываются
        onLoadFailed: {
            store.writeAdapter();
            root.loaded = true;
        }

        adapter: JsonAdapter {
            property string barPosition: "top"
            property string barMode: "island"
        }
    }
}
