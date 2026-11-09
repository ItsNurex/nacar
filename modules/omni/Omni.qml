import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import qs.services
import qs.components

// Omni: lanzador universal. Apps, ventanas, cálculos, comandos, web,
// emojis, portapapeles, archivos y acciones en una sola caja.
Popout {
    id: win
    ns: "nacar-omni"
    open: Ui.omni
    dim: true
    edge: "bottom"
    align: Qt.AlignHCenter
    cardWidth: 680
    cardHeight: 520
    onCloseRequested: Ui.omni = false

    property int sel: 0

    onOpenChanged: {
        if (open) {
            input.text = Ui.omniSeed;
            Search.query = input.text;
            Search.update();
            sel = 0;
            input.forceActiveFocus();
        }
    }

    function run(item, alt) {
        if (!item || !item.run) return;
        Ui.omni = false;
        if (alt && item.alt) item.alt(); else item.run();
    }

    Column {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // ── Caja de búsqueda ──
        Rectangle {
            width: parent.width
            height: 54
            radius: height / 2
            color: Theme.surfaceHigh
            border.width: input.activeFocus ? 2 : 0
            border.color: Theme.primary

            Sym {
                id: modeIcon
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: (Search.modes.find(m => m.p === Search.prefix) || Search.modes[0]).icon
                size: 22
                color: Theme.primary
            }
            TextField {
                id: input
                anchors.left: modeIcon.right
                anchors.right: count.left
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                background: null
                color: Theme.fg
                placeholderText: "Busca apps, ventanas, calcula, = > ? : ; / ! @"
                placeholderTextColor: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: 17
                selectByMouse: true
                onTextChanged: { Search.query = text; win.sel = 0; }
                Keys.onEscapePressed: Ui.omni = false
                Keys.onDownPressed: win.sel = Math.min(Search.results.length - 1, win.sel + (Search.prefix === ":" ? 10 : 1))
                Keys.onUpPressed: win.sel = Math.max(0, win.sel - (Search.prefix === ":" ? 10 : 1))
                Keys.onTabPressed: {
                    // Tab: siguiente modo
                    const i = Search.modes.findIndex(m => m.p === Search.prefix);
                    const next = Search.modes[(i + 1) % Search.modes.length];
                    text = next.p + Search.term;
                }
                Keys.onPressed: ev => {
                    if (ev.key === Qt.Key_PageDown) { win.sel = Math.min(list.count - 1, win.sel + 6); ev.accepted = true; }
                    else if (ev.key === Qt.Key_PageUp) { win.sel = Math.max(0, win.sel - 6); ev.accepted = true; }
                    else if (ev.modifiers & Qt.ControlModifier && ev.key >= Qt.Key_1 && ev.key <= Qt.Key_9) {
                        win.run(Search.results[ev.key - Qt.Key_1]); ev.accepted = true;
                    }
                }
                Keys.onReturnPressed: ev => win.run(Search.results[win.sel], ev.modifiers & Qt.ShiftModifier)
                Keys.onEnterPressed: ev => win.run(Search.results[win.sel], ev.modifiers & Qt.ShiftModifier)
            }
            Txt {
                id: count
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: Search.results.length ? Search.results.length + "" : ""
                size: 12
                color: Theme.fgDim
            }
        }

        // ── Modos ──
        ListView {
            width: parent.width
            height: 32
            orientation: ListView.Horizontal
            spacing: 6
            clip: true
            model: Search.modes
            boundsBehavior: Flickable.StopAtBounds
            delegate: Clicky {
                required property var modelData
                readonly property bool on: Search.prefix === modelData.p
                height: 32
                width: chipRow.width + 22
                base: on ? Theme.secondaryContainer : "transparent"
                border.width: on ? 0 : 1
                border.color: Theme.outlineVariant
                onClicked: { input.text = modelData.p + Search.term; input.forceActiveFocus(); }
                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: 5
                    Sym { text: modelData.icon; size: 16; color: on ? Theme.fgSecondaryContainer : Theme.fgDim }
                    Txt {
                        text: modelData.name + (modelData.p ? "  " + modelData.p : "")
                        size: 12
                        weight: Font.Medium
                        color: on ? Theme.fgSecondaryContainer : Theme.fgDim
                    }
                }
            }
        }

        // ── Resultados ──
        Item {
            width: parent.width
            height: parent.height - 54 - 32 - 30 - 20

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                model: Search.results
                currentIndex: win.sel
                spacing: 2
                visible: Search.prefix !== ":"
                highlightMoveDuration: Theme.fast
                highlightMoveVelocity: -1
                boundsBehavior: Flickable.StopAtBounds
                highlight: Rectangle { radius: 16; color: Theme.secondaryContainer }
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    width: list.width
                    height: 56
                    readonly property bool cur: ListView.isCurrentItem

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: win.sel = row.index
                        onClicked: ev => win.run(row.modelData, ev.modifiers & Qt.ShiftModifier)
                    }

                    Rectangle {
                        id: badge
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 38; height: 38
                        radius: 12
                        color: row.modelData.icon ? "transparent" : (row.cur ? Theme.primary : Theme.surfaceHighest)
                        IconImage {
                            anchors.centerIn: parent
                            visible: !!row.modelData.icon
                            implicitSize: 34
                            source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
                        }
                        Sym {
                            anchors.centerIn: parent
                            visible: !row.modelData.icon
                            text: row.modelData.glyph || "circle"
                            size: 20
                            fill: row.modelData.on === true
                            color: row.cur ? Theme.fgPrimary : Theme.fgDim
                        }
                    }

                    Column {
                        anchors.left: badge.right
                        anchors.leftMargin: 12
                        anchors.right: tail.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 1
                        Txt {
                            width: parent.width
                            text: row.modelData.html || row.modelData.title
                            textFormat: Text.StyledText
                            size: row.modelData.kind === "calc" ? 20 : 15
                            weight: Font.Medium
                            color: row.cur ? Theme.fgSecondaryContainer : Theme.fg
                        }
                        Txt {
                            width: parent.width
                            visible: text !== ""
                            text: row.modelData.subtitle || ""
                            size: 12
                            color: Theme.fgDim
                        }
                    }

                    Row {
                        id: tail
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Rectangle {
                            visible: row.modelData.on !== undefined
                            width: 34; height: 20; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: row.modelData.on ? Theme.primary : Theme.surfaceHighest
                            Rectangle {
                                width: 14; height: 14; radius: 7
                                anchors.verticalCenter: parent.verticalCenter
                                x: row.modelData.on ? 17 : 3
                                color: row.modelData.on ? Theme.fgPrimary : Theme.outline
                            }
                        }
                        Txt {
                            visible: row.index < 9 && !row.cur
                            text: "Ctrl " + (row.index + 1)
                            size: 11
                            color: Theme.outline
                        }
                        Sym { visible: row.cur; text: "keyboard_return"; size: 18; color: Theme.fgSecondaryContainer }
                    }
                }
            }

            // Cuadrícula de emojis
            GridView {
                id: grid
                anchors.fill: parent
                visible: Search.prefix === ":"
                clip: true
                cellWidth: width / 10
                cellHeight: cellWidth
                model: Search.results
                currentIndex: win.sel
                highlight: Rectangle { radius: 14; color: Theme.secondaryContainer }
                highlightMoveDuration: Theme.fast
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    Text { anchors.centerIn: parent; text: modelData.emoji || ""; font.pixelSize: 30 }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: win.sel = index
                        onClicked: win.run(modelData)
                    }
                }
            }

            Txt {
                anchors.centerIn: parent
                visible: Search.results.length === 0
                text: Search.prefix === "/" ? "Escribe para buscar archivos en tu carpeta personal" : "Sin resultados"
                color: Theme.fgDim
            }
        }

        // ── Pie con atajos ──
        Row {
            spacing: 16
            anchors.horizontalCenter: parent.horizontalCenter
            Repeater {
                model: [["keyboard_return", "abrir"], ["keyboard_tab", "cambiar modo"], ["shift", "Shift+Enter alternativo"], ["keyboard_command_key", "Ctrl+1…9 directo"]]
                Row {
                    required property var modelData
                    spacing: 4
                    Sym { text: modelData[0]; size: 14; color: Theme.outline }
                    Txt { text: modelData[1]; size: 11; color: Theme.outline }
                }
            }
        }
    }
}
