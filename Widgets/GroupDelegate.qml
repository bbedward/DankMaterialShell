import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../Common"
import "../Common/NotificationGrouping.js" as NotificationGrouping

Item {
    id: groupDelegate
    
    property var groupModel
    property int groupIndex: -1
    signal clearGroup(int index)
    signal clearNotification(int groupIndex, int notificationIndex)
    
    width: parent ? parent.width : 400
    implicitHeight: header.height + notificationStack.height + Theme.spacingS
    
    // Smooth height animation
    Behavior on implicitHeight {
        NumberAnimation {
            duration: Theme.mediumDuration
            easing.type: Theme.emphasizedEasing
        }
    }
    
    // Group header
    Rectangle {
        id: header
        width: parent.width
        height: 56
        radius: Theme.cornerRadiusLarge
        color: model.expanded ? 
               Theme.surfaceContainerHigh : 
               Theme.surfaceContainer
        
        // Header content
        RowLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingM
            
            // App icon
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Theme.primaryContainer
                Layout.alignment: Qt.AlignVCenter
                
                // Fallback icon
                Loader {
                    active: !model.appIcon || model.appIcon === ""
                    anchors.fill: parent
                    sourceComponent: Text {
                        anchors.centerIn: parent
                        text: "notifications"
                        font.family: Theme.iconFont
                        font.pixelSize: 16
                        color: Theme.primaryText
                    }
                }
                
                // App icon
                Loader {
                    active: model.appIcon && model.appIcon !== ""
                    anchors.centerIn: parent
                    sourceComponent: IconImage {
                        width: 20
                        height: 20
                        asynchronous: true
                        source: {
                            if (!model.appIcon) return ""
                            if (model.appIcon.startsWith("file://") || model.appIcon.startsWith("/")) {
                                return model.appIcon
                            }
                            return Quickshell.iconPath(model.appIcon, "image-missing")
                        }
                    }
                }
            }
            
            // App name
            Text {
                text: model.appName || "App"
                Layout.fillWidth: true
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                elide: Text.ElideRight
            }
            
            // Unread count badge
            Rectangle {
                visible: (model.unreadCount || 0) > 1
                width: Math.max(24, countText.implicitWidth + 8)
                height: 20
                radius: 10
                color: Theme.primary
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: model.unreadCount || 0
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Medium
                }
            }
            
            // Expand/collapse indicator (only show if more than 1 notification)
            Text {
                text: model.expanded ? "expand_less" : "expand_more"
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                color: Theme.surfaceText
                Layout.alignment: Qt.AlignVCenter
                visible: (model.unreadCount || 0) > 1
            }
            
            // Clear group button
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: clearGroupArea.containsMouse ? 
                       Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : 
                       "transparent"
                Layout.alignment: Qt.AlignVCenter
                
                Text {
                    anchors.centerIn: parent
                    text: "close"
                    font.family: Theme.iconFont
                    font.pixelSize: 16
                    color: clearGroupArea.containsMouse ? Theme.error : Theme.surfaceText
                }
                
                MouseArea {
                    id: clearGroupArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        groupDelegate.clearGroup(groupDelegate.groupIndex)
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
        
        // Header tap area (excluding buttons)
        MouseArea {
            anchors.fill: parent
            anchors.rightMargin: 64  // Don't overlap buttons
            cursorShape: Qt.PointingHandCursor
            enabled: (model.unreadCount || 0) > 1  // Only enable if multiple notifications
            
            onClicked: {
                if (groupDelegate.groupModel && (model.unreadCount || 0) > 1) {
                    NotificationGrouping.toggleGroupExpanded(groupDelegate.groupModel, groupDelegate.groupIndex)
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
    
    // Notification stack
    Column {
        id: notificationStack
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: Theme.spacingS
        spacing: Theme.spacingXS
        
        // Show notifications based on expanded state
        Repeater {
            id: notificationRepeater
            
            property var notifications: NotificationGrouping.getNotifications(groupDelegate.model)
            
            model: {
                if (!groupDelegate.model || notificationRepeater.notifications.length === 0) return 0
                
                // If only 1 notification, always show it
                if (notificationRepeater.notifications.length === 1) return 1
                
                // Otherwise, show all when expanded, or just 1 when collapsed
                return groupDelegate.model.expanded ? 
                       notificationRepeater.notifications.length : 
                       1
            }
            
            delegate: NotificationDelegate {
                width: notificationStack.width
                notification: {
                    // For collapsed view, always show the first notification
                    var idx = groupDelegate.model.expanded ? index : 0
                    var notif = notificationRepeater.notifications[idx] || null
                    if (notif && index === 0) {
                        console.log("Notification details:", JSON.stringify(notif))
                    }
                    return notif
                }
                compact: !groupDelegate.model.expanded && notificationRepeater.notifications.length > 1 && index > 0
                
                onClearRequested: {
                    var actualIndex = groupDelegate.model.expanded ? index : 0
                    groupDelegate.clearNotification(groupDelegate.groupIndex, actualIndex)
                }
            }
        }
    }
}