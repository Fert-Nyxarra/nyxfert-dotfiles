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
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string statePath: root.stateDir + "/settings.json"

    readonly property var barPositions: ["top", "bottom", "left", "right"]
    readonly property var barModes: ["island", "panel"]

    // Оформление окон живёт в Hyprland, а не в панели. Храним выбор у себя и
    // раздаём компоновщику через hyprctl: править hyprland.lua опаснее (это
    // код, а не набор ключей), да и вернуть прежнее значение из окна настроек
    // так проще.
    readonly property var windowAnimations: ["off", "slide", "popin", "fast"]

    readonly property int windowBorderMax: 12
    readonly property int windowRoundingMax: 24

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

    readonly property int windowBorder: store.adapter
        ? Math.max(0, Math.min(root.windowBorderMax, store.adapter.windowBorder))
        : 3

    readonly property int windowRounding: store.adapter
        ? Math.max(0, Math.min(root.windowRoundingMax, store.adapter.windowRounding))
        : 0

    readonly property string windowAnimation: store.adapter
        && root.windowAnimations.indexOf(store.adapter.windowAnimation) >= 0
        ? store.adapter.windowAnimation
        : "slide"

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

    function setWindowBorder(value: int): void {
        if (!store.adapter) return;

        store.adapter.windowBorder = Math.max(0, Math.min(root.windowBorderMax, value));
        store.writeAdapter();
        root.applyWindowStyle();
    }

    function setWindowRounding(value: int): void {
        if (!store.adapter) return;

        store.adapter.windowRounding = Math.max(0, Math.min(root.windowRoundingMax, value));
        store.writeAdapter();
        root.applyWindowStyle();
    }

    function setWindowAnimation(value: string): void {
        if (root.windowAnimations.indexOf(value) < 0) return;
        if (!store.adapter) return;

        store.adapter.windowAnimation = value;
        store.writeAdapter();
        root.applyWindowStyle();
    }

    // Кусок конфига на Lua для hyprctl eval. Кривые smooth и overshoot
    // объявлены в hyprland.lua.
    function animationSnippet(kind: string): string {
        if (kind === "off") {
            return 'hl.animation({ leaf = "windows", enabled = false })';
        }

        if (kind === "popin") {
            return 'hl.animation({ leaf = "windows", enabled = true, speed = 4,'
                + ' bezier = "overshoot", style = "popin 80%" })';
        }

        if (kind === "fast") {
            return 'hl.animation({ leaf = "windows", enabled = true, speed = 2,'
                + ' bezier = "smooth", style = "popin 95%" })';
        }

        return 'hl.animation({ leaf = "windows", enabled = true, speed = 3.5,'
            + ' bezier = "overshoot", style = "slide" })';
    }

    // Применяем через `hyprctl eval`, а не `hyprctl keyword`: конфиг у нас на
    // Lua, и keyword на него отвечает «can't work with non-legacy parsers».
    function applyWindowStyle(): void {
        applyProcess.command = ["hyprctl", "eval",
            "hl.config({ general = { border_size = " + root.windowBorder + " },"
            + " decoration = { rounding = " + root.windowRounding + " } }) "
            + root.animationSnippet(root.windowAnimation)];
        applyProcess.running = true;
    }

    function setBarMode(value: string): void {
        if (root.barModes.indexOf(value) < 0) return;
        if (!store.adapter) return;

        store.adapter.barMode = value;
        store.writeAdapter();
    }

    Process { id: applyProcess }

    // Настройки раздаются компоновщику при запуске и после каждой его
    // перезагрузки: `hyprctl reload` (его зовёт matugen после смены обоев)
    // возвращает значения из hyprland.lua и затирает наши.
    onLoadedChanged: if (root.loaded) root.applyWindowStyle()

    // Значения могли измениться не только из окна настроек, но и правкой
    // файла руками — раздаём компоновщику любое изменение.
    onWindowBorderChanged: if (root.loaded) root.applyWindowStyle()
    onWindowRoundingChanged: if (root.loaded) root.applyWindowStyle()
    onWindowAnimationChanged: if (root.loaded) root.applyWindowStyle()

    Connections {
        target: Hyprland

        function onRawEvent(event): void {
            if (event.name === "configreloaded") root.applyWindowStyle();
        }
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

            property int windowBorder: 3
            property int windowRounding: 0
            property string windowAnimation: "slide"
        }
    }
}
