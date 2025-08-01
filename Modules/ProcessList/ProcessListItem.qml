import QtQuick
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: processItem

    property var process: null
    property var contextMenu: null

    width: parent ? parent.width : 0
    height: 40
    radius: Theme.cornerRadiusLarge
    color: processMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : "transparent"
    border.color: processMouseArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
    border.width: 1

    MouseArea {
        id: processMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                if (process && process.pid > 0 && contextMenu) {
                    contextMenu.processData = process;
                    let globalPos = processMouseArea.mapToGlobal(mouse.x, mouse.y);
                    let localPos = contextMenu.parent ? contextMenu.parent.mapFromGlobal(globalPos.x, globalPos.y) : globalPos;
                    contextMenu.show(localPos.x, localPos.y);
                }
            }
        }
        onPressAndHold: {
            if (process && process.pid > 0 && contextMenu) {
                contextMenu.processData = process;
                let globalPos = processMouseArea.mapToGlobal(processMouseArea.width / 2, processMouseArea.height / 2);
                contextMenu.show(globalPos.x, globalPos.y);
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 8

        DankIcon {
            id: processIcon

            name: SysMonitorService.getProcessIcon(process ? process.command : "")
            size: Theme.iconSize - 4
            color: {
                if (process && process.cpu > 80)
                    return Theme.error;

                if (process && process.cpu > 50)
                    return Theme.warning;

                return Theme.surfaceText;
            }
            opacity: 0.8
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
        }

        StyledText {
            text: process ? process.displayName : ""
            font.pixelSize: Theme.fontSizeSmall
            font.family: Prefs.monoFontFamily
            font.weight: Font.Medium
            color: Theme.surfaceText
            width: 250
            elide: Text.ElideRight
            anchors.left: processIcon.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: cpuBadge

            width: 80
            height: 20
            radius: Theme.cornerRadius
            color: {
                if (process && process.cpu > 80)
                    return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12);

                if (process && process.cpu > 50)
                    return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12);

                return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08);
            }
            anchors.right: parent.right
            anchors.rightMargin: 194
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: SysMonitorService.formatCpuUsage(process ? process.cpu : 0)
                font.pixelSize: Theme.fontSizeSmall
                font.family: Prefs.monoFontFamily
                font.weight: Font.Bold
                color: {
                    if (process && process.cpu > 80)
                        return Theme.error;

                    if (process && process.cpu > 50)
                        return Theme.warning;

                    return Theme.surfaceText;
                }
                anchors.centerIn: parent
            }

        }

        Rectangle {
            id: memoryBadge

            width: 80
            height: 20
            radius: Theme.cornerRadius
            color: {
                if (process && process.memoryKB > 1024 * 1024)
                    return Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12);

                if (process && process.memoryKB > 512 * 1024)
                    return Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12);

                return Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08);
            }
            anchors.right: parent.right
            anchors.rightMargin: 102
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                text: SysMonitorService.formatMemoryUsage(process ? process.memoryKB : 0)
                font.pixelSize: Theme.fontSizeSmall
                font.family: Prefs.monoFontFamily
                font.weight: Font.Bold
                color: {
                    if (process && process.memoryKB > 1024 * 1024)
                        return Theme.error;

                    if (process && process.memoryKB > 512 * 1024)
                        return Theme.warning;

                    return Theme.surfaceText;
                }
                anchors.centerIn: parent
            }

        }

        StyledText {
            text: process ? process.pid.toString() : ""
            font.pixelSize: Theme.fontSizeSmall
            font.family: Prefs.monoFontFamily
            color: Theme.surfaceText
            opacity: 0.7
            width: 50
            horizontalAlignment: Text.AlignRight
            anchors.right: parent.right
            anchors.rightMargin: 40
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: menuButton

            width: 28
            height: 28
            radius: Theme.cornerRadius
            color: menuButtonArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                name: "more_vert"
                size: Theme.iconSize - 2
                color: Theme.surfaceText
                opacity: 0.6
                anchors.centerIn: parent
            }

            MouseArea {
                id: menuButtonArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (process && process.pid > 0 && contextMenu) {
                        contextMenu.processData = process;
                        let globalPos = menuButtonArea.mapToGlobal(menuButtonArea.width / 2, menuButtonArea.height);
                        let localPos = contextMenu.parent ? contextMenu.parent.mapFromGlobal(globalPos.x, globalPos.y) : globalPos;
                        contextMenu.show(localPos.x, localPos.y);
                    }
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Theme.shortDuration
                }

            }

        }

    }

}
