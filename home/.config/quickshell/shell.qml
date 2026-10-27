import Quickshell
import Quickshell.Io
import qs
import qs.bar

ShellRoot {

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            LauncherState.toggle();
        }

        function state(): string {
            return LauncherState.opened ? "open" : "closed";
        }

        function wallpaper(): void {
            WallpaperService.toggle();
        }

        function clipboard(): void {
            ClipboardService.toggle();
        }

        function settings(): void {
            Settings.toggle();
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    WallpaperPicker {}

    SettingsWindow {}
}
