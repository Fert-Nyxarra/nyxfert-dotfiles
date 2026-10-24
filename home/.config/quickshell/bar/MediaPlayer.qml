// ~/.config/quickshell/bar/MediaPlayer.qml
// Плеер в контрол-центре: обложка, что играет и кнопки управления.
// Берёт первый активный MPRIS-источник (Spotify, браузер, что угодно).

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.widgets

Item {
    id: root

    readonly property var player: {
        const players = Mpris.players ? Mpris.players.values : [];
        if (players.length === 0) return null;
        return players.find(p => p.isPlaying) ?? players[0];
    }

    readonly property bool hasPlayer: root.player !== null

    visible: root.hasPlayer
    implicitHeight: root.hasPlayer ? 72 : 0

    Rectangle {
        anchors.fill: parent
        radius: Theme.rowRadius
        color: Theme.alpha(Colors.surfaceContainerHigh, 0.7)
    }

    // обложка
    Rectangle {
        id: art

        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        height: 56
        radius: 8
        color: Theme.alpha(Colors.surfaceContainer, 0.9)
        clip: true

        Image {
            anchors.fill: parent
            source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: !root.player || !root.player.trackArtUrl
            text: "󰝚"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize + 8
            color: Colors.outline
        }
    }

    Column {
        x: 76
        width: parent.width - x - 116
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: root.player ? (root.player.trackTitle || root.player.identity) : ""
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.DemiBold
            color: Colors.text
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.player ? root.player.trackArtist : ""
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            color: Colors.subtext
        }
    }

    // кнопки
    component PlayerButton: Rectangle {
        id: button

        property string glyph: ""
        property bool accent: false
        property bool usable: true

        signal activated

        implicitWidth: button.accent ? 34 : 28
        implicitHeight: button.accent ? 34 : 28
        radius: width / 2
        opacity: button.usable ? 1 : 0.35

        color: button.accent
            ? Theme.alpha(Colors.primary, buttonMouse.containsMouse ? 0.35 : 0.2)
            : (buttonMouse.containsMouse ? Theme.alpha(Colors.text, 0.12) : "transparent")

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            anchors.centerIn: parent
            text: button.glyph
            font.family: Theme.fontFamily
            font.pixelSize: button.accent ? Theme.fontSize + 3 : Theme.fontSize + 1
            color: button.accent ? Colors.primary : Colors.text
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.usable
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 8
        spacing: 4

        PlayerButton {
            anchors.verticalCenter: parent.verticalCenter
            glyph: "󰒮"
            usable: root.player ? root.player.canGoPrevious : false
            onActivated: root.player.previous()
        }

        PlayerButton {
            anchors.verticalCenter: parent.verticalCenter
            accent: true
            glyph: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
            usable: root.player ? root.player.canTogglePlaying : false
            onActivated: root.player.togglePlaying()
        }

        PlayerButton {
            anchors.verticalCenter: parent.verticalCenter
            glyph: "󰒭"
            usable: root.player ? root.player.canGoNext : false
            onActivated: root.player.next()
        }
    }
}
