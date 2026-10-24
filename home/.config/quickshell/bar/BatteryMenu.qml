// ~/.config/quickshell/bar/BatteryMenu.qml
// Меню батареи: шкала заряда с состоянием и выбор профиля потребления.
//
// Профили берутся из power-profiles-daemon через UPower. Если демона нет,
// секция профилей просто не показывается, а шкала остаётся.

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs
import qs.widgets

Popup {
    id: root

    required property var battery

    title: "Батарея"
    preferredWidth: 300
    maximumWidth: 300

    readonly property real level: root.battery ? root.battery.percentage : 0
    readonly property int percent: Math.round(root.level * 100)

    readonly property bool charging: root.battery
        && (root.battery.state === UPowerDeviceState.Charging
            || root.battery.state === UPowerDeviceState.FullyCharged)

    readonly property bool profilesAvailable: PowerProfiles.profile !== undefined

    function timeText(seconds: real): string {
        if (!(seconds > 0)) return "";

        const total = Math.round(seconds / 60);
        const hours = Math.floor(total / 60);
        const mins = total % 60;

        if (hours > 0) return hours + " ч " + mins + " мин";
        return mins + " мин";
    }

    readonly property string stateText: {
        if (!root.battery) return "";

        if (root.battery.state === UPowerDeviceState.FullyCharged) return "заряжена";

        if (root.charging) {
            const left = root.timeText(root.battery.timeToFull);
            return left === "" ? "заряжается" : "до полной " + left;
        }

        const left = root.timeText(root.battery.timeToEmpty);
        return left === "" ? "от батареи" : "хватит на " + left;
    }

    // шкала заряда
    Item {
        width: root.contentWidth
        implicitHeight: 54

        Text {
            id: percentText

            x: 10
            y: 4
            text: root.percent + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 4
            font.weight: Font.DemiBold
            color: root.percent <= 15 && !root.charging ? Colors.error : Colors.text
        }

        Text {
            anchors.verticalCenter: percentText.verticalCenter
            x: parent.width - width - 10
            text: root.stateText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 2
            color: Colors.subtext
        }

        Rectangle {
            x: 10
            y: 36
            width: parent.width - 20
            height: 8
            radius: 4
            color: Theme.alpha(Colors.outline, 0.3)

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.level))
                height: parent.height
                radius: parent.radius

                color: root.charging ? Colors.primary
                    : root.percent <= 15 ? Colors.error
                    : Colors.secondary

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Theme.animEasing
                    }
                }
            }
        }
    }

    MenuSeparator { width: root.contentWidth }

    // профили потребления
    component ProfileRow: MenuRow {
        required property int profile

        width: root.contentWidth
        highlight: PowerProfiles.profile === profile

        onClicked: PowerProfiles.profile = profile
    }

    ProfileRow {
        profile: PowerProfile.PowerSaver
        glyph: "󰾆"
        label: "Экономия"
    }

    ProfileRow {
        profile: PowerProfile.Balanced
        glyph: "󰾅"
        label: "Баланс"
    }

    ProfileRow {
        profile: PowerProfile.Performance
        glyph: "󰓅"
        label: "Производительность"
        visible: PowerProfiles.hasPerformanceProfile
        trailing: PowerProfiles.degradationReason === PerformanceDegradationReason.None
            ? ""
            : "ограничено"
    }
}
