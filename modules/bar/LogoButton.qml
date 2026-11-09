import QtQuick
import qs.services
import qs.components

// Botón del lanzador: una perla que gira cuando Omni está abierto.
Clicky {
    id: root
    implicitWidth: Config.o.barHeight - 10
    implicitHeight: Config.o.barHeight - 10
    base: Ui.omni ? Theme.primary : Theme.primaryContainer
    tint: Theme.fgPrimaryContainer
    onClicked: Ui.toggleOmni()
    onRightClicked: Ui.toggleOmni("!")

    Sym {
        anchors.centerIn: parent
        text: "bubble_chart"
        size: 20
        fill: true
        color: Ui.omni ? Theme.fgPrimary : Theme.fgPrimaryContainer
        rotation: Ui.omni ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack } }
    }
}
