// ~/.config/quickshell/bar/Bar.qml
// Сама панель: слой wlr-layer-shell поверх окон, прижатый к одной из кромок
// экрана. Кромка и режим выбираются в настройках (CTRL + SUPER + S).
//
// Все модули лежат внутри ОДНОГО острова во всю длину кромки: фон и рамку
// рисует surface, а сами модули плоские и разделены волосяными линиями.
//
// Горизонтальная и боковая раскладки — это одни и те же модули в Grid,
// которому меняют направление. Делать два набора нельзя: каждый лаунчер,
// трей и центр уведомлений существовал бы дважды, со своим состоянием.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.widgets

PanelWindow {
    id: bar

    // Variants подставляет сюда очередной экран из Quickshell.screens
    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell:bar"
    WlrLayershell.layer: WlrLayer.Top

    // Клавиатура достаётся слою панели, а не окну меню, поэтому ввод ловим
    // здесь и отдаём тому меню, которое его попросило.
    //
    // Режим именно OnDemand: с Exclusive компоновщик отдаёт слою ВЕСЬ ввод, и
    // всплывающее меню перестаёт получать мышь — ни наведения, ни кликов.
    readonly property var keyboardMenu: Menus.current && Menus.current.wantsKeyboard
        ? Menus.current
        : null

    WlrLayershell.keyboardFocus: bar.keyboardMenu
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    readonly property bool vertical: Theme.barVertical

    // панель держится за свою кромку и растягивается вдоль неё
    anchors {
        top: Theme.barPosition !== "bottom"
        bottom: Theme.barPosition !== "top"
        left: Theme.barPosition !== "right"
        right: Theme.barPosition !== "left"
    }

    // от своей кромки отступ barMargin, вдоль кромки — barSideMargin;
    // в режиме «панель» оба нулевые, и остров превращается в полосу впритык
    margins {
        top: bar.vertical ? Theme.barSideMargin
            : Theme.barPosition === "top" ? Theme.barMargin : 0
        bottom: bar.vertical ? Theme.barSideMargin
            : Theme.barPosition === "bottom" ? Theme.barMargin : 0
        left: bar.vertical
            ? (Theme.barPosition === "left" ? Theme.barMargin : 0)
            : Theme.barSideMargin
        right: bar.vertical
            ? (Theme.barPosition === "right" ? Theme.barMargin : 0)
            : Theme.barSideMargin
    }

    implicitHeight: bar.vertical ? 0 : Theme.barThickness
    implicitWidth: bar.vertical ? Theme.barThickness : 0
    color: "transparent"

    // Полноэкранному окну панель мешает: слой Top рисуется поверх него.
    // Поэтому на время фуллскрина панель убираем совсем — заодно уходит и
    // её зарезервированная полоса.
    readonly property var hyprMonitor: Hyprland.monitorFor(bar.modelData)
    readonly property bool fullscreenHere: bar.hyprMonitor && bar.hyprMonitor.activeWorkspace
        ? bar.hyprMonitor.activeWorkspace.hasFullscreen
        : false

    visible: !bar.fullscreenHere

    // история буфера обмена: своим слоем, открывается с SUPER + V
    ClipboardMenu {
        id: clipboardMenu

        barScreen: bar.modelData
    }

    Rectangle {
        id: surface

        anchors.fill: parent
        // в режиме «панель» barRadius равен нулю — углы прямые
        radius: Theme.barRadius
        color: Theme.panelColor
        border.width: 1
        border.color: Theme.panelBorder

        // лаунчер и центр уведомлений встают вплотную к краям острова,
        // поэтому углы под ними разглаживаются — панель и меню читаются как
        // одна фигура
        // Угол гаснет ровно настолько, насколько выехало меню под ним.
        // Своей анимации у него нет намеренно: иначе угол отставал бы от
        // меню — при закрытии оставался острым ещё почти секунду.
        // слева к острову прижаты двое: лаунчер и история буфера, —
        // поэтому угол разглаживает тот, кто открыт
        bottomLeftRadius: Theme.barRadius
            * (1 - Math.max(launcher.menuProgress, clipboardMenu.revealProgress))
        bottomRightRadius: Theme.barRadius * (1 - notifications.menuProgress)

        // приёмник клавиатуры: сам ничего не рисует, только пересылает нажатия
        Item {
            anchors.fill: parent
            focus: bar.keyboardMenu !== null

            Keys.onPressed: event => {
                if (bar.keyboardMenu) bar.keyboardMenu.keyPressed(event);
            }
        }

        // клик по пустому месту панели тоже гасит открытое меню; лежит ниже
        // всех модулей, поэтому их собственные клики перехватывает не она
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onClicked: Menus.closeCurrent()
        }

        // Левая группа у горизонтальной панели, верхняя — у боковой
        Grid {
            id: startGroup

            flow: bar.vertical ? Grid.TopToBottom : Grid.LeftToRight
            rows: bar.vertical ? 99 : 1
            columns: bar.vertical ? 1 : 99
            spacing: Theme.groupGap

            // Grid кладёт детей в левый верхний угол ячейки; без этого
            // разделители и мелкие значки не стояли бы по центру полосы
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            // Координаты явные, без anchors: переключать привязки биндингами
            // (`bar.vertical ? parent.top : undefined`) не выходит — QML
            // оставляет обе и раскладка съезжает, группы наползают друг на
            // друга.
            x: bar.vertical ? (parent.width - width) / 2 : Theme.barPadding
            y: bar.vertical ? Theme.barPadding : (parent.height - height) / 2

            Launcher { id: launcher; barScreen: bar.modelData }
            Separator {}
            Workspaces { screenName: bar.modelData.name }
            Separator { visible: nowPlaying.visible }
            NowPlaying { id: nowPlaying }
        }

        Clock {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
        }

        // Правая группа у горизонтальной панели, нижняя — у боковой
        Grid {
            id: endGroup

            flow: bar.vertical ? Grid.TopToBottom : Grid.LeftToRight
            rows: bar.vertical ? 99 : 1
            columns: bar.vertical ? 1 : 99
            spacing: Theme.groupGap

            // Grid кладёт детей в левый верхний угол ячейки; без этого
            // разделители и мелкие значки не стояли бы по центру полосы
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            x: bar.vertical
                ? (parent.width - width) / 2
                : parent.width - width - Theme.barPadding

            y: bar.vertical
                ? parent.height - height - Theme.barPadding
                : (parent.height - height) / 2

            Tray { id: tray }
            Separator { visible: tray.visible }
            Volume { barScreen: bar.modelData; fullscreen: bar.fullscreenHere }
            NetworkStatus {}
            Battery { id: battery }
            Separator { visible: battery.visible }
            KeyboardLayout {}
            Separator {}
            Notifications { id: notifications }
        }
    }
}
