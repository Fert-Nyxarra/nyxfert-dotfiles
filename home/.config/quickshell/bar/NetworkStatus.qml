import Quickshell.Networking
import qs
import qs.widgets

BarItem {
    id: root

    readonly property var device: {
        const devices = Networking.devices ? Networking.devices.values : [];
        return devices.find(d => d.connected) ?? null;
    }

    readonly property bool wifi: device !== null && device.type === DeviceType.Wifi

    readonly property var network: {
        if (!device || !device.networks) return null;
        return device.networks.values.find(n => n.connected) ?? null;
    }

    readonly property int signalStrength: network && wifi ? (network.signalStrength ?? 0) : 0

    horizontalPadding: 10
    interactive: true
    active: wifiMenu.opened

    onClicked: wifiMenu.toggle()

    WifiMenu {
        id: wifiMenu
        anchorItem: root
    }

    BarText {
        color: root.device ? Colors.secondary : Colors.error
        font.pixelSize: Theme.fontSize + 2
        text: {
            if (!root.device) return "󰤭";
            if (!root.wifi) return "󰈀";

            const s = root.signalStrength;
            return s >= 75 ? "󰤨" : s >= 50 ? "󰤥" : s >= 25 ? "󰤢" : "󰤟";
        }
    }
}
