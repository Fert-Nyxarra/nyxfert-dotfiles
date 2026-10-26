// ~/.config/quickshell/widgets/MenuWindow.qml
// Меню, которое живёт собственным слоем, а не всплывающим окном.
//
// Зачем так: в Hyprland всплывающее окно получает ЛИБО клавиатуру, либо
// мышь. С keyboardFocus: Exclusive у панели popup перестаёт получать
// указатель, а без него клавиатура не доходит, если меню открыли клавишей,
// а не кликом. Обычный слой wlr-layer-shell получает и то и другое.
//
// Слой растянут на весь экран и прозрачен: клик мимо меню закрывает его.
// Так же поступают rofi и прочие лаунчеры, и это заодно решает две беды:
// перехват фокуса (HyprlandFocusGrab) глотал клики по самой панели, так что
// меню нельзя было закрыть тем же значком, которым открыли; а при попытке
// добавить панель в перехват клики всё равно не доходили.
//
// Внешность общая с контекстными меню — MenuSurface.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

PanelWindow {
    id: root

    // монитор, к панели которого прижимаемся
    required property var barScreen

    property bool opened: false
    property int preferredWidth: Theme.popupWidth
    property int maximumWidth: 460
    property int maximumHeight: 560
    // отступ от левого края острова; 0 — вплотную, и тогда модуль гасит угол
    property int edgeInset: 0

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

    // меню на экране, включая анимацию закрытия
    readonly property bool attached: root.visible

    signal keyPressed(var event)

    readonly property int menuWidth: Math.min(root.maximumWidth,
        Math.max(root.preferredWidth, surface.bodyWidth + Theme.popupPadding * 2))

    screen: root.barScreen

    WlrLayershell.namespace: "quickshell:menu"
    WlrLayershell.layer: WlrLayer.Top
    // слой берёт клавиатуру себе, пока открыт; мышь при этом остаётся
    WlrLayershell.keyboardFocus: root.opened
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    // Слой на весь экран, но полосу себе не резервирует и чужие не учитывает:
    // иначе меню уехало бы вниз на высоту панели.
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

    // клик мимо меню — закрыть; лежит под самим меню, так что его не трогает
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: root.close()
    }

    // клавиатура приходит прямо сюда — слой её получает сам
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => root.keyPressed(event)
    }

    MenuSurface {
        id: surface

        // Встаём туда же, куда встало бы всплывающее меню: у своей кромки,
        // со стороны панели. У верхней — заезжая под неё на popupOverlap,
        // у остальных — с зазором popupGap.
        x: Theme.barVertical
            ? (Theme.barPosition === "left"
                ? Theme.barMargin + Theme.barThickness + Theme.popupGap
                : root.width - Theme.barMargin - Theme.barThickness
                    - Theme.popupGap - surface.width)
            : Theme.barSideMargin + root.edgeInset - (surface.seamless ? surface.notch : 0)

        y: Theme.barVertical
            ? Math.max(Theme.barMargin,
                Math.min(root.height - surface.height - Theme.barMargin,
                         Theme.barSideMargin + root.edgeInset))
            : (Theme.barPosition === "bottom"
                ? root.height - Theme.barMargin - Theme.barThickness
                    - Theme.popupGap - surface.height
                : Theme.barMargin + Theme.barThickness - Theme.popupOverlap)
        width: surface.implicitWidth
        height: surface.implicitHeight

        opened: root.opened
        menuWidth: root.menuWidth
        maximumHeight: root.maximumHeight

        seamless: Theme.barPosition === "top"
        slideFrom: Theme.barPosition === "left" ? "left"
            : Theme.barPosition === "right" ? "right"
            : "bottom"

        flushLeft: root.edgeInset === 0
        flushRight: false

        onSettled: hideTimer.restart()
    }
}
