import QtQuick
import QtQuick.Shapes
import qs

Item {
    id: wheel

    property int steps: 16
    property real saturation: 0.68
    property real brightness: 0.92

    property int selected: -1

    readonly property real centerX: wheel.width / 2
    readonly property real centerY: wheel.height / 2
    readonly property real outerRadius: Math.min(wheel.width, wheel.height) / 2 - 6
    readonly property real innerRadius: wheel.outerRadius * 0.46
    readonly property real step: 360 / wheel.steps

    signal picked(int index, color value)

    function colorAt(index: int): color {
        return Qt.hsva(index / wheel.steps, wheel.saturation, wheel.brightness, 1);
    }

    implicitWidth: 160
    implicitHeight: 160

    Repeater {
        model: wheel.steps

        Shape {
            id: sector

            required property int modelData

            readonly property bool isSelected: wheel.selected === modelData
            readonly property bool isHovered: hit.hovered === modelData

            property real reach: wheel.outerRadius
                + (isSelected ? 7 : isHovered ? 3 : 0)

            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            antialiasing: true

            Behavior on reach {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            ShapePath {
                fillColor: wheel.colorAt(sector.modelData)
                strokeColor: sector.isSelected ? Colors.text : "transparent"
                strokeWidth: sector.isSelected ? 2 : 0

                PathAngleArc {
                    centerX: wheel.centerX
                    centerY: wheel.centerY
                    radiusX: sector.reach
                    radiusY: sector.reach
                    startAngle: sector.modelData * wheel.step - 90 + 1.2
                    sweepAngle: wheel.step - 2.4
                    moveToStart: true
                }

                PathAngleArc {
                    centerX: wheel.centerX
                    centerY: wheel.centerY
                    radiusX: wheel.innerRadius
                    radiusY: wheel.innerRadius
                    startAngle: sector.modelData * wheel.step - 90 + wheel.step - 1.2
                    sweepAngle: -(wheel.step - 2.4)
                    moveToStart: false
                }
            }
        }
    }

    MouseArea {
        id: hit

        property int hovered: -1

        function sectorAt(x: real, y: real): int {
            const dx = x - wheel.centerX;
            const dy = y - wheel.centerY;
            const distance = Math.sqrt(dx * dx + dy * dy);

            if (distance < wheel.innerRadius || distance > wheel.outerRadius + 8) return -1;

            const angle = Math.atan2(dy, dx) * 180 / Math.PI + 90;
            return Math.floor(((angle % 360) + 360) % 360 / wheel.step);
        }

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: hit.hovered >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor

        onPositionChanged: event => hit.hovered = hit.sectorAt(event.x, event.y)
        onExited: hit.hovered = -1
        onClicked: event => {
            const index = hit.sectorAt(event.x, event.y);
            if (index >= 0) wheel.picked(index, wheel.colorAt(index));
        }
    }
}
