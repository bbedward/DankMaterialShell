import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

DankModal {
    id: root

    property bool networkInfoModalVisible: false
    property string networkSSID: ""
    property var networkData: null
    property string networkDetails: ""

    function showNetworkInfo(ssid, data) {
        networkSSID = ssid;
        networkData = data;
        networkInfoModalVisible = true;
        NetworkService.fetchNetworkInfo(ssid);
    }

    function hideDialog() {
        networkInfoModalVisible = false;
        networkSSID = "";
        networkData = null;
        networkDetails = "";
    }

    visible: networkInfoModalVisible
    width: 600
    height: 500
    enableShadow: true
    onBackgroundClicked: {
        hideDialog();
    }
    onVisibleChanged: {
        if (!visible) {
            networkSSID = "";
            networkData = null;
            networkDetails = "";
        }
    }

    content: Component {
        Item {
            anchors.fill: parent

        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingL

            // Header
            Row {
                width: parent.width

                Column {
                    width: parent.width - 40
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "Network Information"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    StyledText {
                        text: "Details for \"" + networkSSID + "\""
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceTextMedium
                        width: parent.width
                        elide: Text.ElideRight
                    }

                }

                DankActionButton {
                    iconName: "close"
                    iconSize: Theme.iconSize - 4
                    iconColor: Theme.surfaceText
                    hoverColor: Theme.errorHover
                    onClicked: {
                        root.hideDialog();
                    }
                }

            }

            // Network Details
            ScrollView {
                width: parent.width
                height: parent.height - 140
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Flickable {
                    contentWidth: parent.width
                    contentHeight: detailsRect.height

                    Rectangle {
                        id: detailsRect

                        width: parent.width
                        height: Math.max(parent.parent.height, detailsText.contentHeight + Theme.spacingM * 2)
                        radius: Theme.cornerRadius
                        color: Theme.surfaceHover
                        border.color: Theme.outlineStrong
                        border.width: 1

                        StyledText {
                            id: detailsText

                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            text: NetworkService.networkInfoDetails.replace(/\\n/g, '\n') || "No information available"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            wrapMode: Text.WordWrap
                            lineHeight: 1.5
                        }

                    }

                }

            }

            // Close Button
            Item {
                width: parent.width
                height: 40

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(70, closeText.contentWidth + Theme.spacingM * 2)
                    height: 36
                    radius: Theme.cornerRadius
                    color: closeArea.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary

                    StyledText {
                        id: closeText

                        anchors.centerIn: parent
                        text: "Close"
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.background
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: closeArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.hideDialog();
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

            }

        }
        }
    }

}
