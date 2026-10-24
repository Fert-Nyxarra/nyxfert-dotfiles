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
        ? root.screen.height - Theme.barHeight - Theme.gap * 4
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

    // Меню центрируется под своим модулем, но не должно вылезать за остров.
    // Компоновщик умеет двигать окно только по краю ЭКРАНА, поэтому сдвиг
    // считаем сами и передаём через anchor.rect.x.
    readonly property var placement: {
        const item = root.anchorItem;
        const barWidth = item.Window.width;
        const inset = root.edgeInset;

        root.opened;
        root.geometryRevision;

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

    // низ панели в координатах элемента: модули отцентрованы по вертикали
    anchor.item: root.anchorItem
    anchor.rect.x: root.placement.shift
    anchor.rect.y: root.anchorItem.height
        + (Theme.barHeight - root.anchorItem.height) / 2
        - Theme.popupOverlap
    anchor.rect.width: root.anchorItem.width
    anchor.rect.height: 1
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
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
        flushLeft: root.placement.flushLeft
        flushRight: root.placement.flushRight

        onSettled: hideTimer.restart()
    }
}
