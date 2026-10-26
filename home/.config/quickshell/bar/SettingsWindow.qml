// ~/.config/quickshell/bar/SettingsWindow.qml
// Настройки оболочки, CTRL + SUPER + S. Слева вкладки, справа содержимое.
//
// Пока вкладка одна — панель, — но список именно список: добавить следующую
// значит дописать строку в tabs и блок в содержимое.
//
// Как и у выбора обоев, это собственный слой, а не окно Hyprland: окном оно
// получает фокус и анимацию компоновщика, но ведёт себя не так, как нужно.
// Появление рисуем сами.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.widgets

PanelWindow {
    id: root

    property bool opened: false
    property int tab: 0

    readonly property var tabs: [
        { title: "Панель", hint: "положение и внешний вид" },
        { title: "Окна",   hint: "рамка, скругление, анимация" }
    ]

    WlrLayershell.namespace: "quickshell:settings"
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
        root.visible = true;
        // флаг поднимаем следующим кадром, иначе Behavior не увидит перехода
        // и карточка родится уже открытой — см. WallpaperPicker
        showTimer.restart();
    }

    function close(): void {
        root.opened = false;
    }

    function toggle(): void {
        if (root.opened) root.close();
        else root.open();
    }

    Connections {
        target: Settings

        function onToggleRequested(): void {
            root.toggle();
        }
    }

    Timer {
        id: showTimer
        interval: 16
        onTriggered: if (root.visible) root.opened = true
    }

    Timer {
        id: hideTimer
        interval: 260
        onTriggered: if (!root.opened) root.visible = false
    }

    onOpenedChanged: if (!root.opened) hideTimer.restart()

    // клик мимо карточки закрывает; затемнения нет
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.close();
                event.accepted = true;
            }
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 720
        height: 460
        radius: Theme.popupRadius
        color: Theme.panelColor
        border.width: 1
        border.color: Theme.panelBorder

        opacity: root.opened ? 1 : 0
        scale: root.opened ? 1 : 0.93
        anchors.verticalCenterOffset: root.opened ? 0 : 26

        Behavior on opacity {
            NumberAnimation { duration: root.opened ? 150 : 140; easing.type: Easing.OutCubic }
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

        //// вкладки ////////////////////////////////////////////////////////

        Rectangle {
            id: sidebar

            x: 1
            y: 1
            width: 190
            height: card.height - 2
            topLeftRadius: card.radius
            bottomLeftRadius: card.radius
            color: Theme.alpha(Colors.surfaceContainerHigh, 0.5)

            Text {
                x: 18
                y: 20
                text: "Настройки"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.DemiBold
                color: Colors.text
            }

            Column {
                x: 10
                y: 58
                width: parent.width - 20
                spacing: 4

                Repeater {
                    model: root.tabs

                    Rectangle {
                        required property var modelData
                        required property int index

                        width: parent.width
                        height: 40
                        radius: Theme.rowRadius

                        color: root.tab === index ? Theme.alpha(Colors.primary, 0.18)
                            : tabMouse.containsMouse ? Theme.alpha(Colors.text, 0.08)
                            : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        Text {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.title
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: root.tab === index ? Colors.primary : Colors.text
                        }

                        MouseArea {
                            id: tabMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tab = index
                        }
                    }
                }
            }

            Text {
                x: 18
                y: parent.height - height - 16
                width: parent.width - 36
                wrapMode: Text.WordWrap
                text: "Esc закрывает окно"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                color: Colors.outline
            }
        }

        //// содержимое вкладки «Панель» ////////////////////////////////////

        Item {
            id: page

            x: sidebar.width + 24
            y: 20
            width: card.width - sidebar.width - 48
            height: card.height - 40
            visible: root.tab === 0

            Text {
                id: pageTitle

                text: "Верхняя панель"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 3
                font.weight: Font.DemiBold
                color: Colors.text
            }

            Text {
                id: pageHint

                y: pageTitle.height + 4
                text: "Изменения применяются сразу"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                color: Colors.subtext
            }

            // положение
            Text {
                id: positionLabel

                y: 64
                text: "Положение"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
                color: Colors.text
            }

            Row {
                id: positionRow

                y: positionLabel.y + 28
                spacing: 8

                Repeater {
                    model: [
                        { value: "top",    title: "Сверху" },
                        { value: "bottom", title: "Снизу" },
                        { value: "left",   title: "Слева" },
                        { value: "right",  title: "Справа" }
                    ]

                    Rectangle {
                        required property var modelData

                        readonly property bool active: Settings.barPosition === modelData.value

                        width: 104
                        height: 76
                        radius: 12

                        color: active ? Theme.alpha(Colors.primary, 0.16)
                            : positionMouse.containsMouse ? Theme.alpha(Colors.text, 0.08)
                            : Theme.alpha(Colors.surfaceContainerHigh, 0.45)

                        border.width: active ? 2 : 1
                        border.color: active ? Colors.primary : Theme.panelBorder

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        // схематичный экран с полоской панели у нужной кромки
                        Rectangle {
                            id: screenPreview

                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 12
                            width: 56
                            height: 34
                            radius: 5
                            color: Theme.alpha(Colors.outline, 0.25)
                            border.width: 1
                            border.color: Theme.panelBorder

                            Rectangle {
                                readonly property bool side: modelData.value === "left"
                                    || modelData.value === "right"

                                width: side ? 7 : parent.width - 8
                                height: side ? parent.height - 8 : 7
                                radius: 2
                                color: parent.parent.active ? Colors.primary : Colors.subtext

                                x: modelData.value === "right" ? parent.width - width - 4 : 4
                                y: modelData.value === "bottom" ? parent.height - height - 4 : 4
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: screenPreview.y + screenPreview.height + 6
                            text: modelData.title
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 2
                            color: parent.active ? Colors.primary : Colors.text
                        }

                        MouseArea {
                            id: positionMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.setBarPosition(modelData.value)
                        }
                    }
                }
            }

            // режим
            Text {
                id: modeLabel

                y: positionRow.y + 96
                text: "Вид"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
                color: Colors.text
            }

            Row {
                y: modeLabel.y + 28
                spacing: 10

                Repeater {
                    model: [
                        {
                            value: "island",
                            title: "Остров",
                            hint: "скруглённый, с отступами от краёв"
                        },
                        {
                            value: "panel",
                            title: "Панель",
                            hint: "во всю кромку, без скруглений"
                        }
                    ]

                    Rectangle {
                        required property var modelData

                        readonly property bool active: Settings.barMode === modelData.value

                        width: 214
                        height: 92
                        radius: 12

                        color: active ? Theme.alpha(Colors.primary, 0.16)
                            : modeMouse.containsMouse ? Theme.alpha(Colors.text, 0.08)
                            : Theme.alpha(Colors.surfaceContainerHigh, 0.45)

                        border.width: active ? 2 : 1
                        border.color: active ? Colors.primary : Theme.panelBorder

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        // мини-экран: остров с отступами против полосы впритык
                        Rectangle {
                            id: modePreview

                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 62
                            height: 40
                            radius: 5
                            color: Theme.alpha(Colors.outline, 0.25)
                            border.width: 1
                            border.color: Theme.panelBorder

                            Rectangle {
                                readonly property bool island: modelData.value === "island"

                                x: island ? 5 : 0
                                y: island ? 4 : 0
                                width: island ? parent.width - 10 : parent.width
                                height: 8
                                radius: island ? 4 : 0
                                topLeftRadius: island ? radius : 5
                                topRightRadius: island ? radius : 5
                                color: parent.parent.active ? Colors.primary : Colors.subtext
                            }
                        }

                        Text {
                            id: modeTitle

                            x: modePreview.x + modePreview.width + 12
                            y: 24
                            text: modelData.title
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            color: parent.active ? Colors.primary : Colors.text
                        }

                        Text {
                            x: modeTitle.x
                            y: modeTitle.y + 20
                            width: parent.width - x - 10
                            wrapMode: Text.WordWrap
                            text: modelData.hint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 3
                            color: Colors.subtext
                        }

                        MouseArea {
                            id: modeMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.setBarMode(modelData.value)
                        }
                    }
                }
            }
        }

        //// содержимое вкладки «Окна» //////////////////////////////////////

        Item {
            id: windowsPage

            x: sidebar.width + 24
            y: 20
            width: card.width - sidebar.width - 48
            height: card.height - 40
            visible: root.tab === 1

            Text {
                id: windowsTitle

                text: "Окна"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 3
                font.weight: Font.DemiBold
                color: Colors.text
            }

            Text {
                id: windowsHint

                y: windowsTitle.height + 4
                text: "Настройки Hyprland, применяются сразу"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 2
                color: Colors.subtext
            }

            SettingSlider {
                id: borderSlider

                y: 62
                width: parent.width - 20

                label: "Толщина рамки окна"
                zeroLabel: "выкл"
                from: 0
                to: Settings.windowBorderMax
                value: Settings.windowBorder

                onMoved: amount => Settings.setWindowBorder(amount)
            }

            SettingSlider {
                id: roundingSlider

                y: borderSlider.y + borderSlider.height + 16
                width: parent.width - 20

                label: "Скругление углов"
                zeroLabel: "без скругления"
                from: 0
                to: Settings.windowRoundingMax
                value: Settings.windowRounding

                onMoved: amount => Settings.setWindowRounding(amount)
            }

            Text {
                id: animationLabel

                y: roundingSlider.y + roundingSlider.height + 22
                text: "Анимация появления"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.DemiBold
                color: Colors.text
            }

            Row {
                y: animationLabel.y + 28
                spacing: 8

                Repeater {
                    model: [
                        { value: "off",   title: "Выключена", hint: "окно появляется сразу" },
                        { value: "slide", title: "Выезд",     hint: "выезжает с перелётом" },
                        { value: "popin", title: "Из точки",  hint: "разворачивается из центра" },
                        { value: "fast",  title: "Быстрая",   hint: "короткий рывок" }
                    ]

                    Rectangle {
                        required property var modelData

                        readonly property bool active: Settings.windowAnimation === modelData.value

                        width: 104
                        height: 74
                        radius: 12

                        color: active ? Theme.alpha(Colors.primary, 0.16)
                            : animationMouse.containsMouse ? Theme.alpha(Colors.text, 0.08)
                            : Theme.alpha(Colors.surfaceContainerHigh, 0.45)

                        border.width: active ? 2 : 1
                        border.color: active ? Colors.primary : Theme.panelBorder

                        Behavior on color {
                            ColorAnimation { duration: 140 }
                        }

                        Text {
                            x: 10
                            y: 12
                            width: parent.width - 20
                            text: modelData.title
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 1
                            color: parent.active ? Colors.primary : Colors.text
                        }

                        Text {
                            x: 10
                            y: 34
                            width: parent.width - 20
                            wrapMode: Text.WordWrap
                            text: modelData.hint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize - 4
                            color: Colors.subtext
                        }

                        MouseArea {
                            id: animationMouse

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.setWindowAnimation(modelData.value)
                        }
                    }
                }
            }

            Text {
                y: parent.height - height - 10
                width: parent.width - 20
                wrapMode: Text.WordWrap
                text: "Значения держит панель и возвращает их Hyprland после каждой его перезагрузки — hyprland.lua при этом не меняется."
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                color: Colors.outline
            }
        }
    }
}
