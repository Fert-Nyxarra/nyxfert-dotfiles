import QtQuick
import Quickshell
import qs
import qs.widgets

Popup {
    id: root

    required property var trayItem

    property var path: []

    title: root.trayItem
        ? (root.path.length > 0
            ? root.cleanLabel(root.path[root.path.length - 1].text)
            : (root.trayItem.tooltipTitle || root.trayItem.title || root.trayItem.id))
        : ""

    readonly property var currentMenu: root.path.length > 0
        ? root.path[root.path.length - 1]
        : (root.trayItem ? root.trayItem.menu : null)

    function cleanLabel(text: string): string {
        return (text ?? "").split("&&").map(part => part.replace(/&/g, "")).join("&");
    }

    function entryGlyph(entry): string {
        if (entry.buttonType === QsMenuButtonType.CheckBox)
            return entry.checkState === Qt.Checked ? "󰄲" : "󰄱";
        if (entry.buttonType === QsMenuButtonType.RadioButton)
            return entry.checkState === Qt.Checked ? "󰐾" : "󰝦";
        return "";
    }

    function trigger(entry): void {
        if (entry.hasChildren) {
            root.path = [...root.path, entry];
            return;
        }

        entry.triggered();
        root.close();
    }

    QsMenuOpener {
        id: opener
        menu: root.currentMenu
    }

    onOpenedChanged: if (!root.opened) root.path = []

    MenuRow {
        width: root.contentWidth
        visible: root.path.length > 0
        glyph: "󰌍"
        label: "Назад"
        onClicked: root.path = root.path.slice(0, -1)
    }

    MenuSeparator {
        width: root.contentWidth
        visible: root.path.length > 0
    }

    Repeater {
        model: opener.children

        Loader {
            required property var modelData

            width: root.contentWidth
            sourceComponent: modelData.isSeparator ? separatorComponent : entryComponent
        }
    }

    MenuRow {
        width: root.contentWidth
        visible: opener.children ? opener.children.values.length === 0 : true
        rowEnabled: false
        glyph: "󰂭"
        label: "Меню пустое"
    }

    Component {
        id: separatorComponent

        MenuSeparator {}
    }

    Component {
        id: entryComponent

        MenuRow {
            label: root.cleanLabel(modelData.text)
            glyph: root.entryGlyph(modelData)
            iconSource: modelData.icon
            submenu: modelData.hasChildren
            rowEnabled: modelData.enabled

            onClicked: root.trigger(modelData)
        }
    }
}
