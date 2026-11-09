import QtQuick
import qs.services

// Texto con la fuente de la shell. El peso se aplica con el eje "wght" de la
// fuente variable: Qt pinta mal las instancias en negrita de Google Sans Flex.
Text {
    property real size: 14
    property int weight: Font.Normal
    font.family: Theme.font
    font.pixelSize: size
    font.variableAxes: ({ "wght": weight })
    color: Theme.fg
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    Behavior on color { ColorAnimation { duration: Theme.fast } }
}
