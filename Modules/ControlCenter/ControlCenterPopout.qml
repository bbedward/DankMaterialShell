import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Common
import qs.Modules.ControlCenter
import qs.Services
import qs.Widgets

PanelWindow {
    id: root

    property bool controlCenterVisible: false
    property string currentTab: "network" // "network", "audio", "bluetooth", "display"
    property bool powerOptionsExpanded: false

    signal powerActionRequested(string action, string title, string message)
    signal lockRequested()

    visible: controlCenterVisible
    onVisibleChanged: {
        NetworkService.autoRefreshEnabled = visible && NetworkService.wifiEnabled;
        if (!visible && BluetoothService.adapter && BluetoothService.adapter.discovering)
            BluetoothService.adapter.discovering = false;

        if (visible && UserInfoService)
            UserInfoService.getUptime();

    }
    implicitWidth: 600
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

    Loader {
        id: contentLoader

        readonly property real targetWidth: Math.min(600, Screen.width - Theme.spacingL * 2)

        asynchronous: true
        active: controlCenterVisible
        width: targetWidth
        height: root.powerOptionsExpanded ? 570 : 500
        y: Theme.barHeight + Theme.spacingXS
        x: Math.max(Theme.spacingL, Screen.width - targetWidth - Theme.spacingL)
        opacity: controlCenterVisible ? 1 : 0
        scale: controlCenterVisible ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Anims.durMed
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Anims.emphasized
            }

        }

        sourceComponent: Rectangle {
            color: Theme.popupBackground()
            radius: Theme.cornerRadiusLarge
            border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
            border.width: 1
            antialiasing: true
            smooth: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Column {
                    width: parent.width
                    spacing: Theme.spacingL

                    Rectangle {
                        width: parent.width
                        height: 90
                        radius: Theme.cornerRadiusLarge
                        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.4)
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                        border.width: 1

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.spacingL
                            anchors.rightMargin: Theme.spacingL
                            spacing: Theme.spacingL

                            Item {
                                id: avatarContainer

                                property bool hasImage: profileImageLoader.status === Image.Ready

                                width: 64
                                height: 64

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: "transparent"
                                    border.color: Theme.primary
                                    border.width: 1 // The ring is 1px thick.
                                    visible: parent.hasImage
                                }

                                Image {
                                    id: profileImageLoader

                                    source: {
                                        if (Prefs.profileImage === "")
                                            return "";

                                        if (Prefs.profileImage.startsWith("/"))
                                            return "file://" + Prefs.profileImage;

                                        return Prefs.profileImage;
                                    }
                                    smooth: true
                                    asynchronous: true
                                    mipmap: true
                                    cache: true
                                    visible: false // This item is never shown directly.
                                }

                                MultiEffect {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    source: profileImageLoader
                                    maskEnabled: true
                                    maskSource: circularMask
                                    visible: avatarContainer.hasImage
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1
                                }

                                Item {
                                    id: circularMask

                                    width: 64 - 10
                                    height: 64 - 10
                                    layer.enabled: true
                                    layer.smooth: true
                                    visible: false

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "black"
                                        antialiasing: true
                                    }

                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    color: Theme.primary
                                    visible: !parent.hasImage

                                    DankIcon {
                                        anchors.centerIn: parent
                                        name: "person"
                                        size: Theme.iconSize + 8
                                        color: Theme.primaryText
                                    }

                                }

                                DankIcon {
                                    anchors.centerIn: parent
                                    name: "warning"
                                    size: Theme.iconSize + 8
                                    color: Theme.primaryText
                                    visible: Prefs.profileImage !== "" && profileImageLoader.status === Image.Error
                                }

                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingXS

                                StyledText {
                                    text: UserInfoService.fullName || UserInfoService.username || "User"
                                    font.pixelSize: Theme.fontSizeLarge
                                    color: Theme.surfaceText
                                    font.weight: Font.Medium
                                }

                                StyledText {
                                    text: "Uptime: " + (UserInfoService.uptime || "Unknown")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    font.weight: Font.Normal
                                }

                            }

                        }

                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: Theme.spacingL
                            spacing: Theme.spacingS

                            DankActionButton {
                                buttonSize: 40
                                iconName: "lock"
                                iconSize: Theme.iconSize - 2
                                iconColor: Theme.surfaceText
                                backgroundColor: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)
                                hoverColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                                onClicked: {
                                    controlCenterVisible = false;
                                    root.lockRequested();
                                }
                            }

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: powerButton.containsMouse || root.powerOptionsExpanded ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    radius: parent.radius
                                    color: "transparent"
                                    clip: true

                                    DankIcon {
                                        id: dankIcon

                                        anchors.centerIn: parent
                                        name: root.powerOptionsExpanded ? "expand_less" : "power_settings_new"
                                        size: Theme.iconSize - 2
                                        color: powerButton.containsMouse || root.powerOptionsExpanded ? Theme.error : Theme.surfaceText

                                        Behavior on name {
                                            SequentialAnimation {
                                                NumberAnimation {
                                                    target: dankIcon
                                                    property: "opacity"
                                                    to: 0
                                                    duration: Theme.shortDuration / 2
                                                    easing.type: Theme.standardEasing
                                                }

                                                PropertyAction {
                                                    target: dankIcon
                                                    property: "name"
                                                }

                                                NumberAnimation {
                                                    target: dankIcon
                                                    property: "opacity"
                                                    to: 1
                                                    duration: Theme.shortDuration / 2
                                                    easing.type: Theme.standardEasing
                                                }

                                            }

                                        }

                                    }

                                }

                                MouseArea {
                                    id: powerButton

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.powerOptionsExpanded = !root.powerOptionsExpanded;
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }

                                }

                            }

                            DankActionButton {
                                buttonSize: 40
                                iconName: "settings"
                                iconSize: Theme.iconSize - 2
                                iconColor: Theme.surfaceText
                                backgroundColor: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)
                                hoverColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                                onClicked: {
                                    controlCenterVisible = false;
                                    settingsModal.settingsVisible = true;
                                }
                            }

                        }

                    }

                    Rectangle {
                        width: parent.width
                        height: root.powerOptionsExpanded ? 60 : 0
                        radius: Theme.cornerRadius
                        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, Theme.getContentBackgroundAlpha() * 0.4)
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08)
                        border.width: root.powerOptionsExpanded ? 1 : 0
                        opacity: root.powerOptionsExpanded ? 1 : 0
                        clip: true

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingL
                            visible: root.powerOptionsExpanded

                            Rectangle {
                                width: 100
                                height: 34
                                radius: Theme.cornerRadius
                                color: logoutButton.containsMouse ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    DankIcon {
                                        name: "logout"
                                        size: Theme.fontSizeSmall
                                        color: logoutButton.containsMouse ? Theme.warning : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: "Logout"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: logoutButton.containsMouse ? Theme.warning : Theme.surfaceText
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                }

                                MouseArea {
                                    id: logoutButton

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.powerOptionsExpanded = false;
                                        root.powerActionRequested("logout", "Logout", "Are you sure you want to logout?");
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }

                                }

                            }

                            Rectangle {
                                width: 100
                                height: 34
                                radius: Theme.cornerRadius
                                color: rebootButton.containsMouse ? Qt.rgba(Theme.warning.r, Theme.warning.g, Theme.warning.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    DankIcon {
                                        name: "restart_alt"
                                        size: Theme.fontSizeSmall
                                        color: rebootButton.containsMouse ? Theme.warning : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: "Restart"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: rebootButton.containsMouse ? Theme.warning : Theme.surfaceText
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                }

                                MouseArea {
                                    id: rebootButton

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.powerOptionsExpanded = false;
                                        root.powerActionRequested("reboot", "Restart", "Are you sure you want to restart?");
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }

                                }

                            }

                            Rectangle {
                                width: 100
                                height: 34
                                radius: Theme.cornerRadius
                                color: suspendButton.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    DankIcon {
                                        name: "bedtime"
                                        size: Theme.fontSizeSmall
                                        color: suspendButton.containsMouse ? Theme.primary : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: "Suspend"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: suspendButton.containsMouse ? Theme.primary : Theme.surfaceText
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                }

                                MouseArea {
                                    id: suspendButton

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.powerOptionsExpanded = false;
                                        root.powerActionRequested("suspend", "Suspend", "Are you sure you want to suspend?");
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.shortDuration
                                        easing.type: Theme.standardEasing
                                    }

                                }

                            }

                            Rectangle {
                                width: 100
                                height: 34
                                radius: Theme.cornerRadius
                                color: shutdownButton.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.5)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    DankIcon {
                                        name: "power_settings_new"
                                        size: Theme.fontSizeSmall
                                        color: shutdownButton.containsMouse ? Theme.error : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: "Shutdown"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: shutdownButton.containsMouse ? Theme.error : Theme.surfaceText
                                        font.weight: Font.Medium
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                }

                                MouseArea {
                                    id: shutdownButton

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.powerOptionsExpanded = false;
                                        root.powerActionRequested("poweroff", "Shutdown", "Are you sure you want to shutdown?");
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

                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Theme.shortDuration
                                easing.type: Theme.standardEasing
                            }

                        }

                    }

                    Rectangle {
                        width: parent.width
                        height: tabBar.height + Theme.spacingM * 2
                        radius: Theme.cornerRadiusLarge
                        color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.15)
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.06)
                        border.width: 1

                        DankTabBar {
                            id: tabBar

                            anchors.centerIn: parent
                            width: parent.width - Theme.spacingM * 2
                            tabHeight: 40
                            currentIndex: {
                                let tabs = ["network", "audio"];
                                if (BluetoothService.available)
                                    tabs.push("bluetooth");

                                tabs.push("display");
                                return tabs.indexOf(root.currentTab);
                            }
                            model: {
                                let tabs = [{
                                    "text": "Network",
                                    "icon": "wifi",
                                    "id": "network"
                                }];
                                tabs.push({
                                    "text": "Audio",
                                    "icon": "volume_up",
                                    "id": "audio"
                                });
                                if (BluetoothService.available)
                                    tabs.push({
                                    "text": "Bluetooth",
                                    "icon": "bluetooth",
                                    "id": "bluetooth"
                                });

                                tabs.push({
                                    "text": "Display",
                                    "icon": "brightness_6",
                                    "id": "display"
                                });
                                return tabs;
                            }
                            onTabClicked: function(index) {
                                let tabs = ["network", "audio"];
                                if (BluetoothService.available)
                                    tabs.push("bluetooth");

                                tabs.push("display");
                                root.currentTab = tabs[index];
                            }
                        }

                    }

                }

                Rectangle {
                    width: parent.width
                    Layout.fillHeight: true
                    radius: Theme.cornerRadiusLarge
                    color: Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.1)
                    border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.05)
                    border.width: 1

                    NetworkTab {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        visible: root.currentTab === "network"
                    }

                    AudioTab {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        visible: root.currentTab === "audio"
                    }

                    BluetoothTab {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        visible: BluetoothService.available && root.currentTab === "bluetooth"
                    }

                    Column {
                        property var brightnessDebounceTimer

                        brightnessDebounceTimer: Timer {
                            property int pendingValue: 0

                            interval: BrightnessService.ddcAvailable ? 500 : 50
                            repeat: false
                            onTriggered: {
                                BrightnessService.setBrightness(pendingValue);
                            }
                        }

                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        visible: root.currentTab === "display"
                        spacing: Theme.spacingL
                        Column {
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: BrightnessService.brightnessAvailable

                            StyledText {
                                text: "Brightness"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                            }

                            DankSlider {
                                width: parent.width
                                height: 24
                                value: BrightnessService.brightnessLevel
                                leftIcon: "brightness_low"
                                rightIcon: "brightness_high"
                                enabled: BrightnessService.brightnessAvailable
                                showValue: true
                                onSliderValueChanged: function(newValue) {
                                    parent.parent.brightnessDebounceTimer.pendingValue = newValue;
                                    parent.parent.brightnessDebounceTimer.restart();
                                }
                                onSliderDragFinished: function(finalValue) {
                                    parent.parent.brightnessDebounceTimer.stop();
                                    BrightnessService.setBrightness(finalValue);
                                }
                            }

                            StyledText {
                                text: "ddc changes can be slow to respond"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                visible: BrightnessService.ddcAvailable && !BrightnessService.laptopBacklightAvailable
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                        }

                        DankToggle {
                            width: parent.width
                            text: "Night Mode"
                            description: "Apply warm color temperature to reduce eye strain"
                            checked: Prefs.nightModeEnabled
                            onToggled: (checked) => {
                                Prefs.setNightModeEnabled(checked);
                            }
                        }

                        DankToggle {
                            width: parent.width
                            text: "Light Mode"
                            description: "Use light theme instead of dark theme"
                            checked: Prefs.isLightMode
                            onToggled: (checked) => {
                                Prefs.setLightMode(checked);
                                Theme.isLightMode = checked;
                            }
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }

                    }

                }

            }

            Behavior on height {
                NumberAnimation {
                    duration: Theme.shortDuration // Faster for height changes
                    easing.type: Theme.standardEasing
                }

            }

        }

    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: function(mouse) {
            var localPos = mapToItem(contentLoader, mouse.x, mouse.y);
            if (localPos.x < 0 || localPos.x > contentLoader.width || localPos.y < 0 || localPos.y > contentLoader.height)
                controlCenterVisible = false;

        }
    }

}
