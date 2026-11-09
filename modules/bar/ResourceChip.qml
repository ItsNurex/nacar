import Quickshell
import QtQuick
import qs.services
import qs.components

// CPU con mini-gráfica de historial + RAM + temperatura.
Clicky {
    id: root
    implicitHeight: Config.o.barHeight - 10
    implicitWidth: row.width + 20
    base: "transparent"
    onClicked: Quickshell.execDetached(["plasma-systemmonitor"])

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Canvas {
            id: graph
            width: 34; height: root.height - 14
            anchors.verticalCenter: parent.verticalCenter
            property var data: Sys.cpuHistory
            onDataChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                const n = data.length, w = width, h = height;
                c.beginPath();
                c.moveTo(0, h);
                for (let i = 0; i < n; i++) c.lineTo(i * w / (n - 1), h - data[i] * h);
                c.lineTo(w, h);
                c.closePath();
                c.fillStyle = Theme.alpha(Theme.primary, 0.3);
                c.fill();
                c.beginPath();
                for (let i = 0; i < n; i++) c.lineTo(i * w / (n - 1), h - data[i] * h);
                c.strokeStyle = Theme.primary;
                c.lineWidth = 1.5;
                c.stroke();
            }
        }
        Txt { text: Math.round(Sys.cpu * 100) + "%"; size: 12; weight: Font.DemiBold; font.features: ({ "tnum": 1 }) }
        Sym { text: "memory_alt"; size: 16; color: Theme.fgDim }
        Txt { text: Math.round(Sys.ram * 100) + "%"; size: 12; weight: Font.DemiBold; font.features: ({ "tnum": 1 }) }
        Sym { visible: Sys.temp > 0; text: "device_thermostat"; size: 16; color: Sys.temp > 85 ? Theme.error : Theme.fgDim }
        Txt { visible: Sys.temp > 0; text: Sys.temp + "°"; size: 12; weight: Font.DemiBold; color: Sys.temp > 85 ? Theme.error : Theme.fg }
    }
}
