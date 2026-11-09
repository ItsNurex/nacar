import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Particles
import qs.services
import qs.components

// Escritorio vivo: reloj gigante con dígitos que ruedan, saludo según la
// hora y, cuando suena música, un disco giratorio rodeado de un
// visualizador circular que respira con el sonido.
PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "nacar-desktop"
    mask: Region { item: disc.on ? disc : nothing }
    Item { id: nothing; width: 0; height: 0 }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    readonly property string greeting: {
        const h = clock.date.getHours();
        return h < 6 ? "Buenas noches" : h < 13 ? "Buenos días" : h < 20 ? "Buenas tardes" : "Buenas noches";
    }

    // ── Reloj ──
    Column {
        id: clockCol
        visible: Config.o.desktopClock
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 64
        anchors.bottomMargin: 56
        spacing: -6
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 0.9; shadowOpacity: 0.55; shadowVerticalOffset: 3; shadowHorizontalOffset: 0 }

        Txt {
            text: win.greeting + ", " + Sys.user
            size: 22
            weight: 500
            color: Theme.alpha(Theme.fg, 0.85)
        }
        // Reloj con degradado tornasol que se desliza lentamente (efecto nácar).
        Item {
            id: bigClock
            width: digits.width
            height: digits.height
            RollingText {
                id: digits
                text: Qt.formatTime(clock.date, Config.o.clock24h ? "HH:mm" : "h:mm")
                size: 150
                weight: 250
                color: "white"
                layer.enabled: true
                visible: false
            }
            Rectangle {
                id: sheen
                anchors.fill: parent
                visible: false
                layer.enabled: true
                property real shift: 0
                NumberAnimation on shift { from: 0; to: 1; duration: 9000; loops: Animation.Infinite; running: Theme.speed > 0 }
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: Math.max(0, sheen.shift - 0.6); color: Theme.fg }
                    GradientStop { position: sheen.shift * 0.9; color: Theme.mix(Theme.primary, Theme.fg, 0.35) }
                    GradientStop { position: Math.min(1, sheen.shift * 0.9 + 0.18); color: Theme.mix(Theme.tertiary, Theme.fg, 0.3) }
                    GradientStop { position: 1; color: Theme.fg }
                }
            }
            MultiEffect {
                anchors.fill: parent
                source: sheen
                maskEnabled: true
                maskSource: digits
                maskThresholdMin: 0.3
                maskSpreadAtMin: 0.3
            }
        }
        Row {
            spacing: 12
            Rectangle { width: 36; height: 4; radius: 2; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Txt {
                text: clock.date.toLocaleDateString(Qt.locale(), "dddd d 'de' MMMM")
                size: 22
                weight: 450
                color: Theme.alpha(Theme.fg, 0.85)
            }
        }
    }

    // ── Disco + visualizador circular ──
    Item {
        id: disc
        readonly property real r: 78
        width: r * 2 + 200
        height: width
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -20
        readonly property bool on: Config.o.desktopMusic && Media.active
        opacity: on ? 1 : 0
        scale: (on ? 1 : 0.6) + Media.bass * 0.035
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Theme.slow } }
        Behavior on scale { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack } }

        // Barras radiales
        Canvas {
            id: ring
            anchors.fill: parent
            property var lv: Media.levels
            onLvChanged: requestPaint()
            onPaint: {
                const c = getContext("2d"); c.reset();
                const cx = width / 2, cy = height / 2, n = lv.length * 3, base = disc.r + 18;
                c.lineCap = "round";
                c.lineWidth = 2;
                for (let i = 0; i < n; i++) {
                    // espejo: la mitad derecha refleja la izquierda (simétrico)
                    const half = n / 2, li = Math.floor((i < half ? i : n - 1 - i) / half * lv.length);
                    const v = lv[li] || 0;
                    const a = (i / n) * Math.PI * 2 - Math.PI / 2;
                    const len = 3 + v * 70;
                    const t = i / n;
                    const A = Media.artColor, B = Media.artColor2;
                    const k = Math.abs(t - 0.5) * 2;   // simétrico: el color se refleja
                    c.strokeStyle = Qt.rgba(
                        A.r * (1 - k) + B.r * k, A.g * (1 - k) + B.g * k, A.b * (1 - k) + B.b * k, 0.5 + v * 0.5);
                    c.beginPath();
                    c.moveTo(cx + Math.cos(a) * base, cy + Math.sin(a) * base);
                    c.lineTo(cx + Math.cos(a) * (base + len), cy + Math.sin(a) * (base + len));
                    c.stroke();
                }
            }
        }

        // Resplandor de color detrás del disco, late con el bajo
        Rectangle {
            anchors.centerIn: parent
            width: disc.r * 2; height: width; radius: width / 2
            color: Media.artColor
            opacity: 0.55 + Media.bass * 0.4
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64; autoPaddingEnabled: true }
            scale: 1.15 + Media.bass * 0.15
        }

        // Halo iridiscente
        Pearl {
            anchors.centerIn: parent
            width: disc.r * 2 + 8; height: width
            radius: width / 2
            thickness: 3
            active: Media.playing
        }

        ClippingRectangle {
            id: art
            anchors.centerIn: parent
            width: disc.r * 2; height: width
            radius: width / 2
            color: Theme.primaryContainer
            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize: Qt.size(512, 512)
                RotationAnimator on rotation { from: 0; to: 360; duration: 24000; loops: Animation.Infinite; running: Media.playing && Theme.speed > 0 }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (Media.player) Media.player.togglePlaying()
                onWheel: ev => { if (!Media.player) return; if (ev.angleDelta.y < 0) Media.player.next(); else Media.player.previous(); }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: -70
            spacing: 2
            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Media.title; size: 16; weight: 600; width: Math.min(implicitWidth, 360); horizontalAlignment: Text.AlignHCenter }
            Txt { anchors.horizontalCenter: parent.horizontalCenter; text: Media.artist; size: 13; color: Theme.alpha(Theme.fg, 0.75) }
        }
    }

    // ── Polvo de nácar: motas iridiscentes que suben despacio ──
    ParticleSystem {
        id: dust
        anchors.fill: parent
        running: Config.o.particles && Theme.speed > 0
        z: -1
        ImageParticle {
            source: "qrc:///particleresources/glowdot.png"
            color: Theme.alpha(Theme.primary, 0.55)
            colorVariation: 0.35
            alpha: 0.5
            alphaVariation: 0.4
            entryEffect: ImageParticle.Fade
            rotationVariation: 180
        }
        Emitter {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.6
            emitRate: 3 + Media.bass * 18
            lifeSpan: 14000
            lifeSpanVariation: 4000
            size: 10
            sizeVariation: 12
            endSize: 2
            velocity: AngleDirection { angle: 270; angleVariation: 25; magnitude: 18; magnitudeVariation: 12 }
            acceleration: PointDirection { xVariation: 4; yVariation: 2 }
        }
        Wander { xVariance: 40; pace: 30 }
    }
}
