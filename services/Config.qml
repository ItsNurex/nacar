pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Ajustes del usuario en ~/.config/nacar/config.json.
// Se recargan en caliente: guarda el archivo y la shell cambia al instante.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // NACAR_HOME permite probar la shell con una carpeta aislada.
    readonly property string sandbox: Quickshell.env("NACAR_HOME") || ""
    readonly property string configDir: sandbox ? sandbox + "/config" : home + "/.config/nacar"
    readonly property string stateDir: sandbox ? sandbox + "/state"
        : (Quickshell.env("XDG_STATE_HOME") || home + "/.local/state") + "/nacar"
    readonly property string configPath: configDir + "/config.json"
    readonly property string shellDir: Quickshell.shellDir

    property alias o: adapter
    property bool ready: false

    Process {
        running: true
        command: ["mkdir", "-p", root.configDir, root.stateDir]
        onExited: file.reload()
    }

    FileView {
        id: file
        path: root.configPath
        watchChanges: true
        blockLoading: false
        printErrors: false
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoaded: root.ready = true
        onLoadFailed: function (err) {
            if (err === FileViewError.FileNotFound) {
                writeAdapter();
            }
            root.ready = true;
        }

        JsonAdapter {
            id: adapter

            // Apariencia
            property string themeSource: "wallpaper"   // wallpaper | accent | #rrggbb | /ruta/imagen
            property string scheme: "scheme-tonal-spot"
            property bool darkMode: true
            property real panelOpacity: 0.78
            property bool blur: true                   // cristal esmerilado (KWin)
            property bool glow: true                   // brillos de color y sombras
            property bool particles: true              // polvo de nácar en el escritorio
            property bool artColors: true              // la música tiñe la isla y el disco
            property int radius: 22
            property real animationSpeed: 1.0          // 0 = sin animaciones
            property string fontFamily: "Google Sans Flex"
            property string monoFamily: "CaskaydiaCove Nerd Font"

            // Marco líquido (borde de pantalla unido a la barra; 0 = sin marco)
            property int frameThickness: 7
            // Escritorio: reloj grande + visualizador circular
            property bool desktopWidget: true
            property bool desktopMusic: false          // disco de música en el centro (opcional)
            property bool desktopClock: false          // reloj grande en el escritorio (opcional)
            // Dibujar fondo propio (solo si tu escritorio no lo hace)
            property bool drawWallpaper: false
            property string wallpaper: ""

            // Dock
            property bool dock: true
            property var dockApps: ["org.kde.dolphin", "firefox", "zen", "kitty", "org.kde.konsole", "spotify-launcher", "steam", "systemsettings"]
            property int dockIconSize: 42
            property real dockMagnify: 0.55            // 0 = sin ampliación

            // Fondos de pantalla (selector en carrusel)
            property var wallpaperDirs: ["~/Pictures/Wallpapers", "~/Imágenes/Fondos", "~/Pictures", "/usr/share/wallpapers"]

            // Barra
            property int barHeight: 42
            property bool barFloating: true
            property bool clock24h: true
            property bool clockSeconds: false
            property bool showVisualizer: true
            property bool showResources: true

            // Lanzador
            property string terminal: "kitty"
            property string webSearch: "https://duckduckgo.com/?q=%s"
            property bool searchWindows: true

            // Avisos
            property int notifTimeout: 6000
            property int historyLimit: 80

            // Enfoque (pomodoro)
            property int focusMinutes: 25
            property int breakMinutes: 5
            property int longBreakMinutes: 15
            property bool focusSilences: true

            // Batería
            property int batteryWarn: 20
            property int batteryCritical: 8
        }
    }
}
