// ~/.config/quickshell/bar/Battery.qml
// Батарея ноутбука: значок и проценты. На машине без батареи модуль просто
// не показывается, так что конфиг одинаково годится и для стационарной.

import QtQuick
import Quickshell.Services.UPower
import qs
import qs.widgets

BarItem {
    id: root

    readonly property var battery: {
        const device = UPower.displayDevice;
        return device && device.isLaptopBattery && device.isPresent ? device : null;
    }

    readonly property int percent: root.battery ? Math.round(root.battery.percentage * 100) : 0
    readonly property bool charging: root.battery
        && (root.battery.state === UPowerDeviceState.Charging
            || root.battery.state === UPowerDeviceState.FullyCharged)

    readonly property bool low: !root.charging && root.percent <= 15

    visible: root.battery !== null
    horizontalPadding: 10
    interactive: true
    active: menu.opened

    onClicked: menu.toggle()

    BatteryMenu {
        id: menu
        anchorItem: root
        battery: root.battery
    }

    BarText {
        color: root.low ? Colors.error : root.charging ? Colors.primary : Colors.subtext

        text: {
            if (!root.battery) return "";

            // десять ступеней значка плюс отдельный «на зарядке»
            const level = Math.max(0, Math.min(9, Math.floor(root.percent / 10)));
            const icons = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂"];
            const glyph = root.charging ? "󰂄" : (root.percent >= 100 ? "󰁹" : icons[level]);

            return glyph + " " + root.percent + "%";
        }
    }
}
