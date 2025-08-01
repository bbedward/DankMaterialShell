import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property bool isActive: false

    signal clicked()

    function getWiFiSignalIcon(signalStrength) {
        switch (signalStrength) {
        case "excellent":
            return "wifi";
        case "good":
            return "wifi_2_bar";
        case "fair":
            return "wifi_1_bar";
        case "poor":
            return "signal_wifi_0_bar";
        default:
            return "wifi";
        }
    }

    width: Math.max(80, controlIndicators.implicitWidth + Theme.spacingS * 2)
    height: 30
    radius: Theme.cornerRadius
    color: {
        const baseColor = controlCenterArea.containsMouse || root.isActive ? Theme.primaryPressed : Theme.secondaryHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
    }

    Row {
        id: controlIndicators

        anchors.centerIn: parent
        spacing: Theme.spacingXS

        DankIcon {
            name: {
                if (NetworkService.networkStatus === "ethernet")
                    return "lan";
                else if (NetworkService.networkStatus === "wifi")
                    return getWiFiSignalIcon(NetworkService.wifiSignalStrength);
                else
                    return "wifi_off";
            }
            size: Theme.iconSize - 8
            color: NetworkService.networkStatus !== "disconnected" ? Theme.primary : Theme.outlineButton
            anchors.verticalCenter: parent.verticalCenter
            visible: true
        }

        DankIcon {
            name: "bluetooth"
            size: Theme.iconSize - 8
            color: BluetoothService.enabled ? Theme.primary : Theme.outlineButton
            anchors.verticalCenter: parent.verticalCenter
            visible: BluetoothService.available && BluetoothService.enabled
        }

        Rectangle {
            width: audioIcon.implicitWidth + 4
            height: audioIcon.implicitHeight + 4
            color: "transparent"
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                id: audioIcon

                name: (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.muted) ? "volume_off" : (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.volume * 100) < 33 ? "volume_down" : "volume_up"
                size: Theme.iconSize - 8
                color: audioWheelArea.containsMouse || controlCenterArea.containsMouse || root.isActive ? Theme.primary : Theme.surfaceText
                anchors.centerIn: parent
            }

            MouseArea {
                id: audioWheelArea

                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                onWheel: function(wheelEvent) {
                    let delta = wheelEvent.angleDelta.y;
                    let currentVolume = (AudioService.sink && AudioService.sink.audio && AudioService.sink.audio.volume * 100) || 0;
                    let newVolume;
                    if (delta > 0)
                        newVolume = Math.min(100, currentVolume + 5);
                    else
                        newVolume = Math.max(0, currentVolume - 5);
                    if (AudioService.sink && AudioService.sink.audio) {
                        AudioService.sink.audio.muted = false;
                        AudioService.sink.audio.volume = newVolume / 100;
                    }
                    wheelEvent.accepted = true;
                }
            }

        }

        DankIcon {
            name: "mic"
            size: Theme.iconSize - 8
            color: Theme.primary
            anchors.verticalCenter: parent.verticalCenter
            visible: false // TODO: Add mic detection
        }

    }

    MouseArea {
        id: controlCenterArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.clicked();
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

}
