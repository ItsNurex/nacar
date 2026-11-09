pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Paleta Material 3 generada con matugen a partir del fondo (o un color).
// Se regenera sola cuando cambias el fondo de Plasma.
Singleton {
    id: root

    property var pal: ({})
    property string source: ""
    readonly property bool dark: Config.o.darkMode

    function c(name, fallback) {
        const mode = dark ? pal.dark : pal.light;
        return mode && mode[name] ? mode[name] : fallback;
    }

    // Colores principales
    property color bg: c("background", dark ? "#111318" : "#f9f9ff")
    property color surface: c("surface", dark ? "#111318" : "#f9f9ff")
    property color surfaceLow: c("surface_container_low", dark ? "#191c20" : "#f3f3fa")
    property color surfaceMid: c("surface_container", dark ? "#1d2024" : "#ededf4")
    property color surfaceHigh: c("surface_container_high", dark ? "#282a2f" : "#e7e8ee")
    property color surfaceHighest: c("surface_container_highest", dark ? "#33353a" : "#e2e2e9")
    property color fg: c("on_surface", dark ? "#e2e2e9" : "#1a1b20")
    property color fgDim: c("on_surface_variant", dark ? "#c4c6d0" : "#44474e")
    property color outline: c("outline", dark ? "#8e9099" : "#74777f")
    property color outlineVariant: c("outline_variant", dark ? "#44474e" : "#c4c6d0")
    property color primary: c("primary", dark ? "#aac7ff" : "#415f91")
    property color fgPrimary: c("on_primary", dark ? "#0a305f" : "#ffffff")
    property color primaryContainer: c("primary_container", dark ? "#284777" : "#d6e3ff")
    property color fgPrimaryContainer: c("on_primary_container", dark ? "#d6e3ff" : "#001b3e")
    property color secondary: c("secondary", dark ? "#bec6dc" : "#565f71")
    property color secondaryContainer: c("secondary_container", dark ? "#3e4759" : "#dae2f9")
    property color fgSecondaryContainer: c("on_secondary_container", dark ? "#dae2f9" : "#131c2b")
    property color tertiary: c("tertiary", dark ? "#ddbce0" : "#705575")
    property color tertiaryContainer: c("tertiary_container", dark ? "#573e5c" : "#fad8fd")
    property color fgTertiaryContainer: c("on_tertiary_container", dark ? "#fad8fd" : "#28132e")
    property color error: c("error", dark ? "#ffb4ab" : "#ba1a1a")
    property color errorContainer: c("error_container", dark ? "#93000a" : "#ffdad6")
    readonly property color shadow: "#000000"


    // Transición suave al cambiar de paleta (nuevo fondo = toda la shell se funde al nuevo color)
    Behavior on bg { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on surface { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on surfaceLow { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on surfaceMid { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on surfaceHigh { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on surfaceHighest { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on fg { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on fgDim { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on outline { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on outlineVariant { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on primary { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on fgPrimary { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on primaryContainer { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on fgPrimaryContainer { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on secondary { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on secondaryContainer { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on fgSecondaryContainer { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on tertiary { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on tertiaryContainer { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on fgTertiaryContainer { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on error { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }
    Behavior on errorContainer { enabled: root.speed > 0; ColorAnimation { duration: 850; easing.type: Easing.InOutQuad } }

    // Forma y tipografía
    readonly property int radius: Config.o.radius
    readonly property int radiusSmall: Math.round(Config.o.radius * 0.55)
    readonly property string font: Config.o.fontFamily
    readonly property string mono: Config.o.monoFamily
    readonly property string icons: "Material Symbols Rounded"

    // Tiempos de animación (se escalan con animationSpeed; 0 = desactivado)
    readonly property real speed: Config.o.animationSpeed
    function ms(base) { return speed <= 0 ? 0 : Math.round(base / speed); }
    readonly property int fast: ms(140)
    readonly property int normal: ms(260)
    readonly property int slow: ms(420)

    function alpha(col, a) { return Qt.rgba(col.r, col.g, col.b, a); }
    function mix(a, b, t) {
        return Qt.rgba(a.r * (1 - t) + b.r * t, a.g * (1 - t) + b.g * t, a.b * (1 - t) + b.b * t, 1);
    }

    function regenerate() {
        gen.command = ["python3", Config.shellDir + "/scripts/palette.py", Config.o.themeSource, Config.o.scheme];
        gen.running = false;
        gen.running = true;
    }

    // Paleta en caché: arranque instantáneo con los colores de la última vez.
    FileView {
        id: cache
        path: Config.stateDir + "/palette.json"
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.pal = j;
                root.source = j.source || "";
            } catch (e) {}
        }
    }

    Process {
        id: gen
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    root.pal = j;
                    root.source = j.source || "";
                    cache.setText(text);
                } catch (e) {
                    console.warn("[nacar] paleta inválida:", e);
                }
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() { if (Config.ready) debounce.restart(); }
    }
    Connections {
        target: Config.o
        function onThemeSourceChanged() { debounce.restart(); }
        function onSchemeChanged() { debounce.restart(); }
    }

    // Vigila el fondo de Plasma (solo lectura).
    FileView {
        path: Config.home + "/.config/plasma-org.kde.plasma.desktop-appletsrc"
        watchChanges: Config.o.themeSource === "wallpaper"
        printErrors: false
        onFileChanged: debounce.restart()
    }

    Timer {
        id: debounce
        interval: 600
        onTriggered: root.regenerate()
    }
}
