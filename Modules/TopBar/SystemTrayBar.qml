import QtQuick
import Quickshell.Services.SystemTray
import qs.Common

Rectangle {
    id: root

    signal menuRequested(var menu, var item, real x, real y)

    width: Math.max(40, systemTrayRow.implicitWidth + Theme.spacingS * 2)
    height: 30
    radius: Theme.cornerRadius
    color: Theme.secondaryHover
    visible: systemTrayRow.children.length > 0

    Row {
        id: systemTrayRow

        anchors.centerIn: parent
        spacing: Theme.spacingXS

        Repeater {
            model: SystemTray.items

            delegate: Item {
                property var trayItem: modelData
                property string iconSource: {
                    let icon = trayItem && trayItem.icon;
                    if (typeof icon === 'string' || icon instanceof String) {
                        if (icon.includes("?path=")) {
                            const [name, path] = icon.split("?path=");
                            const fileName = name.substring(name.lastIndexOf("/") + 1);
                            return `file://${path}/${fileName}`;
                        }
                        return icon;
                    }
                    return "";
                }

                width: 24
                height: 24

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.cornerRadiusSmall
                    color: trayItemArea.containsMouse ? Theme.primaryHover : "transparent"

                    Behavior on color {
                        enabled: trayItemArea.containsMouse !== undefined

                        ColorAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: parent.iconSource
                    asynchronous: true
                    smooth: true
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: trayItemArea

                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                        if (!trayItem)
                            return ;

                        if (mouse.button === Qt.LeftButton) {
                            if (!trayItem.onlyMenu)
                                trayItem.activate();

                        } else if (mouse.button === Qt.RightButton) {
                            if (trayItem && trayItem.hasMenu)
                                root.menuRequested(null, trayItem, mouse.x, mouse.y);

                        }
                    }
                }

            }

        }

    }

}
