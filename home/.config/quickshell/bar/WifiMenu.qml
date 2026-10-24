// ~/.config/quickshell/bar/WifiMenu.qml
// Контекстное меню сети: выключатель Wi-Fi, список точек доступа,
// подключение/отключение и ввод пароля для незнакомых сетей.
//
// Сканирование включаем только пока меню открыто — иначе NetworkManager
// будет дёргать радио постоянно.

import QtQuick
import Quickshell.Networking
import qs
import qs.widgets

Popup {
    id: root

    title: "Сеть"
    preferredWidth: 320
    // клавиатура нужна, только когда спрашиваем пароль
    wantsKeyboard: root.pendingNetwork !== null

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: root.devices.find(d => d.type === DeviceType.Wired) ?? null

    // сеть, для которой запрошен пароль, и сам набираемый пароль
    property var pendingNetwork: null
    property string psk: ""

    readonly property int maxNetworks: 8

    readonly property var networks: {
        if (!root.wifiDevice || !root.wifiDevice.networks) return [];

        const list = root.wifiDevice.networks.values.filter(n => n.name !== "");
        list.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
        });
        return list.slice(0, root.maxNetworks);
    }

    function signalGlyph(strength: real): string {
        const s = strength ?? 0;
        return s >= 75 ? "󰤨" : s >= 50 ? "󰤥" : s >= 25 ? "󰤢" : "󰤟";
    }

    function needsPassword(network): bool {
        const open = network.security === WifiSecurityType.Open
                  || network.security === WifiSecurityType.Owe;
        return !open && !network.known;
    }

    // Ввод приходит из панели (см. Popup.wantsKeyboard): поле внутри меню
    // клавиатуру не получает, поэтому пароль набираем сами.
    function handleKey(event): void {
        event.accepted = true;

        if (event.key === Qt.Key_Escape) {
            root.cancelPassword();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submitPassword();
        } else if (event.key === Qt.Key_Backspace) {
            root.psk = (event.modifiers & Qt.ControlModifier) ? "" : root.psk.slice(0, -1);
        } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 0x20) {
            root.psk += event.text;
        } else {
            event.accepted = false;
        }
    }

    onKeyPressed: event => root.handleKey(event)

    function submitPassword(): void {
        if (!root.pendingNetwork || root.psk === "") return;

        root.pendingNetwork.connectWithPsk(root.psk);
        root.cancelPassword();
        root.close();
    }

    function cancelPassword(): void {
        root.psk = "";
        root.pendingNetwork = null;
    }

    function activate(network): void {
        if (network.connected) {
            network.disconnect();
            return;
        }

        if (root.needsPassword(network)) {
            root.pendingNetwork = network;
            return;
        }

        network.connect();
        root.close();
    }

    // сканируем, пока меню открыто
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.opened
        when: root.wifiDevice !== null
    }

    onOpenedChanged: if (!root.opened) root.cancelPassword()

    // выключатель Wi-Fi
    MenuRow {
        width: root.contentWidth
        glyph: Networking.wifiEnabled ? "󰖩" : "󰖪"
        label: "Wi-Fi"
        trailing: Networking.wifiEnabled ? "вкл" : "выкл"
        highlight: Networking.wifiEnabled
        rowEnabled: Networking.wifiHardwareEnabled

        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
    }

    // проводное подключение, если оно есть
    MenuRow {
        width: root.contentWidth
        visible: root.wiredDevice !== null
        glyph: "󰈀"
        label: root.wiredDevice ? root.wiredDevice.name : ""
        trailing: root.wiredDevice && root.wiredDevice.connected ? "подключено" : "отключено"
        highlight: root.wiredDevice ? root.wiredDevice.connected : false

        onClicked: {
            if (root.wiredDevice && root.wiredDevice.connected) root.wiredDevice.disconnect();
        }
    }

    MenuSeparator {
        width: root.contentWidth
        visible: Networking.wifiEnabled
    }

    Repeater {
        model: Networking.wifiEnabled ? root.networks : []

        MenuRow {
            required property var modelData

            width: root.contentWidth
            glyph: root.signalGlyph(modelData.signalStrength)
            label: modelData.name
            highlight: modelData.connected

            trailing: modelData.stateChanging ? "…"
                : modelData.connected ? "подключено"
                : modelData.known ? "сохранена"
                : root.needsPassword(modelData) ? "󰌾"
                : ""

            onClicked: root.activate(modelData)
            // ПКМ по сохранённой сети — забыть её
            onRightClicked: if (modelData.known) modelData.forget()
        }
    }

    MenuRow {
        width: root.contentWidth
        visible: Networking.wifiEnabled && root.networks.length === 0
        rowEnabled: false
        glyph: "󱃎"
        label: "Поиск сетей…"
    }

    // ввод пароля для незнакомой защищённой сети
    Item {
        width: root.contentWidth
        implicitHeight: visible ? Theme.rowHeight + 8 : 0
        visible: root.pendingNetwork !== null

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: 8
            width: parent.width - 16
            height: 30
            radius: 8
            color: Theme.alpha(Colors.surfaceContainerHigh, 0.9)
            border.width: 1
            border.color: Theme.alpha(Colors.primary, 0.8)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 8
                text: "󰌾"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Colors.subtext
            }

            Text {
                id: pskText

                anchors.verticalCenter: parent.verticalCenter
                x: 30
                width: parent.width - 38

                text: "•".repeat(root.psk.length)
                elide: Text.ElideLeft
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                color: Colors.text
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                x: 34
                visible: root.psk === ""
                text: root.pendingNetwork ? "пароль для " + root.pendingNetwork.name : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                color: Colors.outline
            }

            // каретка: поля ввода нет, рисуем сами
            Rectangle {
                x: 30 + Math.min(pskText.contentWidth, pskText.width) + 1
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: Theme.fontSize + 2
                radius: 1
                color: Colors.primary
                visible: pskCaret.shown
            }

            Timer {
                id: pskCaret

                property bool shown: true

                interval: 530
                running: root.pendingNetwork !== null
                repeat: true
                onTriggered: pskCaret.shown = !pskCaret.shown
            }
        }
    }
}
