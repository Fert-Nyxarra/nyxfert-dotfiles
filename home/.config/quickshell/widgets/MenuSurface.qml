import QtQuick
import QtQuick.Shapes
import Quickshell
import qs

Item {
    id: root

    clip: true

    property bool opened: false
    property string title: ""
    property int menuWidth: Theme.popupWidth
    property int maximumHeight: 640

    property bool flushLeft: false
    property bool flushRight: false

    property string attachMode: "top"

    property bool sideFlipped: false

    property string slideFrom: "bottom"

    readonly property bool seamless: root.attachMode !== "card"
    readonly property bool sideAttached: root.attachMode === "side"

    default property alias content: body.data
    property alias header: headerColumn.data
    property alias footer: footerColumn.data
    property alias contentSpacing: body.spacing
    readonly property alias view: view

    readonly property bool hovered: hover.hovered

    signal settled

    readonly property int notch: Theme.notchRadius
    readonly property int headerHeight: root.title !== "" ? 26 : 0

    readonly property int bodyWidth: {
        let widest = 0;

        for (const child of body.children)
            if (child.visible) widest = Math.max(widest, child.implicitWidth);

        for (const child of headerColumn.children)
            if (child.visible) widest = Math.max(widest, child.implicitWidth);

        for (const child of footerColumn.children)
            if (child.visible) widest = Math.max(widest, child.implicitWidth);

        return widest;
    }

    readonly property int headerSlotHeight: headerColumn.implicitHeight > 0
        ? headerColumn.implicitHeight + 6
        : 0

    readonly property int footerHeight: footerColumn.implicitHeight > 0
        ? footerColumn.implicitHeight + 6
        : 0

    readonly property int contentWidth: root.menuWidth - Theme.popupPadding * 2

    readonly property int contentHeight: Math.min(root.maximumHeight,
        root.headerHeight + root.headerSlotHeight + body.implicitHeight
        + root.footerHeight + Theme.popupPadding * 2)

    property real animatedHeight: root.contentHeight

    Behavior on animatedHeight {
        NumberAnimation {
            duration: Math.max(120, root.slideDuration - 40)
            easing.type: Easing.OutCubic
        }
    }

    property int slideDuration: Math.min(430, 200 + root.contentHeight * 0.3)

    readonly property real menuBottom: surface.y + surface.height
    readonly property real menuRight: root.sideFlipped
        ? root.menuWidth - surface.x
        : surface.x + surface.width

    readonly property real revealProgress: !root.seamless
        ? (root.opened ? 1 : 0)
        : root.sideAttached
        ? Math.max(0, Math.min(1, root.menuRight / Math.max(1, root.menuWidth)))
        : root.animatedHeight > 0
        ? Math.max(0, Math.min(1,
            (surface.y + root.animatedHeight + Theme.popupRadius) / root.animatedHeight))
        : 0

    implicitWidth: root.menuWidth
        + (root.attachMode === "top" ? root.notch * 2 : 0)

    implicitHeight: Math.max(1, Math.round(root.animatedHeight
        + (root.sideAttached ? root.notch * 2 : 0)))

    component NotchCorner: Item {
        id: corner

        readonly property real r: Math.max(0, Math.min(root.notch,
            root.menuBottom - Theme.popupRadius - Theme.popupOverlap))

        implicitWidth: root.notch + 1
        implicitHeight: Theme.popupOverlap + root.notch
        visible: corner.r > 0.5

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.panelColor
                strokeWidth: 0

                startX: root.notch - corner.r
                startY: 0
                PathLine { x: root.notch + 1; y: 0 }
                PathLine { x: root.notch + 1; y: Theme.popupOverlap + corner.r }
                PathAngleArc {
                    centerX: root.notch - corner.r
                    centerY: Theme.popupOverlap + corner.r
                    radiusX: corner.r
                    radiusY: corner.r
                    startAngle: 0
                    sweepAngle: -90
                }
                PathLine { x: root.notch - corner.r; y: 0 }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.panelBorder
                strokeWidth: 1

                PathAngleArc {
                    centerX: root.notch - corner.r
                    centerY: Theme.popupOverlap + corner.r
                    radiusX: corner.r
                    radiusY: corner.r
                    startAngle: 0
                    sweepAngle: -90
                }
            }
        }
    }

    component SideNotchCorner: Item {
        id: sideCorner

        readonly property real r: Math.max(0, Math.min(root.notch,
            root.menuRight - Theme.popupRadius - Theme.popupOverlap))

        implicitWidth: Theme.popupOverlap + root.notch
        implicitHeight: root.notch + 1
        visible: sideCorner.r > 0.5

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.panelColor
                strokeWidth: 0

                startX: 0
                startY: root.notch - sideCorner.r
                PathLine { x: 0; y: root.notch + 1 }
                PathLine { x: Theme.popupOverlap + sideCorner.r; y: root.notch + 1 }
                PathAngleArc {
                    centerX: Theme.popupOverlap + sideCorner.r
                    centerY: root.notch - sideCorner.r
                    radiusX: sideCorner.r
                    radiusY: sideCorner.r
                    startAngle: 90
                    sweepAngle: 90
                }
                PathLine { x: 0; y: root.notch - sideCorner.r }
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.panelBorder
                strokeWidth: 1

                PathAngleArc {
                    centerX: Theme.popupOverlap + sideCorner.r
                    centerY: root.notch - sideCorner.r
                    radiusX: sideCorner.r
                    radiusY: sideCorner.r
                    startAngle: 90
                    sweepAngle: 90
                }
            }
        }
    }

    Rectangle {
        id: surface

        width: root.sideAttached
            ? root.menuWidth + Theme.popupRadius
            : root.menuWidth

        height: root.attachMode === "top"
            ? root.animatedHeight + Theme.popupRadius
            : root.animatedHeight

        x: root.attachMode === "top" ? root.notch
            : root.sideAttached
                ? (root.sideFlipped
                    ? (root.opened ? -Theme.popupRadius : root.menuWidth)
                    : (root.opened ? -Theme.popupRadius : -(root.menuWidth + Theme.popupRadius)))
            : root.opened ? 0
            : root.slideFrom === "left" ? -root.menuWidth
            : root.slideFrom === "right" ? root.menuWidth
            : 0

        y: root.attachMode === "top"
            ? (root.opened ? -Theme.popupRadius : -(root.animatedHeight + Theme.popupRadius))
            : root.sideAttached
                ? root.notch
                : (root.opened ? 0 : root.slideFrom === "bottom" ? root.animatedHeight : 0)

        radius: Theme.popupRadius

        topLeftRadius: root.attachMode === "top" ? 0
            : root.sideAttached && !root.sideFlipped ? 0
            : radius

        topRightRadius: root.attachMode === "top" ? 0
            : root.sideAttached && root.sideFlipped ? 0
            : radius

        bottomLeftRadius: root.sideAttached && !root.sideFlipped ? 0 : radius
        bottomRightRadius: root.sideAttached && root.sideFlipped ? 0 : radius
        color: Theme.panelColor
        border.width: 1
        border.color: Theme.panelBorder

        HoverHandler { id: hover }

        Behavior on y {
            NumberAnimation {
                duration: root.slideDuration
                easing.type: Easing.OutQuint

                onRunningChanged: if (!running && !root.opened) root.settled()
            }
        }

        Behavior on x {
            enabled: !root.seamless || root.sideAttached
            NumberAnimation {
                duration: root.slideDuration
                easing.type: Easing.OutQuint
                onRunningChanged: if (!running && !root.opened) root.settled()
            }
        }

        Item {
            id: content

            x: root.sideAttached && !root.sideFlipped ? Theme.popupRadius : 0
            y: root.attachMode === "top" ? Theme.popupRadius : 0
            width: parent.width - (root.sideAttached ? Theme.popupRadius : 0)
            height: root.animatedHeight

            Text {
                id: header

                x: Theme.popupPadding + 8
                y: Theme.popupPadding + 4
                width: root.contentWidth - 16
                visible: root.title !== ""

                text: root.title
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 1
                font.weight: Font.Bold
                color: Colors.subtext
            }

            Column {
                id: headerColumn

                x: Theme.popupPadding
                y: Theme.popupPadding + root.headerHeight
                width: root.contentWidth
                spacing: 2
            }

            Flickable {
                id: view

                x: Theme.popupPadding
                y: Theme.popupPadding + root.headerHeight + root.headerSlotHeight
                width: root.contentWidth
                height: content.height - y - root.footerHeight - Theme.popupPadding

                contentWidth: width
                contentHeight: body.implicitHeight
                interactive: contentHeight > height
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                Column {
                    id: body

                    width: parent.width
                    spacing: 2
                }
            }

            Rectangle {
                id: scrollTrack

                readonly property real scrollRange: Math.max(1, view.contentHeight - view.height)

                x: view.x + view.width + 2
                y: view.y
                width: 4
                height: view.height
                radius: 2
                visible: view.contentHeight > view.height + 1
                color: Theme.alpha(Colors.outlineVariant, 0.5)

                Rectangle {
                    id: thumb

                    width: parent.width
                    height: Math.max(28, scrollTrack.height * view.height / view.contentHeight)
                    y: (scrollTrack.height - height)
                        * Math.max(0, Math.min(1, view.contentY / scrollTrack.scrollRange))
                    radius: 2

                    color: thumbMouse.pressed || thumbMouse.containsMouse
                        ? Colors.primary
                        : Theme.alpha(Colors.text, 0.45)

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }

                MouseArea {
                    id: thumbMouse

                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    property real grabOffset: 0

                    function trackY(mouseY: real): real {
                        return mouseY + anchors.margins;
                    }

                    function scrollTo(mouseY: real): void {
                        const top = thumbMouse.trackY(mouseY) - thumbMouse.grabOffset;
                        const span = scrollTrack.height - thumb.height;
                        const ratio = span > 0 ? Math.max(0, Math.min(1, top / span)) : 0;
                        view.contentY = ratio * scrollTrack.scrollRange;
                    }

                    onPressed: mouse => {
                        const y = thumbMouse.trackY(mouse.y);

                        if (y < thumb.y || y > thumb.y + thumb.height)
                            thumbMouse.grabOffset = thumb.height / 2;
                        else
                            thumbMouse.grabOffset = y - thumb.y;

                        thumbMouse.scrollTo(mouse.y);
                    }

                    onPositionChanged: mouse => {
                        if (thumbMouse.pressed) thumbMouse.scrollTo(mouse.y);
                    }
                }
            }

            Column {
                id: footerColumn

                x: Theme.popupPadding
                y: content.height - Theme.popupPadding - footerColumn.implicitHeight
                width: root.contentWidth
                spacing: 2
            }
        }
    }

    NotchCorner {
        x: 0
        y: 0
        visible: root.attachMode === "top"
        opacity: root.flushLeft ? 0 : 1
    }

    NotchCorner {
        x: root.notch + root.menuWidth - 1
        y: 0
        visible: root.attachMode === "top"
        opacity: root.flushRight ? 0 : 1
        transform: Scale { xScale: -1; origin.x: (root.notch + 1) / 2 }
    }

    SideNotchCorner {
        x: root.sideFlipped ? root.menuWidth - width : 0
        y: 0
        visible: root.sideAttached

        transform: Scale {
            xScale: root.sideFlipped ? -1 : 1
            origin.x: (Theme.popupOverlap + root.notch) / 2
        }
    }

    SideNotchCorner {
        x: root.sideFlipped ? root.menuWidth - width : 0
        y: root.notch + root.animatedHeight - 1
        visible: root.sideAttached

        transform: [
            Scale {
                yScale: -1
                origin.y: (root.notch + 1) / 2
            },
            Scale {
                xScale: root.sideFlipped ? -1 : 1
                origin.x: (Theme.popupOverlap + root.notch) / 2
            }
        ]
    }
}
