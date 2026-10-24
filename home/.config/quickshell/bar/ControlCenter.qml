// ~/.config/quickshell/bar/ControlCenter.qml
// Контрол-центр: ползунки яркости и громкости в один ряд, плеер, сети Wi-Fi
// и устройства вывода звука. Заменил собой отдельные меню громкости и сети.
//
// Ползунок яркости появляется только там, где есть подсветка (см.
// Brightness.qml) — на стационарной машине ряд остаётся с одной громкостью.

import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Services.Pipewire
import qs
import qs.widgets

Popup {
    id: root

    title: "Центр управления"
    preferredWidth: 380
    maximumWidth: 380
    // клавиатура нужна, только когда спрашиваем пароль Wi-Fi
    wantsKeyboard: root.pendingNetwork !== null

    // ── звук ────────────────────────────────────────────────────────────
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: root.sink ? root.sink.audio : null
    readonly property real volume: root.audio ? root.audio.volume : 0
    readonly property bool muted: root.audio ? root.audio.muted : false

    readonly property var sinks: Pipewire.nodes
        ? Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
        : []

    function sinkName(node): string {
        return node.description || node.nickname || node.name;
    }

    function setVolume(fraction: real): void {
        if (!root.audio) return;
        root.audio.muted = false;
        root.audio.volume = Math.max(0, Math.min(1, fraction));
    }

    PwObjectTracker {
        objects: root.sinks
    }

    // ── сети ────────────────────────────────────────────────────────────
    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: root.devices.find(d => d.type === DeviceType.Wired) ?? null

    property var pendingNetwork: null
    property string psk: ""

    readonly property int maxNetworks: 6

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
    }

    function submitPassword(): void {
        if (!root.pendingNetwork || root.psk === "") return;

        root.pendingNetwork.connectWithPsk(root.psk);
        root.cancelPassword();
    }

    function cancelPassword(): void {
        root.psk = "";
        root.pendingNetwork = null;
    }

    // ввод приходит из панели (см. Popup.wantsKeyboard)
    function handleKey(event): void {
        event.accepted = true;

        if (event.key === Qt.Key_Escape) root.cancelPassword();
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.submitPassword();
        else if (event.key === Qt.Key_Backspace)
            root.psk = (event.modifiers & Qt.ControlModifier) ? "" : root.psk.slice(0, -1);
        else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 0x20)
            root.psk += event.text;
        else event.accepted = false;
    }

    onKeyPressed: event => root.handleKey(event)

    // сканируем, пока центр открыт
    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root.opened
        when: root.wifiDevice !== null
    }

    onOpenedChanged: if (!root.opened) root.cancelPassword()

    // ── содержимое ──────────────────────────────────────────────────────

    // ползунки в один ряд
    Item {
        width: root.contentWidth
        implicitHeight: 158

        Row {
            anchors.centerIn: parent
            spacing: 12

            VerticalSlider {
                visible: Brightness.available
                glyph: "󰃞"
                value: Brightness.value
                onMoved: value => Brightness.setValue(value)
            }

            VerticalSlider {
                glyph: root.muted || root.volume <= 0.001 ? "󰝟"
                    : root.volume < 0.34 ? "󰕿"
                    : root.volume < 0.67 ? "󰖀"
                    : "󰕾"
                value: root.volume
                muted: root.muted
                onMoved: value => root.setVolume(value)
            }
        }
    }

    MediaPlayer {
        width: root.contentWidth
    }

    MenuSeparator {
        width: root.contentWidth
        visible: Networking.wifiEnabled || root.wiredDevice
    }

    // ── сети ────────────────────────────────────────────────────────────
    MenuRow {
        width: root.contentWidth
        glyph: Networking.wifiEnabled ? "󰖩" : "󰖪"
        label: "Wi-Fi"
        trailing: Networking.wifiEnabled ? "вкл" : "выкл"
        highlight: Networking.wifiEnabled
        rowEnabled: Networking.wifiHardwareEnabled

        onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
    }

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

    // поле пароля для незнакомой защищённой сети
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
                visible: caret.shown
            }

            Timer {
                id: caret

                property bool shown: true

                interval: 530
                running: root.pendingNetwork !== null
                repeat: true
                onTriggered: caret.shown = !caret.shown
            }
        }
    }

    MenuSeparator {
        width: root.contentWidth
        visible: root.sinks.length > 0
    }

    // ── вывод звука ─────────────────────────────────────────────────────
    Repeater {
        model: root.sinks

        MenuRow {
            required property var modelData

            width: root.contentWidth
            label: root.sinkName(modelData)
            highlight: modelData === root.sink
            glyph: modelData === root.sink ? "󰓃" : "󰤽"
            trailing: modelData === root.sink ? "активно" : ""

            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
}
