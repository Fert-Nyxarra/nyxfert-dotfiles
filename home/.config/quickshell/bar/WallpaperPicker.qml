// ~/.config/quickshell/bar/WallpaperPicker.qml
// Выбор обоев: слайды со стрелками, палитра для «приоритетного» цвета
// matugen и применение по Enter.
//
// Это собственный слой, а не окно Hyprland: окном оно получало фокус и
// анимацию компоновщика, но вело себя не так, как нужно. Анимацию открытия
// рисуем сами — выезд с лёгким перелётом, в тон остальной панели.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.widgets

PanelWindow {
    id: root

    property bool opened: false
    property int index: 0
    // пустая строка — цвет подбирает сам matugen
    property string selectedColor: ""
    // -1 глубже и насыщеннее, 0 стандарт Material You, 1 бледнее
    property real contrast: 0
    // чёрно-белая схема: ни оттенок, ни контраст на неё не влияют
    property bool mono: false

    // Параметры кольца держим здесь: на id внутри карточки ссылаться
    // нельзя — её содержимое создаётся только при первом показе окна.
    readonly property int hueSteps: 16

    function hueColor(index: int): color {
        return Qt.hsva(index / root.hueSteps, 0.68, 0.92, 1);
    }

    // схема из matugen для превью: роль -> цвет тёмной темы
    property var previewTheme: null

    function tone(role: string, fallback: color): color {
        if (!root.previewTheme) return fallback;

        const value = root.previewTheme[role];
        return value !== undefined ? value : fallback;
    }

    // какой сектор кольца соответствует выбранному цвету (-1 — никакой:
    // цвет либо «авто», либо закреплён ещё старой палитрой)
    readonly property int selectedHue: {
        if (root.selectedColor === "") return -1;

        for (let i = 0; i < root.hueSteps; i++) {
            if (root.hueColor(i).toString() === root.selectedColor) return i;
        }

        return -1;
    }

    // строка поиска: фильтруем по имени файла, регистр не важен
    property string query: ""

    readonly property var files: {
        if (root.query === "") return WallpaperService.files;

        const needle = root.query.toLowerCase();
        return WallpaperService.files.filter(path =>
            path.slice(path.lastIndexOf("/") + 1).toLowerCase().includes(needle));
    }
    readonly property string current: root.files.length > 0
        ? root.files[Math.max(0, Math.min(root.files.length - 1, root.index))]
        : ""

    readonly property string fileName: root.current === ""
        ? ""
        : root.current.slice(root.current.lastIndexOf("/") + 1)

    WlrLayershell.namespace: "quickshell:wallpapers"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function open(): void {
        // открываемся на текущих обоях и их закреплённом цвете
        root.query = "";

        const at = root.files.indexOf(WallpaperService.current);
        root.index = at >= 0 ? at : 0;
        root.selectedColor = WallpaperService.colorFor(root.current);
        root.contrast = WallpaperService.contrastFor(root.current);
        root.mono = WallpaperService.monoFor(root.current);
        root.visible = true;
        // Behaviors должны увидеть переход 0 → 1. На момент первого показа
        // сцена только создаётся, и если поднять флаг тут же, карточка
        // родится уже открытой и просто мигнёт. Поэтому — следующим кадром.
        showTimer.restart();
    }

    function close(): void {
        root.opened = false;
    }

    function toggle(): void {
        if (root.opened) root.close();
        else root.open();
    }

    function step(delta: int): void {
        if (root.files.length === 0) return;

        root.index = (root.index + delta + root.files.length) % root.files.length;
    }

    function applyCurrent(): void {
        if (root.current === "") return;

        WallpaperService.pin(root.current, root.selectedColor, root.contrast, root.mono);
        WallpaperService.apply(root.current);
        root.close();
    }

    // Превью считает сам matugen в режиме --dry-run: он печатает схему в
    // JSON и при этом не трогает ни шаблоны, ни обои, ни запущенные
    // программы. Значит, в карточке видно ровно то, что применится.
    function refreshPreview(): void {
        if (root.current === "") return;

        previewProcess.command = ["matugen", "--dry-run", "-j", "hex"].concat(
            WallpaperService.matugenArgs(root.current, root.selectedColor,
                                         root.contrast, root.mono));
        previewProcess.running = true;
    }

    // листание и ручка контраста сыплют изменениями пачками, поэтому
    // запускаем matugen не на каждое, а через паузу
    Timer {
        id: previewTimer
        interval: 180
        onTriggered: root.refreshPreview()
    }

    onSelectedColorChanged: previewTimer.restart()
    onContrastChanged: previewTimer.restart()
    onMonoChanged: previewTimer.restart()
    onCurrentChanged: {
        root.selectedColor = WallpaperService.colorFor(root.current);
        root.contrast = WallpaperService.contrastFor(root.current);
        root.mono = WallpaperService.monoFor(root.current);
        previewTimer.restart();
    }

    // после фильтра показываем первое совпадение
    onQueryChanged: root.index = 0

    Process {
        id: previewProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(this.text);
                    const dark = {};

                    for (const role in data.colors) dark[role] = data.colors[role].dark.color;

                    root.previewTheme = dark;
                } catch (error) {
                    // matugen мог не разобрать картинку — оставляем прошлое
                    // превью, пустая карточка хуже устаревшей
                }
            }
        }
    }

    Connections {
        target: WallpaperService

        function onToggleRequested(): void {
            root.toggle();
        }
    }

    Timer {
        id: showTimer
        interval: 16
        onTriggered: if (root.visible) root.opened = true
    }

    // окно живёт, пока карточка не доиграла уход
    Timer {
        id: hideTimer
        interval: 260
        onTriggered: if (!root.opened) root.visible = false
    }

    onOpenedChanged: {
        if (root.opened) root.refreshPreview();
        else hideTimer.restart();
    }

    // затемнения нет: ловим только клик мимо карточки
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }


    Rectangle {
        id: card

        anchors.centerIn: parent
        width: Math.min(880, root.width - 120)
        height: stage.height + 446
        radius: Theme.popupRadius
        color: Theme.panelColor
        border.width: 1
        border.color: Theme.panelBorder

        // Появление: короткий выезд снизу с лёгким перелётом плюс проявление.
        // Пружина на смещении и масштабе, прозрачность быстрее — иначе
        // карточка кажется тяжёлой.
        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.93
        anchors.verticalCenterOffset: root.opened ? 0 : 26

        Behavior on opacity {
            NumberAnimation {
                duration: root.opened ? 150 : 140
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: root.opened ? 330 : 180
                easing.type: root.opened ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 1.5
            }
        }

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: root.opened ? 330 : 180
                easing.type: root.opened ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 1.2
            }
        }

        // клик по карточке не должен закрывать окно
        MouseArea {
            anchors.fill: parent
        }

        // Поиск по имени файла. Сетку миниатюр сюда уже не впихнуть —
        // карточка и так большая, а строка решает ту же задачу: добраться
        // до нужных обоев, не листая всю папку.
        Rectangle {
            id: searchBox

            x: 12
            y: 12
            width: 320
            height: 34
            radius: 10
            color: Theme.alpha(Colors.surfaceContainerHigh, 0.9)
            border.width: 1
            border.color: search.activeFocus
                ? Theme.alpha(Colors.primary, 0.6)
                : Theme.panelBorder

            Text {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "󰍉"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Colors.subtext
            }

            TextInput {
                id: search

                x: 38
                width: parent.width - 50
                anchors.verticalCenter: parent.verticalCenter
                focus: true
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Colors.text
                selectionColor: Theme.alpha(Colors.primary, 0.4)
                selectedTextColor: Colors.text
                clip: true

                onTextChanged: root.query = text

                // Клавиатуру забирает поле, поэтому листание и применение
                // разбираются здесь же. Стрелки отданы слайдам: имена файлов
                // короткие, курсор внутри строки двигать незачем.
                Keys.onPressed: event => {
                    event.accepted = true;

                    if (event.key === Qt.Key_Escape) {
                        if (search.text !== "") search.text = "";
                        else root.close();
                    } else if (event.key === Qt.Key_Left) root.step(-1);
                    else if (event.key === Qt.Key_Right) root.step(1);
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.applyCurrent();
                    else event.accepted = false;
                }
            }

            Text {
                x: 38
                anchors.verticalCenter: parent.verticalCenter
                visible: search.text === ""
                text: "поиск по имени"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Colors.outline
            }
        }

        // счётчик — в ту же строку, справа
        Text {
            x: card.width - width - 16
            anchors.verticalCenter: searchBox.verticalCenter
            text: root.files.length === 0
                ? (root.query === "" ? "папка пуста" : "ничего не найдено")
                : (root.index + 1) + " / " + root.files.length
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            color: Colors.subtext
        }

        // слайды
        Item {
            id: stage

            x: 12
            y: searchBox.y + searchBox.height + 12
            width: parent.width - 24
            // на невысоких экранах предпросмотр ужимаем, иначе карточка
            // не влезет вместе с кольцом
            height: Math.min(Math.round(width * 9 / 16), root.height - 546)
            clip: true

            Row {
                x: -root.index * stage.width

                Behavior on x {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }

                Repeater {
                    model: root.files

                    Image {
                        required property string modelData

                        width: stage.width
                        height: stage.height
                        source: "file://" + modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 1280
                    }
                }
            }
        }

        // подпись
        Text {
            x: 16
            y: stage.y + stage.height + 12
            text: root.fileName
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            font.weight: Font.DemiBold
            color: Colors.text
        }

        // кольцо оттенков, в середине — «авто»
        Item {
            id: controls

            x: 16
            y: stage.y + stage.height + 44
            width: card.width - 32
            height: 192

            HueWheel {
                id: wheel

                y: (controls.height - height) / 2
                width: 160
                height: 160
                enabled: !root.mono
                opacity: root.mono ? 0.3 : 1

                Behavior on opacity {
                    NumberAnimation { duration: 160 }
                }
                steps: root.hueSteps
                selected: root.selectedHue

                onPicked: (index, value) => root.selectedColor = value.toString()
            }

            // дырка кольца: цвет подбирает сам matugen по картинке
            Rectangle {
                id: autoButton

                readonly property bool active: root.selectedColor === ""

                x: wheel.x + (wheel.width - width) / 2
                y: wheel.y + (wheel.height - height) / 2
                enabled: !root.mono
                opacity: root.mono ? 0.3 : 1
                width: Math.round(wheel.innerRadius * 1.5)
                height: width
                radius: width / 2

                color: autoMouse.containsMouse || autoButton.active
                    ? Theme.alpha(Colors.surfaceContainerHigh, 0.95)
                    : Theme.alpha(Colors.surfaceContainer, 0.95)
                border.width: autoButton.active ? 2 : 1
                border.color: autoButton.active ? Colors.primary : Theme.panelBorder

                Text {
                    anchors.centerIn: parent
                    text: "авто"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: autoButton.active ? Colors.primary : Colors.subtext
                }

                MouseArea {
                    id: autoMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedColor = ""
                }
            }

            // выбранный акцент и ручка контраста
            Column {
                x: 192
                y: 6
                width: controls.width - 192
                spacing: 12

                Row {
                    spacing: 10
                    enabled: !root.mono
                    opacity: root.mono ? 0.3 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: 160 }
                    }

                    Rectangle {
                        width: 26
                        height: 26
                        radius: 8
                        color: root.selectedColor === ""
                            ? Theme.alpha(Colors.surfaceContainerHigh, 0.9)
                            : root.selectedColor
                        border.width: 1
                        border.color: Theme.panelBorder
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.selectedColor === ""
                            ? "акцент по картинке"
                            : "акцент " + root.selectedColor
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        color: Colors.text
                    }
                }

                // Чёрно-белая тема — отдельный переключатель, а не ещё
                // один цвет в кольце: matugen строит её другой схемой, и ни
                // оттенок, ни контраст на неё не влияют. Поэтому всё
                // остальное при включении гаснет.
                // MouseArea с anchors.fill внутри Row ломает сам Row —
                // поэтому строка завёрнута в Item, а обработчик лежит
                // поверх него.
                Item {
                    width: monoRow.implicitWidth
                    height: monoRow.implicitHeight

                    Row {
                        id: monoRow

                        spacing: 10

                        Rectangle {
                            id: monoBox

                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            radius: 7
                            color: root.mono ? Colors.primary : "transparent"
                            border.width: root.mono ? 0 : 2
                            border.color: monoMouse.containsMouse
                                ? Colors.subtext
                                : Theme.alpha(Colors.outline, 0.8)

                            Behavior on color {
                                ColorAnimation { duration: 140 }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "\u2713"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                color: Colors.textOnPrimary
                                opacity: root.mono ? 1 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: 140 }
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Чёрно-белая тема"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: root.mono ? Colors.text : Colors.subtext
                        }
                    }

                    MouseArea {
                        id: monoMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.mono = !root.mono
                    }
                }

                Text {
                    enabled: !root.mono
                    opacity: root.mono ? 0.3 : 1
                    text: "Контраст " + (root.contrast === 0
                        ? "0 · стандарт"
                        : (root.contrast > 0 ? "+" : "\u2212") + Math.abs(root.contrast).toFixed(1))
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Colors.text
                }

                // Ручка глубины: тон акцента в тёмной теме задан
                // спецификацией, и от исходного цвета выживает только
                // оттенок. Минус опускает тон — цвета становятся
                // насыщеннее, плюс поднимает — бледнее.
                Item {
                    id: contrastBar

                    readonly property real usable: width - handle.width

                    enabled: !root.mono
                    opacity: root.mono ? 0.3 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: 160 }
                    }

                    width: parent.width - 16
                    height: 26

                    function pick(x: real): void {
                        const at = Math.max(0, Math.min(1, (x - handle.width / 2) / contrastBar.usable));
                        root.contrast = Math.round((at * 2 - 1) * 10) / 10;
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: handle.width / 2
                        width: contrastBar.usable
                        height: 6
                        radius: 3
                        color: Theme.alpha(Colors.outline, 0.35)
                    }

                    // засечка стандартного значения
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: contrastBar.width / 2 - 1
                        width: 2
                        height: 12
                        radius: 1
                        color: Theme.alpha(Colors.outline, 0.7)
                    }

                    // заливка от середины к ручке
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.min(contrastBar.width / 2, handle.x + handle.width / 2)
                        width: Math.abs(handle.x + handle.width / 2 - contrastBar.width / 2)
                        height: 6
                        radius: 3
                        color: Theme.alpha(Colors.primary, 0.55)
                    }

                    Rectangle {
                        id: handle

                        anchors.verticalCenter: parent.verticalCenter
                        x: (root.contrast + 1) / 2 * contrastBar.usable
                        width: 20
                        height: 20
                        radius: 10
                        color: Colors.primary
                        scale: contrastMouse.containsMouse || contrastMouse.pressed ? 1.15 : 1

                        Behavior on x {
                            NumberAnimation {
                                duration: contrastMouse.pressed ? 0 : 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on scale {
                            NumberAnimation { duration: 120 }
                        }
                    }

                    MouseArea {
                        id: contrastMouse

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: event => contrastBar.pick(event.x)
                        onPositionChanged: event => {
                            if (contrastMouse.pressed) contrastBar.pick(event.x);
                        }
                        onDoubleClicked: root.contrast = 0
                    }
                }

                Text {
                    text: root.mono
                        ? "чёрно-белая схема не настраивается"
                        : "минус — глубже и насыщеннее, плюс — мягче и светлее, двойной клик сбрасывает"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    color: Colors.outline
                }
            }
        }

        // Превью будущей темы: мини-панель, образцы ролей и мок меню.
        // Всё рисуется цветами из matugen, а не текущими Colors — видно
        // результат до применения.
        Item {
            id: preview

            x: 16
            y: controls.y + controls.height + 14
            width: card.width - 32
            height: 92

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: root.tone("surface", Colors.surface)
                border.width: 1
                border.color: Theme.panelBorder
            }

            // остров панели
            Rectangle {
                id: mockBar

                x: 12
                y: 10
                width: preview.width - 24
                height: 34
                radius: 10
                color: root.tone("surface_container", Colors.surfaceContainer)
                border.width: 1
                border.color: root.tone("outline_variant", Colors.outline)

                Row {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12
                        height: 12
                        radius: 6
                        color: root.tone("primary", Colors.primary)
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 9
                        height: 9
                        radius: 4.5
                        color: root.tone("on_surface_variant", Colors.subtext)
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 7
                        height: 7
                        radius: 3.5
                        color: root.tone("outline", Colors.outline)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "12:34"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 1
                    color: root.tone("on_surface", Colors.text)
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Rectangle {
                        width: 28
                        height: 12
                        radius: 6
                        color: root.tone("secondary", Colors.subtext)
                    }

                    Rectangle {
                        width: 14
                        height: 12
                        radius: 6
                        color: root.tone("tertiary", Colors.primary)
                    }
                }
            }

            // образцы ролей
            Row {
                x: 12
                y: mockBar.y + mockBar.height + 10
                spacing: 6

                Repeater {
                    model: ["primary", "secondary", "tertiary", "error", "on_surface", "outline"]

                    Rectangle {
                        required property string modelData

                        width: 26
                        height: 26
                        radius: 8
                        color: root.tone(modelData, Colors.subtext)
                    }
                }
            }

            // мок контекстного меню
            Rectangle {
                x: preview.width - width - 12
                y: mockBar.y + mockBar.height + 8
                width: 230
                height: 30
                radius: 9
                color: root.tone("surface_container_high", Colors.surfaceContainerHigh)
                border.width: 1
                border.color: root.tone("outline_variant", Colors.outline)

                Rectangle {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: 9
                    height: 9
                    radius: 4.5
                    color: root.tone("primary", Colors.primary)
                }

                Rectangle {
                    x: 30
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    height: 6
                    radius: 3
                    color: root.tone("on_surface", Colors.text)
                }

                Rectangle {
                    x: 152
                    anchors.verticalCenter: parent.verticalCenter
                    width: 62
                    height: 6
                    radius: 3
                    color: root.tone("on_surface_variant", Colors.subtext)
                }
            }
        }

        Text {
            x: 16
            y: card.height - height - 12
            text: "← → листать · Enter применить · Esc очистить поиск или закрыть"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            color: Colors.outline
        }

        // применить мышью
        Rectangle {
            x: card.width - width - 16
            y: card.height - height - 10
            width: applyText.implicitWidth + 28
            height: 32
            radius: 10
            color: applyMouse.containsMouse
                ? Theme.alpha(Colors.primary, 0.35)
                : Theme.alpha(Colors.primary, 0.18)

            Text {
                id: applyText
                anchors.centerIn: parent
                text: "Применить"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Colors.primary
            }

            MouseArea {
                id: applyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.applyCurrent()
            }
        }
    }
}
