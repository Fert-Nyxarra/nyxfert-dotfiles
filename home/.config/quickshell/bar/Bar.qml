// ~/.config/quickshell/bar/Bar.qml
// Сама панель: слой wlr-layer-shell поверх окон, прижата к верху экрана.
//
// Все модули лежат внутри ОДНОГО острова на всю ширину экрана: фон и рамку
// рисует surface, а сами модули плоские и разделены волосяными линиями.

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

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.gap
        left: Theme.sideMargin
        right: Theme.sideMargin
    }

    implicitHeight: Theme.barHeight
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
        radius: Theme.radius
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
        bottomLeftRadius: Theme.radius
            * (1 - Math.max(launcher.menuProgress, clipboardMenu.revealProgress))
        bottomRightRadius: Theme.radius * (1 - notifications.menuProgress)

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

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.barPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.groupGap

            Launcher { id: launcher; barScreen: bar.modelData }
            Separator {}
            Workspaces { screenName: bar.modelData.name }
            Separator { visible: nowPlaying.visible }
            NowPlaying { id: nowPlaying }
        }

        Clock {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.barPadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.groupGap

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
