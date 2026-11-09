import QtQuick
import qs.services
import qs.components

// Escritorios: puntos que se estiran en el activo, con un indicador
// que se desliza entre ellos (animación tipo "gota").
Rectangle {
    id: root
    visible: Desktops.available
    readonly property int dot: 10
    readonly property int activeW: 28
    readonly property int sp: 7

    implicitHeight: Config.o.barHeight - 10
    implicitWidth: row.width + 22
    radius: height / 2
    color: Theme.alpha(Theme.surfaceHigh, 0.7)

    // Indicador "gusano": el borde delantero corre rápido y el trasero lo
    // sigue con retraso, así se estira hacia el destino y luego se recoge.
    Rectangle {
        id: pill
        readonly property Item target: rep.count > Desktops.currentIndex && Desktops.currentIndex >= 0 ? rep.itemAt(Desktops.currentIndex) : null
        readonly property real tl: row.x + (target ? target.x : 0)
        readonly property real tr: tl + (target ? target.width : 0)
        property real l: tl
        property real r: tr
        property bool goingRight: true
        onTlChanged: goingRight = tl > l
        Behavior on l { NumberAnimation { duration: pill.goingRight ? Theme.slow : Theme.normal * 0.7; easing.type: Easing.OutCubic } }
        Behavior on r { NumberAnimation { duration: pill.goingRight ? Theme.normal * 0.7 : Theme.slow; easing.type: Easing.OutCubic } }
        x: l
        width: Math.max(height, r - l)
        height: root.dot + 4
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Theme.primary }
            GradientStop { position: 1; color: Theme.tertiary }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root.sp
        Repeater {
            id: rep
            model: Desktops.list
            Item {
                required property var modelData
                required property int index
                readonly property bool cur: modelData.id === Desktops.current
                width: cur ? root.activeW : root.dot + 4
                height: root.dot + 4
                Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.cur ? 0 : (ma.containsMouse ? root.dot + 2 : root.dot)
                    height: width
                    radius: width / 2
                    color: ma.containsMouse ? Theme.fg : Theme.outline
                    Behavior on width { NumberAnimation { duration: Theme.fast } }
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Desktops.activate(modelData.id)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onWheel: ev => Desktops.cycle(ev.angleDelta.y > 0 ? -1 : 1)
    }
}
