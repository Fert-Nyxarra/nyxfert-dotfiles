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
    readonly property color primary: "#ff629a"
    readonly property color textOnPrimary: "#45001f"
    readonly property color primaryContainer: "#770039"
    readonly property color textOnPrimaryContainer: "#ffa9c0"
    readonly property color secondary: "#dc7d9a"
    readonly property color tertiary: "#ff6d1e"
    readonly property color error: "#ff6a5d"
    readonly property color textOnError: "#3b0001"
    readonly property color surface: "#1c1013"
    readonly property color surfaceContainer: "#2a1c1f"
    readonly property color surfaceContainerHigh: "#35262a"
    readonly property color text: "#d1babf"
    readonly property color subtext: "#b09399"
    readonly property color outline: "#8c7077"
    readonly property color outlineVariant: "#4a343a"
}
