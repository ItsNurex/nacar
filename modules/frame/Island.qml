import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components

// ── La isla dinámica ──────────────────────────────────────────────
// Vive en el centro de la barra y cambia de forma con un muelle:
//   reposo     → reloj · fecha (+ música / enfoque en miniatura)
//   reproductor→ al pasar el ratón con música: controles y progreso
//   aviso      → llega una notificación: se estira y brilla en nácar
//   osd        → volumen / micro / brillo
//   calendario → la isla entera se convierte en el calendario
Item {
    id: root

    property int barHeight: 42
    property color fill: Theme.surface
    property real maxWidth: 800
    readonly property bool wantsKeys: mode === "calendar"
    readonly property alias hitbox: hit
    readonly property alias bodyItem: body
    // Color de acento vivo: el de la carátula si suena música.
    readonly property color accent: Media.playing && Media.hasArtColor ? Media.artColor : Theme.primary

    // ── Estado ──
    property string osdKind: ""
    property bool osdOn: false
    property bool armed: false
    property var flashN: null
    readonly property bool hovered: hover.hovered

    readonly property string mode: Ui.islandForce !== "" ? Ui.islandForce
        : Ui.calendar ? "calendar"
        : osdOn ? (osdKind === "desk" ? "desk" : "osd")
        : flashN ? "notif"
        : (hovered && Media.active) ? "player"
        : "idle"

    readonly property var sizes: ({
        calendar: [780, 430],
        osd: [360, 56],
        desk: [300, 52],
        notif: [460, 74],
        player: [480, 96],
        idle: [0, 0]
    })
    readonly property real wantW: Math.min(maxWidth, Math.max(top.implicitWidth + 36, sizes[mode][0]))
    readonly property real wantH: sizes[mode][1]

    property real bodyW: wantW
    property real extra: wantH
    Behavior on bodyW { enabled: Theme.speed > 0; SpringAnimation { spring: 3.6; damping: 0.34; epsilon: 0.3 } }
    Behavior on extra { enabled: Theme.speed > 0; SpringAnimation { spring: 3.6; damping: 0.30; epsilon: 0.3 } }

    readonly property real ear: Theme.radius * 0.8
    width: bodyW + ear * 2
    height: barHeight + Math.max(0, extra)

    // ── Disparadores ──
    function showOsd(k) { if (!armed) return; osdKind = k; osdOn = true; osdTimer.restart(); }
    Timer { interval: 1500; running: true; onTriggered: root.armed = true }
    Timer { id: osdTimer; interval: 1500; onTriggered: root.osdOn = false }
    Timer { id: flashTimer; interval: 4200; onTriggered: root.flashN = null }
    Connections {
        target: Audio
        function onVolumeChanged() { root.showOsd("vol"); }
        function onMutedChanged() { root.showOsd("vol"); }
        function onMicMutedChanged() { root.showOsd("mic"); }
    }
    Connections { target: Sys; function onBrightnessTouched() { root.showOsd("bri"); } }
    Connections { target: Desktops; function onCurrentChanged() { root.showOsd("desk"); } }
    Connections {
        target: Notifs
        function onFlashed(n) { root.flashN = n; flashTimer.restart(); }
    }

    // Zona que recibe clics (pastilla + cuerpo).
    Item {
        id: hit
        x: root.ear
        width: root.bodyW
        height: root.height
    }
    HoverHandler { id: hover }

    // ── Forma: cuelga de la barra, con un halo de color que late con el bajo ──
    Item {
        anchors.fill: parent
        layer.enabled: Config.o.glow && root.extra > 1
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.accent
            shadowOpacity: 0.35 + Media.bass * 0.45
            shadowBlur: 1.0
            shadowVerticalOffset: 6
            shadowHorizontalOffset: 0
            autoPaddingEnabled: true
        }
        Tab {
            y: root.barHeight - 1
            bodyWidth: root.bodyW
            bodyHeight: Math.max(0, root.extra) + 1
            ear: root.ear
            color: root.fill
        }
        // Velo de color de la carátula dentro del cuerpo
        Rectangle {
            x: root.ear; y: root.barHeight
            width: root.bodyW; height: Math.max(0, root.extra)
            bottomLeftRadius: Theme.radius; bottomRightRadius: Theme.radius
            opacity: root.mode === "player" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.normal } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.alpha(root.accent, 0.28) }
                GradientStop { position: 0.7; color: Theme.alpha(root.accent, 0.06) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    // Pastilla bajo la fila superior (le da cuerpo de "isla").
    Rectangle {
        id: pill
        x: root.ear + 4
        y: 5
        width: root.bodyW - 8
        height: root.barHeight - 10
        radius: height / 2
        color: Theme.alpha(Theme.surfaceHigh, 0.85)
        layer.enabled: Config.o.glow && Media.playing
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.accent
            shadowOpacity: 0.15 + Media.bass * 0.6
            shadowBlur: 0.8
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }
        Pearl {
            anchors.fill: parent
            thickness: 1.6
            active: root.mode === "notif" || Focus.phase === "focus" || (root.mode === "player" && Media.playing)
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: ev => {
                if (ev.button === Qt.RightButton) Ui.toggleCenter("avisos");
                else if (ev.button === Qt.MiddleButton) { if (Media.player) Media.player.togglePlaying(); }
                else if (root.mode === "notif") { root.flashN = null; Ui.toggleCenter("avisos"); }
                else Ui.toggleCalendar();
            }
            onWheel: ev => Audio.step(ev.angleDelta.y > 0 ? 0.05 : -0.05)
        }
    }

    // ── Fila superior (siempre visible) ──
    SystemClock { id: clock; precision: Config.o.clockSeconds ? SystemClock.Seconds : SystemClock.Minutes }

    RowLayout {
        id: top
        anchors.horizontalCenter: pill.horizontalCenter
        anchors.verticalCenter: pill.verticalCenter
        spacing: 10

        Txt {
            text: Qt.formatTime(clock.date, Config.o.clock24h ? (Config.o.clockSeconds ? "HH:mm:ss" : "HH:mm") : "h:mm AP")
            size: 15
            weight: Font.Bold
            font.features: ({ "tnum": 1 })
        }
        Txt {
            visible: !Media.active || root.mode === "calendar"
            text: clock.date.toLocaleDateString(Qt.locale(), "ddd d MMM")
            size: 13
            color: Theme.fgDim
        }

        // Enfoque en miniatura
        Row {
            visible: Focus.phase !== "idle"
            spacing: 5
            Sym { text: Focus.phase === "focus" ? "timer" : "self_improvement"; size: 16; fill: true; color: Theme.tertiary }
            Txt { text: Focus.clock; size: 13; weight: Font.DemiBold; color: Theme.tertiary; font.features: ({ "tnum": 1 }) }
        }

        // Música en miniatura
        Row {
            visible: Media.active && root.mode !== "calendar"
            spacing: 8
            Rectangle { width: 1; height: 16; color: Theme.outlineVariant; anchors.verticalCenter: parent.verticalCenter }
            ClippingRectangle {
                width: 22; height: 22; radius: 11
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.primaryContainer
                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(64, 64)
                    RotationAnimator on rotation { from: 0; to: 360; duration: 10000; loops: Animation.Infinite; running: Media.playing && Theme.speed > 0 }
                }
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 220)
                text: Media.title
                size: 13
                weight: Font.Medium
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                visible: Config.o.showVisualizer
                Repeater {
                    model: 6
                    Rectangle {
                        required property int index
                        width: 3; radius: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        height: Math.max(3, 18 * (Media.levels[index * 8] || 0))
                        color: Theme.mix(Theme.primary, Theme.tertiary, index / 6)
                        Behavior on height { NumberAnimation { duration: 70 } }
                    }
                }
            }
        }
    }

    // ── Cuerpo (debajo de la barra) ──
    Item {
        id: body
        x: root.ear
        y: root.barHeight
        width: root.bodyW
        height: Math.max(0, root.extra)
        clip: true

        component Pane: Item {
            property string name
            anchors.fill: parent
            anchors.margins: 0
            readonly property bool on: root.mode === name
            visible: opacity > 0.01
            opacity: on ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: on ? Theme.normal : Theme.fast } }
        }

        // Reproductor
        Pane {
            name: "player"
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.bottomMargin: 12
                anchors.topMargin: 4
                spacing: 12
                ClippingRectangle {
                    Layout.preferredWidth: 72; Layout.preferredHeight: 72
                    radius: 18
                    scale: 1 + Media.bass * 0.06
                    color: Theme.primaryContainer
                    Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Txt { Layout.fillWidth: true; text: Media.title; size: 14; weight: Font.Bold }
                    Txt { Layout.fillWidth: true; text: Media.artist; size: 12; color: Theme.fgDim }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Txt { text: Media.fmt(Media.position); size: 10; color: Theme.outline; font.features: ({ "tnum": 1 }) }
                        Item {
                            Layout.fillWidth: true
                            height: 14
                            // Barra de progreso ondulada mientras suena
                            Canvas {
                                id: wave
                                anchors.fill: parent
                                property real p: Media.length > 0 ? Math.min(1, Media.position / Media.length) : 0
                                property real phase: 0
                                NumberAnimation on phase { from: 0; to: Math.PI * 2; duration: 1600; loops: Animation.Infinite; running: Media.playing && wave.visible && Theme.speed > 0 }
                                onPhaseChanged: requestPaint()
                                onPChanged: requestPaint()
                                onPaint: {
                                    const c = getContext("2d"); c.reset();
                                    const mid = height / 2, end = width * p;
                                    c.lineWidth = 3; c.lineCap = "round";
                                    c.strokeStyle = root.accent;
                                    c.beginPath();
                                    for (let x = 0; x <= end; x += 2) {
                                        const y = mid + (Media.playing ? Math.sin(x / 6 + phase) * 3 : 0);
                                        x === 0 ? c.moveTo(x, y) : c.lineTo(x, y);
                                    }
                                    c.stroke();
                                    c.strokeStyle = Theme.alpha(Theme.fg, 0.18);
                                    c.beginPath(); c.moveTo(end + 4, mid); c.lineTo(width, mid); c.stroke();
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !!Media.player && Media.player.canSeek
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ev => { Media.player.position = Media.length * ev.x / width; Media.position = Media.player.position; }
                            }
                        }
                        Txt { text: Media.fmt(Media.length); size: 10; color: Theme.outline; font.features: ({ "tnum": 1 }) }
                    }
                }
                Row {
                    spacing: 2
                    IconButton { icon: "skip_previous"; onClicked: Media.player.previous() }
                    IconButton {
                        icon: Media.playing ? "pause" : "play_arrow"
                        active: true
                        base: root.accent
                        implicitWidth: 44; implicitHeight: 44
                        radius: Media.playing ? 14 : 22
                        Behavior on radius { NumberAnimation { duration: Theme.normal } }
                        onClicked: Media.player.togglePlaying()
                    }
                    IconButton { icon: "skip_next"; onClicked: Media.player.next() }
                }
            }
        }

        // Volumen / micro / brillo
        Pane {
            name: "osd"
            Fader {
                anchors.fill: parent
                anchors.margins: 8
                anchors.topMargin: 2
                max: root.osdKind === "vol" && Audio.volume > 1 ? 1.5 : 1
                value: root.osdKind === "vol" ? Audio.volume : root.osdKind === "mic" ? Audio.micVolume : Sys.brightness
                off: root.osdKind === "vol" ? Audio.muted : root.osdKind === "mic" ? Audio.micMuted : false
                icon: root.osdKind === "vol" ? Audio.icon(Audio.volume, false) : root.osdKind === "mic" ? "mic" : "light_mode"
                iconOff: root.osdKind === "vol" ? "volume_off" : "mic_off"
                accent: root.osdKind === "mic" ? Theme.tertiary : root.osdKind === "bri" ? Theme.secondary : Theme.primary
                onMoved: v => { if (root.osdKind === "vol") Audio.setVolume(v); else if (root.osdKind === "mic") Audio.setMic(v); else Sys.setBrightness(v); osdTimer.restart(); }
            }
        }

        // Escritorio actual
        Pane {
            name: "desk"
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -4
                spacing: 12
                Txt {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Desktops.currentIndex >= 0 && Desktops.list[Desktops.currentIndex]
                        ? (/^\d+$/.test(Desktops.list[Desktops.currentIndex].name) ? "Escritorio " + Desktops.list[Desktops.currentIndex].name : Desktops.list[Desktops.currentIndex].name) : ""
                    size: 14
                    weight: 600
                }
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: Desktops.list.length
                        Rectangle {
                            required property int index
                            readonly property bool cur: index === Desktops.currentIndex
                            anchors.verticalCenter: parent.verticalCenter
                            width: cur ? 22 : 8; height: 8; radius: 4
                            color: cur ? root.accent : Theme.outline
                            Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                        }
                    }
                }
            }
        }

        // Aviso entrante
        Pane {
            name: "notif"
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.bottomMargin: 10
                spacing: 12
                ClippingRectangle {
                    Layout.preferredWidth: 46; Layout.preferredHeight: 46
                    radius: 15
                    color: Theme.primaryContainer
                    Image {
                        id: nImg
                        anchors.fill: parent
                        source: root.flashN ? root.flashN.image : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    IconImage {
                        anchors.centerIn: parent
                        visible: !nImg.visible
                        implicitSize: 30
                        source: root.flashN ? Quickshell.iconPath(root.flashN.appIcon || (root.flashN.appName || "").toLowerCase(), "dialog-information") : ""
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    RowLayout {
                        Layout.fillWidth: true
                        Txt { Layout.fillWidth: true; text: root.flashN ? root.flashN.summary : ""; size: 14; weight: Font.Bold }
                        Txt { text: root.flashN ? root.flashN.appName : ""; size: 11; color: Theme.outline }
                    }
                    Txt {
                        Layout.fillWidth: true
                        text: root.flashN ? root.flashN.body.replace(/<[^>]*>/g, "") : ""
                        size: 12
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        color: Theme.fgDim
                    }
                }
            }
        }

        // Calendario
        Pane {
            name: "calendar"
            CalendarBody { anchors.fill: parent }
        }
    }
}
