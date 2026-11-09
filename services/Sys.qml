pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

// Sistema: CPU, RAM, temperatura, batería, brillo, perfil de energía, usuario.
Singleton {
    id: root

    // ── Recursos ────────────────────────────────────────────────────
    property real cpu: 0
    property real ram: 0
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property int temp: 0
    property var cpuHistory: new Array(30).fill(0)
    property var lastCpu: null

    FileView { id: stat; path: "/proc/stat"; printErrors: false }
    FileView { id: mem; path: "/proc/meminfo"; printErrors: false }
    Process {
        id: tempProc
        command: ["sh", "-c", "for z in /sys/class/hwmon/hwmon*; do n=$(cat $z/name 2>/dev/null); case $n in k10temp|coretemp|zenpower|cpu_thermal|acpitz) cat $z/temp1_input 2>/dev/null && exit;; esac; done"]
        stdout: StdioCollector { onStreamFinished: root.temp = Math.round((parseInt(text) || 0) / 1000) }
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload(); mem.reload();
            const l = (stat.text().split("\n")[0] || "").trim().split(/\s+/).slice(1).map(Number);
            if (l.length > 4) {
                const idle = l[3] + (l[4] || 0), tot = l.reduce((a, b) => a + b, 0);
                if (root.lastCpu) {
                    const dt = tot - root.lastCpu.tot, di = idle - root.lastCpu.idle;
                    root.cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
                    root.cpuHistory = root.cpuHistory.slice(1).concat([root.cpu]);
                }
                root.lastCpu = { tot: tot, idle: idle };
            }
            const m = {};
            for (const line of mem.text().split("\n")) {
                const p = line.split(/:\s+/);
                if (p.length === 2) m[p[0]] = parseInt(p[1]);
            }
            if (m.MemTotal) {
                root.ramTotalGb = m.MemTotal / 1048576;
                root.ramUsedGb = (m.MemTotal - m.MemAvailable) / 1048576;
                root.ram = 1 - m.MemAvailable / m.MemTotal;
            }
            tempProc.running = true;
        }
    }

    // ── Batería ─────────────────────────────────────────────────────
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isLaptopBattery
    readonly property real batteryLevel: hasBattery ? battery.percentage : 1
    readonly property bool charging: hasBattery && (battery.state === UPowerDeviceState.Charging
        || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge)
    readonly property string batteryIcon: {
        if (!hasBattery) return "power";
        if (charging) return "battery_charging_full";
        const l = batteryLevel;
        return l > 0.9 ? "battery_full" : l > 0.75 ? "battery_6_bar" : l > 0.6 ? "battery_5_bar"
            : l > 0.45 ? "battery_4_bar" : l > 0.3 ? "battery_3_bar" : l > 0.15 ? "battery_2_bar" : "battery_alert";
    }
    readonly property string batteryTime: {
        if (!hasBattery) return "";
        const s = charging ? battery.timeToFull : battery.timeToEmpty;
        if (!s) return "";
        const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
        return (h ? h + " h " : "") + m + " min" + (charging ? " para llenar" : " restantes");
    }
    property int warnedAt: 101
    onBatteryLevelChanged: {
        const pct = Math.round(batteryLevel * 100);
        if (charging) { warnedAt = 101; return; }
        for (const lim of [Config.o.batteryWarn, Config.o.batteryCritical]) {
            if (pct <= lim && warnedAt > lim) {
                warnedAt = lim;
                Quickshell.execDetached(["notify-send", "-a", "Nácar", "-i", "battery-low",
                    "-u", lim === Config.o.batteryCritical ? "critical" : "normal",
                    "Batería al " + pct + "%", "Conecta el cargador pronto."]);
            }
        }
    }

    // ── Perfil de energía ───────────────────────────────────────────
    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    function setProfile(p) { PowerProfiles.profile = p; }
    function profileName(p) {
        return p === PowerProfile.PowerSaver ? "Ahorro" : p === PowerProfile.Performance ? "Rendimiento" : "Equilibrado";
    }
    function profileIcon(p) {
        return p === PowerProfile.PowerSaver ? "eco" : p === PowerProfile.Performance ? "bolt" : "balance";
    }

    // ── Brillo ──────────────────────────────────────────────────────
    property real brightness: 0
    property bool hasBrightness: false
    signal brightnessTouched()
    Process {
        id: blGet
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length >= 5) { root.hasBrightness = true; root.brightness = parseInt(f[2]) / parseInt(f[4]); }
            }
        }
    }
    function setBrightness(v) {
        v = Math.max(0.01, Math.min(1, v));
        brightness = v;
        Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "s", Math.round(v * 100) + "%"]);
        brightnessTouched();
    }
    function stepBrightness(d) { setBrightness(brightness + d); }

    // ── Usuario y sesión ────────────────────────────────────────────
    readonly property string user: Quickshell.env("USER") || "tú"
    readonly property string face: Config.home + "/.face.icon"
    property string uptime: ""
    property string host: ""
    Process {
        id: up
        running: true
        command: ["sh", "-c", "cat /proc/uptime; cat /proc/sys/kernel/hostname"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                const s = parseFloat(l[0]);
                const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60);
                root.uptime = (d ? d + " d " : "") + (h ? h + " h " : "") + m + " min";
                root.host = l[1] || "";
            }
        }
    }
    Timer { interval: 60000; repeat: true; running: true; onTriggered: up.running = true }

    // ── Acciones de sesión (KDE) ────────────────────────────────────
    function lock() { Quickshell.execDetached(["loginctl", "lock-session"]); }
    function suspend() { Quickshell.execDetached(["systemctl", "suspend"]); }
    function logout() { Quickshell.execDetached(["qdbus6", "org.kde.Shutdown", "/Shutdown", "logout"]); }
    function reboot() { Quickshell.execDetached(["qdbus6", "org.kde.Shutdown", "/Shutdown", "logoutAndReboot"]); }
    function poweroff() { Quickshell.execDetached(["qdbus6", "org.kde.Shutdown", "/Shutdown", "logoutAndShutdown"]); }
}
