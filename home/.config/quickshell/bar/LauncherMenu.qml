import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs
import qs.widgets

MenuWindow {
    id: root

    readonly property int rowHeight: 42

    edgeInset: 0
    contentSpacing: 0

    slideDuration: 230
    preferredWidth: 420
    maximumWidth: 420
    maximumHeight: 560

    property string query: ""
    property int selected: 0

    readonly property var entries: {
        const all = DesktopEntries.applications.values.filter(entry => !entry.noDisplay);
        all.sort((a, b) => a.name.localeCompare(b.name));
        return all;
    }

    readonly property string needle: root.query.trim().toLowerCase()

    readonly property var results: root.needle === ""
        ? root.entries
        : root.entries.filter(entry => root.score(entry, root.needle) > 0)

    function score(entry, q: string): int {
        const name = (entry.name ?? "").toLowerCase();
        if (name.startsWith(q)) return 4;
        if (name.includes(q)) return 3;

        const generic = (entry.genericName ?? "").toLowerCase();
        if (generic.includes(q)) return 2;

        const extra = ((entry.comment ?? "") + " " + (entry.keywords ?? "") + " " + entry.id).toLowerCase();
        return extra.includes(q) ? 1 : 0;
    }

    function launch(entry): void {
        if (!entry) return;
        entry.execute();
        root.close();
    }

    function handleKey(event): void {
        event.accepted = true;

        if (event.key === Qt.Key_Escape) {
            root.close();
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.launch(root.results[root.selected]);
        } else if (event.key === Qt.Key_Down) {
            root.move(1);
        } else if (event.key === Qt.Key_Up) {
            root.move(-1);
        } else if (event.key === Qt.Key_Backspace) {
            root.query = (event.modifiers & Qt.ControlModifier) ? "" : root.query.slice(0, -1);
        } else if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) {
            root.query = "";
        } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 0x20) {
            root.query += event.text;
        } else {
            event.accepted = false;
        }
    }

    onKeyPressed: event => root.handleKey(event)

    onQueryChanged: {
        root.selected = 0;
        root.view.contentY = 0;
    }

    function move(delta: int): void {
        if (root.results.length === 0) return;

        root.selected = Math.max(0, Math.min(root.results.length - 1, root.selected + delta));
        root.ensureVisible(root.selected);
    }

    function ensureVisible(index: int): void {
        const entry = root.results[index];
        if (!entry) return;

        let item = null;
        for (let i = 0; i < repeater.count; i++) {
            const candidate = repeater.itemAt(i);
            if (candidate && candidate.modelData === entry) {
                item = candidate;
                break;
            }
        }

        if (!item) return;

        if (item.y < root.view.contentY)
            root.view.contentY = item.y;
        else if (item.y + item.height > root.view.contentY + root.view.height)
            root.view.contentY = item.y + item.height - root.view.height;
    }

    onOpenedChanged: {
        root.query = "";
        root.selected = 0;
        if (root.opened) root.view.contentY = 0;
    }

    header: Rectangle {
        width: root.contentWidth
        implicitHeight: 38
        radius: 10
        color: Theme.alpha(Colors.surfaceContainerHigh, 0.9)
        border.width: 1
        border.color: root.opened
            ? Theme.alpha(Colors.primary, 0.8)
            : Theme.alpha(Colors.outlineVariant, 0.8)

        Text {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "\udb80\udf49"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 1
            color: Colors.subtext
        }

        Text {
            id: queryText

            x: 38
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 48

            text: root.query
            elide: Text.ElideLeft
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Colors.text
        }

        Text {
            x: 42
            anchors.verticalCenter: parent.verticalCenter
            visible: root.query === ""
            text: "Поиск приложений"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            color: Colors.outline
        }

        Rectangle {
            x: 38 + Math.min(queryText.contentWidth, queryText.width) + 1
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: Theme.fontSize + 4
            radius: 1
            color: Colors.primary
            visible: caretTimer.shown
        }

        Timer {
            id: caretTimer

            property bool shown: true

            interval: 530
            running: root.opened
            repeat: true
            onTriggered: caretTimer.shown = !caretTimer.shown
        }
    }

    Repeater {
        id: repeater
        model: root.entries

        Item {
            id: appRow

            required property var modelData

            readonly property bool matched: root.results.indexOf(appRow.modelData) >= 0
            readonly property bool current: root.results[root.selected] === appRow.modelData
            readonly property string iconSource: Quickshell.iconPath(modelData.icon, true)

            width: root.contentWidth
            height: appRow.matched ? root.rowHeight : 0
            opacity: appRow.matched ? 1 : 0

            x: appRow.matched ? 0 : -14
            clip: true
            visible: height > 0.5

            Behavior on height {
                NumberAnimation {
                    duration: 190
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on x {
                NumberAnimation {
                    duration: 190
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                anchors.bottomMargin: 1
                radius: Theme.rowRadius

                color: appMouse.containsMouse || appRow.current
                    ? Theme.alpha(Colors.text, 0.10)
                    : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }
            }

            IconImage {
                id: appIcon
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 26
                asynchronous: true
                visible: appRow.iconSource !== ""
                source: appRow.iconSource
            }

            Text {
                x: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                horizontalAlignment: Text.AlignHCenter
                visible: appRow.iconSource === ""
                text: "󰣆"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize + 4
                color: Colors.subtext
            }

            Column {
                x: 44
                width: parent.width - 52
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: appRow.modelData.name
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: appRow.current ? Font.DemiBold : Font.Normal
                    color: Colors.text
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: appRow.modelData.genericName || appRow.modelData.comment || ""
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 3
                    color: Colors.subtext
                }
            }

            MouseArea {
                id: appMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selected = root.results.indexOf(appRow.modelData)
                onClicked: root.launch(appRow.modelData)
            }
        }
    }

    MenuRow {
        width: root.contentWidth
        visible: root.results.length === 0
        rowEnabled: false
        glyph: "󰍉"
        label: "Ничего не найдено"
    }

    footer: [
        MenuSeparator { width: root.contentWidth },

        Row {
            width: root.contentWidth
            spacing: 6

            component PowerButton: Rectangle {
                id: button

                property string glyph: ""
                property string label: ""
                property color accent: Colors.subtext

                signal activated

                implicitWidth: (root.contentWidth - 12) / 3
                implicitHeight: 38
                radius: Theme.rowRadius
                color: buttonMouse.containsMouse
                    ? Theme.alpha(button.accent, 0.18)
                    : Theme.alpha(Colors.surfaceContainerHigh, 0.7)

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: button.glyph
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize + 1
                        color: button.accent
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: button.label
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize - 2
                        color: buttonMouse.containsMouse ? button.accent : Colors.subtext
                    }
                }

                MouseArea {
                    id: buttonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: button.activated()
                }
            }

            PowerButton {
                glyph: "󰗽"
                label: "Сеанс"
                onActivated: {
                    root.close();
                    logoutProcess.running = true;
                }
            }

            PowerButton {
                glyph: "󰜉"
                label: "Перезагрузка"
                onActivated: {
                    root.close();
                    rebootProcess.running = true;
                }
            }

            PowerButton {
                glyph: "󰐥"
                label: "Выключение"
                accent: Colors.error
                onActivated: {
                    root.close();
                    shutdownProcess.running = true;
                }
            }
        }
    ]

    Process {
        id: logoutProcess
        command: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"]
    }

    Process {
        id: rebootProcess
        command: ["reboot"]
    }

    Process {
        id: shutdownProcess
        command: ["shutdown", "now"]
    }
}
