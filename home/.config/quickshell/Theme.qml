pragma Singleton

import QtQuick
import Quickshell

Singleton {

    readonly property string barPosition: Settings.barPosition

    readonly property bool barVertical: Settings.barVertical

    readonly property bool barFlipped: Settings.barFlipped

    readonly property bool island: Settings.barIsland

    readonly property int barThickness: 38
    readonly property int gap: 8
    readonly property int groupGap: 1
    readonly property int sideMargin: 12
    readonly property int radius: 18
    readonly property int padding: 12
    readonly property int barPadding: 6

    readonly property int barMargin: island ? gap : 0
    readonly property int barSideMargin: island ? sideMargin : 0
    readonly property int barRadius: island ? radius : 0

    readonly property int itemHeight: 28
    readonly property int itemRadius: 10

    readonly property int popupWidth: 290
    readonly property int popupRadius: 16
    readonly property int popupPadding: 8
    readonly property int popupOverlap: 2
    readonly property int popupGap: 6
    readonly property int notchRadius: 10
    readonly property int rowHeight: 34
    readonly property int rowRadius: 10

    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    readonly property int animDuration: 220
    readonly property int animEasing: Easing.OutCubic

    readonly property color panelColor: Colors.surfaceContainer
    readonly property color panelBorder: alpha(Colors.outlineVariant, 0.6)

    function alpha(color: color, a: real): color {
        return Qt.rgba(color.r, color.g, color.b, a);
    }
}
