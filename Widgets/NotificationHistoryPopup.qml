import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../Common"
import "../Common/NotificationGrouping.js" as NotificationGrouping

PanelWindow {
    id: notificationHistoryPopup
    
    visible: root.notificationHistoryVisible
    
    implicitWidth: 400
    implicitHeight: 500
    
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    
    color: "transparent"
    
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }
    
    Rectangle {
        width: 400
        height: 500
        x: parent.width - width - Theme.spacingL
        y: Theme.barHeight + Theme.spacingXS
        color: Theme.surfaceContainer
        radius: Theme.cornerRadiusLarge
        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12)
        border.width: 1
        
        opacity: root.notificationHistoryVisible ? 1.0 : 0.0
        scale: root.notificationHistoryVisible ? 1.0 : 0.85
        
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
        
        Column {
            anchors.fill: parent
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingM
            
            // Header
            Column {
                width: parent.width
                spacing: Theme.spacingM
                
                Row {
                    width: parent.width
                    height: 32
                    
                    Text {
                        id: notificationsTitle
                        text: "Notifications"
                        font.pixelSize: Theme.fontSizeLarge
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Item { 
                        width: parent.width - notificationsTitle.width - clearButton.width - Theme.spacingM
                        height: 1 
                    }
                    
                    // Compact Clear All Button
                    Rectangle {
                        id: clearButton
                        width: 120
                        height: 28
                        radius: Theme.cornerRadius
                        anchors.verticalCenter: parent.verticalCenter
                        visible: root.notificationHistory.count > 0
                        
                        color: clearArea.containsMouse ? 
                               Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : 
                               Theme.surfaceContainer
                        
                        border.color: clearArea.containsMouse ? 
                                     Theme.primary : 
                                     Theme.outline
                        border.width: 1
                        
                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS
                            
                            Text {
                                text: "delete_sweep"
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSizeSmall
                                color: clearArea.containsMouse ? Theme.primary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "Clear All"
                                font.pixelSize: Theme.fontSizeSmall
                                color: clearArea.containsMouse ? Theme.primary : Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            
                            onClicked: {
                                root.notificationHistory.clear()
                            }
                        }
                        
                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }
                        
                        Behavior on border.color {
                            ColorAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }
                        }
                    }
                }
            }
            
            // Grouped Notification List
            ScrollView {
                width: parent.width
                height: parent.height - 120
                clip: true
                
                ListView {
                    id: groupView
                    model: root.notificationHistory  // Using the alias to notificationGroups
                    spacing: Theme.spacingS
                    
                    delegate: GroupDelegate {
                        width: groupView.width
                        groupModel: root.notificationHistory
                        groupIndex: index
                        
                        onClearGroup: (index) => {
                            NotificationGrouping.clearGroup(root.notificationHistory, index)
                        }
                        
                        onClearNotification: (groupIndex, notificationIndex) => {
                            NotificationGrouping.clearNotification(root.notificationHistory, groupIndex, notificationIndex)
                        }
                    }
                }
                
                // Empty state - properly centered
                Item {
                    anchors.fill: parent
                    visible: root.notificationHistory.count === 0
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingM
                        width: parent.width * 0.8
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "notifications_none"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.iconSizeLarge + 16
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.3)
                            font.weight: Theme.iconFontWeight
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No notifications"
                            font.pixelSize: Theme.fontSizeLarge
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.6)
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                        }
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Notifications will appear here grouped by app"
                            font.pixelSize: Theme.fontSizeMedium
                            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.4)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
    
    // Click outside to close
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            root.notificationHistoryVisible = false
        }
    }
}