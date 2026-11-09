import QtQuick
import qs.services

Clicky {
    id: root
    property string icon: ""
    property bool active: false
    property real iconSize: 20
    implicitWidth: 36
    implicitHeight: 36
    base: active ? Theme.primary : "transparent"
    tint: active ? Theme.fgPrimary : Theme.fg
    Sym {
        anchors.centerIn: parent
        text: root.icon
        size: root.iconSize
        fill: root.active
        color: root.active ? Theme.fgPrimary : Theme.fg
    }
}
