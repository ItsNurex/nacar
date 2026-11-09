pragma Singleton
import Quickshell
import QtQuick

// Modo enfoque (pomodoro): ciclos de trabajo/descanso, silencia avisos
// mientras trabajas y lleva la cuenta de sesiones del día.
Singleton {
    id: root

    property string phase: "idle"     // idle | focus | break
    property bool paused: false
    property int remaining: 0         // segundos
    property int total: 1
    property int cycle: 0             // sesiones de enfoque completadas en esta racha

    readonly property real progress: total > 0 ? 1 - remaining / total : 0
    readonly property string clock: {
        const m = Math.floor(remaining / 60), s = remaining % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
    readonly property int today: Store.focusDay === new Date().toDateString() ? Store.focusSessionsToday : 0

    function start() { begin("focus"); }
    function stop() { phase = "idle"; paused = false; remaining = 0; cycle = 0; }
    function togglePause() { if (phase !== "idle") paused = !paused; }
    function toggle() { if (phase === "idle") start(); else togglePause(); }
    function skip() { finish(); }

    function begin(p) {
        phase = p;
        paused = false;
        const mins = p === "focus" ? Config.o.focusMinutes
            : (cycle > 0 && cycle % 4 === 0 ? Config.o.longBreakMinutes : Config.o.breakMinutes);
        total = remaining = Math.max(1, mins) * 60;
    }

    function finish() {
        if (phase === "focus") {
            cycle++;
            const d = new Date().toDateString();
            Store.focusSessionsToday = (Store.focusDay === d ? Store.focusSessionsToday : 0) + 1;
            Store.focusDay = d;
            notify("¡Sesión completada!", "Tómate un descanso. Llevas " + root.today + " hoy.");
            begin("break");
        } else if (phase === "break") {
            notify("Fin del descanso", "¿Listo para otra ronda?");
            phase = "idle";
        }
    }

    function notify(title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Nácar · Enfoque", "-i", "alarm", title, body]);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.phase !== "idle" && !root.paused
        onTriggered: {
            root.remaining--;
            if (root.remaining <= 0) root.finish();
        }
    }
}
