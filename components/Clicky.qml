import QtQuick
import qs.services

// Superficie pulsable con capa de estado (hover/press) y onda al pulsar.
Rectangle {
    id: root

    property color base: "transparent"
    property color tint: Theme.fg
    property bool hoverable: true
    property alias hovered: mouse.containsMouse
    property alias pressed: mouse.pressed
    property alias mouse: mouse
    property string tip: ""
    signal clicked(var ev)
    signal rightClicked(var ev)
    signal middleClicked(var ev)
    signal wheel(var ev)

    radius: height / 2
    color: base
    // Se hunde al pulsar y rebota como gelatina al soltar.
    scale: mouse.pressed ? 0.92 : 1
    Behavior on scale { enabled: Theme.speed > 0; SpringAnimation { spring: 6; damping: 0.28; epsilon: 0.002 } }
    clip: true
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.tint
        opacity: !root.enabled ? 0 : mouse.pressed ? 0.16 : (mouse.containsMouse && root.hoverable) ? 0.08 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fast } }
    }

    Rectangle {
        id: ripple
        property real cx: 0
        property real cy: 0
        x: cx - width / 2; y: cy - height / 2
        width: 0; height: width
        radius: width / 2
        color: root.tint
        opacity: 0
        ParallelAnimation {
            id: rippleAnim
            NumberAnimation { target: ripple; property: "width"; from: 0; to: Math.max(root.width, root.height) * 2.4; duration: Theme.slow; easing.type: Easing.OutCubic }
            NumberAnimation { target: ripple; property: "opacity"; from: 0.18; to: 0; duration: Theme.slow }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: ev => { ripple.cx = ev.x; ripple.cy = ev.y; if (Theme.speed > 0) rippleAnim.restart(); }
        onClicked: ev => {
            if (ev.button === Qt.RightButton) root.rightClicked(ev);
            else if (ev.button === Qt.MiddleButton) root.middleClicked(ev);
            else root.clicked(ev);
        }
        onWheel: ev => root.wheel(ev)
    }
}
