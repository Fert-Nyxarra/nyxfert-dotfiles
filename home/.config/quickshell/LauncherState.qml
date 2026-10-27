pragma Singleton

import QtQuick
import Quickshell

Singleton {

    property bool opened: false

    signal toggleRequested

    function toggle(): void {
        toggleRequested();
    }
}
