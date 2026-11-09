import QtQuick
import qs.services

// Deslizador Material 3 "expresivo": barra gruesa con icono dentro.
Item {
    id: root

    property real value: 0          // 0..1 (puede pasar de 1 si max > 1)
    property real max: 1
    property string icon: ""
    property string iconOff: icon
    property bool off: false
    property color accent: Theme.primary
    signal moved(real v)
    signal iconClicked()

    implicitHeight: 44
    implicitWidth: 240

    readonly property real frac: Math.max(0, Math.min(1, value / max))

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.surfaceHighest
        clip: true

        Rectangle {
            height: parent.height
            width: Math.max(parent.height, parent.width * root.frac)
            radius: height / 2
            color: root.off ? Theme.outline : root.accent
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }

        Sym {
            id: ico
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: root.off ? root.iconOff : root.icon
            size: 20
            fill: true
            color: root.off ? Theme.surface : Theme.fgPrimary
        }

        Txt {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(root.value * 100) + "%"
            size: 12
            weight: Font.DemiBold
            color: root.frac > 0.86 ? Theme.fgPrimary : Theme.fgDim
        }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(x) { root.moved(Math.max(0, Math.min(1, x / width)) * root.max); }
        onPressed: ev => { if (ev.x < 44) root.iconClicked(); else set(ev.x); }
        onPositionChanged: ev => { if (pressed && ev.x >= 0) set(ev.x); }
        onWheel: ev => root.moved(Math.max(0, Math.min(root.max, root.value + (ev.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
