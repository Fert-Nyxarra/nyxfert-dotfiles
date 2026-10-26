// ~/.config/quickshell/bar/Workspaces.qml
// Рабочие столы Hyprland. Всегда показываются столы 1-5, плюс все
// существующие на этом мониторе.
//
// ЛКМ по точке — перейти на этот стол, колесо — листать столы по порядку.
// Клики доходят до точек потому, что ряд содержимого в BarItem лежит поверх
// его общей MouseArea, а она подхватывает только колесо и промахи.

import QtQuick
import Quickshell.Hyprland
import qs
import qs.widgets

BarItem {
    id: root

    // имя монитора, по которому фильтруем рабочие столы
    property string screenName: ""

    readonly property int persistentCount: 5

    readonly property var workspaces: {
        const list = [];
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id <= 0) continue; // спецстолы (scratchpad) не показываем
            if (root.screenName !== "" && ws.monitor && ws.monitor.name !== root.screenName) continue;
            list.push(ws);
        }
        return list;
    }

    readonly property var ids: {
        const set = new Set();
        for (let i = 1; i <= root.persistentCount; i++) set.add(i);
        for (const ws of root.workspaces) set.add(ws.id);
        return Array.from(set).sort((a, b) => a - b);
    }

    horizontalPadding: 10
    spacing: 6
    interactive: true

    onWheel: delta => Hypr.cycleWorkspace(delta > 0 ? "e-1" : "e+1")

    Repeater {
        model: root.ids

        Item {
            id: slot

            required property int modelData

            readonly property bool focused: Hyprland.focusedWorkspace
                && Hyprland.focusedWorkspace.id === modelData
            readonly property var workspace: root.workspaces.find(ws => ws.id === modelData) ?? null
            readonly property bool occupied: workspace !== null
            readonly property bool urgent: workspace ? workspace.urgent : false

            implicitWidth: Theme.barVertical ? Theme.itemHeight : dot.implicitWidth
            implicitHeight: Theme.barVertical ? dot.implicitLength : Theme.itemHeight

            Rectangle {
                id: dot

                anchors.centerIn: parent

                // Активный стол — пилюля, остальные — точки; цвет сплошной,
                // без градиента. Пилюля вытягивается ВДОЛЬ панели, поэтому у
                // боковой она вертикальная.
                // не readonly: на readonly нельзя повесить Behavior
                property int implicitLength: slot.focused ? 28 : 12

                implicitWidth: Theme.barVertical ? 12 : dot.implicitLength
                implicitHeight: Theme.barVertical ? dot.implicitLength : 12
                width: implicitWidth
                height: implicitHeight
                radius: height / 2
                scale: mouse.containsMouse && !slot.focused ? 1.25 : 1

                color: slot.urgent ? Colors.error
                     : slot.focused ? Colors.primary
                     : slot.occupied ? Colors.subtext
                     : Theme.alpha(Colors.outline, 0.35)

                Behavior on implicitLength {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Easing.OutBack
                    }
                }

                Behavior on scale {
                    NumberAnimation { duration: 120 }
                }

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }
            }

            // кликабельна вся высота панели над точкой, а не 12 пикселей
            MouseArea {
                id: mouse

                anchors.fill: parent
                anchors.leftMargin: -3
                anchors.rightMargin: -3
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Menus.closeCurrent();
                    Hypr.focusWorkspace(slot.modelData);
                }
            }
        }
    }
}
