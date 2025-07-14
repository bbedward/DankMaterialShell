// NotificationGrouping.js
// Helper functions for Android 16-style notification grouping

function addOrUpdate(groupsModel, rawNotification) {
    const appId = rawNotification.appId || rawNotification.appName || "unknown";
    
    // 1. Does a group for this app already exist?
    for (let i = 0; i < groupsModel.count; ++i) {
        const g = groupsModel.get(i);
        if (g.appId === appId) {
            // Get existing notifications from JSON string
            let notifications = [];
            try {
                if (g.notificationsJson) {
                    notifications = JSON.parse(g.notificationsJson);
                }
            } catch (e) {
                console.warn("Failed to parse notifications JSON:", e);
            }
            
            // Add new notification to front (newest first)
            notifications.unshift(rawNotification);
            
            // Keep only last 50 notifications per group
            if (notifications.length > 50) {
                notifications = notifications.slice(0, 50);
            }
            
            // Update the group
            groupsModel.setProperty(i, "notificationsJson", JSON.stringify(notifications));
            groupsModel.setProperty(i, "unreadCount", notifications.length);
            groupsModel.setProperty(i, "lastTimestamp", rawNotification.timestamp || Date.now());
            
            // Move this group to the front (most recent activity)
            if (i > 0) {
                groupsModel.move(i, 0, 1);
            }
            return;
        }
    }
    
    // 2. Create new group object
    const notifications = [rawNotification];
    const newGroup = {
        appId: appId,
        appName: rawNotification.appName || "App",
        appIcon: rawNotification.appIcon || "",
        expanded: false,
        unreadCount: 1,
        lastTimestamp: rawNotification.timestamp || Date.now(),
        notificationsJson: JSON.stringify(notifications)
    };
    
    // Insert at the beginning (most recent)
    groupsModel.insert(0, newGroup);
}

function clearGroup(groupsModel, groupIndex) {
    if (groupIndex >= 0 && groupIndex < groupsModel.count) {
        groupsModel.remove(groupIndex);
    }
}

function clearNotification(groupsModel, groupIndex, notificationIndex) {
    if (groupIndex < 0 || groupIndex >= groupsModel.count) return;
    
    const group = groupsModel.get(groupIndex);
    let notifications = [];
    
    try {
        if (group.notificationsJson) {
            notifications = JSON.parse(group.notificationsJson);
        }
    } catch (e) {
        console.warn("Failed to parse notifications JSON:", e);
        return;
    }
    
    if (notificationIndex < 0 || notificationIndex >= notifications.length) return;
    
    // Remove the specific notification
    notifications.splice(notificationIndex, 1);
    
    if (notifications.length === 0) {
        // Remove the entire group if no notifications left
        groupsModel.remove(groupIndex);
    } else {
        // Update the group
        groupsModel.setProperty(groupIndex, "notificationsJson", JSON.stringify(notifications));
        groupsModel.setProperty(groupIndex, "unreadCount", notifications.length);
    }
}

function toggleGroupExpanded(groupsModel, groupIndex) {
    if (groupIndex >= 0 && groupIndex < groupsModel.count) {
        const group = groupsModel.get(groupIndex);
        groupsModel.setProperty(groupIndex, "expanded", !group.expanded);
    }
}

function getTotalUnreadCount(groupsModel) {
    let total = 0;
    for (let i = 0; i < groupsModel.count; ++i) {
        const group = groupsModel.get(i);
        total += group.unreadCount || 0;
    }
    return total;
}

function getFirstGroupUnreadCount(groupsModel) {
    if (groupsModel.count > 0) {
        const firstGroup = groupsModel.get(0);
        return firstGroup.unreadCount || 0;
    }
    return 0;
}

function getNotifications(group) {
    if (!group || !group.notificationsJson) return [];
    
    try {
        return JSON.parse(group.notificationsJson);
    } catch (e) {
        console.warn("Failed to parse notifications JSON:", e);
        return [];
    }
}