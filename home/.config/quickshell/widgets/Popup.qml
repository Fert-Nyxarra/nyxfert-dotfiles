import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

PopupWindow {
    id: root

    required property Item anchorItem
    property int preferredWidth: Theme.popupWidth
    property int maximumWidth: 460

    property int maximumHeight: root.screen
        ? root.screen.height - Theme.barThickness - Theme.barMargin * 4
        : 640
    property bool opened: false

    property bool grabFocus: true

    property bool managed: true

    property bool wantsKeyboard: false

    signal keyPressed(var event)

    property int edgeInset: Theme.radius + Theme.notchRadius

    property alias title: surface.title
    default property alias content: surface.content
    property alias header: surface.header
    property alias footer: surface.footer
    property alias contentSpacing: surface.contentSpacing
    property alias slideDuration: surface.slideDuration
    readonly property alias view: surface.view
    readonly property int contentWidth: surface.contentWidth

    readonly property real revealProgress: surface.revealProgress

    readonly property bool hovered: surface.hovered

    readonly property bool attached: root.visible

    readonly property int menuWidth: Math.min(root.maximumWidth,
        Math.max(root.preferredWidth, surface.bodyWidth + Theme.popupPadding * 2))

    property int geometryRevision: 0

    TransformWatcher {
        a: root.anchorItem
        b: root.anchorItem.Window.contentItem
        onTransformChanged: root.geometryRevision++
    }

    readonly property var placement: {
        const item = root.anchorItem;
        const inset = root.edgeInset;

        root.opened;
        root.geometryRevision;

        if (Theme.barVertical) {

            const screenHeight = item.Window.height;
            const menuHeight = Math.max(1, root.implicitHeight);
            const middle = item.mapToItem(null, 0, item.height / 2).y;
            const halfHeight = menuHeight / 2;
            const bottomLimit = screenHeight - halfHeight - Theme.barMargin;
            const topLimit = halfHeight + Theme.barMargin;

            const wanted = bottomLimit < topLimit
                ? screenHeight / 2
                : Math.max(topLimit, Math.min(middle, bottomLimit));

            return { shift: wanted - middle, flushLeft: false, flushRight: false };
        }

        const barWidth = item.Window.width;
        const center = item.mapToItem(null, item.width / 2, 0).x;
        const half = root.menuWidth / 2;
        const limit = barWidth - root.menuWidth - inset;

        const left = limit < inset
            ? (barWidth - root.menuWidth) / 2
            : Math.max(inset, Math.min(center - half, limit));

        return {
            shift: left + half - center,
            flushLeft: left <= 0.5,
            flushRight: left + root.menuWidth >= barWidth - 0.5
        };
    }

    readonly property real barInset: Theme.barVertical
        ? (Theme.barThickness - root.anchorItem.width) / 2
        : (Theme.barThickness - root.anchorItem.height) / 2

    anchor.item: root.anchorItem

    anchor.rect.x: Math.round(Theme.barVertical
        ? (Theme.barPosition === "left"
            ? root.anchorItem.width + root.barInset - Theme.popupOverlap
            : -root.barInset + Theme.popupOverlap)
        : root.placement.shift)

    anchor.rect.y: Math.round(Theme.barVertical
        ? root.anchorItem.height / 2 + root.placement.shift
        : (Theme.barFlipped
            ? -root.barInset + Theme.popupOverlap
            : root.anchorItem.height + root.barInset - Theme.popupOverlap))

    anchor.rect.width: Theme.barVertical ? 1 : root.anchorItem.width
    anchor.rect.height: 1

    anchor.edges: Theme.barVertical
        ? (Theme.barPosition === "left" ? Edges.Right : Edges.Left)
        : (Theme.barFlipped ? Edges.Top : Edges.Bottom)

    anchor.gravity: root.anchor.edges

    anchor.adjustment: PopupAdjustment.None

    color: "transparent"
    visible: false

    implicitWidth: surface.implicitWidth
    implicitHeight: surface.implicitHeight

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
                if (root.managed) Menus.opened(root);
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

    HyprlandFocusGrab {
        active: root.opened && root.visible && root.grabFocus
        windows: [root]
        onCleared: root.close()
    }

    MenuSurface {
        id: surface

        anchors.fill: parent

        opened: root.opened
        menuWidth: root.menuWidth
        maximumHeight: root.maximumHeight

        attachMode: Theme.barPosition === "top" ? "top"
            : Theme.barVertical ? "side"
            : "card"

        sideFlipped: Theme.barPosition === "right"
        slideFrom: "bottom"

        flushLeft: root.placement.flushLeft
        flushRight: root.placement.flushRight

        onSettled: hideTimer.restart()
    }
}
