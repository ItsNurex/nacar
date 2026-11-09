import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.services
import qs.components

ListView {
    id: root
    clip: true
    spacing: 6
    readonly property var adapter: Bluetooth.defaultAdapter
    model: Bluetooth.devices.values.filter(d => d.paired || d.connected || d.name).sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired))
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    header: Item {
        width: root.width
        height: 40
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: !root.adapter ? "Sin adaptador Bluetooth" : root.adapter.discovering ? "Buscando dispositivos…" : "Dispositivos"
            size: 12; color: Theme.fgDim
        }
        IconButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.adapter && root.adapter.enabled
            icon: "bluetooth_searching"
            active: root.adapter ? root.adapter.discovering : false
            onClicked: root.adapter.discovering = !root.adapter.discovering
        }
    }

    delegate: Clicky {
        required property var modelData
        width: root.width
        height: 52
        radius: 14
        base: modelData.connected ? Theme.secondaryContainer : Theme.surfaceHigh
        onClicked: {
            if (modelData.connected) modelData.disconnect();
            else if (modelData.paired) modelData.connect();
            else modelData.pair();
        }
        Row {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            IconImage { anchors.verticalCenter: parent.verticalCenter; implicitSize: 24; source: Quickshell.iconPath(modelData.icon || "bluetooth", "bluetooth") }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt { text: modelData.name || modelData.address; size: 13; weight: modelData.connected ? Font.DemiBold : Font.Normal }
                Txt {
                    text: modelData.connected ? ("Conectado" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "% batería" : ""))
                        : modelData.pairing ? "Emparejando…" : modelData.paired ? "Emparejado" : "Toca para emparejar"
                    size: 11; color: Theme.fgDim
                }
            }
        }
    }
}
