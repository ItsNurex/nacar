import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import QtQuick
import qs.services
import qs.components

// Bandeja del sistema plegable: muestra 3 iconos y el resto al expandir.
Rectangle {
    id: root
    required property var window
    property bool expanded: false
    readonly property var items: SystemTray.items.values
    readonly property int shown: expanded ? items.length : Math.min(3, items.length)

    visible: items.length > 0
    implicitHeight: Config.o.barHeight - 10
    implicitWidth: row.width + 12
    radius: height / 2
    color: "transparent"
    Behavior on implicitWidth { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    clip: true

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 6
        spacing: 2

        Repeater {
            model: root.items
            Clicky {
                required property var modelData
                required property int index
                visible: index < root.shown
                width: root.height - 6
                height: width
                onClicked: modelData.onlyMenu ? openMenu() : modelData.activate()
                onRightClicked: openMenu()
                onMiddleClicked: modelData.secondaryActivate()
                function openMenu() {
                    if (!modelData.hasMenu) return;
                    const p = mapToItem(null, 0, height + 6);
                    modelData.display(root.window, p.x, p.y);
                }
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 18
                    source: {
                        const ic = modelData.icon;
                        if (ic.indexOf("?path=") >= 0) {
                            const [name, path] = ic.split("?path=");
                            return "file://" + path + "/" + name.slice(name.lastIndexOf("/") + 1);
                        }
                        return ic;
                    }
                }
            }
        }

        IconButton {
            visible: root.items.length > 3
            width: root.height - 6
            height: width
            icon: root.expanded ? "chevron_left" : "chevron_right"
            iconSize: 18
            onClicked: root.expanded = !root.expanded
        }
    }
}
