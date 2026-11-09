import QtQuick
import Quickshell.Bluetooth
import qs.services
import qs.components

// Red · Bluetooth · Volumen · Batería en una sola pastilla → abre el centro.
// Rueda encima: cambia el volumen.
Clicky {
    id: root
    implicitHeight: Config.o.barHeight - 10
    implicitWidth: row.width + 22
    base: Ui.center ? Theme.secondaryContainer : "transparent"
    onClicked: Ui.toggleCenter()
    onRightClicked: Audio.toggleMute()
    onWheel: ev => Audio.step(ev.angleDelta.y > 0 ? 0.05 : -0.05)

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property bool btOn: bt ? bt.enabled : false
    readonly property bool btConnected: Bluetooth.devices.values.some(d => d.connected)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 9

        Sym { text: Net.icon; size: 18; fill: true; color: Net.kind === "none" ? Theme.outline : Theme.fg }
        Sym {
            visible: root.btOn
            text: root.btConnected ? "bluetooth_connected" : "bluetooth"
            size: 18
            color: root.btConnected ? Theme.primary : Theme.fg
        }
        Sym { visible: Ui.caffeine; text: "coffee"; size: 18; fill: true; color: Theme.tertiary }
        Sym { text: Audio.icon(Audio.volume, Audio.muted); size: 18; fill: true; color: Audio.muted ? Theme.outline : Theme.fg }
        Row {
            visible: Sys.hasBattery
            spacing: 3
            Sym {
                text: Sys.batteryIcon
                size: 18
                fill: true
                rotation: 90
                color: Sys.charging ? Theme.primary : Sys.batteryLevel <= Config.o.batteryWarn / 100 ? Theme.error : Theme.fg
            }
            Txt { text: Math.round(Sys.batteryLevel * 100) + "%"; size: 12; weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
    }
}
