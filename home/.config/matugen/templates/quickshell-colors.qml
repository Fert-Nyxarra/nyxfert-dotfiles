pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color primary: "{{colors.primary.dark.hex}}"
    readonly property color textOnPrimary: "{{colors.on_primary.dark.hex}}"
    readonly property color primaryContainer: "{{colors.primary_container.dark.hex}}"
    readonly property color textOnPrimaryContainer: "{{colors.on_primary_container.dark.hex}}"
    readonly property color secondary: "{{colors.secondary.dark.hex}}"
    readonly property color tertiary: "{{colors.tertiary.dark.hex}}"
    readonly property color error: "{{colors.error.dark.hex}}"
    readonly property color textOnError: "{{colors.on_error.dark.hex}}"
    readonly property color surface: "{{colors.surface.dark.hex}}"
    readonly property color surfaceContainer: "{{colors.surface_container.dark.hex}}"
    readonly property color surfaceContainerHigh: "{{colors.surface_container_high.dark.hex}}"
    readonly property color text: "{{colors.on_surface.dark.hex}}"
    readonly property color subtext: "{{colors.on_surface_variant.dark.hex}}"
    readonly property color outline: "{{colors.outline.dark.hex}}"
    readonly property color outlineVariant: "{{colors.outline_variant.dark.hex}}"
}
