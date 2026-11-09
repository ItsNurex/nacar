pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Red con NetworkManager (nmcli): estado, lista Wi-Fi y conexión.
Singleton {
    id: root

    property string kind: "none"      // wifi | ethernet | none
    property string name: ""
    property int signal: 0
    property bool wifiOn: true
    property var networks: []         // [{ssid, signal, secure, active}]
    property bool scanning: false

    readonly property string icon: kind === "ethernet" ? "lan"
        : kind === "wifi" ? (signal > 75 ? "signal_wifi_4_bar" : signal > 50 ? "network_wifi_3_bar"
            : signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar")
        : wifiOn ? "signal_wifi_statusbar_not_connected" : "signal_wifi_off"
    readonly property string label: kind === "none" ? (wifiOn ? "Sin conexión" : "Wi-Fi apagado") : name

    function refresh() { if (!status.running) status.running = true; if (!radio.running) radio.running = true; }
    function scan() { scanning = true; list.running = false; list.running = true; }
    function setWifi(on) {
        wifiOn = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }
    function connect(ssid) {
        Quickshell.execDetached(["nmcli", "device", "wifi", "connect", ssid]);
        refreshSoon.restart();
    }
    function disconnect() {
        Quickshell.execDetached(["sh", "-c", "nmcli -t -f DEVICE,TYPE device | awk -F: '$2==\"wifi\"{print $1; exit}' | xargs -r nmcli device disconnect"]);
        refreshSoon.restart();
    }

    Process {
        id: status
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device; echo '--'; nmcli -t -f ACTIVE,SIGNAL device wifi 2>/dev/null | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("--");
                let k = "none", n = "";
                for (const l of parts[0].trim().split("\n")) {
                    const f = l.split(":");
                    if (f[1] !== "connected") continue;
                    if (f[0] === "ethernet") { k = "ethernet"; n = f.slice(2).join(":"); break; }
                    if (f[0] === "wifi" && k === "none") { k = "wifi"; n = f.slice(2).join(":"); }
                }
                // En modo demo no se muestra el nombre real de tu red.
                if (Quickshell.env("NACAR_DEMO") === "1" && n) n = "Mi Wi-Fi";
                root.kind = k; root.name = n;
                const w = (parts[1] || "").trim().split(":");
                root.signal = parseInt(w[1]) || 0;
            }
        }
    }
    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: list
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const l of text.trim().split("\n")) {
                    const f = l.replace(/\\:/g, "\u0001").split(":").map(x => x.replace(/\u0001/g, ":"));
                    if (f.length < 4 || !f[1] || seen[f[1]]) continue;
                    seen[f[1]] = true;
                    out.push({ active: f[0] === "*", ssid: f[1], signal: parseInt(f[2]) || 0, secure: f[3] !== "" && f[3] !== "--" });
                }
                out.sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
                root.networks = out;
                root.scanning = false;
            }
        }
    }

    // Reacciona al instante a cambios de NetworkManager.
    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: refreshSoon.restart() }
    }
    Timer { id: refreshSoon; interval: 400; onTriggered: root.refresh() }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
