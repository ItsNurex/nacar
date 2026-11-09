import QtQuick
import qs.services

// Icono de Material Symbols (por ligadura: text: "wifi").
Text {
    property real size: 20
    property bool fill: false
    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({ "FILL": fill ? 1 : 0, "wght": 450, "opsz": Math.min(48, Math.max(20, size)) })
    color: Theme.fg
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
    Behavior on color { ColorAnimation { duration: Theme.fast } }
}
