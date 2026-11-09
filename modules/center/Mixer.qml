import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.services
import qs.components

// Mezclador: elegir salida de audio y volumen por aplicación.
Flickable {
    id: root
    clip: true
    contentHeight: col.height
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    Column {
        id: col
        width: root.width
        spacing: 8

        Txt { text: "Salida"; size: 12; weight: Font.DemiBold; color: Theme.fgDim }
        Repeater {
            model: Audio.sinks
            Clicky {
                required property var modelData
                readonly property bool cur: modelData === Audio.sink
                width: col.width
                height: 44
                radius: 14
                base: cur ? Theme.secondaryContainer : Theme.surfaceHigh
                onClicked: Audio.useSink(modelData)
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 12
                    spacing: 10
                    Sym { text: cur ? "radio_button_checked" : "radio_button_unchecked"; size: 18; color: cur ? Theme.primary : Theme.outline }
                    Txt { width: col.width - 60; text: modelData.description || modelData.name; size: 13 }
                }
            }
        }

        Txt { text: "Aplicaciones"; size: 12; weight: Font.DemiBold; color: Theme.fgDim; topPadding: 6 }
        Txt {
            visible: Audio.streams.length === 0
            text: "Ninguna app está sonando ahora mismo."
            size: 13
            color: Theme.outline
        }
        Repeater {
            model: Audio.streams
            Row {
                required property var modelData
                width: col.width
                spacing: 10
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 30
                    source: Quickshell.iconPath(Audio.nodeIcon(modelData), "audio-volume-high")
                }
                Column {
                    width: parent.width - 40
                    spacing: 3
                    Txt { width: parent.width; text: Audio.nodeName(modelData) + (modelData.properties["media.name"] ? " — " + modelData.properties["media.name"] : ""); size: 12 }
                    Fader {
                        width: parent.width
                        height: 30
                        value: modelData.audio ? modelData.audio.volume : 0
                        off: modelData.audio ? modelData.audio.muted : false
                        icon: "volume_up"; iconOff: "volume_off"
                        onMoved: v => { if (modelData.audio) { modelData.audio.muted = false; modelData.audio.volume = v; } }
                        onIconClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
                    }
                }
            }
        }
    }
}
