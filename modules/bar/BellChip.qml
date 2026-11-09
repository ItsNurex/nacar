import QtQuick
import qs.services
import qs.components

// Campana: contador de avisos, se agita al llegar uno nuevo.
Clicky {
    id: root
    implicitHeight: Config.o.barHeight - 10
    implicitWidth: Notifs.count > 0 ? row.width + 20 : implicitHeight
    base: Ui.center && Ui.centerTab === "avisos" ? Theme.secondaryContainer : "transparent"
    onClicked: Ui.toggleCenter("avisos")
    onRightClicked: Notifs.setDnd(!Notifs.dnd)
    Behavior on implicitWidth { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5
        Sym {
            id: bell
            text: Notifs.silenced ? "notifications_paused" : Notifs.count > 0 ? "notifications_unread" : "notifications"
            size: 19
            fill: Notifs.count > 0
            color: Notifs.silenced ? Theme.outline : Theme.fg
            SequentialAnimation on rotation {
                id: shake
                running: false
                NumberAnimation { to: 18; duration: 70 }
                NumberAnimation { to: -16; duration: 110 }
                NumberAnimation { to: 10; duration: 100 }
                NumberAnimation { to: -6; duration: 90 }
                NumberAnimation { to: 0; duration: 80 }
            }
        }
        Txt {
            visible: Notifs.count > 0
            text: Notifs.count > 99 ? "99+" : Notifs.count
            size: 12
            weight: Font.Bold
            font.features: ({ "tnum": 1 })
        }
    }
    Connections {
        target: Notifs
        function onArrived() { if (Theme.speed > 0) shake.restart(); }
    }
}
