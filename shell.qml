//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import "modules/frame"
import "modules/desktop"
import "modules/omni"
import "modules/center"
import "modules/notifications"
import "modules/session"
import "modules/dock"
import "modules/wallpapers"

// ╭──────────────────────────────────────────────╮
// │  Nácar — shell de escritorio para KDE Plasma │
// ╰──────────────────────────────────────────────╯
ShellRoot {
    id: root

    // Pantalla principal para los paneles (la primera, o la de NACAR_SCREEN).
    readonly property var mainScreen: {
        const want = Quickshell.env("NACAR_SCREEN");
        return Quickshell.screens.find(s => s.name === want) || Quickshell.screens[0];
    }

    // Por pantalla: fondo (opcional) · escritorio vivo · marco líquido
    Variants {
        model: Config.o.drawWallpaper ? Quickshell.screens : []
        Wallpaper { required property var modelData; screen: modelData }
    }
    Variants {
        model: Config.o.desktopWidget ? Quickshell.screens : []
        Desktop { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens
        Frame { }
    }

    Omni { screen: root.mainScreen }
    Center { screen: root.mainScreen }
    Popups { screen: root.mainScreen }
    Session { id: session; screen: root.mainScreen }
    Picker { screen: root.mainScreen }
    LazyLoader {
        active: Config.o.dock
        Dock { screen: root.mainScreen }
    }

    // Despierta los servicios que no usa ningún panel visible al inicio.
    Component.onCompleted: { Theme.dark; Notifs.count; Desktops.available; Sys.cpu; Net.kind; }

    // ── Control remoto: qs -c nacar ipc call nacar <función> ──
    IpcHandler {
        target: "nacar"
        function omni(): void { Ui.toggleOmni(); }
        function omniWith(prefix: string): void { Ui.toggleOmni(prefix); }
        function center(): void { Ui.toggleCenter(); }
        function notifications(): void { Ui.toggleCenter("avisos"); }
        function mixer(): void { Ui.toggleCenter("mezclador"); }
        function calendar(): void { Ui.toggleCalendar(); }
        function session(): void { Ui.toggleSession(); }
        function wallpapers(): void { Ui.toggleWallpapers(); }
        // Vista previa de la despedida (no ejecuta ninguna acción)
        function farewellPreview(): void { session.farewell(null, "Hasta pronto, "); }
        function applyWall(path: string): void { Walls.apply(path); }
        function close(): void { Ui.closeAll(); }
        function dnd(): void { Notifs.setDnd(!Notifs.dnd); }
        function caffeine(): void { Ui.caffeine = !Ui.caffeine; }
        function focus(): void { Focus.toggle(); }
        function focusStop(): void { Focus.stop(); }
        function volumeUp(): void { Audio.step(0.05); }
        function volumeDown(): void { Audio.step(-0.05); }
        function mute(): void { Audio.toggleMute(); }
        function micMute(): void { Audio.toggleMic(); }
        function brightnessUp(): void { Sys.stepBrightness(0.05); }
        function brightnessDown(): void { Sys.stepBrightness(-0.05); }
        function playPause(): void { if (Media.player) Media.player.togglePlaying(); }
        function next(): void { if (Media.player) Media.player.next(); }
        function previous(): void { if (Media.player) Media.player.previous(); }
        function theme(): void { Theme.regenerate(); }
        function island(mode: string): void { Ui.islandForce = mode; }
        function toggleDark(): void { Config.o.darkMode = !Config.o.darkMode; }
        // Consulta Omni desde la terminal: qs -c nacar ipc call nacar query "2+2"
        function query(q: string): string {
            Search.query = q;
            return Search.results.slice(0, 10).map(r => r.kind + "\t" + r.title).join("\n");
        }
        function state(): string {
            return JSON.stringify({ omni: Ui.omni, results: Search.results.length, notifs: Notifs.count, popups: Notifs.popups.length, dnd: Notifs.dnd, desktops: Desktops.list.length, theme: Theme.source });
        }
    }
}
