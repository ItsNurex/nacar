pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../lib/Fuzzy.js" as Fuzzy
import "../lib/Calc.js" as Calc
import "../lib/Emoji.js" as Emoji

// Motor de "Omni": una sola caja para TODO.
//   (nada)  apps con frecencia + ventanas abiertas + acciones + cálculo
//   =  calculadora y unidades        >  ejecutar comando (Shift+Enter: en terminal)
//   ?  buscar en la web              :  emojis
//   ;  portapapeles (cliphist)       /  archivos (fd)
//   !  acciones del sistema          @  ventanas abiertas
Singleton {
    id: root

    readonly property var modes: [
        { p: "", name: "Todo", icon: "apps" },
        { p: "=", name: "Calcular", icon: "calculate" },
        { p: ">", name: "Comando", icon: "terminal" },
        { p: "?", name: "Web", icon: "travel_explore" },
        { p: ":", name: "Emoji", icon: "mood" },
        { p: ";", name: "Portapapeles", icon: "content_paste" },
        { p: "/", name: "Archivos", icon: "folder_open" },
        { p: "!", name: "Acciones", icon: "bolt" },
        { p: "@", name: "Ventanas", icon: "select_window" }
    ]

    property string query: ""
    property var results: []
    property var windows: []
    property var files: []
    property var clips: []

    // Se calculan a mano (no como bindings) para que update() nunca vea
    // la consulta anterior.
    function prefixOf(q) { const c = q.charAt(0); return c !== "" && "=>?:;/!@".indexOf(c) >= 0 ? c : ""; }
    property string prefix: ""
    property string term: ""

    onQueryChanged: {
        prefix = prefixOf(query);
        term = (prefix ? query.slice(1) : query).trim();
        update();
        if (prefix === "/") fileTimer.restart();
        if (prefix === ";") clipList.running = true;
        if ((prefix === "" && Config.o.searchWindows && term.length > 1) || prefix === "@") winTimer.restart();
    }

    function hl(text, pos) { return Fuzzy.highlight(text, pos, Theme.primary.toString()); }

    // ── Acciones del sistema ────────────────────────────────────────
    readonly property var actions: [
        { t: "Bloquear pantalla", k: "lock bloquear", g: "lock", f: () => Sys.lock() },
        { t: "Suspender", k: "suspend dormir", g: "bedtime", f: () => Sys.suspend() },
        { t: "Cerrar sesión", k: "logout salir", g: "logout", f: () => Sys.logout() },
        { t: "Reiniciar", k: "reboot restart", g: "restart_alt", f: () => Sys.reboot() },
        { t: "Apagar", k: "shutdown poweroff", g: "power_settings_new", f: () => Sys.poweroff() },
        { t: "No molestar", k: "dnd silencio notificaciones", g: "do_not_disturb_on", f: () => Notifs.setDnd(!Notifs.dnd), state: () => Notifs.dnd },
        { t: "Cafeína (no suspender)", k: "caffeine despierto", g: "coffee", f: () => Ui.caffeine = !Ui.caffeine, state: () => Ui.caffeine },
        { t: "Modo enfoque", k: "pomodoro focus concentrar", g: "timer", f: () => Focus.toggle(), state: () => Focus.phase !== "idle" },
        { t: "Captura de región", k: "screenshot captura", g: "screenshot_region", f: () => Quickshell.execDetached(["spectacle", "-r"]) },
        { t: "Captura de pantalla completa", k: "screenshot captura", g: "screenshot_monitor", f: () => Quickshell.execDetached(["spectacle", "-f"]) },
        { t: "Selector de color", k: "color picker gotero", g: "colorize", f: () => Quickshell.execDetached(["kcolorchooser"]) },
        { t: "Centro de control", k: "control ajustes rapidos", g: "tune", f: () => Ui.toggleCenter() },
        { t: "Modo oscuro / claro", k: "dark light tema", g: "contrast", f: () => Config.o.darkMode = !Config.o.darkMode, state: () => Config.o.darkMode },
        { t: "Cambiar fondo de pantalla", k: "wallpaper fondo imagen carrusel", g: "wallpaper", f: () => Ui.toggleWallpapers() },
        { t: "Regenerar colores desde el fondo", k: "tema matugen colores wallpaper", g: "palette", f: () => { Config.o.themeSource = "wallpaper"; Theme.regenerate(); } },
        { t: "Abrir ajustes de Nácar", k: "settings config ajustes", g: "settings", f: () => Quickshell.execDetached(["xdg-open", Config.configPath]) },
        { t: "Ajustes del sistema", k: "systemsettings kde", g: "settings_applications", f: () => Quickshell.execDetached(["systemsettings"]) },
        { t: "Monitor del sistema", k: "procesos tareas", g: "monitoring", f: () => Quickshell.execDetached(["plasma-systemmonitor"]) },
        { t: "Recargar Nácar", k: "reload reiniciar shell", g: "refresh", f: () => Quickshell.reload(true) }
    ]

    function actionItems(t, boost) {
        const out = [];
        for (const a of actions) {
            const m = t ? (Fuzzy.match(t, a.t) || Fuzzy.match(t, a.k)) : { score: 0, pos: [] };
            if (!m) continue;
            const mt = t ? Fuzzy.match(t, a.t) : null;
            out.push({ kind: "action", title: a.t, html: hl(a.t, mt ? mt.pos : []), subtitle: "Acción",
                glyph: a.g, on: a.state ? a.state() : undefined, score: m.score * 0.9 + (boost || 0), run: a.f });
        }
        return out;
    }

    function appItems(t) {
        const out = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            const fr = Store.frecencyOf(e.id);
            if (!t) {
                out.push({ kind: "app", title: e.name, html: hl(e.name, []), subtitle: e.comment || e.genericName || "",
                    icon: e.icon, score: fr, entry: e, run: () => launch(e) });
                continue;
            }
            const m = Fuzzy.match(t, e.name);
            const alt = m ? null : Fuzzy.match(t, [e.genericName, (e.keywords || []).join(" "), e.execString].join(" "));
            if (!m && !alt) continue;
            const s = (m ? m.score : alt.score * 0.6) + Math.min(fr * 3, 60);
            out.push({ kind: "app", title: e.name, html: hl(e.name, m ? m.pos : []), subtitle: e.comment || e.genericName || "",
                icon: e.icon, score: s, entry: e, run: () => launch(e) });
        }
        return out;
    }

    function launch(e) {
        Store.bump(e.id);
        e.execute();
    }

    function calcItem(t) {
        const r = Calc.evaluate(t);
        if (!r) return null;
        return { kind: "calc", title: r.value, html: "<b>" + Fuzzy.escapeHtml(r.value) + "</b>", subtitle: t + "  ·  Enter copia el resultado",
            glyph: "calculate", score: 1000, run: () => Quickshell.execDetached(["wl-copy", String(r.raw)]) };
    }

    function webItem(t) {
        const url = Config.o.webSearch.replace("%s", encodeURIComponent(t));
        return { kind: "web", title: "Buscar «" + t + "»", html: "Buscar «<b>" + Fuzzy.escapeHtml(t) + "</b>» en la web",
            subtitle: url.split("/")[2] || "", glyph: "travel_explore", score: -1000, run: () => Qt.openUrlExternally(url) };
    }

    function update() {
        const t = term;
        let out = [];
        switch (prefix) {
        case "=": {
            const c = calcItem(t || "0");
            out = c ? [c] : [{ kind: "info", title: "Escribe una operación", html: "Escribe una operación: <i>2^10</i>, <i>15% de 80</i>, <i>5 km a mi</i>, <i>30 c a f</i>", glyph: "calculate", subtitle: "", score: 0, run: null }];
            break;
        }
        case ">":
            out = t ? [{ kind: "cmd", title: t, html: "<tt>" + Fuzzy.escapeHtml(t) + "</tt>", subtitle: "Enter ejecuta · Shift+Enter en " + Config.o.terminal,
                glyph: "terminal", score: 1, run: () => Quickshell.execDetached(["sh", "-c", t]),
                alt: () => Quickshell.execDetached([Config.o.terminal, "-e", "sh", "-c", t + "; exec $SHELL"]) }] : [];
            break;
        case "?":
            out = t ? [webItem(t)] : [];
            break;
        case ":":
            for (const e of Emoji.LIST) {
                const m = t ? Fuzzy.match(t, e[1]) : { score: 0 };
                if (m) out.push({ kind: "emoji", title: e[0], emoji: e[0], html: e[1].split(" ").slice(0, 3).join(" · "), subtitle: "", score: m.score,
                    run: () => Quickshell.execDetached(["wl-copy", e[0]]) });
            }
            break;
        case ";":
            for (const c of clips) {
                const m = t ? Fuzzy.match(t, c.text) : { score: 0, pos: [] };
                if (m) out.push({ kind: "clip", title: c.text, html: Fuzzy.escapeHtml(c.text.slice(0, 140)), subtitle: "Portapapeles", glyph: "content_paste",
                    score: m.score - c.idx * 0.01, run: () => Quickshell.execDetached(["sh", "-c", "cliphist decode " + c.id + " | wl-copy"]) });
            }
            if (!clips.length) out = [{ kind: "info", title: "", html: "Historial vacío. Activa <tt>wl-paste --watch cliphist store</tt>", glyph: "content_paste_off", subtitle: "", score: 0, run: null }];
            break;
        case "/":
            out = files.map((f, i) => ({ kind: "file", title: f.split("/").pop(), html: hl(f.split("/").pop(), (Fuzzy.match(t, f.split("/").pop()) || {}).pos),
                subtitle: f.replace(Config.home, "~"), glyph: f.endsWith("/") ? "folder" : "description", score: -i,
                run: () => Qt.openUrlExternally("file://" + f) }));
            break;
        case "!":
            out = actionItems(t, 0);
            break;
        case "@":
            out = windowItems();
            break;
        default: {
            if (!t) {
                out = appItems("").filter(a => a.score > 0);
                if (out.length < 8) out = appItems("").sort((a, b) => b.score - a.score || a.title.localeCompare(b.title));
                out = out.slice(0, 40);
                break;
            }
            const c = calcItem(t);
            if (c) out.push(c);
            out = out.concat(appItems(t), actionItems(t, -20), windowItems());
            out.push(webItem(t));
        }
        }
        out.sort((a, b) => b.score - a.score);
        results = out.slice(0, 60);
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.update(); }
    }

    // ── Ventanas abiertas (vía KRunner de KWin) ─────────────────────
    function windowItems() {
        return windows.map(w => ({ kind: "window", title: w.text, html: hl(w.text, (Fuzzy.match(term, w.text) || {}).pos),
            subtitle: "Ventana abierta · cambiar a ella", icon: w.icon, glyph: "select_window",
            score: 150 + w.rel * 50, run: () => Quickshell.execDetached(["busctl", "--user", "call", "org.kde.KWin", "/WindowsRunner", "org.kde.krunner1", "Run", "ss", w.id, ""]) }));
    }
    Timer { id: winTimer; interval: 120; onTriggered: { winProc.running = false; winProc.running = true; } }
    Process {
        id: winProc
        command: ["busctl", "--user", "--json=short", "call", "org.kde.KWin", "/WindowsRunner", "org.kde.krunner1", "Match", "s", root.term || " "]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    root.windows = (j.data[0] || [])
                        .slice(0, 8).map(m => ({ id: m[0], text: m[1], icon: m[2], rel: m[4] || 0 }));
                } catch (e) { root.windows = []; }
                root.update();
            }
        }
    }

    // ── Archivos ────────────────────────────────────────────────────
    Timer { id: fileTimer; interval: 200; onTriggered: { fileProc.running = false; if (root.term.length > 1) fileProc.running = true; else root.files = []; } }
    Process {
        id: fileProc
        command: ["fd", "-i", "--max-results", "40", "--max-depth", "6", "--", root.term, Config.home]
        stdout: StdioCollector {
            onStreamFinished: { root.files = text.trim().split("\n").filter(x => x); root.update(); }
        }
    }

    // ── Portapapeles ────────────────────────────────────────────────
    Process {
        id: clipList
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.clips = text.split("\n").filter(x => x).slice(0, 200).map((l, i) => {
                    const tab = l.indexOf("\t");
                    return { id: l.slice(0, tab), text: l.slice(tab + 1), idx: i };
                });
                root.update();
            }
        }
    }
}
