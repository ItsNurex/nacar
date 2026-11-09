pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Escritorios virtuales de KWin por D-Bus, sin scripts ni demonios extra.
// Escucha las señales de KWin y solo vuelve a consultar cuando algo cambia.
Singleton {
    id: root

    property var list: []          // [{id, name, pos}]
    property string current: ""
    readonly property int currentIndex: list.findIndex(d => d.id === current)
    readonly property bool available: list.length > 0

    readonly property var busBase: ["busctl", "--user", "--json=short", "get-property", "org.kde.KWin",
        "/VirtualDesktopManager", "org.kde.KWin.VirtualDesktopManager"]

    function refresh() {
        if (!qList.running) qList.running = true;
        if (!qCur.running) qCur.running = true;
    }
    function activate(id) {
        if (!id) return;
        root.current = id; // respuesta instantánea en la barra
        Quickshell.execDetached(["busctl", "--user", "set-property", "org.kde.KWin", "/VirtualDesktopManager",
            "org.kde.KWin.VirtualDesktopManager", "current", "s", id]);
    }
    function cycle(dir) {
        if (!list.length) return;
        const i = Math.max(0, currentIndex);
        activate(list[(i + dir + list.length) % list.length].id);
    }

    Process {
        id: qList
        command: root.busBase.concat(["desktops"])
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    root.list = j.data.map(e => ({ pos: e[0], id: e[1], name: e[2] }));
                } catch (e) {}
            }
        }
    }
    Process {
        id: qCur
        command: root.busBase.concat(["current"])
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.current = JSON.parse(text).data; } catch (e) {}
            }
        }
    }

    // Escucha cambios (cambio de escritorio, crear/borrar/renombrar).
    Process {
        id: watcher
        running: true
        command: ["dbus-monitor", "--session",
            "type='signal',path='/VirtualDesktopManager'"]
        stdout: SplitParser {
            onRead: line => { if (line.indexOf("member=") >= 0) debounce.restart(); }
        }
        onExited: restartWatch.start()
    }
    Timer { id: restartWatch; interval: 3000; onTriggered: watcher.running = true }
    Timer { id: debounce; interval: 60; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
