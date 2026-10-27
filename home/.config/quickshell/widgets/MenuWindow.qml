import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    required property var barScreen

    property bool opened: false
    property int preferredWidth: Theme.popupWidth
    property int maximumWidth: 460
    property int maximumHeight: 560

    property int edgeInset: 0

    property alias title: surface.title
    default property alias content: surface.content
    property alias header: surface.header
    property alias footer: surface.footer
    property alias contentSpacing: surface.contentSpacing
    property alias slideDuration: surface.slideDuration
    readonly property alias view: surface.view
    readonly property int contentWidth: surface.contentWidth

    readonly property real revealProgress: surface.revealProgress

    readonly property bool attached: root.visible

    signal keyPressed(var event)

    readonly property int menuWidth: Math.min(root.maximumWidth,
        Math.max(root.preferredWidth, surface.bodyWidth + Theme.popupPadding * 2))

    screen: root.barScreen

    WlrLayershell.namespace: "quickshell:menu"
    WlrLayershell.layer: WlrLayer.Top

    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function open(): void {
        root.opened = true;
    }

    function close(): void {
        root.opened = false;
    }

    function toggle(): void {
        root.opened = !root.opened;
    }

    Connections {
        target: root

        function onOpenedChanged(): void {
            if (root.opened) {
                root.visible = true;
                Menus.opened(root);
            } else {
                Menus.closed(root);
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 60
        onTriggered: if (!root.opened) root.visible = false
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.close()
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => root.keyPressed(event)
    }

    MenuSurface {
        id: surface

        x: Theme.barVertical
            ? (Theme.barPosition === "left"
                ? Theme.barMargin + Theme.barThickness - Theme.popupOverlap
                : root.width - Theme.barMargin - Theme.barThickness
                    + Theme.popupOverlap - surface.width)
            : Theme.barSideMargin + root.edgeInset
                - (surface.attachMode === "top" ? surface.notch : 0)

        y: Theme.barVertical
            ? Math.max(Theme.barMargin - surface.notch,
                Math.min(root.height - surface.height - Theme.barMargin,
                         Theme.barSideMargin + root.edgeInset - surface.notch))
            : (Theme.barPosition === "bottom"
                ? root.height - Theme.barMargin - Theme.barThickness
                    - Theme.popupGap - surface.height
                : Theme.barMargin + Theme.barThickness - Theme.popupOverlap)
        width: surface.implicitWidth
        height: surface.implicitHeight

        opened: root.opened
        menuWidth: root.menuWidth
        maximumHeight: root.maximumHeight

        attachMode: Theme.barPosition === "top" ? "top"
            : Theme.barVertical ? "side"
            : "card"

        sideFlipped: Theme.barPosition === "right"
        slideFrom: "bottom"

        flushLeft: root.edgeInset === 0
        flushRight: false

        onSettled: hideTimer.restart()
    }
}
