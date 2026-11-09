import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import qs.services

// Panel que BROTA del marco: una pestaña líquida (Tab) que crece desde
// el borde superior o inferior con un muelle, y el contenido aparece
// cuando la forma ya casi terminó de crecer. Clic fuera o Esc cierran.
PanelWindow {
    id: win

    property bool open: false
    property string ns: "nacar-popout"
    property int cardWidth: 420
    property int cardHeight: 500
    property string edge: "top"            // top | bottom
    property int align: Qt.AlignRight      // AlignLeft | AlignHCenter | AlignRight
    property bool dim: false
    property bool grabKeys: true
    default property alias content: inner.data
    signal closeRequested()

    readonly property int bh: Config.o.barHeight
    readonly property int ft: Config.o.frameThickness
    readonly property real ear: Theme.radius * 0.9

    // Progreso de apertura 0..1 con muelle (efecto gelatina).
    property real grow: open ? 1 : 0
    Behavior on grow {
        enabled: Theme.speed > 0
        SpringAnimation { spring: 3.2; damping: 0.32; epsilon: 0.004; mass: 1 }
    }

    visible: open || grow > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: ns
    WlrLayershell.keyboardFocus: open && grabKeys ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    BackgroundEffect.blurRegion: Config.o.blur && visible ? blurRegion : null
    Region {
        id: blurRegion
        item: bodyRect
        topLeftRadius: win.edge === "bottom" ? Theme.radius : 0
        topRightRadius: win.edge === "bottom" ? Theme.radius : 0
        bottomLeftRadius: win.edge === "top" ? Theme.radius : 0
        bottomRightRadius: win.edge === "top" ? Theme.radius : 0
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: win.dim ? 0.32 * Math.min(1, win.grow) : 0
    }

    MouseArea {
        anchors.fill: parent
        onClicked: win.closeRequested()
    }

    Item {
        id: holder
        focus: true
        Keys.onEscapePressed: win.closeRequested()

        readonly property real h: Math.max(0, win.cardHeight * win.grow)
        readonly property real w: win.cardWidth * (0.82 + 0.18 * Math.min(1, win.grow))

        width: tab.width
        height: h
        x: (win.align & Qt.AlignLeft) ? win.ft + 10
            : (win.align & Qt.AlignRight) ? parent.width - width - win.ft - 10
            : (parent.width - width) / 2
        y: win.edge === "top" ? win.bh - 1 : parent.height - win.ft - h + 1

        Tab {
            id: tab
            bodyWidth: holder.w
            bodyHeight: holder.h
            ear: win.ear
            flip: win.edge === "bottom"
            color: Theme.alpha(Theme.surface, Config.o.panelOpacity)
        }
        Item { id: bodyRect; x: tab.e; width: holder.w; height: holder.h }
        // Brillo sutil en el borde que toca el marco: parece luz atravesando cristal.
        Rectangle {
            x: tab.e + Theme.radius; width: holder.w - Theme.radius * 2
            y: win.edge === "top" ? holder.h - 1.5 : 0.5
            height: 1
            opacity: Math.min(1, win.grow) * 0.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.primary }
                GradientStop { position: 1; color: "transparent" }
            }
        }

        // Atrapa clics dentro del panel para que no lo cierren.
        MouseArea {
            x: tab.e; width: holder.w; height: holder.h
        }

        Item {
            id: inner
            x: tab.e
            y: win.edge === "top" ? 0 : holder.h - win.cardHeight
            width: win.cardWidth
            height: win.cardHeight
            clip: false
            opacity: Math.max(0, (win.grow - 0.55) / 0.45)
            transform: Translate { y: (1 - Math.min(1, win.grow)) * (win.edge === "top" ? -14 : 14) }
        }

        clip: true
    }
}
