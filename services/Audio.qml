pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Sonido vía PipeWire: salida, micrófono, dispositivos y mezclador por app.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : true
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : true

    function mediaClass(n) { return (n && n.properties && n.properties["media.class"]) || ""; }

    // Apps que están sonando (Stream/Output/Audio).
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio
        && mediaClass(n).indexOf("Output") >= 0)
    readonly property var sinks: Pipewire.nodes.values.filter(n => !n.isStream && n.audio
        && mediaClass(n) === "Audio/Sink")
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isStream && n.audio
        && mediaClass(n) === "Audio/Source")

    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.streams).concat(root.sinks)
    }

    function setVolume(v) {
        if (sink && sink.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1.5, v));
        }
    }
    function step(d) { setVolume(volume + d); }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
    function setMic(v) { if (source && source.audio) { source.audio.muted = false; source.audio.volume = Math.max(0, Math.min(1.5, v)); } }
    function toggleMic() { if (source && source.audio) source.audio.muted = !source.audio.muted; }
    function useSink(n) { Pipewire.preferredDefaultAudioSink = n; }

    function nodeName(n) {
        if (!n) return "—";
        const p = n.properties || {};
        return p["application.name"] || n.description || n.nickname || n.name || "Desconocido";
    }
    function nodeIcon(n) {
        const p = (n && n.properties) || {};
        return p["application.icon-name"] || p["application.process.binary"] || "audio-volume-high";
    }
    function icon(vol, mute) {
        if (mute || vol <= 0.001) return "volume_off";
        if (vol < 0.34) return "volume_mute";
        if (vol < 0.67) return "volume_down";
        return "volume_up";
    }
}
