// ~/.config/quickshell/bar/Workspaces.qml
// Рабочие столы Hyprland. Столов десять, но кружков всегда пять: показывается
// та пятёрка, в которой сейчас находишься. Ушёл на шестой — кружки
// переключаются на столы 6-10, и они пустые, то есть набор выглядит новым.
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

    // сколько кружков видно за раз; столов вдвое больше
    readonly property int pageSize: 5

    // Активный стол берём у СВОЕГО монитора, а не глобально: иначе на втором
    // мониторе пятёрка прыгала бы вслед за фокусом на первом.
    readonly property var monitor: Hyprland.monitors
        ? Hyprland.monitors.values.find(m => m.name === root.screenName) ?? null
        : null

    readonly property int activeId: root.monitor && root.monitor.activeWorkspace
        ? root.monitor.activeWorkspace.id
        : (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)

    // какая пятёрка сейчас на экране: 0 — столы 1-5, 1 — столы 6-10
    readonly property int page: Math.max(0, Math.floor((root.activeId - 1) / root.pageSize))

    readonly property var workspaces: {
        const list = [];
        for (const ws of Hyprland.workspaces.values) {
            if (ws.id <= 0) continue; // спецстолы (scratchpad) не показываем
            if (root.screenName !== "" && ws.monitor && ws.monitor.name !== root.screenName) continue;
            list.push(ws);
        }
        return list;
    }

    // Смена пятёрки должна читаться как смена набора, а не как подсветка
    // соседнего кружка. Поэтому старые точки по очереди уезжают в сторону
    // движения и гаснут, а новые влетают с противоположной стороны с лёгким
    // перелётом. Волна идёт с задержкой по индексу — так видно направление.
    property int pageTick: 0
    property int pageDirection: 1

    onPageChanged: {
        root.pageDirection = root.page > root.previousPage ? 1 : -1;
        root.previousPage = root.page;
        root.pageTick++;
    }

    property int previousPage: root.page

    horizontalPadding: 10
    spacing: 6
    interactive: true

    onWheel: delta => Hypr.cycleWorkspace(delta > 0 ? "e-1" : "e+1")

    Repeater {
        // Модель — ПЯТЬ постоянных мест, а не список номеров: при смене
        // пятёрки Repeater пересоздал бы делегаты, и анимация перелистывания
        // никогда бы не проигралась — новые точки просто появлялись бы на
        // месте старых.
        model: root.pageSize

        Item {
            id: slot

            required property int index

            // какой стол показывает это место сейчас
            readonly property int workspaceId: root.page * root.pageSize + slot.index + 1

            readonly property bool focused: Hyprland.focusedWorkspace
                && Hyprland.focusedWorkspace.id === slot.workspaceId
            readonly property var workspace: root.workspaces.find(ws => ws.id === slot.workspaceId) ?? null
            readonly property bool occupied: workspace !== null
            readonly property bool urgent: workspace ? workspace.urgent : false

            // сдвиг рисуем через transform: x/y у детей позиционера занят им
            // самим, и трогать их нельзя
            property real slide: 0

            opacity: slot.fade

            property real fade: 1

            transform: Translate {
                x: Theme.barVertical ? 0 : slot.slide
                y: Theme.barVertical ? slot.slide : 0
            }

            SequentialAnimation {
                id: pageSwap

                PauseAnimation { duration: slot.index * 35 }

                ParallelAnimation {
                    NumberAnimation {
                        target: slot
                        property: "slide"
                        to: 14 * root.pageDirection
                        duration: 120
                        easing.type: Easing.InCubic
                    }

                    NumberAnimation {
                        target: slot
                        property: "fade"
                        to: 0
                        duration: 120
                    }
                }

                // мгновенный переброс на другую сторону, уже невидимым
                PropertyAction {
                    target: slot
                    property: "slide"
                    value: -18 * root.pageDirection
                }

                ParallelAnimation {
                    NumberAnimation {
                        target: slot
                        property: "slide"
                        to: 0
                        duration: 320
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.6
                    }

                    NumberAnimation {
                        target: slot
                        property: "fade"
                        to: 1
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Connections {
                target: root

                function onPageTickChanged(): void {
                    pageSwap.restart();
                }
            }

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
                    Hypr.focusWorkspace(slot.workspaceId);
                }
            }
        }
    }
}
