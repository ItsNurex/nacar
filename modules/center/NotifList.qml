import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.services
import qs.components

// Historial de avisos agrupado por app; los grupos se pliegan.
ListView {
    id: root
    clip: true
    spacing: 8
    model: Notifs.groups
    boundsBehavior: Flickable.StopAtBounds
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    add: Transition { NumberAnimation { properties: "opacity,scale"; from: 0; to: 1; duration: Theme.normal } }
    displaced: Transition { NumberAnimation { properties: "y"; duration: Theme.normal; easing.type: Easing.OutCubic } }

    Txt {
        anchors.centerIn: parent
        visible: root.count === 0
        horizontalAlignment: Text.AlignHCenter
        text: "Todo tranquilo ✨\nNo hay avisos"
        color: Theme.fgDim
    }

    delegate: Rectangle {
        id: group
        required property var modelData
        property bool expanded: modelData.items.length <= 2
        width: root.width
        height: col.height + 16
        radius: 18
        color: Theme.surfaceHigh

        Column {
            id: col
            x: 8; y: 8
            width: parent.width - 16
            spacing: 6

            Row {
                width: parent.width
                height: 28
                spacing: 8
                IconImage {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 20
                    source: Quickshell.iconPath(group.modelData.items[0].icon || group.modelData.app.toLowerCase(), "dialog-information")
                }
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 120
                    text: group.modelData.app + (group.modelData.items.length > 1 ? "  ·  " + group.modelData.items.length : "")
                    size: 12; weight: Font.DemiBold; color: Theme.fgDim
                }
                IconButton {
                    visible: group.modelData.items.length > 2
                    width: 28; height: 28; iconSize: 18
                    icon: group.expanded ? "expand_less" : "expand_more"
                    onClicked: group.expanded = !group.expanded
                }
                IconButton {
                    width: 28; height: 28; iconSize: 18
                    icon: "close"
                    onClicked: Notifs.forgetApp(group.modelData.app)
                }
            }

            Repeater {
                model: group.expanded ? group.modelData.items : group.modelData.items.slice(0, 1)
                Rectangle {
                    required property var modelData
                    width: col.width
                    height: Math.max(54, body.height + 16)
                    radius: 14
                    color: hov.hovered ? Theme.surfaceHighest : Theme.surfaceMid
                    HoverHandler { id: hov }

                    Image {
                        id: thumb
                        visible: modelData.image !== ""
                        x: 8; anchors.verticalCenter: parent.verticalCenter
                        width: visible ? 40 : 0; height: 40
                        source: modelData.image
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    Column {
                        id: body
                        anchors.left: thumb.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 34
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Row {
                            width: parent.width
                            spacing: 6
                            Txt { width: Math.min(implicitWidth, parent.width - 70); text: modelData.summary; size: 13; weight: Font.DemiBold }
                            Txt { text: Notifs.ago(modelData.time); size: 11; color: Theme.outline }
                        }
                        Txt {
                            width: parent.width
                            visible: text !== ""
                            text: modelData.body
                            textFormat: Text.StyledText
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            size: 12
                            color: Theme.fgDim
                        }
                    }
                    IconButton {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 4
                        width: 26; height: 26; iconSize: 16
                        visible: hov.hovered
                        icon: "close"
                        onClicked: Notifs.forget(modelData.id)
                    }
                }
            }
        }
    }
}
