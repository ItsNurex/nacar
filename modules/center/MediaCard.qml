import QtQuick
import Quickshell.Widgets
import qs.services
import qs.components

// Tarjeta de música con la carátula difuminada de fondo y barra de progreso.
ClippingRectangle {
    id: root
    visible: Media.active
    implicitHeight: 128
    radius: Theme.radius - 4
    color: Theme.surfaceHigh

    Image {
        anchors.fill: parent
        source: Media.art
        fillMode: Image.PreserveAspectCrop
        opacity: 0.35
        asynchronous: true
        sourceSize.width: 64
        sourceSize.height: 64
        smooth: true
    }
    Rectangle { anchors.fill: parent; gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Theme.alpha(Theme.surfaceHigh, 0.4) }
        GradientStop { position: 1; color: Theme.alpha(Theme.surfaceHigh, 0.95) }
    } }

    ClippingRectangle {
        id: cover
        x: 12; y: 12
        width: 104; height: 104
        radius: 16
        color: Theme.primaryContainer
        Image { anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; asynchronous: true }
    }

    Column {
        anchors.left: cover.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: cover.top
        spacing: 2
        Txt { width: parent.width; text: Media.title; size: 15; weight: Font.Bold }
        Txt { width: parent.width; text: Media.artist || (Media.player ? Media.player.identity : ""); size: 12; color: Theme.fgDim }
    }

    Row {
        anchors.left: cover.right
        anchors.leftMargin: 8
        anchors.bottom: bar.top
        anchors.bottomMargin: 4
        spacing: 2
        IconButton { icon: "skip_previous"; onClicked: Media.player.previous() }
        IconButton {
            icon: Media.playing ? "pause" : "play_arrow"
            active: true
            radius: Media.playing ? 12 : 18
            Behavior on radius { NumberAnimation { duration: Theme.normal } }
            onClicked: Media.player.togglePlaying()
        }
        IconButton { icon: "skip_next"; onClicked: Media.player.next() }
        IconButton { visible: Media.players.length > 1; icon: "swap_horiz"; onClicked: Media.cyclePlayer() }
    }

    // Progreso (clic para saltar)
    Item {
        id: bar
        anchors.left: cover.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.bottom: cover.bottom
        height: 16
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 4; radius: 2
            color: Theme.alpha(Theme.fg, 0.15)
            Rectangle {
                width: Media.length > 0 ? parent.width * Math.min(1, Media.position / Media.length) : 0
                height: parent.height; radius: 2
                color: Theme.primary
                Behavior on width { NumberAnimation { duration: 900 } }
            }
        }
        Txt {
            anchors.right: parent.right
            anchors.bottom: parent.top
            text: Media.fmt(Media.position) + " / " + Media.fmt(Media.length)
            size: 10
            color: Theme.fgDim
            font.features: ({ "tnum": 1 })
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: Media.player && Media.player.canSeek
            onClicked: ev => { Media.player.position = Media.length * ev.x / width; Media.position = Media.player.position; }
        }
    }
}
