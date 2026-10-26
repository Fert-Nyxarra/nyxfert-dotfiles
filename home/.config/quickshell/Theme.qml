pragma Singleton

// ~/.config/quickshell/Theme.qml
// Размеры, шрифты и прочие константы оформления.
// Цвета живут отдельно — в Colors.qml, который генерирует matugen.
//
// Положение и режим панели выбираются в настройках (CTRL + SUPER + S) и живут
// в Settings.qml; здесь из них считается вся геометрия, от которой зависят
// панель и меню: толщина, отступы и скругление.

import QtQuick
import Quickshell

Singleton {
    // где держим панель: "top" | "bottom" | "left" | "right"
    readonly property string barPosition: Settings.barPosition
    // боковая панель: модули идут столбиком, меню выезжают сбоку карточкой
    readonly property bool barVertical: Settings.barVertical
    // панель у дальнего края (снизу или справа): меню выезжают наоборот
    readonly property bool barFlipped: Settings.barFlipped
    // «остров» со скруглением и отступами против «панели» во всю кромку
    readonly property bool island: Settings.barIsland

    // геометрия панели: один общий «остров» на всю длину экрана
    readonly property int barThickness: 38 // высота у верхней и нижней, ширина у боковых
    readonly property int gap: 8          // расстояние между элементами внутри модуля
    readonly property int groupGap: 1     // расстояние между модулями
    readonly property int sideMargin: 12  // отступ панели от краёв экрана
    readonly property int radius: 18      // скругление острова
    readonly property int padding: 12     // внутренний отступ модуля
    readonly property int barPadding: 6   // отступ от края острова до модулей

    // В режиме «панель» отступов и скругления нет вовсе: панель прижата к
    // кромке экрана во всю его длину, как панель задач.
    readonly property int barMargin: island ? gap : 0        // отступ от своего края экрана
    readonly property int barSideMargin: island ? sideMargin : 0 // отступ по длине панели
    readonly property int barRadius: island ? radius : 0

    // элемент внутри острова: плоский, подсвечивается только под курсором
    readonly property int itemHeight: 28
    readonly property int itemRadius: 10

    // контекстные меню
    readonly property int popupWidth: 290
    readonly property int popupRadius: 16
    readonly property int popupPadding: 8
    readonly property int popupOverlap: 2 // меню заезжает под панель, чтобы не было шва
    readonly property int popupGap: 6     // зазор между боковой панелью и карточкой меню
    readonly property int notchRadius: 10 // обратное скругление на стыке меню и панели
    readonly property int rowHeight: 34
    readonly property int rowRadius: 10

    // типографика
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    // анимации
    readonly property int animDuration: 220
    readonly property int animEasing: Easing.OutCubic

    // Фон и рамка панели и контекстных меню — одни и те же: иначе на стыке
    // видна ступенька и меню перестаёт читаться как продолжение панели.
    //
    // Фон НЕПРОЗРАЧНЫЙ намеренно: меню заезжает на панель, а обратные
    // скругления — и на панель, и на меню. С полупрозрачным фоном в местах
    // нахлёста тон удваивался, и на стыках проступали лишние линии.
    readonly property color panelColor: Colors.surfaceContainer
    readonly property color panelBorder: alpha(Colors.outlineVariant, 0.6)

    // цвет с прозрачностью: Theme.alpha(Colors.primary, 0.3)
    function alpha(color: color, a: real): color {
        return Qt.rgba(color.r, color.g, color.b, a);
    }
}
