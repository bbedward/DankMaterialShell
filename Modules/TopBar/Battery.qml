import QtQuick
import Quickshell.Services.UPower
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: battery

    property bool batteryPopupVisible: false

    signal toggleBatteryPopup()

    width: BatteryService.batteryAvailable ? 70 : 40
    height: 30
    radius: Theme.cornerRadius
    color: {
        const baseColor = batteryArea.containsMouse || batteryPopupVisible ? Theme.primaryPressed : Theme.secondaryHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
    }
    visible: true

    Row {
        anchors.centerIn: parent
        spacing: 4

        DankIcon {
            name: Theme.getBatteryIcon(BatteryService.batteryLevel, BatteryService.isCharging, BatteryService.batteryAvailable)
            size: Theme.iconSize - 6
            color: {
                if (!BatteryService.batteryAvailable)
                    return Theme.surfaceText;

                if (BatteryService.isLowBattery && !BatteryService.isCharging)
                    return Theme.error;

                if (BatteryService.isCharging)
                    return Theme.primary;

                return Theme.surfaceText;
            }
            anchors.verticalCenter: parent.verticalCenter

            SequentialAnimation on opacity {
                running: BatteryService.isCharging
                loops: Animation.Infinite

                NumberAnimation {
                    to: 0.6
                    duration: Anims.durLong
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anims.standard
                }

                NumberAnimation {
                    to: 1
                    duration: Anims.durLong
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Anims.standard
                }

            }

        }

        StyledText {
            text: BatteryService.batteryLevel + "%"
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: {
                if (!BatteryService.batteryAvailable)
                    return Theme.surfaceText;

                if (BatteryService.isLowBattery && !BatteryService.isCharging)
                    return Theme.error;

                if (BatteryService.isCharging)
                    return Theme.primary;

                return Theme.surfaceText;
            }
            anchors.verticalCenter: parent.verticalCenter
            visible: BatteryService.batteryAvailable
        }

    }

    MouseArea {
        id: batteryArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleBatteryPopup();
        }
    }

    Rectangle {
        id: batteryTooltip

        width: Math.max(120, tooltipText.contentWidth + Theme.spacingM * 2)
        height: tooltipText.contentHeight + Theme.spacingS * 2
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Theme.surfaceVariantAlpha
        border.width: 1
        visible: batteryArea.containsMouse && !batteryPopupVisible
        anchors.bottom: parent.top
        anchors.bottomMargin: Theme.spacingS
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: batteryArea.containsMouse ? 1 : 0

        Column {
            anchors.centerIn: parent
            spacing: 2

            StyledText {
                id: tooltipText

                text: {
                    if (!BatteryService.batteryAvailable) {
                        if (typeof PowerProfiles === "undefined")
                            return "Power Management";

                        switch (PowerProfiles.profile) {
                        case PowerProfile.PowerSaver:
                            return "Power Profile: Power Saver";
                        case PowerProfile.Performance:
                            return "Power Profile: Performance";
                        default:
                            return "Power Profile: Balanced";
                        }
                    }
                    let status = BatteryService.batteryStatus;
                    let level = BatteryService.batteryLevel + "%";
                    let time = BatteryService.formatTimeRemaining();
                    if (time !== "Unknown")
                        return status + " • " + level + " • " + time;
                    else
                        return status + " • " + level;
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
                horizontalAlignment: Text.AlignHCenter
            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }

    }

}
