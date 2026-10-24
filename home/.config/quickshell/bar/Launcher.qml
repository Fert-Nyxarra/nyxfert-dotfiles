// ~/.config/quickshell/bar/Launcher.qml
// Лаунчер приложений: снежинка NixOS слева. ЛКМ или Super — открыть/закрыть.
//
// Логотип берём глифом Nerd Font (nf-linux-nixos), а не иконкой из темы:
// глиф одноцветный и красится цветом из палитры matugen, тогда как
// nix-snowflake.png всегда синий и мимо темы.

import QtQuick
import Quickshell
import qs
import qs.widgets

BarItem {
    id: root

    // монитор, на котором висит эта панель, — меню создаёт на нём свой слой
    required property var barScreen

    // по этому числу Bar гасит нижний левый угол острова — синхронно с выездом
    readonly property real menuProgress: menu.revealProgress

    horizontalPadding: 12
    interactive: true
    active: menu.attached

    onClicked: menu.toggle()

    function toggle(): void {
        menu.toggle();
    }

    LauncherMenu {
        id: menu
        barScreen: root.barScreen
    }

    Binding {
        target: LauncherState
        property: "opened"
        value: menu.opened
    }

    // хоткей Super приходит через IPC в shell.qml
    Connections {
        target: LauncherState

        function onToggleRequested(): void {
            menu.toggle();
        }
    }

    BarText {
        text: "\uf313"
        font.pixelSize: Theme.fontSize + 4
        color: Colors.primary
    }
}
