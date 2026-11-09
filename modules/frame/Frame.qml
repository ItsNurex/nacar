import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import "../bar"

// El marco líquido: la barra superior y un borde fino alrededor de la
// pantalla son UNA sola pieza, con esquinas interiores redondeadas que
// "redondean" también las ventanas maximizadas. La isla dinámica cuelga
// del centro de la barra y cambia de forma según lo que pasa.
Scope {
    id: scope
    required property var modelData

    readonly property int t: Config.o.frameThickness
    readonly property int bh: Config.o.barHeight

    // Reserva de espacio en los bordes (ventanas invisibles).
    component Edge: PanelWindow {
        screen: scope.modelData
        color: "transparent"
        mask: Region { }
        WlrLayershell.namespace: "nacar-edge"
        WlrLayershell.layer: WlrLayer.Bottom
    }
    Edge { anchors { top: true; left: true; right: true } implicitHeight: 1; exclusiveZone: scope.bh }
    Edge { visible: scope.t > 0; anchors { left: true; top: true; bottom: true } implicitWidth: 1; exclusiveZone: scope.t }
    Edge { visible: scope.t > 0; anchors { right: true; top: true; bottom: true } implicitWidth: 1; exclusiveZone: scope.t }
    Edge { anchors { bottom: true; left: true; right: true } implicitHeight: 1; exclusiveZone: scope.t + (Config.o.dock ? Config.o.dockIconSize + 20 : 0) }

    PanelWindow {
        id: win
        screen: scope.modelData
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "nacar-frame"
        WlrLayershell.keyboardFocus: island.wantsKeys ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Solo la barra y la isla reciben clics; el resto atraviesa.
        mask: Region {
            item: barArea
            Region { item: island.hitbox }
        }

        IdleInhibitor { window: win; enabled: Ui.caffeine }

        // Cristal esmerilado: todo el marco menos el hueco + el cuerpo de la isla.
        BackgroundEffect.blurRegion: Config.o.blur ? blurRegion : null
        Region {
            id: blurRegion
            x: 0; y: 0; width: win.width; height: win.height
            Region {
                intersection: Intersection.Subtract
                x: scope.t; y: scope.bh
                width: win.width - scope.t * 2
                height: win.height - scope.bh - scope.t
                radius: Theme.radius
            }
            Region {
                item: island.bodyItem
                bottomLeftRadius: Theme.radius
                bottomRightRadius: Theme.radius
            }
        }

        readonly property color fill: Theme.alpha(Theme.surface, Config.o.panelOpacity)

        // ── Marco: rectángulo de pantalla menos un hueco redondeado ──
        // La sombra cae HACIA DENTRO del hueco: da profundidad, como un marco real.
        Shape {
            anchors.fill: parent
            // entrada: el marco cae desde arriba con rebote
            opacity: Math.min(1, Ui.introFrame * 1.5)
            transform: Translate { y: -(1 - Ui.introFrame) * (scope.bh + 40) }
            layer.enabled: Config.o.glow
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Theme.shadow
                shadowOpacity: 0.45
                shadowBlur: 0.7
                shadowVerticalOffset: 2
                shadowHorizontalOffset: 0
            }
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: win.fill
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill
                PathRectangle { x: 0; y: 0; width: win.width; height: win.height }
                PathRectangle {
                    x: scope.t; y: scope.bh
                    width: win.width - scope.t * 2
                    height: win.height - scope.bh - scope.t
                    radius: Theme.radius
                }
            }
            // Filo interior muy sutil: da volumen sin parecer un borde.
            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.alpha(Theme.outlineVariant, 0.35)
                strokeWidth: 1
                PathRectangle {
                    x: scope.t - 0.5; y: scope.bh - 0.5
                    width: win.width - scope.t * 2 + 1
                    height: win.height - scope.bh - scope.t + 1
                    radius: Theme.radius
                }
            }
        }

        // ── Barra ──
        Item {
            id: barArea
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: scope.bh
            opacity: Math.min(1, Ui.introFrame * 1.5)
            transform: Translate { y: -(1 - Ui.introFrame) * (scope.bh + 40) }

            MouseArea {
                anchors.fill: parent
                onWheel: ev => Desktops.cycle(ev.angleDelta.y > 0 ? -1 : 1)
            }

            RowLayout {
                id: left
                anchors.left: parent.left
                anchors.leftMargin: Math.max(8, scope.t + 2)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                LogoButton { }
                Workspaces { }
                ResourceChip { visible: Config.o.showResources && win.width > 1200 }
            }

            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: Math.max(8, scope.t + 2)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                TrayChip { window: win }
                StatusChip { }
                BellChip { }
                IconButton {
                    icon: "power_settings_new"
                    implicitWidth: scope.bh - 10
                    implicitHeight: scope.bh - 10
                    onClicked: Ui.toggleSession()
                }
            }
        }

        Island {
            id: island
            opacity: Math.min(1, Ui.introIsland * 2)
            transform: Scale { origin.x: island.width / 2; origin.y: 0; xScale: 0.25 + 0.75 * Ui.introIsland; yScale: 0.6 + 0.4 * Math.min(1, Ui.introIsland) }
            barHeight: scope.bh
            fill: win.fill
            x: (win.width - width) / 2
            maxWidth: win.width - 2 * Math.max(left.width + 40, 520)
        }
    }
}
