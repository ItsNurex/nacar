import QtQuick
import qs.services
import qs.components

// Interruptor rápido grande: icono + título + estado. Clic derecho = detalles.
Clicky {
    id: root
    property string icon: ""
    property string title: ""
    property string detail: ""
    property bool on: false
    signal more()

    implicitHeight: 62
    radius: on ? 20 : 31
    base: on ? Theme.primary : Theme.surfaceHigh
    tint: on ? Theme.fgPrimary : Theme.fg
    onRightClicked: more()
    Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    Rectangle {
        id: bubble
        x: 9
        anchors.verticalCenter: parent.verticalCenter
        width: 44; height: 44
        radius: 22
        color: root.on ? Theme.alpha(Theme.fgPrimary, 0.16) : Theme.surfaceHighest
        Sym {
            anchors.centerIn: parent
            text: root.icon
            size: 22
            fill: root.on
            color: root.on ? Theme.fgPrimary : Theme.fgDim
        }
    }
    Column {
        anchors.left: bubble.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        Txt { width: parent.width; text: root.title; size: 14; weight: Font.DemiBold; color: root.on ? Theme.fgPrimary : Theme.fg }
        Txt { width: parent.width; visible: text; text: root.detail; size: 12; color: root.on ? Theme.alpha(Theme.fgPrimary, 0.8) : Theme.fgDim }
    }
}
