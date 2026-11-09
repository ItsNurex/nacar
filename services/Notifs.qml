pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Servidor de notificaciones con:
//  · emergentes con acciones, respuesta rápida, imágenes y progreso
//  · historial persistente (sobrevive a reinicios)
//  · agrupación por app, no molestar y silencio automático en modo enfoque
Singleton {
    id: root

    property var popups: []                  // notificaciones vivas en pantalla
    readonly property var live: server.trackedNotifications.values
    readonly property var history: Store.history || []
    readonly property int count: history.length
    readonly property bool dnd: !!Store.dnd
    readonly property bool silenced: dnd || (Focus.phase === "focus" && Config.o.focusSilences)

    signal arrived(var n)
    // Avisos simples: los muestra la isla dinámica. Los "ricos" (con acciones,
    // respuesta rápida o críticos) además salen como tarjeta.
    signal flashed(var n)

    function setDnd(v) { Store.dnd = v; }

    function remember(n) {
        const entry = {
            id: n.id + "-" + Date.now(),
            app: n.appName || "Sistema",
            icon: n.appIcon || "",
            image: n.image || "",
            summary: n.summary || "",
            body: n.body || "",
            urgency: n.urgency,
            time: Date.now()
        };
        const h = [entry].concat(Store.history).slice(0, Config.o.historyLimit);
        Store.history = h;
    }
    function forget(id) { Store.history = Store.history.filter(e => e.id !== id); }
    function forgetApp(app) { Store.history = Store.history.filter(e => e.app !== app); }
    function clearAll() {
        Store.history = [];
        for (const n of live.slice()) n.dismiss();
    }
    function dropPopup(n) { popups = popups.filter(p => p !== n); }

    // Historial agrupado por app (más reciente primero).
    readonly property var groups: {
        const map = {}, order = [];
        for (const e of history) {
            if (!map[e.app]) { map[e.app] = []; order.push(e.app); }
            map[e.app].push(e);
        }
        return order.map(a => ({ app: a, items: map[a] }));
    }

    function ago(t) {
        const s = Math.floor((Date.now() - t) / 1000);
        if (s < 60) return "ahora";
        if (s < 3600) return "hace " + Math.floor(s / 60) + " min";
        if (s < 86400) return "hace " + Math.floor(s / 3600) + " h";
        return "hace " + Math.floor(s / 86400) + " d";
    }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        inlineReplySupported: true
        persistenceSupported: true

        onNotification: function (n) {
            n.tracked = true;
            if (!n.transient) root.remember(n);
            const critical = n.urgency === NotificationUrgency.Critical;
            const rich = critical || n.hasInlineReply || n.actions.some(a => a.identifier !== "default");
            if (!root.silenced || critical) {
                if (rich) root.popups = [n].concat(root.popups.filter(p => p !== n)).slice(0, 4);
                else root.flashed(n);
            }
            root.arrived(n);
            n.closed.connect(() => root.dropPopup(n));
        }
    }
}
