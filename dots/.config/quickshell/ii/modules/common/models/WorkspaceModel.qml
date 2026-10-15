import QtQuick
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services
import qs.modules.common as C

NestableObject {
    id: root

    required property HyprlandMonitor monitor
    readonly property var liveMonitorData: HyprlandData.monitors.find(m => m.id === monitor.id)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int activeWorkspace: monitor?.activeWorkspace?.id ?? 1
    readonly property bool currentWorkspaceNotFake: activeWindow?.activated ?? false // Active empty workspace = fake. At least, that's how I like to call it.
    readonly property int fakeWorkspace: currentWorkspaceNotFake ? -9999 : activeWorkspace
    readonly property int shownCount: C.Config.options.bar.workspaces.shown
    readonly property int group: Math.floor((activeWorkspace - 1) / shownCount)
    readonly property var specialWorkspace: liveMonitorData?.specialWorkspace
    readonly property string specialWorkspaceName: specialWorkspace?.name.replace("special:", "") ?? "special"
    readonly property bool specialWorkspaceActive: specialWorkspaceName !== ""

    readonly property bool dynamicMode: C.Config.options?.bar?.workspaces?.dynamicWorkspaces ?? false
    readonly property var configuredWorkspaceNames: C.Config.options?.bar?.workspaces?.workspaceNames ?? ["C", "V", "D", "P", "A", "T", "Z", "S"]
    readonly property bool showActiveEvenIfEmpty: C.Config.options?.bar?.workspaces?.showActiveEvenIfEmpty ?? true

    property var visibleWorkspaces: []
    property int activeVisibleIndex: {
        if (!dynamicMode || !visibleWorkspaces || visibleWorkspaces.length === 0) return 0;
        const idx = visibleWorkspaces.findIndex(ws => ws.wsId === root.activeWorkspace);
        return idx !== -1 ? idx : 0;
    }

    property list<bool> occupied: []
    property list<var> biggestWindow: occupied.map((_, index) => {
        const wsId = getWorkspaceIdAt(index);
        var biggestWindow = HyprlandData.biggestWindowForWorkspace(wsId);
        return biggestWindow;
    })

    function getWorkspaceId(group, index) {
        return group * root.shownCount + index + 1;
    }
    function getWorkspaceIdAt(index) {
        return root.getWorkspaceId(root.group, index);
    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        root.occupied = Array.from({
            length: root.shownCount
        }, (_, i) => {
            const thisWorkspaceId = getWorkspaceId(root.group, i);
            return Hyprland.workspaces.values.some(ws => ws.id === thisWorkspaceId);
        });
        if (root.dynamicMode) {
            updateDynamicWorkspaces();
        }
    }

    function getWsIdForName(name, idx) {
        if (/^[1-9]$/.test(name)) return parseInt(name, 10);
        if (/^[A-Za-z]$/.test(name)) return name.toUpperCase().charCodeAt(0) - 65 + 11;
        return idx + 1;
    }

    function updateDynamicWorkspaces() {
        const names = root.configuredWorkspaceNames || [];
        const result = [];
        const activeId = root.activeWorkspace;
        const activeWs = Hyprland.workspaces ? Hyprland.workspaces.values.find(w => w.id === activeId) : null;
        const activeName = activeWs?.name ?? "";

        for (let i = 0; i < names.length; ++i) {
            const name = names[i];
            const wsId = root.getWsIdForName(name, i);

            const hasWindows = (HyprlandData.windowList && HyprlandData.windowList.some(win => win.workspace && (win.workspace.id === wsId || win.workspace.name === name))) ||
                (Hyprland.workspaces && Hyprland.workspaces.values.some(ws => (ws.id === wsId || ws.name === name) && ws.toplevels && ws.toplevels.values.length > 0));

            const isActive = (wsId === activeId || (activeName !== "" && name === activeName));

            if (hasWindows || (isActive && root.showActiveEvenIfEmpty)) {
                result.push({
                    wsId: wsId,
                    name: name,
                    occupied: hasWindows,
                    active: isActive
                });
            }
        }

        // If currently focused workspace is not in the list, still show it so the user is never lost
        const isCurrentInResult = result.some(w => w.wsId === activeId || (activeName && w.name === activeName));
        if (root.showActiveEvenIfEmpty && !isCurrentInResult && activeId > 0) {
            result.push({
                wsId: activeId,
                name: activeName || String(activeId),
                occupied: false,
                active: true
            });
        }

        root.visibleWorkspaces = result;
    }

    // Occupied workspace updates
    Component.onCompleted: {
        updateWorkspaceOccupied();
        if (root.dynamicMode) {
            updateDynamicWorkspaces();
        }
    }
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            root.updateWorkspaceOccupied();
        }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.updateWorkspaceOccupied();
        }
    }
    Connections {
        target: HyprlandData
        function onWindowListChanged() {
            if (root.dynamicMode) {
                root.updateDynamicWorkspaces();
            }
        }
    }
    onActiveWorkspaceChanged: {
        if (root.dynamicMode) {
            root.updateDynamicWorkspaces();
        }
    }
    onGroupChanged: {
        updateWorkspaceOccupied();
    }
}

