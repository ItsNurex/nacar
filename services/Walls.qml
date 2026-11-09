pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Fondos de pantalla: lista las carpetas configuradas y aplica el elegido.
// Al aplicarlo, Theme regenera la paleta y TODA la shell cambia de color.
Singleton {
    id: root

    property var list: []
    property bool loading: false
    readonly property string current: Config.o.drawWallpaper ? (Config.o.wallpaper || Theme.source) : Theme.source

    function refresh() {
        loading = true;
        proc.command = ["python3", Config.shellDir + "/scripts/walls.py", Config.shellDir + "/wallpapers"].concat(Config.o.wallpaperDirs);
        proc.running = true;
    }

    function apply(path) {
        if (!path) return;
        if (Config.o.drawWallpaper) {
            // Nácar pinta su propio fondo
            Config.o.wallpaper = path;
            Config.o.themeSource = path;
        } else {
            // Plasma pinta el fondo: se lo pedimos y la paleta se regenera sola
            Quickshell.execDetached(["plasma-apply-wallpaperimage", path]);
            Config.o.themeSource = "wallpaper";
            regen.restart();
        }
    }
    Timer { id: regen; interval: 900; onTriggered: Theme.regenerate() }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.list = JSON.parse(text); } catch (e) { root.list = []; }
                root.loading = false;
            }
        }
    }
}
