pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property var current: null

    function opened(menu): void {
        if (current && current !== menu) current.close();
        current = menu;
    }

    function closed(menu): void {
        if (current === menu) current = null;
    }

    function clicked(item): void {
        if (current && current.anchorItem !== item) current.close();
    }

    function closeCurrent(): void {
        if (current) current.close();
    }
}
