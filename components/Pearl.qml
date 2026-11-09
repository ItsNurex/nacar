import QtQuick
import QtQuick.Shapes
import qs.services

// Brillo nácar: un contorno iridiscente que gira lentamente, como la luz
// sobre el interior de una concha. Se usa para anunciar que "algo pasa".
Item {
    id: root
    property real radius: height / 2
    property real thickness: 2
    property bool active: true
    property real angle: 0

    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.slow } }

    NumberAnimation on angle {
        from: 0; to: 360
        duration: 4200
        loops: Animation.Infinite
        running: root.active && root.visible && Theme.speed > 0
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        // Anillo = rectángulo exterior menos el interior (regla par-impar).
        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            fillGradient: ConicalGradient {
                centerX: root.width / 2
                centerY: root.height / 2
                angle: root.angle
                GradientStop { position: 0.00; color: Theme.primary }
                GradientStop { position: 0.25; color: Theme.tertiary }
                GradientStop { position: 0.50; color: "#f4eefc" }
                GradientStop { position: 0.75; color: Theme.secondary }
                GradientStop { position: 1.00; color: Theme.primary }
            }
            PathRectangle { x: 0; y: 0; width: root.width; height: root.height; radius: root.radius }
            PathRectangle {
                x: root.thickness; y: root.thickness
                width: root.width - root.thickness * 2
                height: root.height - root.thickness * 2
                radius: Math.max(0, root.radius - root.thickness)
            }
        }
    }
}
