pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Estado persistente: sobrevive a reinicios de la shell y del PC.
// (frecencia del lanzador, historial de avisos, no molestar, tareas…)
Singleton {
    id: root

    property var frecency: ({})
    property var history: []
    property var todos: []
    property bool dnd: false
    property int focusSessionsToday: 0
    property string focusDay: ""

    property bool loaded: false
    readonly property var keys: ["frecency", "history", "todos", "dnd", "focusSessionsToday", "focusDay"]

    // Frecencia: cuántas veces y cuándo abriste cada app.
    function bump(id) {
        const f = Object.assign({}, frecency);
        const e = f[id] || { n: 0, t: 0 };
        f[id] = { n: e.n + 1, t: Date.now() };
        frecency = f;
    }
    function frecencyOf(id) {
        const e = frecency[id];
        if (!e) return 0;
        const days = (Date.now() - e.t) / 86400000;
        const decay = days < 1 ? 4 : days < 7 ? 2 : days < 30 ? 1 : 0.5;
        return e.n * decay;
    }

    onFrecencyChanged: save()
    onHistoryChanged: save()
    onTodosChanged: save()
    onDndChanged: save()
    onFocusSessionsTodayChanged: save()
    onFocusDayChanged: save()
    function save() { if (loaded) saver.restart(); }

    FileView {
        id: file
        path: Config.stateDir + "/state.json"
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text());
                for (const k of root.keys) if (j[k] !== undefined) root[k] = j[k];
            } catch (e) {}
            root.loaded = true;
        }
        onLoadFailed: root.loaded = true
    }

    // Agrupa escrituras para no machacar el disco.
    Timer {
        id: saver
        interval: 800
        onTriggered: {
            const o = {};
            for (const k of root.keys) o[k] = root[k];
            file.setText(JSON.stringify(o, null, 1));
        }
    }
}
