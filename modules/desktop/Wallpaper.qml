import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Fondo propio (opcional, desactivado por defecto: en KDE lo pinta Plasma).
// Cambia de fondo con un fundido suave.
PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.bg
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "nacar-wallpaper"
    mask: Region { }

    readonly property string src: Config.o.wallpaper || Theme.source
    property bool flip: false
    onSrcChanged: { flip = !flip; (flip ? a : b).source = src.startsWith("/") ? "file://" + src : src; }

    Image { id: a; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true; opacity: win.flip ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 900 } } }
    Image { id: b; anchors.fill: parent; fillMode: Image.PreserveAspectCrop; asynchronous: true; opacity: win.flip ? 0 : 1; Behavior on opacity { NumberAnimation { duration: 900 } } }
}
