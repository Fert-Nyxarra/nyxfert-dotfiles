// ~/.config/quickshell/widgets/Popup.qml
// Контекстное меню панели: окно, приклеенное к низу острова.
//
// Внешность — в MenuSurface, здесь только окно: расчёт места под своим
// модулем, перехват ввода и показ/скрытие.
//
// Клавиатуру это окно не получает (в Hyprland всплывающее окно либо мышь,
// либо клавиатура): меню, которому нужен ввод, просит wantsKeyboard, панель
// включает себе keyboardFocus и пересылает нажатия сигналом keyPressed.
// Лаунчеру нужны оба ввода сразу, поэтому он — не Popup, а MenuWindow.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs

PopupWindow {
    id: root

    // элемент панели, под которым показываем меню
    required property Item anchorItem
    property int preferredWidth: Theme.popupWidth
    property int maximumWidth: 460
    // длинные меню (например, у Steam) не должны уезжать за край экрана
    property int maximumHeight: root.screen
        ? root.screen.height - Theme.barThickness - Theme.barMargin * 4
        : 640
    property bool opened: false
    // перехватывать ли ввод: меню по наведению этого не делают
    property bool grabFocus: true
    // участвует ли в правиле «одно меню за раз»
    property bool managed: true
    // нужна ли меню клавиатура (пароль Wi-Fi) — см. Bar.qml
    property bool wantsKeyboard: false

    signal keyPressed(var event)

    // Отступ от края острова: радиус скругления плюс ширина обратного
    // скругления, иначе меню вместе с фаской заезжает в зону загиба угла.
    // 0 — вплотную к краю; тогда модуль гасит соответствующий угол острова.
    property int edgeInset: Theme.radius + Theme.notchRadius

    property alias title: surface.title
    default property alias content: surface.content
    property alias header: surface.header
    property alias footer: surface.footer
    property alias contentSpacing: surface.contentSpacing
    property alias slideDuration: surface.slideDuration
    readonly property alias view: surface.view
    readonly property int contentWidth: surface.contentWidth
    // ход выезда меню: по нему панель гасит свой угол (см. Bar.qml)
    readonly property real revealProgress: surface.revealProgress

    // курсор над самим меню — по нему меню «по наведению» понимают, что их
    // рано закрывать
    readonly property bool hovered: surface.hovered

    // меню на экране, включая анимацию закрытия: панель гасит свой угол
    // именно по этому флагу, иначе угол скруглится раньше времени
    readonly property bool attached: root.visible

    readonly property int menuWidth: Math.min(root.maximumWidth,
        Math.max(root.preferredWidth, surface.bodyWidth + Theme.popupPadding * 2))

    // Положение модуля в панели плавает (соседний модуль поменял ширину), а
    // mapToItem сам по себе не пересчитывается — следим TransformWatcher'ом.
    property int geometryRevision: 0

    TransformWatcher {
        a: root.anchorItem
        b: root.anchorItem.Window.contentItem
        onTransformChanged: root.geometryRevision++
    }

    // Меню центрируется на своём модуле, но не должно вылезать за экран.
    // Компоновщик умеет двигать окно только по краю ЭКРАНА, поэтому сдвиг
    // считаем сами и передаём через anchor.rect.
    readonly property var placement: {
        const item = root.anchorItem;
        const inset = root.edgeInset;

        root.opened;
        root.geometryRevision;

        if (Theme.barVertical) {
            // боковая панель: двигаем меню по вертикали
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

    // Насколько модуль утоплен в толщину панели: модули отцентрованы, а
    // меню должно отсчитываться от кромки острова, а не от края модуля.
    readonly property real barInset: Theme.barVertical
        ? (Theme.barThickness - root.anchorItem.width) / 2
        : (Theme.barThickness - root.anchorItem.height) / 2

    anchor.item: root.anchorItem

    // У верхней панели меню висит под ней и заезжает под кромку на
    // popupOverlap — шва не видно. У остальных трёх это обычная карточка с
    // зазором popupGap.
    // У боковой панели меню не отстоит, а заезжает под кромку на
    // popupOverlap — ровно как под верхней: иначе на стыке видна щель.
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

    // Поправки компоновщика выключены: границы держит расчёт выше, а SlideX
    // вдобавок сдвигал окно на пару пикселей.
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

    // Окно показываем сразу, прячем — после анимации закрытия. Через
    // Connections, а не onOpenedChanged: свой обработчик в наследнике
    // перекрыл бы обработчик базового типа.
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

    // Окно гасим не сразу, а через пару кадров после того, как меню уехало
    // под панель: иначе Hyprland подхватывает последний кадр с ещё видимым
    // меню и гасит уже его — на экране остаётся призрак грани.
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

        // стык с панелью рисуется только у верхней кромки — см. MenuSurface
        // верхняя панель — стык под кромкой, боковая — он же, повёрнутый,
        // нижняя — обычная карточка
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
