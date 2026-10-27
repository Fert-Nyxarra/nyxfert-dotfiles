import QtQuick
import qs

Item {
    id: root

    property bool playing: false
    property color barColor: Colors.primary

    readonly property int barCount: 4
    readonly property int barWidth: 3
    readonly property int minHeight: 3
    readonly property int maxHeight: 14

    implicitWidth: root.barCount * root.barWidth + (root.barCount - 1) * 2
    implicitHeight: root.maxHeight

    Row {
        anchors.fill: parent
        spacing: 2

        Repeater {
            model: root.barCount

            Rectangle {
                id: bar

                required property int index

                anchors.bottom: parent.bottom
                width: root.barWidth
                height: root.minHeight
                radius: root.barWidth / 2
                color: root.barColor
                opacity: root.playing ? 1 : 0.45

                Behavior on opacity {
                    NumberAnimation { duration: 180 }
                }

                SequentialAnimation on height {
                    running: root.playing
                    loops: Animation.Infinite
                    alwaysRunToEnd: false

                    NumberAnimation {
                        to: root.maxHeight - bar.index * 2
                        duration: 260 + bar.index * 70
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        to: root.minHeight + (bar.index % 2) * 3
                        duration: 300 + bar.index * 50
                        easing.type: Easing.InOutSine
                    }
                }

                Behavior on height {
                    enabled: !root.playing
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }
}
