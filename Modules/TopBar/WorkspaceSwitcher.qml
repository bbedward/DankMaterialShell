import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets

Rectangle {
    id: root

    property string screenName: ""
    property int currentWorkspace: getDisplayActiveWorkspace()
    property var workspaceList: {
        var baseList = getDisplayWorkspaces();
        return Prefs.showWorkspacePadding ? padWorkspaces(baseList) : baseList;
    }

    function padWorkspaces(list) {
        var padded = list.slice();
        while (padded.length < 3)padded.push(-1) // Use -1 as a placeholder
        return padded;
    }

    function getDisplayWorkspaces() {
        if (!NiriService.niriAvailable || NiriService.allWorkspaces.length === 0)
            return [1, 2];

        if (!root.screenName)
            return NiriService.getCurrentOutputWorkspaceNumbers();

        var displayWorkspaces = [];
        for (var i = 0; i < NiriService.allWorkspaces.length; i++) {
            var ws = NiriService.allWorkspaces[i];
            if (ws.output === root.screenName)
                displayWorkspaces.push(ws.idx + 1);

        }
        return displayWorkspaces.length > 0 ? displayWorkspaces : [1, 2];
    }

    function getDisplayActiveWorkspace() {
        if (!NiriService.niriAvailable || NiriService.allWorkspaces.length === 0)
            return 1;

        if (!root.screenName)
            return NiriService.getCurrentWorkspaceNumber();

        for (var i = 0; i < NiriService.allWorkspaces.length; i++) {
            var ws = NiriService.allWorkspaces[i];
            if (ws.output === root.screenName && ws.is_active)
                return ws.idx + 1;

        }
        return 1;
    }

    width: Prefs.showWorkspacePadding ? Math.max(120, workspaceRow.implicitWidth + Theme.spacingL * 2) : workspaceRow.implicitWidth + Theme.spacingL * 2
    height: 30
    radius: Theme.cornerRadiusLarge
    color: {
        const baseColor = Theme.surfaceTextHover;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * Theme.widgetTransparency);
    }
    visible: NiriService.niriAvailable

    Connections {
        function onAllWorkspacesChanged() {
            root.workspaceList = Prefs.showWorkspacePadding ? root.padWorkspaces(root.getDisplayWorkspaces()) : root.getDisplayWorkspaces();
            root.currentWorkspace = root.getDisplayActiveWorkspace();
        }

        function onFocusedWorkspaceIndexChanged() {
            root.currentWorkspace = root.getDisplayActiveWorkspace();
        }

        function onNiriAvailableChanged() {
            if (NiriService.niriAvailable) {
                root.workspaceList = Prefs.showWorkspacePadding ? root.padWorkspaces(root.getDisplayWorkspaces()) : root.getDisplayWorkspaces();
                root.currentWorkspace = root.getDisplayActiveWorkspace();
            }
        }

        target: NiriService
    }

    Connections {
        function onShowWorkspacePaddingChanged() {
            var baseList = root.getDisplayWorkspaces();
            root.workspaceList = Prefs.showWorkspacePadding ? root.padWorkspaces(baseList) : baseList;
        }

        target: Prefs
    }

    Row {
        id: workspaceRow

        anchors.centerIn: parent
        spacing: Theme.spacingS

        Repeater {
            model: root.workspaceList

            Rectangle {
                property bool isActive: modelData === root.currentWorkspace
                property bool isPlaceholder: modelData === -1
                property bool isHovered: mouseArea.containsMouse
                property int sequentialNumber: index + 1

                width: isActive ? Theme.spacingXL + Theme.spacingM : Theme.spacingL + Theme.spacingXS
                height: Theme.spacingL
                radius: height / 2
                color: isActive ? Theme.primary : isPlaceholder ? Theme.surfaceTextLight : isHovered ? Theme.outlineButton : Theme.surfaceTextAlpha

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent
                    hoverEnabled: !isPlaceholder
                    cursorShape: isPlaceholder ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !isPlaceholder
                    onClicked: {
                        if (!isPlaceholder)
                            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", (modelData - 1).toString()]);

                    }
                }

                StyledText {
                    visible: Prefs.showWorkspaceIndex
                    anchors.centerIn: parent
                    text: isPlaceholder ? sequentialNumber : sequentialNumber
                    color: isActive ? Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.95) : isPlaceholder ? Theme.surfaceTextAlpha : Theme.surfaceTextMedium
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: isActive && !isPlaceholder ? Font.DemiBold : Font.Normal
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.mediumDuration
                        easing.type: Theme.emphasizedEasing
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.mediumDuration
                        easing.type: Theme.emphasizedEasing
                    }

                }

            }

        }

    }

}
