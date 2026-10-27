// ~/.config/quickshell/widgets/MenuSurface.qml
// Внешность меню: фон с обрезанной верхней кромкой, обратные скругления
// («чёлка»), закреплённые шапка и подвал, прокручиваемая середина и ползунок.
//
// Вынесено из Popup, потому что то же самое нужно лаунчеру — а он не может
// быть всплывающим окном: в Hyprland popup либо получает клавиатуру, либо
// мышь, но не одновременно. Лаунчер поэтому собственный слой (MenuWindow),
// и обе части переиспользуют эту поверхность.

import QtQuick
import QtQuick.Shapes
import Quickshell
import qs

Item {
    id: root

    // Фон поднят выше своей верхней границы (так срезается верхняя кромка и
    // скругления), поэтому обрезаем сами: в полноэкранном слое за нас этого
    // уже не делает край окна.
    clip: true

    property bool opened: false
    property string title: ""
    property int menuWidth: Theme.popupWidth
    property int maximumHeight: 640
    // грань меню совпала с гранью острова — обратное скругление там не нужно
    property bool flushLeft: false
    property bool flushRight: false

    // Как меню крепится к панели:
    //   "top"  — висит под верхней кромкой: стык со скруглениями, выезд вниз;
    //   "side" — приклеено к боковой панели: тот же стык, повёрнутый на 90°;
    //   "card" — обычная карточка (нижняя панель), выезжает со стороны панели.
    property string attachMode: "top"
    // боковая панель справа: стык зеркалим
    property bool sideFlipped: false
    // откуда выезжает карточка в режиме "card"
    property string slideFrom: "bottom"

    readonly property bool seamless: root.attachMode !== "card"
    readonly property bool sideAttached: root.attachMode === "side"

    default property alias content: body.data
    property alias header: headerColumn.data
    property alias footer: footerColumn.data
    property alias contentSpacing: body.spacing
    readonly property alias view: view

    readonly property bool hovered: hover.hovered

    // выезд или заезд закончился — окну пора показаться или спрятаться
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

    // Видимая высота тянется за contentHeight с задержкой: когда список
    // фильтруется, меню съезжает плавно, а не прыгает на новый размер.
    property real animatedHeight: root.contentHeight

    Behavior on animatedHeight {
        NumberAnimation {
            duration: Math.max(120, root.slideDuration - 40)
            easing.type: Easing.OutCubic
        }
    }

    // длинному меню нужно чуть больше времени на выезд; меню может попросить
    // свою длительность (лаунчер открывается быстрее остальных)
    property int slideDuration: Math.min(430, 200 + root.contentHeight * 0.3)

    // нижняя грань меню в координатах окна: по ней подрезаются скругления,
    // пока меню ещё выезжает
    readonly property real menuBottom: surface.y + surface.height
    readonly property real menuRight: root.sideFlipped
        ? root.menuWidth - surface.x
        : surface.x + surface.width

    // Насколько меню выехало: 0 — спрятано под панелью, 1 — на месте.
    // По этому же числу панель гасит свой угол, поэтому угол и меню идут
    // синхронно: ни «угол уже острый, а меню ещё нет», ни наоборот.
    readonly property real revealProgress: !root.seamless
        ? (root.opened ? 1 : 0)
        : root.sideAttached
        ? Math.max(0, Math.min(1, root.menuRight / Math.max(1, root.menuWidth)))
        : root.animatedHeight > 0
        ? Math.max(0, Math.min(1,
            (surface.y + root.animatedHeight + Theme.popupRadius) / root.animatedHeight))
        : 0

    // Окно шире (или выше) самого меню на поля под обратные скругления: у
    // верхней панели поля по бокам, у боковой — сверху и снизу.
    implicitWidth: root.menuWidth
        + (root.attachMode === "top" ? root.notch * 2 : 0)

    implicitHeight: Math.max(1, Math.round(root.animatedHeight
        + (root.sideAttached ? root.notch * 2 : 0)))

    component NotchCorner: Item {
        id: corner

        // пока из-под панели выезжает скруглённый низ меню, скруглять на
        // стыке ещё нечего: боковой грани меню там попросту нет
        readonly property real r: Math.max(0, Math.min(root.notch,
            root.menuBottom - Theme.popupRadius - Theme.popupOverlap))

        implicitWidth: root.notch + 1
        implicitHeight: Theme.popupOverlap + root.notch
        visible: corner.r > 0.5

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // материал: прямоугольник минус четверть круга
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

            // рамка панели продолжается по дуге
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

    // То же обратное скругление, но для боковой панели: стык идёт по
    // вертикали, поэтому координаты у шейпа зеркально переставлены (x↔y).
    component SideNotchCorner: Item {
        id: sideCorner

        // пока меню только выезжает из-под панели, скруглять нечего
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

            // рамка панели продолжается по дуге
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

        // прямоугольник поднят на радиус вверх: верхние скругления и верхняя
        // рамка остаются за границей окна и не рисуются
        // У боковой панели меню выезжает вбок, поэтому «лишний» радиус,
        // который прячется под кромкой, добавляется не к высоте, а к ширине.
        width: root.sideAttached
            ? root.menuWidth + Theme.popupRadius
            : root.menuWidth

        height: root.attachMode === "top"
            ? root.animatedHeight + Theme.popupRadius
            : root.animatedHeight

        // Приклеенное меню стоит за кромкой окна на радиус: скругления и
        // рамка с той стороны остаются снаружи и не рисуются. Карточка же
        // целиком внутри окна и уезжает за ту грань, со стороны которой
        // лежит панель.
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

        // Прямые углы — с той стороны, которой меню прижато к панели. У
        // верхней это верхние два, у боковой — те, что смотрят на панель.
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

                // меню уехало под панель — окно можно гасить
                onRunningChanged: if (!running && !root.opened) root.settled()
            }
        }

        // карточка у боковой панели уезжает вбок, сигнал нужен и оттуда
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

            // спрятанный за кромкой радиус не должен съедать содержимое:
            // сдвигаем его на ту же величину с нужной стороны
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

            // Flickable, чтобы длинное меню можно было прокрутить колесом
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

            // Ползунок прокрутки. Живёт в правом отступе меню, поэтому ничего
            // не перекрывает и не заставляет строки менять ширину, когда
            // появляется. Тащим не сам ползунок, а contentY: положение
            // ползунка на него завязано и подтянется само.
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

                    // поле промаха: по четырём пикселям попасть тяжело
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    // где держим ползунок относительно его верха
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

                        // мимо ползунка — прыгаем туда и продолжаем тащить
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

    // то же скругление, зеркально: грань меню приходится на локальный x = 1
    NotchCorner {
        x: root.notch + root.menuWidth - 1
        y: 0
        visible: root.attachMode === "top"
        opacity: root.flushRight ? 0 : 1
        transform: Scale { xScale: -1; origin.x: (root.notch + 1) / 2 }
    }

    // стык с боковой панелью: сверху и снизу от меню
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
