import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.components

// Menú de sesión con navegación por teclado y cuenta atrás cancelable
// (para que un clic sin querer no te apague el PC).
PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nacar-session"
    WlrLayershell.keyboardFocus: Ui.session ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    visible: Ui.session || bye || bg.opacity > 0

    readonly property var items: [
        { icon: "lock", name: "Bloquear", key: "B", f: () => Sys.lock(), instant: true },
        { icon: "bedtime", name: "Suspender", key: "S", f: () => Sys.suspend(), instant: true },
        { icon: "logout", name: "Cerrar sesión", key: "C", f: () => Sys.logout() },
        { icon: "restart_alt", name: "Reiniciar", key: "R", f: () => Sys.reboot() },
        { icon: "power_settings_new", name: "Apagar", key: "A", f: () => Sys.poweroff() }
    ]
    property int sel: 0
    property int pending: -1
    property int countdown: 0

    onVisibleChanged: if (Ui.session) { sel = 0; pending = -1; keys.forceActiveFocus(); }

    function choose(i) {
        const it = items[i];
        if (it.instant) { farewell(it.f, it.name === "Bloquear" ? "Hasta luego, " : "Dulces sueños, "); return; }
        pending = i; countdown = 3; tick.restart();
    }

    // ── Despedida: todo se funde y se escribe un adiós letra a letra ──
    property bool bye: false
    property string byeFull: ""
    property string byeTyped: ""
    property var byeAction: null
    function farewell(f, greeting) {
        byeAction = f;
        byeFull = (greeting || "Hasta pronto, ") + Sys.user;
        byeTyped = "";
        bye = true;
        typer.start();
    }
    Timer {
        id: typer
        interval: 55
        repeat: true
        onTriggered: {
            if (win.byeTyped.length < win.byeFull.length) {
                win.byeTyped = win.byeFull.slice(0, win.byeTyped.length + 1);
            } else {
                stop();
                doIt.start();
            }
        }
    }
    Timer {
        id: doIt
        interval: Theme.speed > 0 ? 900 : 0
        onTriggered: {
            const f = win.byeAction;
            Ui.session = false;
            win.pending = -1;
            if (f) f();
            resetBye.start();
        }
    }
    // Si la acción no apaga el equipo (bloquear, suspender), la shell vuelve.
    Timer { id: resetBye; interval: 1500; onTriggered: { win.bye = false; win.byeTyped = ""; } }
    function cancel() { pending = -1; tick.stop(); }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            win.countdown--;
            if (win.countdown <= 0) {
                stop();
                win.farewell(win.items[win.pending].f, win.items[win.pending].name === "Cerrar sesión" ? "Nos vemos, " : "Hasta pronto, ");
            }
        }
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Theme.alpha(Theme.bg, 0.82)
        opacity: Ui.session ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
        MouseArea { anchors.fill: parent; onClicked: { win.cancel(); Ui.session = false; } }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        opacity: bg.opacity
        Keys.onPressed: ev => {
            if (ev.key === Qt.Key_Escape) { if (win.pending >= 0) win.cancel(); else Ui.session = false; }
            else if (ev.key === Qt.Key_Left) win.sel = (win.sel + win.items.length - 1) % win.items.length;
            else if (ev.key === Qt.Key_Right || ev.key === Qt.Key_Tab) win.sel = (win.sel + 1) % win.items.length;
            else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter || ev.key === Qt.Key_Space) win.choose(win.sel);
            else {
                const i = win.items.findIndex(it => it.key === ev.text.toUpperCase());
                if (i >= 0) win.choose(i);
            }
            ev.accepted = true;
        }

        Column {
            anchors.centerIn: parent
            spacing: 30

            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: win.pending >= 0 ? win.items[win.pending].name + " en " + win.countdown + "…" : "¿Qué hacemos, " + Sys.user + "?"
                size: 30
                weight: Font.Bold
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 18
                Repeater {
                    model: win.items
                    Clicky {
                        id: b
                        required property var modelData
                        required property int index
                        readonly property bool cur: win.sel === index
                        readonly property bool armed: win.pending === index
                        width: 130; height: 150
                        radius: cur ? 36 : 65
                        base: armed ? Theme.error : cur ? Theme.primary : Theme.surfaceHigh
                        tint: cur ? Theme.fgPrimary : Theme.fg
                        scale: cur ? 1.06 : 1
                        Behavior on radius { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                        onClicked: win.choose(index)
                        mouse.onEntered: win.sel = index
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Sym { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; size: 44; fill: b.cur; color: b.cur || b.armed ? Theme.fgPrimary : Theme.fg }
                            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.name; size: 14; weight: Font.DemiBold; color: b.cur || b.armed ? Theme.fgPrimary : Theme.fg }
                            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.key; size: 11; color: b.cur ? Theme.alpha(Theme.fgPrimary, 0.7) : Theme.outline }
                        }
                    }
                }
            }

            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: win.pending >= 0 ? "Esc o clic para cancelar" : "← → para moverte · Enter para elegir · o pulsa la letra"
                size: 13
                color: Theme.fgDim
            }
        }
    }

    // Capa de despedida
    Rectangle {
        id: byeLayer
        anchors.fill: parent
        color: Theme.bg
        opacity: win.bye ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.slow; easing.type: Easing.InOutQuad } }

        Pearl {
            anchors.centerIn: parent
            width: byeText.width + 120; height: 120
            thickness: 2
            active: win.bye
            scale: win.bye ? 1 : 0.6
            Behavior on scale { NumberAnimation { duration: 900; easing.type: Easing.OutBack } }
        }
        Column {
            anchors.centerIn: parent
            spacing: 8
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                Txt { id: byeText; text: win.byeTyped; size: 40; weight: 600 }
                Rectangle {
                    width: 3; height: 42; radius: 1.5
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.primary
                    SequentialAnimation on opacity { loops: Animation.Infinite; running: win.bye
                        NumberAnimation { to: 0; duration: 420 } NumberAnimation { to: 1; duration: 420 } }
                }
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "さようなら"
                size: 18
                color: Theme.fgDim
                opacity: win.byeTyped.length === win.byeFull.length && win.bye ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 500 } }
            }
        }
    }
}
