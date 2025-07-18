import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property bool wifiPasswordDialogVisible: false
    property string wifiPasswordSSID: ""
    property string wifiPasswordInput: ""

    visible: wifiPasswordDialogVisible
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: wifiPasswordDialogVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    color: "transparent"
    onVisibleChanged: {
        if (visible)
            passwordInput.forceActiveFocus();

    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: wifiPasswordDialogVisible ? 1 : 0

        MouseArea {
            anchors.fill: parent
            onClicked: {
                wifiPasswordDialogVisible = false;
                wifiPasswordInput = "";
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.standardEasing
            }

        }

    }

    Rectangle {
        width: Math.min(400, parent.width - Theme.spacingL * 2)
        height: Math.min(250, parent.height - Theme.spacingL * 2)
        anchors.centerIn: parent
        color: Theme.surfaceContainer
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
        border.width: 1
        opacity: wifiPasswordDialogVisible ? 1 : 0
        scale: wifiPasswordDialogVisible ? 1 : 0.9

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

                    Text {
                        text: "Connect to Wi-Fi"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "Enter password for \"" + wifiPasswordSSID + "\""
                        font.pixelSize: Theme.fontSizeMedium
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                        width: parent.width
                        elide: Text.ElideRight
                    }

                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: closeDialogArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"

                    DankIcon {
                        anchors.centerIn: parent
                        name: "close"
                        size: Theme.iconSize - 4
                        color: closeDialogArea.containsMouse ? Theme.error : Theme.surfaceText
                    }

                    MouseArea {
                        id: closeDialogArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            wifiPasswordDialogVisible = false;
                            wifiPasswordInput = "";
                        }
                    }

                }

            }

            // Password input
            Rectangle {
                width: parent.width
                height: 50
                radius: Theme.cornerRadius
                color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
                border.color: passwordInput.activeFocus ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
                border.width: passwordInput.activeFocus ? 2 : 1

                TextInput {
                    id: passwordInput

                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    echoMode: showPasswordCheckbox.checked ? TextInput.Normal : TextInput.Password
                    verticalAlignment: TextInput.AlignVCenter
                    cursorVisible: activeFocus
                    selectByMouse: true
                    onTextChanged: {
                        wifiPasswordInput = text;
                    }
                    onAccepted: {
                        WifiService.connectToWifiWithPassword(wifiPasswordSSID, wifiPasswordInput);
                    }
                    Component.onCompleted: {
                        if (wifiPasswordDialogVisible)
                            forceActiveFocus();

                    }

                    Text {
                        anchors.fill: parent
                        text: "Enter password"
                        font: parent.font
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.5)
                        verticalAlignment: Text.AlignVCenter
                        visible: parent.text.length === 0
                    }

                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.IBeamCursor
                    onClicked: {
                        passwordInput.forceActiveFocus();
                    }
                }

            }

            // Show password checkbox
            Row {
                spacing: Theme.spacingS

                Rectangle {
                    id: showPasswordCheckbox

                    property bool checked: false

                    width: 20
                    height: 20
                    radius: 4
                    color: checked ? Theme.primary : "transparent"
                    border.color: checked ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.5)
                    border.width: 2

                    DankIcon {
                        anchors.centerIn: parent
                        name: "check"
                        size: 12
                        color: Theme.background
                        visible: parent.checked
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            showPasswordCheckbox.checked = !showPasswordCheckbox.checked;
                        }
                    }

                }

                Text {
                    text: "Show password"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceText
                    anchors.verticalCenter: parent.verticalCenter
                }

            }

            // Buttons
            Item {
                width: parent.width
                height: 40

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingM

                    Rectangle {
                        width: Math.max(70, cancelText.contentWidth + Theme.spacingM * 2)
                        height: 36
                        radius: Theme.cornerRadius
                        color: cancelArea.containsMouse ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08) : "transparent"
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                        border.width: 1

                        Text {
                            id: cancelText

                            anchors.centerIn: parent
                            text: "Cancel"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: cancelArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wifiPasswordDialogVisible = false;
                                wifiPasswordInput = "";
                            }
                        }

                    }

                    Rectangle {
                        width: Math.max(80, connectText.contentWidth + Theme.spacingM * 2)
                        height: 36
                        radius: Theme.cornerRadius
                        color: connectArea.containsMouse ? Qt.darker(Theme.primary, 1.1) : Theme.primary
                        enabled: wifiPasswordInput.length > 0
                        opacity: enabled ? 1 : 0.5

                        Text {
                            id: connectText

                            anchors.centerIn: parent
                            text: "Connect"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.background
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: connectArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: parent.enabled
                            onClicked: {
                                WifiService.connectToWifiWithPassword(wifiPasswordSSID, wifiPasswordInput);
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

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Theme.mediumDuration
                easing.type: Theme.emphasizedEasing
            }

        }

    }

}
