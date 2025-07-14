import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../Common"

Item {
    id: notificationDelegate
    
    property var notification
    property bool compact: false
    signal clearRequested()
    
    width: parent ? parent.width : 400
    height: compact ? 60 : 80
    
    // Background
    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: notifMouseArea.containsMouse ? 
               Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : 
               Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)
        
        Behavior on color {
            ColorAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }
    }
    
    // Main content
    Row {
        anchors.fill: parent
        anchors.margins: compact ? Theme.spacingS : Theme.spacingM
        anchors.rightMargin: 40  // Space for close button
        spacing: compact ? Theme.spacingS : Theme.spacingM
        
        // Notification icon
        Rectangle {
            width: compact ? 32 : 48
            height: compact ? 32 : 48
            radius: width / 2
            color: Theme.primaryContainer
            anchors.verticalCenter: parent.verticalCenter
            
            // Fallback icon
            Loader {
                active: !notificationDelegate.notification || !notificationDelegate.notification.appIcon || notificationDelegate.notification.appIcon === ""
                anchors.fill: parent
                sourceComponent: Text {
                    anchors.centerIn: parent
                    text: "notifications"
                    font.family: Theme.iconFont
                    font.pixelSize: compact ? 16 : 20
                    color: Theme.primaryText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            // App icon (when no notification image)
            Loader {
                active: notificationDelegate.notification && 
                       notificationDelegate.notification.appIcon !== "" && 
                       (!notificationDelegate.notification.image || notificationDelegate.notification.image === "")
                anchors.centerIn: parent
                sourceComponent: IconImage {
                    width: compact ? 20 : 32
                    height: compact ? 20 : 32
                    asynchronous: true
                    source: {
                        if (!notificationDelegate.notification || !notificationDelegate.notification.appIcon) return ""
                        if (notificationDelegate.notification.appIcon.startsWith("file://") || 
                            notificationDelegate.notification.appIcon.startsWith("/")) {
                            return notificationDelegate.notification.appIcon
                        }
                        return Quickshell.iconPath(notificationDelegate.notification.appIcon, "image-missing")
                    }
                }
            }
            
            // Notification image (priority)
            Loader {
                active: notificationDelegate.notification && notificationDelegate.notification.image !== ""
                anchors.fill: parent
                sourceComponent: Item {
                    anchors.fill: parent
                    
                    Image {
                        id: notifImage
                        anchors.fill: parent
                        source: notificationDelegate.notification ? notificationDelegate.notification.image : ""
                        fillMode: Image.PreserveAspectCrop
                        cache: true
                        antialiasing: true
                        asynchronous: true
                        smooth: true
                        sourceSize.width: parent.width
                        sourceSize.height: parent.height
                        
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: Rectangle {
                                width: compact ? 32 : 48
                                height: compact ? 32 : 48
                                radius: width / 2
                            }
                        }
                        
                        onStatusChanged: {
                            if (status === Image.Error) {
                                console.warn("Failed to load notification image:", source)
                            }
                        }
                    }
                    
                    // Small app icon overlay when showing notification image
                    Loader {
                        active: notificationDelegate.notification && 
                               notificationDelegate.notification.appIcon !== "" && 
                               notifImage.status === Image.Ready
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        sourceComponent: IconImage {
                            width: compact ? 12 : 16
                            height: compact ? 12 : 16
                            asynchronous: true
                            source: {
                                if (!notificationDelegate.notification || !notificationDelegate.notification.appIcon) return ""
                                if (notificationDelegate.notification.appIcon.startsWith("file://") || 
                                    notificationDelegate.notification.appIcon.startsWith("/")) {
                                    return notificationDelegate.notification.appIcon
                                }
                                return Quickshell.iconPath(notificationDelegate.notification.appIcon, "image-missing")
                            }
                        }
                    }
                }
            }
        }
        
        // Text content
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - (compact ? 48 : 64)
            spacing: compact ? 2 : Theme.spacingXS
            
            // App name (only in expanded mode)
            Text {
                text: notificationDelegate.notification ? (notificationDelegate.notification.appName || "App") : ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primary
                font.weight: Font.Medium
                visible: !compact && text.length > 0
                width: parent.width
                elide: Text.ElideRight
            }
            
            // Summary/title
            Text {
                text: notificationDelegate.notification ? (notificationDelegate.notification.summary || "") : ""
                font.pixelSize: compact ? Theme.fontSizeSmall : Theme.fontSizeMedium
                color: Theme.surfaceText
                font.weight: Font.Medium
                width: parent.width
                elide: Text.ElideRight
                visible: text.length > 0
            }
            
            // Body text
            Text {
                text: notificationDelegate.notification ? (notificationDelegate.notification.body || "") : ""
                font.pixelSize: compact ? Theme.fontSizeXSmall : Theme.fontSizeSmall
                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.7)
                width: parent.width
                wrapMode: Text.WordWrap
                maximumLineCount: compact ? 1 : 2
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }
    
    // Close button overlay
    Rectangle {
        width: 24
        height: 24
        radius: 12
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        color: closeArea.containsMouse ? 
               Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : 
               "transparent"
        
        Text {
            anchors.centerIn: parent
            text: "close"
            font.family: Theme.iconFont
            font.pixelSize: 14
            color: closeArea.containsMouse ? Theme.error : Theme.surfaceText
        }
        
        MouseArea {
            id: closeArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: {
                notificationDelegate.clearRequested()
            }
        }
        
        Behavior on color {
            ColorAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }
    }
    
    // Click handling
    MouseArea {
        id: notifMouseArea
        anchors.fill: parent
        anchors.rightMargin: 36  // Don't overlap with close button
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            // Handle notification click if needed
            if (notificationDelegate.notification && root.handleNotificationClick) {
                root.handleNotificationClick(notificationDelegate.notification)
            }
        }
    }
}