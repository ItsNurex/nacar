import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Calendario + reloj grande + enfoque + tareas rápidas.
// Vive dentro de la isla dinámica: la isla se transforma en este panel.
Item {
    id: win
    property bool open: Ui.calendar
    property date shown: new Date()
    onOpenChanged: if (open) shown = new Date()

    SystemClock { id: clock; precision: SystemClock.Seconds }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        anchors.topMargin: 6
        spacing: 16

        // ── Calendario ──
        ColumnLayout {
            Layout.preferredWidth: 320
            Layout.maximumWidth: 320
            Layout.fillHeight: true
            spacing: 8

            Txt { text: Qt.formatTime(clock.date, Config.o.clock24h ? "HH:mm" : "h:mm AP"); size: 46; weight: Font.Bold; color: Theme.primary }
            Txt { text: clock.date.toLocaleDateString(Qt.locale(), "dddd, d 'de' MMMM yyyy"); size: 14; color: Theme.fgDim }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                Txt { Layout.fillWidth: true; text: win.shown.toLocaleDateString(Qt.locale(), "MMMM yyyy"); size: 15; weight: Font.DemiBold }
                IconButton { icon: "chevron_left"; onClicked: win.shown = new Date(win.shown.getFullYear(), win.shown.getMonth() - 1, 1) }
                IconButton { icon: "today"; onClicked: win.shown = new Date() }
                IconButton { icon: "chevron_right"; onClicked: win.shown = new Date(win.shown.getFullYear(), win.shown.getMonth() + 1, 1) }
            }

            Grid {
                id: grid
                columns: 7
                Layout.fillWidth: true
                readonly property real cell: 320 / 7
                readonly property var days: {
                    const y = win.shown.getFullYear(), m = win.shown.getMonth();
                    const first = (new Date(y, m, 1).getDay() + 6) % 7; // lunes primero
                    const out = [];
                    for (let i = 0; i < 42; i++) {
                        const d = new Date(y, m, i - first + 1);
                        out.push({ d: d.getDate(), cur: d.getMonth() === m, today: d.toDateString() === new Date().toDateString(), we: (i % 7) >= 5 });
                    }
                    return out;
                }
                Repeater {
                    model: ["L", "M", "X", "J", "V", "S", "D"]
                    Txt { required property var modelData; width: grid.cell; height: 26; horizontalAlignment: Text.AlignHCenter; text: modelData; size: 11; weight: Font.Bold; color: Theme.outline }
                }
                Repeater {
                    model: grid.days
                    Item {
                        required property var modelData
                        width: grid.cell; height: 34
                        Rectangle {
                            anchors.centerIn: parent
                            width: 32; height: 32; radius: 16
                            color: modelData.today ? Theme.primary : "transparent"
                        }
                        Txt {
                            anchors.centerIn: parent
                            text: modelData.d
                            size: 13
                            weight: modelData.today ? Font.Bold : Font.Normal
                            color: modelData.today ? Theme.fgPrimary : !modelData.cur ? Theme.outlineVariant : modelData.we ? Theme.tertiary : Theme.fg
                        }
                    }
                }
            }
        }

        Rectangle { Layout.fillHeight: true; width: 1; color: Theme.outlineVariant }

        // ── Enfoque + tareas ──
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                height: 120
                radius: 20
                color: Focus.phase === "focus" ? Theme.tertiaryContainer : Theme.surfaceHigh
                Behavior on color { ColorAnimation { duration: Theme.normal } }
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Txt { text: Focus.phase === "idle" ? "Modo enfoque" : Focus.phase === "focus" ? "Concéntrate" : "Descansa"; size: 13; color: Theme.fgDim }
                    Txt { text: Focus.phase === "idle" ? Config.o.focusMinutes + ":00" : Focus.clock; size: 38; weight: Font.Bold; font.features: ({ "tnum": 1 }) }
                    Txt { text: Focus.today + " sesiones hoy"; size: 12; color: Theme.fgDim }
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    IconButton { active: true; icon: Focus.phase === "idle" ? "play_arrow" : Focus.paused ? "play_arrow" : "pause"; onClicked: Focus.toggle() }
                    IconButton { visible: Focus.phase !== "idle"; icon: "skip_next"; onClicked: Focus.skip() }
                    IconButton { visible: Focus.phase !== "idle"; icon: "stop"; onClicked: Focus.stop() }
                }
            }

            Txt { text: "Tareas"; size: 13; weight: Font.DemiBold; color: Theme.fgDim }
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 19
                color: Theme.surfaceHigh
                TextInput {
                    id: todoIn
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: 13
                    clip: true
                    Text { anchors.verticalCenter: parent.verticalCenter; visible: !parent.text; text: "Añadir tarea y Enter…"; color: Theme.outline; font: parent.font }
                    onAccepted: {
                        if (!text.trim()) return;
                        Store.todos = Store.todos.concat([{ t: text.trim(), done: false }]);
                        text = "";
                    }
                }
            }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: Store.todos
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    height: 32
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Sym {
                            text: modelData.done ? "check_circle" : "radio_button_unchecked"
                            fill: modelData.done
                            color: modelData.done ? Theme.primary : Theme.outline
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const t = Store.todos.slice();
                                    t[index] = { t: modelData.t, done: !modelData.done };
                                    Store.todos = t;
                                }
                            }
                        }
                        Txt { text: modelData.t; size: 13; font.strikeout: modelData.done; color: modelData.done ? Theme.outline : Theme.fg }
                    }
                    IconButton {
                        anchors.right: parent.right
                        width: 28; height: 28; iconSize: 16
                        icon: "delete"
                        onClicked: Store.todos = Store.todos.filter((_, i) => i !== index)
                    }
                }
            }
        }
    }
}
