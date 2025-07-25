import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.Common

ScrollView {
    id: listView

    property alias model: list.model
    property int currentIndex: 0
    property int itemHeight: 72
    property int iconSize: 56
    property bool showDescription: true
    property int itemSpacing: Theme.spacingS
    property bool hoverUpdatesSelection: true
    property bool keyboardNavigationActive: false

    signal keyboardNavigationReset()
    signal itemClicked(int index, var modelData)
    signal itemHovered(int index)

    // Ensure the current item is visible
    function ensureVisible(index) {
        if (index < 0 || index >= list.count)
            return ;

        var itemY = index * (itemHeight + itemSpacing);
        var itemBottom = itemY + itemHeight;
        if (itemY < list.contentY)
            list.contentY = itemY;
        else if (itemBottom > list.contentY + list.height)
            list.contentY = itemBottom - list.height;
    }

    onCurrentIndexChanged: {
        if (keyboardNavigationActive)
            ensureVisible(currentIndex);

    }
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AlwaysOn
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ListView {
        id: list

        anchors.fill: parent
        anchors.margins: itemSpacing
        spacing: listView.itemSpacing
        focus: true
        interactive: true
        currentIndex: listView.currentIndex
        flickDeceleration: 600
        maximumFlickVelocity: 30000

        delegate: Rectangle {
            width: list.width
            height: itemHeight
            radius: Theme.cornerRadiusLarge
            color: ListView.isCurrentItem ? Theme.primaryPressed : mouseArea.containsMouse ? Theme.primaryHoverLight : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.03)
            border.color: ListView.isCurrentItem ? Theme.primarySelected : Theme.outlineMedium
            border.width: ListView.isCurrentItem ? 2 : 1

            Row {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingL

                Item {
                    width: iconSize
                    height: iconSize
                    anchors.verticalCenter: parent.verticalCenter

                    IconImage {
                        id: iconImg

                        anchors.fill: parent
                        source: (model.icon) ? Quickshell.iconPath(model.icon, "") : ""
                        smooth: true
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: !iconImg.visible
                        color: Theme.surfaceLight
                        radius: Theme.cornerRadiusLarge
                        border.width: 1
                        border.color: Theme.primarySelected

                        Text {
                            anchors.centerIn: parent
                            text: (model.name && model.name.length > 0) ? model.name.charAt(0).toUpperCase() : "A"
                            font.pixelSize: iconSize * 0.4
                            color: Theme.primary
                            font.weight: Font.Bold
                        }

                    }

                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - iconSize - Theme.spacingL
                    spacing: Theme.spacingXS

                    Text {
                        width: parent.width
                        text: model.name || ""
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: model.comment || "Application"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceVariantText
                        elide: Text.ElideRight
                        visible: showDescription && model.comment && model.comment.length > 0
                    }

                }

            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                z: 10
                onEntered: {
                    if (hoverUpdatesSelection && !keyboardNavigationActive)
                        listView.currentIndex = index;

                    itemHovered(index);
                }
                onPositionChanged: {
                    // Signal parent to reset keyboard navigation flag when mouse moves
                    keyboardNavigationReset();
                }
                onClicked: {
                    itemClicked(index, model);
                }
            }

        }

    }

}
