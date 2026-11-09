import QtQuick
import QtQuick.Shapes
import qs.services

// La forma "líquida" de Nácar: una pestaña que cuelga de un borde con
// esquinas cóncavas que se funden con él (orejas) y esquinas redondeadas
// en el otro extremo. Al animar bodyWidth/bodyHeight, la forma se "derrite".
//
//   ╲________________________╱   ← borde (y = 0), orejas de radio `ear`
//    │                      │
//    ╰──────────────────────╯   ← esquinas de radio `radius`
Item {
    id: root

    property real bodyWidth: 200
    property real bodyHeight: 60
    property real radius: Theme.radius
    property real ear: Theme.radius * 0.8
    property color color: Theme.surface
    property color strokeColor: "transparent"
    property real strokeWidth: 0
    property bool flip: false          // true: cuelga hacia arriba (desde el borde inferior)

    readonly property real e: Math.max(0, Math.min(ear, bodyHeight / 2, bodyWidth / 2))
    readonly property real r: Math.max(0, Math.min(radius, bodyHeight - e, bodyWidth / 2))

    width: bodyWidth + e * 2
    height: Math.max(0, bodyHeight)
    visible: bodyHeight > 0.5 && bodyWidth > 0.5

    transform: Scale { origin.y: root.height / 2; yScale: root.flip ? -1 : 1 }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeColor: root.strokeColor
            strokeWidth: root.strokeWidth
            startX: 0; startY: -1
            PathLine { x: 0; y: 0 }
            PathArc { x: root.e; y: root.e; radiusX: root.e; radiusY: root.e; direction: PathArc.Clockwise }
            PathLine { x: root.e; y: root.height - root.r }
            PathArc { x: root.e + root.r; y: root.height; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
            PathLine { x: root.e + root.bodyWidth - root.r; y: root.height }
            PathArc { x: root.e + root.bodyWidth; y: root.height - root.r; radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
            PathLine { x: root.e + root.bodyWidth; y: root.e }
            PathArc { x: root.bodyWidth + root.e * 2; y: 0; radiusX: root.e; radiusY: root.e; direction: PathArc.Clockwise }
            PathLine { x: root.bodyWidth + root.e * 2; y: -1 }
        }
    }
}
