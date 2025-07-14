import QtQuick
import "../../Common"

Rectangle {
    id: root
    
    property bool hasUnread: false
    property int unreadCount: 0
    property bool isActive: false
    signal clicked()
    
    width: 40
    height: 30
    radius: Theme.cornerRadius
    color: notificationArea.containsMouse || root.isActive ? 
           Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.16) : 
           Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.08)
    
    Text {
        anchors.centerIn: parent
        text: "notifications"
        font.family: Theme.iconFont
        font.pixelSize: Theme.iconSize - 6
        font.weight: Theme.iconFontWeight
        color: notificationArea.containsMouse || root.isActive ? 
               Theme.primary : Theme.surfaceText
    }
    
    // Notification count badge
    Rectangle {
        width: root.unreadCount > 0 ? Math.max(16, countText.implicitWidth + 6) : 8
        height: root.unreadCount > 0 ? 16 : 8
        radius: width / 2
        color: Theme.error
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 4
        anchors.topMargin: 4
        visible: root.hasUnread || root.unreadCount > 0
        
        Text {
            id: countText
            anchors.centerIn: parent
            text: root.unreadCount > 99 ? "99+" : root.unreadCount.toString()
            color: Theme.surfaceText
            font.pixelSize: 10
            font.weight: Font.Medium
            visible: root.unreadCount > 0
        }
        
        Behavior on width {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }
        
        Behavior on height {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Theme.standardEasing
            }
        }
    }
    
    MouseArea {
        id: notificationArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            root.clicked()
        }
    }
    
    Behavior on color {
        ColorAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }
    }
}