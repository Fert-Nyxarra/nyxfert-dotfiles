import QtQuick
import QtQuick.Shapes
import qs

Item {
    id: root

    property real value: 0
    property bool playing: false
    property bool interactive: true

    property color activeColor: Colors.primary
    property color inactiveColor: Theme.alpha(Colors.outline, 0.35)

    readonly property int wavelength: 22
    readonly property real amplitude: 3.5

    property real waveAmplitude: root.playing ? root.amplitude : 0

    Behavior on waveAmplitude {
        NumberAnimation {
            duration: 320
            easing.type: Easing.OutCubic
        }
    }
    readonly property real thickness: 3.5
    readonly property int handleWidth: 4
    readonly property int handleHeight: 16

    readonly property int handleGap: 5

    signal moved(real value)

    implicitHeight: 24

    readonly property real progressX: Math.max(0, Math.min(1, root.value)) * root.width

    readonly property var wavePoints: {
        const points = [];
        const total = root.width + root.wavelength;

        for (let x = 0; x <= total; x += 2) {
            const y = root.height / 2
                + root.waveAmplitude * Math.sin(2 * Math.PI * x / root.wavelength);
            points.push(Qt.point(x, y));
        }

        return points;
    }

    Rectangle {
        x: root.progressX + root.handleGap + root.handleWidth
        width: Math.max(0, root.width - x)
        height: root.thickness
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.inactiveColor
    }

    Item {
        width: Math.max(0, root.progressX - root.handleGap)
        height: parent.height
        clip: true

        Shape {
            id: wave

            width: root.width + root.wavelength
            height: root.height
            preferredRendererType: Shape.CurveRenderer

            NumberAnimation on x {
                running: root.playing
                loops: Animation.Infinite
                from: 0
                to: -root.wavelength
                duration: 1100
            }

            ShapePath {
                strokeColor: root.activeColor
                strokeWidth: root.thickness
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                fillColor: "transparent"

                PathPolyline {
                    path: root.wavePoints
                }
            }
        }
    }

    Rectangle {
        x: root.progressX
        anchors.verticalCenter: parent.verticalCenter
        width: root.handleWidth
        height: root.handleHeight
        radius: width / 2
        color: root.activeColor
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor

        function apply(x: real): void {
            root.moved(Math.max(0, Math.min(1, (x + 6) / root.width)));
        }

        onPressed: mouse => apply(mouse.x)
        onPositionChanged: mouse => {
            if (pressed) apply(mouse.x);
        }
    }
}
