import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Avisos emergentes: entran deslizándose, se pausan al pasar el ratón,
// muestran acciones, imagen, progreso y respuesta rápida. Arrastra para descartar.
PanelWindow {
    id: win
    anchors { top: true; right: true }
    margins.top: Config.o.barHeight + 8
    margins.right: Config.o.frameThickness + 8
    implicitWidth: 400
    implicitHeight: Math.max(1, col.implicitHeight + 10)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: Notifs.popups.length > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nacar-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { item: col }

    Column {
        id: col
        width: parent.width - 10
        x: 5
        spacing: 8

        move: Transition { NumberAnimation { properties: "y"; duration: Theme.normal; easing.type: Easing.OutCubic } }

        Repeater {
            model: Notifs.popups
            delegate: Item {
                id: card
                required property var modelData
                readonly property var n: modelData
                readonly property bool critical: n.urgency === NotificationUrgency.Critical
                width: col.width
                height: box.height
                property real progress: 1

                Component.onCompleted: { enterAnim.start(); }
                NumberAnimation { id: enterAnim; target: box; property: "x"; from: col.width; to: 0; duration: Theme.normal; easing.type: Easing.OutCubic }

                // Barra de tiempo: se detiene al pasar el ratón.
                NumberAnimation on progress {
                    id: life
                    from: 1; to: 0
                    duration: card.n.expireTimeout > 0 ? card.n.expireTimeout : Config.o.notifTimeout
                    running: !card.critical && !hover.hovered && !reply.activeFocus
                    onFinished: Notifs.dropPopup(card.n)
                }

                HoverHandler { id: hover }

                Rectangle {
                    id: box
                    width: parent.width
                    height: content.implicitHeight + 24
                    radius: Theme.radius - 4
                    color: Theme.alpha(card.critical ? Theme.errorContainer : Theme.surface, Config.o.panelOpacity)
                    border.width: 1
                    border.color: card.critical ? Theme.error : Theme.alpha(Theme.outlineVariant, 0.6)
                    opacity: 1 - Math.abs(x) / width

                    DragHandler {
                        id: drag
                        yAxis.enabled: false
                        xAxis.minimum: -40
                        onActiveChanged: if (!active) {
                            if (box.x > box.width * 0.35) Notifs.dropPopup(card.n);
                            else box.x = 0;
                        }
                    }
                    TapHandler { onTapped: { const d = card.n.actions.find(a => a.identifier === "default"); if (d) d.invoke(); Notifs.dropPopup(card.n); } }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.leftMargin: parent.radius
                        height: 3
                        radius: 1.5
                        width: (parent.width - parent.radius * 2) * card.progress
                        color: Theme.primary
                        opacity: 0.6
                        visible: !card.critical
                    }

                    ColumnLayout {
                        id: content
                        x: 12; y: 12
                        width: parent.width - 24
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            ClippingRectangle {
                                width: 44; height: 44; radius: 14
                                color: Theme.primaryContainer
                                Image {
                                    id: img
                                    anchors.fill: parent
                                    source: card.n.image
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                    asynchronous: true
                                }
                                IconImage {
                                    anchors.centerIn: parent
                                    visible: !img.visible
                                    implicitSize: 28
                                    source: Quickshell.iconPath(card.n.appIcon || (card.n.appName || "").toLowerCase(), "dialog-information")
                                }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                RowLayout {
                                    Layout.fillWidth: true
                                    Txt { Layout.fillWidth: true; text: card.n.summary; size: 14; weight: Font.DemiBold }
                                    Txt { text: card.n.appName; size: 11; color: Theme.outline }
                                }
                                Txt {
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                    text: card.n.body
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    size: 13
                                    color: Theme.fgDim
                                    onLinkActivated: link => Qt.openUrlExternally(link)
                                }
                            }
                            IconButton { Layout.alignment: Qt.AlignTop; width: 28; height: 28; iconSize: 16; icon: "close"; onClicked: card.n.dismiss() }
                        }

                        // Progreso (hint "value", p. ej. descargas)
                        Rectangle {
                            readonly property var v: card.n.hints ? card.n.hints["value"] : undefined
                            visible: v !== undefined
                            Layout.fillWidth: true
                            height: 6; radius: 3
                            color: Theme.surfaceHighest
                            Rectangle { width: parent.width * Math.min(1, (parent.v || 0) / 100); height: 6; radius: 3; color: Theme.primary }
                        }

                        // Acciones
                        RowLayout {
                            Layout.fillWidth: true
                            visible: actionsRep.count > 0
                            spacing: 6
                            Repeater {
                                id: actionsRep
                                model: card.n.actions.filter(a => a.identifier !== "default")
                                Clicky {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 34
                                    base: Theme.secondaryContainer
                                    tint: Theme.fgSecondaryContainer
                                    onClicked: { modelData.invoke(); Notifs.dropPopup(card.n); }
                                    Txt { anchors.centerIn: parent; text: modelData.text; size: 12; weight: Font.Medium; color: Theme.fgSecondaryContainer }
                                }
                            }
                        }

                        // Respuesta rápida
                        Rectangle {
                            Layout.fillWidth: true
                            visible: card.n.hasInlineReply
                            height: 38; radius: 19
                            color: Theme.surfaceHigh
                            TextInput {
                                id: reply
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 40
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: 13
                                clip: true
                                Text { anchors.verticalCenter: parent.verticalCenter; visible: !parent.text; text: card.n.inlineReplyPlaceholder || "Responder…"; color: Theme.outline; font: parent.font }
                                onAccepted: { if (text) { card.n.sendInlineReply(text); Notifs.dropPopup(card.n); } }
                            }
                            IconButton { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 32; height: 32; iconSize: 18; icon: "send"; onClicked: reply.accepted() }
                        }
                    }
                }
            }
        }
    }
}
