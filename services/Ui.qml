pragma Singleton
import Quickshell
import QtQuick

// Qué paneles están abiertos. Abrir uno cierra los demás.
Singleton {
    id: root

    property bool omni: false
    property string omniSeed: ""
    property bool center: false
    property string centerTab: "avisos"   // avisos | mezclador | wifi | bluetooth
    property bool calendar: false
    property bool session: false
    property bool wallpapers: false
    property bool caffeine: false
    // Fuerza un modo de la isla (demos/capturas): "", player, osd, notif…
    property string islandForce: ""

    // ── Entrada al arrancar (0 → 1, escalonada) ──
    // introFrame: el marco baja desde arriba · introIsland: la isla se abre
    // introDock: el dock sube desde abajo.
    property real introFrame: 0
    property real introIsland: 0
    property real introDock: 0
    SequentialAnimation {
        running: true
        PauseAnimation { duration: 250 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "introFrame"; to: 1; duration: Theme.speed > 0 ? 900 : 0; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            SequentialAnimation {
                PauseAnimation { duration: Theme.speed > 0 ? 350 : 0 }
                NumberAnimation { target: root; property: "introIsland"; to: 1; duration: Theme.speed > 0 ? 800 : 0; easing.type: Easing.OutElastic; easing.amplitude: 1.0; easing.period: 0.55 }
            }
            SequentialAnimation {
                PauseAnimation { duration: Theme.speed > 0 ? 550 : 0 }
                NumberAnimation { target: root; property: "introDock"; to: 1; duration: Theme.speed > 0 ? 800 : 0; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            }
        }
    }

    readonly property bool anyOpen: omni || center || calendar || session || wallpapers

    function closeAll() { omni = false; center = false; calendar = false; session = false; wallpapers = false; }

    function toggleOmni(seed) {
        const was = omni;
        closeAll();
        omniSeed = seed || "";
        omni = !was || (seed !== undefined && seed !== "");
    }
    function toggleCenter(tab) {
        const was = center && (!tab || tab === centerTab);
        closeAll();
        if (tab) centerTab = tab;
        center = !was;
    }
    function toggleCalendar() { const was = calendar; closeAll(); calendar = !was; }
    function toggleWallpapers() { const was = wallpapers; closeAll(); wallpapers = !was; }
    function toggleSession() { const was = session; closeAll(); session = !was; }
}
