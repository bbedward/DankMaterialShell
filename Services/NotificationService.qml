pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.Services
import qs.Common
import "../Common/markdown2html.js" as Markdown2Html

Singleton {
    id: root

    readonly property list<NotifWrapper> notifications: []
    readonly property list<NotifWrapper> allWrappers: []
    readonly property list<NotifWrapper> popups: allWrappers.filter(n => n.popup)
    
    property list<NotifWrapper> notificationQueue: []
    property list<NotifWrapper> visibleNotifications: []
    property int maxVisibleNotifications: 3
    property bool addGateBusy: false
    property int enterAnimMs: 400
    property int seqCounter: 0
    property bool bulkDismissing: false

    Timer {
        id: addGate
        interval: enterAnimMs + 50
        running: false
        repeat: false
        onTriggered: { addGateBusy = false; processQueue(); }
    }
    
    // Android 16-style grouped notifications
    readonly property var groupedNotifications: getGroupedNotifications()
    readonly property var groupedPopups: getGroupedPopups()
    
    
    property var expandedGroups: ({})
    property var expandedMessages: ({})
    property bool popupsDisabled: false
    

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: notif => {
            notif.tracked = true;

            const shouldShowPopup = !root.popupsDisabled && !Prefs.doNotDisturb;
            const wrapper = notifComponent.createObject(root, {
                popup: shouldShowPopup,
                notification: notif
            });

            if (wrapper) {
                root.allWrappers.push(wrapper);
                root.notifications.push(wrapper);
                
                if (shouldShowPopup) {
                    notificationQueue = [...notificationQueue, wrapper];
                    processQueue();
                }
            }
        }
    }

    component NotifWrapper: QtObject {
        id: wrapper

        property bool popup: false
        property bool removedByLimit: false
        property bool isPersistent: true
        property int seq: 0
        
        onPopupChanged: {
            if (!popup) {
                removeFromVisibleNotifications(wrapper);
            }
        }
        
        
        readonly property Timer timer: Timer {
            interval: 5000
            repeat: false
            running: false
            onTriggered: {
                wrapper.popup = false;
            }
        }
        readonly property date time: new Date()
        readonly property string timeStr: {
            const now = new Date();
            const diff = now.getTime() - time.getTime();
            const m = Math.floor(diff / 60000);
            const h = Math.floor(m / 60);

            if (h < 1 && m < 1)
                return "now";
            if (h < 1)
                return `${m}m`;
            return `${h}h`;
        }

        required property Notification notification
        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string htmlBody: {
            if (body && (body.includes('<') && body.includes('>'))) {
                return body;
            }
            return Markdown2Html.markdownToHtml(body);
        }
        readonly property string appIcon: notification.appIcon
        readonly property string appName: {
            if (notification.appName == "") {
                // try to get the app name from the desktop entry
                const entry = DesktopEntries.byId(notification.desktopEntry);
                if (entry && entry.name) {
                    return entry.name.toLowerCase();
                }
            }
            return notification.appName || "app";
        }
        readonly property string desktopEntry: notification.desktopEntry
        readonly property string image: notification.image
        readonly property string cleanImage: {
            if (!image) return "";
            if (image.startsWith("file://")) {
                return image.substring(7);
            }
            return image;
        }
        readonly property int urgency: notification.urgency
        readonly property list<NotificationAction> actions: notification.actions

        readonly property bool hasImage: image && image.length > 0
        readonly property bool hasAppIcon: appIcon && appIcon.length > 0

        readonly property Connections conn: Connections {
            target: wrapper.notification.Retainable

            function onDropped(): void {
                const notifIndex = root.notifications.indexOf(wrapper);
                const allIndex = root.allWrappers.indexOf(wrapper);
                if (allIndex !== -1) root.allWrappers.splice(allIndex, 1);
                if (notifIndex !== -1) root.notifications.splice(notifIndex, 1);

                if (root.bulkDismissing) return;

                const groupKey = getGroupKey(wrapper);
                const remainingInGroup = root.notifications.filter(n => getGroupKey(n) === groupKey);
                
                if (remainingInGroup.length <= 1) {
                    clearGroupExpansionState(groupKey);
                }
                
                cleanupExpansionStates();
            }

            function onAboutToDestroy(): void {
                wrapper.destroy();
            }
        }
    }

    Component {
        id: notifComponent
        NotifWrapper {}
    }

    function clearAllNotifications() {
        bulkDismissing = true;
        popupsDisabled = true;
        addGate.stop();
        addGateBusy = false;
        notificationQueue = [];

        for (const w of visibleNotifications) w.popup = false;
        visibleNotifications = [];

        const toDismiss = notifications.slice();

        if (notifications.length) notifications.splice(0, notifications.length);
        expandedGroups = {};
        expandedMessages = {};

        for (let i = 0; i < toDismiss.length; ++i) {
            const w = toDismiss[i];
            if (w && w.notification) {
                try { w.notification.dismiss(); } catch (e) {}
            }
        }

        bulkDismissing = false;
        popupsDisabled = false;
    }

    function dismissNotification(wrapper) {
        if (!wrapper || !wrapper.notification) return;
        wrapper.popup = false;
        wrapper.notification.dismiss();
    }
    
    function disablePopups(disable) {
        popupsDisabled = disable;
        if (disable) {
            notificationQueue = [];
            visibleNotifications = [];
            for (const notif of root.allWrappers) {
                notif.popup = false;
            }
        }
    }
    
    function processQueue() {
        if (addGateBusy) return;
        if (popupsDisabled) return;
        if (Prefs.doNotDisturb) return;
        if (notificationQueue.length === 0) return;

        const [next, ...rest] = notificationQueue;
        notificationQueue = rest;

        next.seq = ++seqCounter;
        visibleNotifications = [...visibleNotifications, next];
        next.popup = true;

        addGateBusy = true;
        addGate.restart();
    }

    function removeFromVisibleNotifications(wrapper) {
        const i = visibleNotifications.findIndex(n => n === wrapper);
        if (i !== -1) {
            const v = [...visibleNotifications]; v.splice(i, 1);
            visibleNotifications = v;
            processQueue();
        }
    }

    function releaseWrapper(w) {
        // Remove from visible
        let v = visibleNotifications.slice();
        const vi = v.indexOf(w); 
        if (vi !== -1) { 
            v.splice(vi, 1); 
            visibleNotifications = v; 
        }

        // Remove from queue
        let q = notificationQueue.slice();
        const qi = q.indexOf(w); 
        if (qi !== -1) { 
            q.splice(qi, 1); 
            notificationQueue = q; 
        }

        // Destroy wrapper if non-persistent
        if (w && w.destroy && !w.isPersistent) {
            w.destroy();
        }
    }


    // Android 16-style notification grouping functions
    function getGroupKey(wrapper) {
        // Priority 1: Use desktopEntry if available
        if (wrapper.desktopEntry && wrapper.desktopEntry !== "") {
            return wrapper.desktopEntry.toLowerCase();
        }
        
        // Priority 2: Use appName as fallback
        return wrapper.appName.toLowerCase();
    }

    function getGroupedNotifications() {
        const groups = {};
        
        for (const notif of notifications) {
            const groupKey = getGroupKey(notif);
            if (!groups[groupKey]) {
                groups[groupKey] = {
                    key: groupKey,
                    appName: notif.appName,
                    notifications: [],
                    latestNotification: null,
                    count: 0,
                    hasInlineReply: false,
                };
            }
            
            groups[groupKey].notifications.unshift(notif);
            groups[groupKey].latestNotification = groups[groupKey].notifications[0];
            groups[groupKey].count = groups[groupKey].notifications.length;
            
            if (notif.notification.hasInlineReply) {
                groups[groupKey].hasInlineReply = true;
            }
        }
        
        return Object.values(groups).sort((a, b) => {
            const aUrgency = a.latestNotification.urgency || 0;
            const bUrgency = b.latestNotification.urgency || 0;
            if (aUrgency !== bUrgency) {
                return bUrgency - aUrgency;
            }
            return b.latestNotification.time.getTime() - a.latestNotification.time.getTime();
        });
    }

    function getGroupedPopups() {
        const groups = {};
        
        for (const notif of popups) {
            const groupKey = getGroupKey(notif);
            if (!groups[groupKey]) {
                groups[groupKey] = {
                    key: groupKey,
                    appName: notif.appName,
                    notifications: [],
                    latestNotification: null,
                    count: 0,
                    hasInlineReply: false,
                };
            }
            
            groups[groupKey].notifications.unshift(notif);
            groups[groupKey].latestNotification = groups[groupKey].notifications[0];
            groups[groupKey].count = groups[groupKey].notifications.length;
            
            if (notif.notification.hasInlineReply) {
                groups[groupKey].hasInlineReply = true;
            }
        }
        
        return Object.values(groups).sort((a, b) => {
            return b.latestNotification.time.getTime() - a.latestNotification.time.getTime();
        });
    }

    function toggleGroupExpansion(groupKey) {
        let newExpandedGroups = {};
        for (const key in expandedGroups) {
            newExpandedGroups[key] = expandedGroups[key];
        }
        newExpandedGroups[groupKey] = !newExpandedGroups[groupKey];
        expandedGroups = newExpandedGroups;
    }

    function dismissGroup(groupKey) {
        const group = groupedNotifications.find(g => g.key === groupKey);
        if (group) {
            for (const notif of group.notifications) {
                if (notif && notif.notification) {
                    notif.notification.dismiss();
                }
            }
        } else {
            for (const notif of allWrappers) {
                if (notif && notif.notification && getGroupKey(notif) === groupKey) {
                    notif.notification.dismiss();
                }
            }
        }
    }
    
    function clearGroupExpansionState(groupKey) {
        let newExpandedGroups = {};
        for (const key in expandedGroups) {
            if (key !== groupKey && expandedGroups[key]) {
                newExpandedGroups[key] = true;
            }
        }
        expandedGroups = newExpandedGroups;
    }

    function cleanupExpansionStates() {
        const currentGroupKeys = new Set(groupedNotifications.map(g => g.key));
        const currentMessageIds = new Set();
        for (const group of groupedNotifications) {
            for (const notif of group.notifications) {
                currentMessageIds.add(notif.notification.id);
            }
        }
        let newExpandedGroups = {};
        for (const key in expandedGroups) {
            if (currentGroupKeys.has(key) && expandedGroups[key]) {
                newExpandedGroups[key] = true;
            }
        }
        expandedGroups = newExpandedGroups;
        let newExpandedMessages = {};
        for (const messageId in expandedMessages) {
            if (currentMessageIds.has(messageId) && expandedMessages[messageId]) {
                newExpandedMessages[messageId] = true;
            }
        }
        expandedMessages = newExpandedMessages;
    }

    function toggleMessageExpansion(messageId) {
        let newExpandedMessages = {};
        for (const key in expandedMessages) {
            newExpandedMessages[key] = expandedMessages[key];
        }
        newExpandedMessages[messageId] = !newExpandedMessages[messageId];
        expandedMessages = newExpandedMessages;
    }


    Connections {
        target: Prefs
        function onDoNotDisturbChanged() {
            if (Prefs.doNotDisturb) {
                // Hide all current popups when DND is enabled
                for (const notif of visibleNotifications) {
                    notif.popup = false;
                }
                visibleNotifications = [];
                notificationQueue = [];
            } else {
                // Re-enable popup processing when DND is disabled
                processQueue();
            }
        }
    }

}