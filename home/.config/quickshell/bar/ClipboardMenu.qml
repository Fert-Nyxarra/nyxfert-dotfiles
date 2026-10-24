// ~/.config/quickshell/bar/ClipboardMenu.qml
// История буфера обмена на SUPER + V — как в Windows.
//
// Меню собственным слоем, а не всплывающим окном: его открывают клавишей, а
// в Hyprland popup получает ЛИБО клавиатуру, либо мышь (см. README).
// Стрелки ходят по списку, Enter кладёт запись обратно в буфер и закрывает,
// Esc закрывает, ПКМ по строке — забыть запись.

import QtQuick
import Quickshell.Widgets
import qs
import qs.widgets

MenuWindow {
    id: root

    property int highlighted: 0

    readonly property var items: ClipboardService.items

    title: "Буфер обмена"
    preferredWidth: 420
    maximumWidth: 460
    maximumHeight: 520
    edgeInset: 0

    // Параметр без типа намеренно: запись — это объект {kind, mime, value},
    // а QML-функция с типом string молча приводит его к
    // "[object V4ReferenceObject]" и именно это уезжает в буфер.
    function pick(item): void {
        ClipboardService.copy(item);
        root.close();
    }

    function move(delta: int): void {
        if (root.items.length === 0) return;

        root.highlighted = (root.highlighted + delta + root.items.length) % root.items.length;
        root.view.positionViewAtIndex(root.highlighted, ListView.Contain);
    }

    Connections {
        target: ClipboardService

        function onToggleRequested(): void {
            root.highlighted = 0;
            root.toggle();
        }
    }

    onOpenedChanged: if (root.opened) root.highlighted = 0

    onKeyPressed: event => {
        if (event.key === Qt.Key_Escape) root.close();
        else if (event.key === Qt.Key_Down) root.move(1);
        else if (event.key === Qt.Key_Up) root.move(-1);
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.items.length > 0) root.pick(root.items[root.highlighted]);
        }
    }

    Repeater {
        model: root.items

        // Текст и картинка рисуются по-разному, но живут одной строкой
        // списка: стрелки ходят по ним вперемешку.
        Item {
            id: row

            required property var modelData
            required property int index

            readonly property bool isImage: ClipboardService.kindOf(row.modelData) === "image"
            readonly property string value: ClipboardService.payloadOf(row.modelData)

            width: root.contentWidth
            implicitHeight: row.isImage ? 66 : Theme.rowHeight

            MenuRow {
                anchors.fill: parent
                visible: !row.isImage

                glyph: "󰆏"
                label: ClipboardService.preview(row.value)
                highlight: row.index === root.highlighted

                trailing: {
                    const lines = ClipboardService.lineCount(row.value);
                    if (lines < 2) return "";

                    // 2 строки, но 5 строк — русский счёт на единицу не ложится
                    const last = lines % 10;
                    const tens = lines % 100;
                    const word = tens >= 11 && tens <= 14 ? "строк"
                        : last === 1 ? "строка"
                        : last >= 2 && last <= 4 ? "строки"
                        : "строк";

                    return lines + " " + word;
                }

                onClicked: root.pick(row.modelData)
                onRightClicked: ClipboardService.forget(row.modelData)
            }

            // предпросмотр скопированной картинки
            Rectangle {
                anchors.fill: parent
                visible: row.isImage
                radius: Theme.rowRadius

                color: imageMouse.containsMouse ? Theme.alpha(Colors.text, 0.10)
                    : row.index === root.highlighted ? Theme.alpha(Colors.primary, 0.14)
                    : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                ClippingRectangle {
                    id: frame

                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 92
                    height: 50
                    radius: 8
                    color: Theme.alpha(Colors.outline, 0.25)

                    Image {
                        anchors.fill: parent
                        // картинка может быть и в десяток мегабайт — в
                        // память тянем уменьшенную копию, а не оригинал
                        source: row.isImage ? "file://" + row.value : ""
                        sourceSize.width: 184
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }
                }

                Text {
                    x: frame.x + frame.width + 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Изображение"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    color: Colors.text
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width - width - 10

                    // из mime получается внятная подпись: image/png -> PNG
                    text: ClipboardService.mimeOf(row.modelData).replace("image/", "").toUpperCase()
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize - 2
                    color: Colors.subtext
                }

                MouseArea {
                    id: imageMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) ClipboardService.forget(row.modelData);
                        else root.pick(row.modelData);
                    }
                }
            }
        }
    }

    MenuRow {
        width: root.contentWidth
        visible: root.items.length === 0
        rowEnabled: false
        glyph: "󰆏"
        label: "Буфер пуст"
    }

    footer: MenuRow {
        width: root.contentWidth
        visible: root.items.length > 0
        glyph: "󰆴"
        label: "Очистить историю"
        labelColor: Colors.subtext

        onClicked: {
            ClipboardService.clear();
            root.close();
        }
    }
}
