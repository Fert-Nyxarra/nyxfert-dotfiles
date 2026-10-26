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

    // Приклеено к кромке панели: обратные скругления на стыке и выезд
    // из-под неё. Так ведёт себя меню у ВЕРХНЕЙ панели — она для этого и
    // рисовалась. У остальных трёх кромок меню — обычная карточка, которая
    // выезжает со стороны панели: стык там пришлось бы рисовать заново, в
    // зеркальном и повёрнутом виде.
    property bool seamless: true
    // откуда выезжает карточка, когда seamless выключен: "bottom" | "left" | "right"
    property string slideFrom: "bottom"

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

    // Насколько меню выехало: 0 — спрятано под панелью, 1 — на месте.
    // По этому же числу панель гасит свой угол, поэтому угол и меню идут
    // синхронно: ни «угол уже острый, а меню ещё нет», ни наоборот.
    readonly property real revealProgress: !root.seamless
        ? (root.opened ? 1 : 0)
        : root.animatedHeight > 0
        ? Math.max(0, Math.min(1,
            (surface.y + root.animatedHeight + Theme.popupRadius) / root.animatedHeight))
        : 0

    // окно шире самого меню на поля под обратные скругления
    implicitWidth: root.menuWidth + (root.seamless ? root.notch * 2 : 0)
    implicitHeight: Math.max(1, Math.round(root.animatedHeight))

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

    Rectangle {
        id: surface

        // прямоугольник поднят на радиус вверх: верхние скругления и верхняя
        // рамка остаются за границей окна и не рисуются
        width: root.menuWidth
        height: root.seamless ? root.animatedHeight + Theme.popupRadius : root.animatedHeight

        // Приклеенное меню стоит выше окна на радиус: его верхние скругления
        // и верхняя рамка остаются за границей и не рисуются. Карточка же
        // целиком внутри окна и уезжает за ту грань, со стороны которой
        // лежит панель.
        x: root.seamless ? root.notch
            : root.opened ? 0
            : root.slideFrom === "left" ? -root.menuWidth
            : root.slideFrom === "right" ? root.menuWidth
            : 0

        y: root.seamless
            ? (root.opened ? -Theme.popupRadius : -(root.animatedHeight + Theme.popupRadius))
            : (root.opened ? 0 : root.slideFrom === "bottom" ? root.animatedHeight : 0)

        radius: Theme.popupRadius
        // У приклеенного меню верхние углы прямые: обычно их всё равно
        // срезает обрезка выше, но если она не сработает, меню не станет
        // вдруг отдельной карточкой со скруглённой макушкой.
        topLeftRadius: root.seamless ? 0 : radius
        topRightRadius: root.seamless ? 0 : radius
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
            enabled: !root.seamless
            NumberAnimation {
                duration: root.slideDuration
                easing.type: Easing.OutQuint
                onRunningChanged: if (!running && !root.opened) root.settled()
            }
        }

        Item {
            id: content

            x: 0
            // у приклеенного меню верхний радиус спрятан за кромкой окна,
            // поэтому содержимое начинается ниже; у карточки — с самого верха
            y: root.seamless ? Theme.popupRadius : 0
            width: parent.width
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
        visible: root.seamless
        opacity: root.flushLeft ? 0 : 1
    }

    // то же скругление, зеркально: грань меню приходится на локальный x = 1
    NotchCorner {
        x: root.notch + root.menuWidth - 1
        y: 0
        visible: root.seamless
        opacity: root.flushRight ? 0 : 1
        transform: Scale { xScale: -1; origin.x: (root.notch + 1) / 2 }
    }
}
