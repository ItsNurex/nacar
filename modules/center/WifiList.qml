import QtQuick
import QtQuick.Controls
import qs.services
import qs.components

ListView {
    id: root
    clip: true
    spacing: 6
    model: Net.networks
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
    Component.onCompleted: Net.scan()

    header: Item {
        width: root.width
        height: 40
        Txt { anchors.verticalCenter: parent.verticalCenter; text: Net.scanning ? "Buscando redes…" : Net.networks.length + " redes"; size: 12; color: Theme.fgDim }
        IconButton { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; icon: "refresh"; onClicked: Net.scan() }
    }

    delegate: Clicky {
        required property var modelData
        width: root.width
        height: 50
        radius: 14
        base: modelData.active ? Theme.secondaryContainer : Theme.surfaceHigh
        onClicked: modelData.active ? Net.disconnect() : Net.connect(modelData.ssid)
        Row {
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Sym {
                text: modelData.signal > 75 ? "signal_wifi_4_bar" : modelData.signal > 50 ? "network_wifi_3_bar" : modelData.signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                size: 20; fill: true
                color: modelData.active ? Theme.primary : Theme.fgDim
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Txt { text: modelData.ssid; size: 13; weight: modelData.active ? Font.DemiBold : Font.Normal }
                Txt { text: (modelData.active ? "Conectada · " : "") + modelData.signal + "%" + (modelData.secure ? " · protegida" : " · abierta"); size: 11; color: Theme.fgDim }
            }
        }
        Sym { anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; visible: modelData.secure; text: "lock"; size: 16; color: Theme.outline }
    }
}
