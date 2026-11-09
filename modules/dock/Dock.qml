import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import qs.services
import qs.components

// ── Dock líquido ──────────────────────────────────────────────────
// Brota del borde inferior del marco. Al pasar el ratón los iconos se
// agrandan en ola (como macOS), rebotan al abrir y un punto marca las
// apps abiertas. Si la app ya está abierta, la trae al frente.
PanelWindow {
    id: win

    readonly property int size: Config.o.dockIconSize
    readonly property int slot: size + 12
    readonly property int bodyH: size + 20
    readonly property real ear: Theme.radius * 0.8
    readonly property real magnify: Config.o.dockMagnify

    anchors.bottom: true
    implicitWidth: Math.max(400, tab.width + 200)
    implicitHeight: bodyH + size * magnify + 60
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "nacar-dock"
    mask: Region { item: hit }

    BackgroundEffect.blurRegion: Config.o.blur ? blurRegion : null
    Region { id: blurRegion; item: hit; topLeftRadius: Theme.radius; topRightRadius: Theme.radius }

    // Apps fijadas que existen en el sistema
    // (leer applications.values crea la dependencia: se recalcula al cargar las apps)
    readonly property var apps: {
        const all = DesktopEntries.applications.values;
        return Config.o.dockApps
            .map(id => all.find(e => e.id === id || e.id === id + ".desktop") || DesktopEntries.heuristicLookup(id))
            .filter((e, i, a) => e && a.indexOf(e) === i);
    }

    // ── Apps en marcha (barato: un ps cada 3 s) ──
    property var running: ({})
    function binOf(e) {
        const cmd = (e.command && e.command.length ? e.command : (e.execString || "").split(" "));
        const first = cmd.find(c => c && c.indexOf("=") < 0 && c !== "env") || "";
        return first.split("/").pop().toLowerCase();
    }
    Process {
        id: ps
        command: ["ps", "-eo", "comm="]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                for (const l of text.split("\n")) m[l.trim().toLowerCase()] = true;
                win.running = m;
            }
        }
    }
    Timer { interval: 3000; running: true; repeat: true; triggeredOnStart: true; onTriggered: ps.running = true }
    readonly property bool demo: Quickshell.env("NACAR_DEMO") === "1"
    function isRunning(e) {
        if (demo) return apps.indexOf(e) === 0 || apps.indexOf(e) === 1 || apps.indexOf(e) === 3;
        const b = binOf(e);
        return !!running[b] || !!running[b.slice(0, 15)] || !!running[(e.startupClass || "").toLowerCase()];
    }

    function activate(e, item) {
        if (isRunning(e)) {
            focuser.target = e.name;
            focuser.running = true;
        } else {
            Store.bump(e.id);
            e.execute();
            item.bounce();
        }
    }

    // Enfocar ventana: KRunner de KWin busca por nombre y activa la primera.
    Process {
        id: focuser
        property string target: ""
        command: ["sh", "-c", "id=$(busctl --user --json=short call org.kde.KWin /WindowsRunner org.kde.krunner1 Match s \"$1\" | python3 -c 'import json,sys; d=json.load(sys.stdin)[\"data\"][0]; print(d[0][0] if d else \"\")'); [ -n \"$id\" ] && busctl --user call org.kde.KWin /WindowsRunner org.kde.krunner1 Run ss \"$id\" ''", "sh", target]
    }

    // ── Geometría ──
    property real mouseX: -1000
    readonly property bool hovering: hover.hovered

    Item {
        id: hit
        x: tab.x + tab.e
        y: win.height - win.bodyH - (win.hovering ? win.size * win.magnify : 0)
        width: tab.bodyWidth
        height: win.height - y
        HoverHandler {
            id: hover
            onPointChanged: win.mouseX = hit.x + point.position.x
        }
    }

    Item {
        anchors.fill: parent
        transform: Translate { y: (1 - Ui.introDock) * 160 }
        layer.enabled: Config.o.glow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Theme.shadow
            shadowOpacity: 0.5
            shadowBlur: 1.0
            shadowVerticalOffset: -2
            shadowHorizontalOffset: 0
        }
        Tab {
            id: tab
            flip: true
            x: (win.width - width) / 2
            y: win.height - height
            bodyWidth: row.width + 20
            bodyHeight: win.bodyH
            ear: win.ear
            color: Theme.alpha(Theme.surface, Config.o.panelOpacity)
            Behavior on bodyWidth { enabled: Theme.speed > 0; SpringAnimation { spring: 4; damping: 0.4; epsilon: 0.3 } }
        }
    }

    // ── Iconos ──
    Row {
        id: row
        transform: Translate { y: (1 - Ui.introDock) * 160 }
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        spacing: 2

        Repeater {
            model: win.apps.map(e => ({ kind: "app", entry: e }))
                .concat([{ kind: "sep" },
                         { kind: "btn", glyph: "bubble_chart", label: "Omni", act: "omni" },
                         { kind: "btn", glyph: "wallpaper", label: "Fondos", act: "wall" }])

            delegate: Item {
                id: it
                required property var modelData
                readonly property var entry: modelData.kind === "app" ? modelData.entry : null
                readonly property bool sep: modelData.kind === "sep"
                readonly property string label: entry ? entry.name : (modelData.label || "")
                readonly property bool running: !!entry && win.isRunning(entry)

                readonly property real dist: win.hovering && !sep ? Math.abs(win.mouseX - (row.x + x + width / 2)) : 1000
                readonly property real grow: win.magnify * Math.exp(-(dist * dist) / (2 * Math.pow(win.slot * 1.1, 2)))
                property real lift: 0

                width: sep ? 14 : win.slot * (1 + grow * 0.9)
                height: win.size

                function bounce() { if (Theme.speed > 0) bounceAnim.restart(); }
                SequentialAnimation {
                    id: bounceAnim
                    loops: 2
                    NumberAnimation { target: it; property: "lift"; to: -18; duration: 220; easing.type: Easing.OutQuad }
                    NumberAnimation { target: it; property: "lift"; to: 0; duration: 260; easing.type: Easing.OutBounce }
                }

                Rectangle {
                    visible: it.sep
                    anchors.centerIn: parent
                    width: 1.5; height: win.size * 0.6; radius: 1
                    color: Theme.outlineVariant
                }

                Item {
                    id: iconBox
                    visible: !it.sep
                    width: win.size * (1 + it.grow)
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: it.lift

                    IconImage {
                        anchors.fill: parent
                        visible: !!it.entry
                        source: it.entry ? Quickshell.iconPath(it.entry.icon, "application-x-executable") : ""
                        mipmap: true
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: !it.entry
                        radius: width * 0.3
                        gradient: Gradient {
                            GradientStop { position: 0; color: Theme.primaryContainer }
                            GradientStop { position: 1; color: Theme.tertiaryContainer }
                        }
                        Sym { anchors.centerIn: parent; text: it.modelData.glyph || ""; size: parent.width * 0.5; fill: true; color: Theme.fgPrimaryContainer }
                    }
                }

                // Punto de "abierta"
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.bottom
                    anchors.topMargin: 3
                    width: it.running ? 14 : 0; height: 4; radius: 2
                    color: Theme.primary
                    Behavior on width { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutBack } }
                }

                // Etiqueta flotante
                Rectangle {
                    anchors.horizontalCenter: iconBox.horizontalCenter
                    anchors.bottom: iconBox.top
                    anchors.bottomMargin: 8
                    width: tip.implicitWidth + 20; height: 26; radius: 13
                    color: Theme.alpha(Theme.surfaceHighest, 0.95)
                    visible: !it.sep
                    opacity: ma.containsMouse ? 1 : 0
                    scale: ma.containsMouse ? 1 : 0.8
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                    Behavior on scale { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutBack } }
                    Txt { id: tip; anchors.centerIn: parent; text: it.label; size: 12; weight: 550 }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    enabled: !it.sep
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (it.entry) win.activate(it.entry, it);
                        else if (it.modelData.act === "omni") Ui.toggleOmni();
                        else if (it.modelData.act === "wall") Ui.toggleWallpapers();
                    }
                }
            }
        }
    }
}
