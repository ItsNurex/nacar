pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

// Reproductores MPRIS + visualizador con cava (solo si hay algo sonando).
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer manual: null
    readonly property MprisPlayer player: {
        if (manual && players.indexOf(manual) >= 0) return manual;
        const playing = players.find(p => p.isPlaying);
        return playing || (players.length ? players[0] : null);
    }
    readonly property bool active: player !== null && player.trackTitle !== ""
    readonly property bool playing: player ? player.isPlaying : false
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string art: player ? (player.trackArtUrl || "") : ""
    readonly property real length: player && player.lengthSupported ? player.length : 0
    property real position: 0

    function cyclePlayer() {
        if (players.length < 2) return;
        const i = players.indexOf(player);
        manual = players[(i + 1) % players.length];
    }
    function fmt(sec) {
        sec = Math.max(0, Math.floor(sec));
        const m = Math.floor(sec / 60), s = sec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // MPRIS no emite la posición sola: la pedimos cada segundo mientras suena.
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        triggeredOnStart: true
        onTriggered: { if (root.player) { root.player.positionChanged(); root.position = root.player.position; } }
    }
    Connections {
        target: root.player
        function onPostTrackChanged() { root.position = 0; }
        function onPositionChanged() { root.position = root.player.position; }
    }

    // ── Colores de la carátula ──────────────────────────────────────
    // ColorQuantizer saca la paleta dominante; la isla, el disco y el centro
    // de control se tiñen con ella mientras suena.
    ColorQuantizer {
        id: quant
        source: root.art && Config.o.artColors ? root.art : ""
        depth: 2
        rescaleSize: 48
    }
    function vivid(list) {
        // el color más saturado y luminoso suele ser el más bonito
        let best = null, score = -1;
        for (const c of list || []) {
            const mx = Math.max(c.r, c.g, c.b), mn = Math.min(c.r, c.g, c.b);
            const sc = (mx - mn) * 1.4 + mx * 0.6;
            if (sc > score) { score = sc; best = c; }
        }
        return best;
    }
    readonly property bool hasArtColor: active && quant.colors.length > 0 && Config.o.artColors
    readonly property color artColor: hasArtColor ? (vivid(quant.colors) || Theme.primary) : Theme.primary
    readonly property color artColor2: hasArtColor && quant.colors.length > 1
        ? quant.colors.slice().sort((a, b) => (b.r + b.g + b.b) - (a.r + a.g + a.b))[0] : Theme.tertiary

    // "Bajo": energía de las primeras bandas, suavizada. Hace latir brillos y el disco.
    property real bass: 0
    Behavior on bass { NumberAnimation { duration: 90 } }
    onLevelsChanged: {
        let s = 0; const n = Math.min(6, levels.length);
        for (let i = 0; i < n; i++) s += levels[i];
        bass = playing && n ? Math.min(1, s / n) : 0;
    }

    // ── Visualizador ────────────────────────────────────────────────
    property int bars: 48
    property var levels: new Array(bars).fill(0)
    readonly property bool wantVisualizer: Config.o.showVisualizer && playing

    // NACAR_DEMO=1: niveles simulados (para capturas sin sonido real).
    readonly property bool demo: Quickshell.env("NACAR_DEMO") === "1"
    Timer {
        interval: 33
        repeat: true
        running: root.demo && root.playing
        property real t: 0
        onTriggered: {
            t += 0.09;
            const out = [];
            for (let i = 0; i < root.bars; i++) {
                const v = 0.35 + 0.3 * Math.sin(t * 2.1 + i * 0.45) + 0.25 * Math.sin(t * 3.7 - i * 0.9) * Math.cos(i * 0.2);
                out.push(Math.max(0.03, Math.min(1, v * (1 - i / root.bars * 0.55))));
            }
            root.levels = out;
        }
    }

    Process {
        id: cava
        running: root.wantVisualizer && !root.demo
        command: ["sh", "-c",
            "printf '[general]\\nbars=" + root.bars + "\\nframerate=30\\n[input]\\nmethod=pipewire\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=100\\n' > \"${XDG_RUNTIME_DIR:-/tmp}/nacar-cava.conf\"; exec cava -p \"${XDG_RUNTIME_DIR:-/tmp}/nacar-cava.conf\""]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(";").filter(x => x !== "").map(x => parseInt(x) / 100);
                if (v.length === root.bars) root.levels = v;
            }
        }
        onRunningChanged: if (!running) root.levels = new Array(root.bars).fill(0)
    }
}
