import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Modules
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property var modelData
    property string screenName: modelData.name
    property real backgroundTransparency: Prefs.topBarTransparency
    readonly property int notificationCount: NotificationService.notifications.length

    screen: modelData
    implicitHeight: Theme.barHeight - 4
    color: "transparent"
    Component.onCompleted: {
        let fonts = Qt.fontFamilies();
        if (fonts.indexOf("Material Symbols Rounded") === -1)
            ToastService.showError("Please install Material Symbols Rounded and Restart your Shell. See README.md for instructions");

        Prefs.forceTopBarLayoutRefresh.connect(function() {
            Qt.callLater(() => {
                leftSection.visible = false;
                centerSection.visible = false;
                rightSection.visible = false;
                Qt.callLater(() => {
                    leftSection.visible = true;
                    centerSection.visible = true;
                    rightSection.visible = true;
                });
            });
        });
    }

    Connections {
        function onTopBarTransparencyChanged() {
            root.backgroundTransparency = Prefs.topBarTransparency;
        }

        target: Prefs
    }

    QtObject {
        id: notificationHistory

        property int count: 0
    }

    anchors {
        top: true
        left: true
        right: true
    }

    Item {
        anchors.fill: parent
        anchors.margins: 2
        anchors.topMargin: 6
        anchors.bottomMargin: 0
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Rectangle {
            anchors.fill: parent
            radius: Theme.cornerRadiusXLarge
            color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, root.backgroundTransparency)
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Theme.outlineMedium
                border.width: 1
                radius: parent.radius
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Theme.surfaceTint.r, Theme.surfaceTint.g, Theme.surfaceTint.b, 0.04)
                radius: parent.radius

                SequentialAnimation on opacity {
                    running: false
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.08
                        duration: Theme.extraLongDuration
                        easing.type: Theme.standardEasing
                    }

                    NumberAnimation {
                        to: 0.02
                        duration: Theme.extraLongDuration
                        easing.type: Theme.standardEasing
                    }

                }

            }

            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 4
                shadowBlur: 0.5 // radius/32, adjusted for visual match
                shadowColor: Qt.rgba(0, 0, 0, 0.15)
                shadowOpacity: 0.15
            }

        }

        Item {
            id: topBarContent

            readonly property int availableWidth: width
            readonly property int launcherButtonWidth: 40
            readonly property int workspaceSwitcherWidth: 120 // Approximate
            readonly property int focusedAppMaxWidth: 456 // Fixed width since we don't have focusedApp reference
            readonly property int estimatedLeftSectionWidth: launcherButtonWidth + workspaceSwitcherWidth + focusedAppMaxWidth + (Theme.spacingXS * 2)
            readonly property int rightSectionWidth: rightSection.width
            readonly property int clockWidth: 120 // Approximate clock width
            readonly property int mediaMaxWidth: 280 // Normal max width
            readonly property int weatherWidth: 80 // Approximate weather width
            readonly property bool validLayout: availableWidth > 100 && estimatedLeftSectionWidth > 0 && rightSectionWidth > 0
            readonly property int clockLeftEdge: (availableWidth - clockWidth) / 2
            readonly property int clockRightEdge: clockLeftEdge + clockWidth
            readonly property int leftSectionRightEdge: estimatedLeftSectionWidth
            readonly property int mediaLeftEdge: clockLeftEdge - mediaMaxWidth - Theme.spacingS
            readonly property int rightSectionLeftEdge: availableWidth - rightSectionWidth
            readonly property int leftToClockGap: Math.max(0, clockLeftEdge - leftSectionRightEdge)
            readonly property int leftToMediaGap: mediaMaxWidth > 0 ? Math.max(0, mediaLeftEdge - leftSectionRightEdge) : leftToClockGap
            readonly property int mediaToClockGap: mediaMaxWidth > 0 ? Theme.spacingS : 0
            readonly property int clockToRightGap: validLayout ? Math.max(0, rightSectionLeftEdge - clockRightEdge) : 1000
            readonly property bool spacingTight: validLayout && (leftToMediaGap < 150 || clockToRightGap < 100)
            readonly property bool overlapping: validLayout && (leftToMediaGap < 100 || clockToRightGap < 50)

            function getWidgetEnabled(enabled) {
                return enabled !== undefined ? enabled : true;
            }

            function getWidgetVisible(widgetId) {
                switch (widgetId) {
                case "launcherButton":
                    return true;
                case "workspaceSwitcher":
                    return true;
                case "focusedWindow":
                    return true;
                case "clock":
                    return true;
                case "music":
                    return true;
                case "weather":
                    return true;
                case "systemTray":
                    return true;
                case "clipboard":
                    return true;
                case "systemResources":
                    return true;
                case "notificationButton":
                    return true;
                case "battery":
                    return true;
                case "controlCenterButton":
                    return true;
                case "spacer":
                    return true;
                case "separator":
                    return true;
                default:
                    return false;
                }
            }

            function getWidgetComponent(widgetId) {
                switch (widgetId) {
                case "launcherButton":
                    return launcherButtonComponent;
                case "workspaceSwitcher":
                    return workspaceSwitcherComponent;
                case "focusedWindow":
                    return focusedWindowComponent;
                case "clock":
                    return clockComponent;
                case "music":
                    return mediaComponent;
                case "weather":
                    return weatherComponent;
                case "systemTray":
                    return systemTrayComponent;
                case "clipboard":
                    return clipboardComponent;
                case "systemResources":
                    return systemResourcesComponent;
                case "notificationButton":
                    return notificationButtonComponent;
                case "battery":
                    return batteryComponent;
                case "controlCenterButton":
                    return controlCenterButtonComponent;
                case "spacer":
                    return spacerComponent;
                case "separator":
                    return separatorComponent;
                default:
                    return null;
                }
            }

            anchors.fill: parent
            anchors.leftMargin: Theme.spacingM
            anchors.rightMargin: Theme.spacingM
            anchors.topMargin: Theme.spacingXS
            anchors.bottomMargin: Theme.spacingXS
            clip: true

            Row {
                id: leftSection

                height: parent.height
                spacing: Theme.spacingXS
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: Prefs.topBarLeftWidgetsModel

                    Loader {
                        property string widgetId: model.widgetId
                        property var widgetData: model
                        property int spacerSize: model.size || 20

                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        active: topBarContent.getWidgetVisible(model.widgetId)
                        sourceComponent: topBarContent.getWidgetComponent(model.widgetId)
                        opacity: topBarContent.getWidgetEnabled(model.enabled) ? 1 : 0
                    }

                }

            }

            Item {
                id: centerSection

                property var centerWidgets: []
                property int totalWidgets: 0
                property real totalWidth: 0
                property real spacing: Theme.spacingS

                function updateLayout() {
                    centerWidgets = [];
                    totalWidgets = 0;
                    totalWidth = 0;
                    for (let i = 0; i < centerRepeater.count; i++) {
                        let item = centerRepeater.itemAt(i);
                        if (item && item.active && item.item) {
                            centerWidgets.push(item.item);
                            totalWidgets++;
                            totalWidth += item.item.width;
                        }
                    }
                    if (totalWidgets > 1)
                        totalWidth += spacing * (totalWidgets - 1);

                    positionWidgets();
                }

                function positionWidgets() {
                    if (totalWidgets === 0)
                        return ;

                    let parentCenterX = width / 2;
                    if (totalWidgets % 2 === 1) {
                        let middleIndex = Math.floor(totalWidgets / 2);
                        let currentX = parentCenterX - (centerWidgets[middleIndex].width / 2);
                        centerWidgets[middleIndex].x = currentX;
                        centerWidgets[middleIndex].anchors.horizontalCenter = undefined;
                        currentX = centerWidgets[middleIndex].x;
                        for (let i = middleIndex - 1; i >= 0; i--) {
                            currentX -= (spacing + centerWidgets[i].width);
                            centerWidgets[i].x = currentX;
                            centerWidgets[i].anchors.horizontalCenter = undefined;
                        }
                        currentX = centerWidgets[middleIndex].x + centerWidgets[middleIndex].width;
                        for (let i = middleIndex + 1; i < totalWidgets; i++) {
                            currentX += spacing;
                            centerWidgets[i].x = currentX;
                            centerWidgets[i].anchors.horizontalCenter = undefined;
                            currentX += centerWidgets[i].width;
                        }
                    } else {
                        let leftMiddleIndex = (totalWidgets / 2) - 1;
                        let rightMiddleIndex = totalWidgets / 2;
                        let gapCenter = parentCenterX;
                        let halfSpacing = spacing / 2;
                        centerWidgets[leftMiddleIndex].x = gapCenter - halfSpacing - centerWidgets[leftMiddleIndex].width;
                        centerWidgets[leftMiddleIndex].anchors.horizontalCenter = undefined;
                        centerWidgets[rightMiddleIndex].x = gapCenter + halfSpacing;
                        centerWidgets[rightMiddleIndex].anchors.horizontalCenter = undefined;
                        let currentX = centerWidgets[leftMiddleIndex].x;
                        for (let i = leftMiddleIndex - 1; i >= 0; i--) {
                            currentX -= (spacing + centerWidgets[i].width);
                            centerWidgets[i].x = currentX;
                            centerWidgets[i].anchors.horizontalCenter = undefined;
                        }
                        currentX = centerWidgets[rightMiddleIndex].x + centerWidgets[rightMiddleIndex].width;
                        for (let i = rightMiddleIndex + 1; i < totalWidgets; i++) {
                            currentX += spacing;
                            centerWidgets[i].x = currentX;
                            centerWidgets[i].anchors.horizontalCenter = undefined;
                            currentX += centerWidgets[i].width;
                        }
                    }
                }

                height: parent.height
                width: parent.width
                anchors.centerIn: parent
                Component.onCompleted: {
                    Qt.callLater(() => {
                        Qt.callLater(updateLayout);
                    });
                }

                Repeater {
                    id: centerRepeater

                    model: Prefs.topBarCenterWidgetsModel

                    Loader {
                        property string widgetId: model.widgetId
                        property var widgetData: model
                        property int spacerSize: model.size || 20

                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        active: topBarContent.getWidgetVisible(model.widgetId)
                        sourceComponent: topBarContent.getWidgetComponent(model.widgetId)
                        opacity: topBarContent.getWidgetEnabled(model.enabled) ? 1 : 0
                        onLoaded: {
                            if (item) {
                                item.onWidthChanged.connect(centerSection.updateLayout);
                                if (model.widgetId === "spacer")
                                    item.spacerSize = Qt.binding(() => {
                                    return model.size || 20;
                                });

                                Qt.callLater(centerSection.updateLayout);
                            }
                        }
                        onActiveChanged: {
                            Qt.callLater(centerSection.updateLayout);
                        }
                    }

                }

                Connections {
                    function onCountChanged() {
                        Qt.callLater(centerSection.updateLayout);
                    }

                    target: Prefs.topBarCenterWidgetsModel
                }

            }

            Row {
                id: rightSection

                height: parent.height
                spacing: Theme.spacingXS
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: Prefs.topBarRightWidgetsModel

                    Loader {
                        property string widgetId: model.widgetId
                        property var widgetData: model
                        property int spacerSize: model.size || 20

                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        active: topBarContent.getWidgetVisible(model.widgetId)
                        sourceComponent: topBarContent.getWidgetComponent(model.widgetId)
                        opacity: topBarContent.getWidgetEnabled(model.enabled) ? 1 : 0
                    }

                }

            }

            Component {
                id: launcherButtonComponent

                LauncherButton {
                    isActive: appDrawerPopout ? appDrawerPopout.isVisible : false
                    onClicked: {
                        if (appDrawerPopout)
                            appDrawerPopout.toggle();

                    }
                }

            }

            Component {
                id: workspaceSwitcherComponent

                WorkspaceSwitcher {
                    screenName: root.screenName
                }

            }

            Component {
                id: focusedWindowComponent

                FocusedApp {
                    compactMode: topBarContent.spacingTight
                    availableWidth: topBarContent.leftToMediaGap
                }

            }

            Component {
                id: clockComponent

                Clock {
                    compactMode: topBarContent.overlapping
                    onClockClicked: {
                        centcomPopout.calendarVisible = !centcomPopout.calendarVisible;
                    }
                }

            }

            Component {
                id: mediaComponent

                Media {
                    compactMode: topBarContent.spacingTight || topBarContent.overlapping
                    onClicked: {
                        centcomPopout.calendarVisible = !centcomPopout.calendarVisible;
                    }
                }

            }

            Component {
                id: weatherComponent

                Weather {
                    onClicked: {
                        centcomPopout.calendarVisible = !centcomPopout.calendarVisible;
                    }
                }

            }

            Component {
                id: systemTrayComponent

                SystemTrayBar {
                    onMenuRequested: (menu, item, x, y) => {
                        systemTrayContextMenu.currentTrayMenu = menu;
                        systemTrayContextMenu.currentTrayItem = item;
                        systemTrayContextMenu.contextMenuX = rightSection.x + rightSection.width - 400 - Theme.spacingL;
                        systemTrayContextMenu.contextMenuY = Theme.barHeight - Theme.spacingXS;
                        systemTrayContextMenu.showContextMenu = true;
                        menu.menuVisible = true;
                    }
                }

            }

            Component {
                id: clipboardComponent

                Rectangle {
                    width: 40
                    height: 30
                    radius: Theme.cornerRadius
                    color: {
                        const baseColor = clipboardArea.containsMouse ? Theme.primaryHover : Theme.secondaryHover;
                        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "content_paste"
                        size: Theme.iconSize - 6
                        color: Theme.surfaceText
                    }

                    MouseArea {
                        id: clipboardArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            clipboardHistoryModalPopup.toggle();
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

            Component {
                id: systemResourcesComponent

                Row {
                    spacing: Theme.spacingXS

                    CpuMonitor {
                        toggleProcessList: () => {
                            return processListPopout.toggle();
                        }
                    }

                    RamMonitor {
                        toggleProcessList: () => {
                            return processListPopout.toggle();
                        }
                    }

                }

            }

            Component {
                id: notificationButtonComponent

                NotificationCenterButton {
                    hasUnread: root.notificationCount > 0
                    isActive: notificationCenter.notificationHistoryVisible
                    onClicked: {
                        notificationCenter.notificationHistoryVisible = !notificationCenter.notificationHistoryVisible;
                    }
                }

            }

            Component {
                id: batteryComponent

                Battery {
                    batteryPopupVisible: batteryPopout.batteryPopupVisible
                    onToggleBatteryPopup: {
                        batteryPopout.batteryPopupVisible = !batteryPopout.batteryPopupVisible;
                    }
                }

            }

            Component {
                id: controlCenterButtonComponent

                ControlCenterButton {
                    isActive: controlCenterPopout.controlCenterVisible
                    onClicked: {
                        controlCenterPopout.controlCenterVisible = !controlCenterPopout.controlCenterVisible;
                        if (controlCenterPopout.controlCenterVisible) {
                            if (NetworkService.wifiEnabled)
                                NetworkService.scanWifi();

                        }
                    }
                }

            }

            Component {
                id: spacerComponent

                Item {
                    width: parent.spacerSize || 20
                    height: 30

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                        border.width: 1
                        radius: 2
                        visible: false

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.visible = true
                            onExited: parent.visible = false
                        }

                    }

                }

            }

            Component {
                id: separatorComponent

                Rectangle {
                    width: 1
                    height: 20
                    color: Theme.outline
                    opacity: 0.3
                }

            }

        }

    }

}
