import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Centro de control: interruptores, deslizadores, música y pestañas
// (avisos · mezclador · Wi-Fi · Bluetooth).
Popout {
    id: win
    ns: "nacar-center"
    open: Ui.center
    cardWidth: 440
    cardHeight: Math.min(800, (screen ? screen.height : 1080) - bh - 60)
    onCloseRequested: Ui.center = false

    readonly property var bt: Bluetooth.defaultAdapter

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // ── Cabecera ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            ClippingRectangle {
                width: 44; height: 44; radius: 22
                color: Theme.primaryContainer
                Image { id: face; anchors.fill: parent; source: "file://" + Sys.face; fillMode: Image.PreserveAspectCrop }
                Sym { anchors.centerIn: parent; visible: face.status !== Image.Ready; text: "person"; fill: true; color: Theme.fgPrimaryContainer }
            }
            Column {
                Layout.fillWidth: true
                Txt { text: "Hola, " + Sys.user; size: 16; weight: Font.Bold }
                Txt { text: "Encendido " + Sys.uptime + (Sys.hasBattery ? " · " + (Sys.batteryTime || Math.round(Sys.batteryLevel * 100) + "%") : ""); size: 12; color: Theme.fgDim }
            }
            IconButton { icon: "settings"; onClicked: { Ui.center = false; Quickshell.execDetached(["systemsettings"]); } }
            IconButton { icon: "power_settings_new"; onClicked: Ui.toggleSession() }
        }

        // ── Interruptores ──
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 8
            columnSpacing: 8
            Tile {
                Layout.fillWidth: true
                icon: Net.icon
                title: "Wi-Fi"
                detail: Net.label
                on: Net.wifiOn
                onClicked: Net.setWifi(!Net.wifiOn)
                onMore: Ui.centerTab = "wifi"
            }
            Tile {
                Layout.fillWidth: true
                icon: "bluetooth"
                title: "Bluetooth"
                detail: !win.bt ? "No disponible" : !win.bt.enabled ? "Apagado"
                    : (Bluetooth.devices.values.filter(d => d.connected).map(d => d.name)[0] || "Encendido")
                on: win.bt ? win.bt.enabled : false
                enabled: !!win.bt
                onClicked: if (win.bt) win.bt.enabled = !win.bt.enabled
                onMore: Ui.centerTab = "bluetooth"
            }
            Tile {
                Layout.fillWidth: true
                icon: "do_not_disturb_on"
                title: "No molestar"
                detail: Notifs.dnd ? "Activado" : Focus.phase === "focus" && Config.o.focusSilences ? "Por enfoque" : "Desactivado"
                on: Notifs.dnd
                onClicked: Notifs.setDnd(!Notifs.dnd)
            }
            Tile {
                Layout.fillWidth: true
                icon: "coffee"
                title: "Cafeína"
                detail: Ui.caffeine ? "Pantalla despierta" : "Desactivada"
                on: Ui.caffeine
                onClicked: Ui.caffeine = !Ui.caffeine
            }
            Tile {
                Layout.fillWidth: true
                icon: "timer"
                title: "Enfoque"
                detail: Focus.phase === "idle" ? Focus.today + " sesiones hoy" : (Focus.phase === "focus" ? "Trabajando · " : "Descanso · ") + Focus.clock
                on: Focus.phase !== "idle"
                onClicked: Focus.phase === "idle" ? Focus.start() : Focus.stop()
            }
            Tile {
                Layout.fillWidth: true
                icon: Sys.profileIcon(Sys.profile)
                title: "Energía"
                detail: Sys.profileName(Sys.profile)
                on: Sys.profile !== PowerProfile.Balanced
                onClicked: {
                    const order = [PowerProfile.PowerSaver, PowerProfile.Balanced].concat(Sys.hasPerformance ? [PowerProfile.Performance] : []);
                    Sys.setProfile(order[(order.indexOf(Sys.profile) + 1) % order.length]);
                }
            }
        }

        // ── Deslizadores ──
        Fader {
            Layout.fillWidth: true
            value: Audio.volume
            off: Audio.muted
            icon: Audio.icon(Audio.volume, false)
            iconOff: "volume_off"
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
        Fader {
            Layout.fillWidth: true
            value: Audio.micVolume
            off: Audio.micMuted
            icon: "mic"
            iconOff: "mic_off"
            accent: Theme.tertiary
            onMoved: v => Audio.setMic(v)
            onIconClicked: Audio.toggleMic()
        }
        Fader {
            Layout.fillWidth: true
            visible: Sys.hasBrightness
            value: Sys.brightness
            icon: "light_mode"
            accent: Theme.secondary
            onMoved: v => Sys.setBrightness(v)
        }

        MediaCard { Layout.fillWidth: true }

        // ── Pestañas ──
        Rectangle {
            Layout.fillWidth: true
            height: 40
            radius: 20
            color: Theme.surfaceHigh
            Rectangle {
                id: tabPill
                readonly property int idx: ["avisos", "mezclador", "wifi", "bluetooth"].indexOf(Ui.centerTab)
                y: 4; height: 32; radius: 16
                width: (parent.width - 8) / 4
                x: 4 + idx * width
                color: Theme.secondaryContainer
                Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
            }
            Row {
                anchors.fill: parent
                anchors.margins: 4
                Repeater {
                    model: [["avisos", "notifications", "Avisos"], ["mezclador", "tune", "Mezclador"], ["wifi", "wifi", "Wi-Fi"], ["bluetooth", "bluetooth", "Bluetooth"]]
                    Item {
                        required property var modelData
                        width: parent.width / 4; height: 32
                        Row {
                            anchors.centerIn: parent
                            spacing: 4
                            Sym { text: modelData[1]; size: 16; color: Ui.centerTab === modelData[0] ? Theme.fgSecondaryContainer : Theme.fgDim }
                            Txt { text: modelData[2]; size: 12; weight: Font.Medium; color: Ui.centerTab === modelData[0] ? Theme.fgSecondaryContainer : Theme.fgDim }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.centerTab = modelData[0] }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120

            NotifList { anchors.fill: parent; anchors.bottomMargin: 40; visible: Ui.centerTab === "avisos" }
            Row {
                visible: Ui.centerTab === "avisos" && Notifs.count > 0
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                spacing: 6
                Clicky {
                    width: 120; height: 34
                    base: Theme.surfaceHigh
                    onClicked: Notifs.clearAll()
                    Row { anchors.centerIn: parent; spacing: 6
                        Sym { text: "clear_all"; size: 18 }
                        Txt { text: "Borrar todo"; size: 12; weight: Font.Medium }
                    }
                }
            }
            Loader { anchors.fill: parent; active: Ui.centerTab === "mezclador" && win.open; sourceComponent: Mixer { } }
            Loader { anchors.fill: parent; active: Ui.centerTab === "wifi" && win.open; sourceComponent: WifiList { } }
            Loader { anchors.fill: parent; active: Ui.centerTab === "bluetooth" && win.open; sourceComponent: BtList { } }
        }
    }
}
