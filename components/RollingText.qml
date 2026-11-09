import QtQuick
import qs.services

// Texto cuyos caracteres "ruedan" como un contador mecánico al cambiar.
Row {
    id: root
    property string text: ""
    property real size: 96
    property int weight: 300
    property color color: Theme.fg
    property string family: Theme.font

    spacing: 0
    Repeater {
        model: root.text.length
        Item {
            id: cell
            required property int index
            readonly property string ch: root.text.charAt(index)
            property string shown: ch
            property string previous: ch
            width: metrics.advanceWidth
            height: cur.implicitHeight
            clip: true

            TextMetrics { id: metrics; font: cur.font; text: cell.ch === ":" ? ":" : "0" }

            onChChanged: {
                previous = shown;
                shown = ch;
                if (Theme.speed > 0) roll.restart();
            }

            Text {
                id: old
                text: cell.previous
                font: cur.font
                color: root.color
                anchors.horizontalCenter: parent.horizontalCenter
                y: -cell.height
                opacity: 0
            }
            Text {
                id: cur
                text: cell.shown
                font.family: root.family
                font.pixelSize: root.size
                font.variableAxes: ({ "wght": root.weight })
                font.features: ({ "tnum": 1 })
                color: root.color
                anchors.horizontalCenter: parent.horizontalCenter
            }
            ParallelAnimation {
                id: roll
                NumberAnimation { target: cur; property: "y"; from: cell.height * 0.6; to: 0; duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                NumberAnimation { target: cur; property: "opacity"; from: 0; to: 1; duration: Theme.normal }
                NumberAnimation { target: old; property: "y"; from: 0; to: -cell.height * 0.6; duration: Theme.normal; easing.type: Easing.InCubic }
                NumberAnimation { target: old; property: "opacity"; from: 1; to: 0; duration: Theme.normal }
            }
        }
    }
}
