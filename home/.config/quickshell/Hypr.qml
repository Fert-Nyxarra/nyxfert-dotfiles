pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {

    function focusWorkspace(id: int): void {
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = ${id} })`
            : `workspace ${id}`);
    }

    function cycleWorkspace(step: string): void {
        Hyprland.dispatch(Hyprland.usingLua
            ? `hl.dsp.focus({ workspace = "${step}" })`
            : `workspace ${step}`);
    }
}
