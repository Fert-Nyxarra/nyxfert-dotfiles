pragma Singleton

// ВАЖНО: pragma Singleton — первой строкой. Сканер синглтонов в Quickshell
// считает фигурные скобки и не пропускает комментарии, поэтому "{" в шапке
// выше pragma превращает файл в обычный тип, и Colors.* перестают работать.

// ~/.config/matugen/templates/quickshell-colors.qml
// генерирует matugen -> ~/.config/quickshell/Colors.qml
//
// Имена ролей Material You изменены: свойство, начинающееся на "on" + заглавная
// буква, QML считает обработчиком сигнала, поэтому on_primary -> textOnPrimary.

import QtQuick
import Quickshell

Singleton {
    readonly property color primary: "#ff6d7c"
    readonly property color textOnPrimary: "#42000d"
    readonly property color primaryContainer: "#7a0020"
    readonly property color textOnPrimaryContainer: "#ffb0b4"
    readonly property color secondary: "#ff6d7c"
    readonly property color tertiary: "#f67a25"
    readonly property color error: "#ff7063"
    readonly property color textOnError: "#3a0001"
    readonly property color surface: "#200e0f"
    readonly property color surfaceContainer: "#2e1a1b"
    readonly property color surfaceContainerHigh: "#3a2425"
    readonly property color text: "#debbbc"
    readonly property color subtext: "#bc9394"
    readonly property color outline: "#987273"
    readonly property color outlineVariant: "#503234"
}
