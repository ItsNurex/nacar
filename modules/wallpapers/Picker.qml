import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.services
import qs.components

// ── Selector de fondos en carrusel 3D ─────────────────────────────
// Tarjetas en perspectiva: la central grande y de frente, las laterales
// giradas y más pequeñas. Rueda / flechas para moverse, Enter o clic para
// aplicar. Al aplicar, la shell entera se recolorea con el nuevo fondo.
PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nacar-wallpapers"
    WlrLayershell.keyboardFocus: Ui.wallpapers ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property real shown: Ui.wallpapers ? 1 : 0
    Behavior on shown { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutCubic } }
    visible: Ui.wallpapers || shown > 0.01

    BackgroundEffect.blurRegion: Config.o.blur && Ui.wallpapers ? full : null
    Region { id: full; x: 0; y: 0; width: win.width; height: win.height }

    onVisibleChanged: if (Ui.wallpapers) {
        if (!Walls.list.length) Walls.refresh();
        view.forceActiveFocus();
        const i = Walls.list.indexOf(Walls.current);
        if (i >= 0) view.currentIndex = i;
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.bg, 0.55)
        opacity: win.shown
        MouseArea { anchors.fill: parent; onClicked: Ui.wallpapers = false }
    }

    // Título
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.12 - (1 - win.shown) * 30
        opacity: win.shown
        spacing: 6
        Txt { anchors.horizontalCenter: parent.horizontalCenter; text: "Elige tu fondo"; size: 30; weight: 650 }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Walls.loading ? "Buscando imágenes…" : Walls.list.length + " fondos · la shell tomará sus colores"
            size: 14; color: Theme.fgDim
        }
    }

    PathView {
        id: view
        anchors.fill: parent
        anchors.topMargin: parent.height * 0.18
        anchors.bottomMargin: parent.height * 0.18
        model: Walls.list
        pathItemCount: 7
        preferredHighlightBegin: 0.5
        preferredHighlightEnd: 0.5
        highlightRangeMode: PathView.StrictlyEnforceRange
        snapMode: PathView.SnapToItem
        highlightMoveDuration: Theme.normal
        opacity: win.shown
        scale: 0.9 + 0.1 * win.shown
        focus: true

        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()
        Keys.onEscapePressed: Ui.wallpapers = false
        Keys.onReturnPressed: { Walls.apply(Walls.list[currentIndex]); }
        Keys.onEnterPressed: { Walls.apply(Walls.list[currentIndex]); }

        MouseArea {
            anchors.fill: parent
            z: -1
            onWheel: ev => ev.angleDelta.y > 0 ? view.decrementCurrentIndex() : view.incrementCurrentIndex()
            onClicked: Ui.wallpapers = false
        }

        path: Path {
            startX: -view.width * 0.15; startY: view.height / 2
            PathAttribute { name: "s"; value: 0.55 }
            PathAttribute { name: "ang"; value: 55 }
            PathAttribute { name: "z"; value: 0 }
            PathAttribute { name: "o"; value: 0.0 }
            PathLine { x: view.width * 0.5; y: view.height / 2 }
            PathAttribute { name: "s"; value: 1.0 }
            PathAttribute { name: "ang"; value: 0 }
            PathAttribute { name: "z"; value: 10 }
            PathAttribute { name: "o"; value: 1.0 }
            PathLine { x: view.width * 1.15; y: view.height / 2 }
            PathAttribute { name: "s"; value: 0.55 }
            PathAttribute { name: "ang"; value: -55 }
            PathAttribute { name: "z"; value: 0 }
            PathAttribute { name: "o"; value: 0.0 }
        }

        delegate: Item {
            id: card
            required property string modelData
            required property int index
            readonly property bool cur: PathView.isCurrentItem
            readonly property bool applied: modelData === Walls.current
            width: view.height * 1.25
            height: view.height * 0.7
            scale: PathView.s
            z: PathView.z
            opacity: 0.25 + 0.75 * PathView.o
            transform: Rotation {
                origin.x: card.width / 2; origin.y: card.height / 2
                axis { x: 0; y: 1; z: 0 }
                angle: card.PathView.ang
            }

            // Reflejo/sombra de color
            Item {
                anchors.fill: parent
                layer.enabled: card.cur && Config.o.glow
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Theme.primary
                    shadowOpacity: 0.55
                    shadowBlur: 1.0
                    shadowVerticalOffset: 14
                    shadowHorizontalOffset: 0
                }
                ClippingRectangle {
                    anchors.fill: parent
                    radius: Theme.radius + 6
                    color: Theme.surfaceHigh
                    Image {
                        anchors.fill: parent
                        source: "file://" + card.modelData
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 640
                        cache: true
                    }
                    // Brillo nácar en la tarjeta activa
                    Pearl {
                        anchors.fill: parent
                        radius: Theme.radius + 6
                        thickness: 3
                        active: card.cur
                    }
                }
            }

            // Etiqueta "En uso"
            Rectangle {
                visible: card.applied
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 14
                width: usedRow.width + 18; height: 28; radius: 14
                color: Theme.primary
                Row {
                    id: usedRow
                    anchors.centerIn: parent
                    spacing: 4
                    Sym { text: "check"; size: 16; color: Theme.fgPrimary }
                    Txt { text: "En uso"; size: 12; weight: 600; color: Theme.fgPrimary }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: card.cur ? Walls.apply(card.modelData) : (view.currentIndex = card.index)
            }
        }
    }

    // Nombre del fondo y pista
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: parent.height * 0.08
        opacity: win.shown
        spacing: 8
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Walls.list.length ? Walls.list[view.currentIndex].split("/").pop().replace(/\.[^.]+$/, "") : ""
            size: 16; weight: 600
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← →  o rueda para moverte  ·  Enter o clic para aplicar  ·  Esc para salir"
            size: 12; color: Theme.fgDim
        }
    }
}
