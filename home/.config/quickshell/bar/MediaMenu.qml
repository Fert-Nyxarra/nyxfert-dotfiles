import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.widgets

Popup {
    id: root

    required property var player

    preferredWidth: 360
    maximumWidth: 360

    readonly property real position: root.player ? root.player.position : 0
    readonly property real length: root.player && root.player.lengthSupported ? root.player.length : 0
    readonly property bool seekable: root.player && root.player.canSeek && root.length > 0

    title: root.player ? root.player.identity : ""

    function timeText(seconds: real): string {
        if (!(seconds > 0)) return "0:00";

        const total = Math.floor(seconds);
        const mins = Math.floor(total / 60);
        const secs = total % 60;
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    function seekTo(fraction: real): void {
        if (!root.seekable) return;
        root.player.position = Math.max(0, Math.min(1, fraction)) * root.length;
    }

    Timer {
        interval: 500
        repeat: true
        running: root.opened && root.player && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    Item {
        width: root.contentWidth
        implicitHeight: 68

        Rectangle {
            id: art

            x: 4
            anchors.verticalCenter: parent.verticalCenter
            width: 60
            height: 60
            radius: 8
            color: Theme.alpha(Colors.surfaceContainerHigh, 0.8)
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
            width: parent.width - x - 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                width: parent.width
                text: root.player ? (root.player.trackTitle || "Без названия") : ""
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
                font.pixelSize: Theme.fontSize - 2
                color: Colors.subtext
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: root.player ? root.player.trackAlbum : ""
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize - 3
                color: Colors.outline
            }
        }
    }

    Item {
        width: root.contentWidth
        implicitHeight: 30
        visible: root.length > 0

        Text {
            id: elapsed

            x: 6
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeText(root.position)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            color: Colors.subtext
        }

        WavySlider {
            id: seekTrack

            anchors.verticalCenter: parent.verticalCenter
            x: 48
            width: parent.width - x - 48

            value: root.length > 0 ? root.position / root.length : 0
            playing: root.player ? root.player.isPlaying : false
            interactive: root.seekable
            activeColor: root.seekable ? Colors.primary : Colors.outline

            onMoved: fraction => root.seekTo(fraction)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width - width - 6
            text: root.timeText(root.length)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 3
            color: Colors.subtext
        }
    }

    component PlayerButton: Rectangle {
        id: button

        property string glyph: ""
        property bool accent: false
        property bool usable: true
        property bool lit: false

        signal activated

        implicitWidth: button.accent ? 40 : 32
        implicitHeight: button.accent ? 40 : 32
        radius: width / 2
        opacity: button.usable ? 1 : 0.35

        color: button.accent || button.lit
            ? Theme.alpha(Colors.primary, buttonMouse.containsMouse ? 0.38 : 0.22)
            : (buttonMouse.containsMouse ? Theme.alpha(Colors.text, 0.12) : "transparent")

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Text {
            anchors.centerIn: parent
            text: button.glyph
            font.family: Theme.fontFamily
            font.pixelSize: button.accent ? Theme.fontSize + 5 : Theme.fontSize + 2
            color: button.accent || button.lit ? Colors.primary : Colors.text
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

    Item {
        width: root.contentWidth
        implicitHeight: 48

        Row {
            anchors.centerIn: parent
            spacing: 8

            PlayerButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "󰒝"
                lit: root.player ? root.player.shuffle : false
                usable: root.player ? root.player.shuffleSupported : false
                onActivated: root.player.shuffle = !root.player.shuffle
            }

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

            PlayerButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: root.player && root.player.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                lit: root.player ? root.player.loopState !== MprisLoopState.None : false
                usable: root.player ? root.player.loopSupported : false

                onActivated: {
                    const states = [MprisLoopState.None, MprisLoopState.Playlist, MprisLoopState.Track];
                    const next = (states.indexOf(root.player.loopState) + 1) % states.length;
                    root.player.loopState = states[next];
                }
            }
        }
    }
}
