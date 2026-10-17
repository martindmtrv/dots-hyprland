hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- >>> BEGIN AEROSPACE WORKSPACES >>>
--------------------------------------------------------------------------------
-- AeroSpace-Style Workspaces (A-Z and 1-9)
--------------------------------------------------------------------------------
-- Navigation modifier:
--   - Focus workspace: ALT + <key>
--   - Move active window: ALT + SHIFT + <key>
-- In dots-hyprland, ALT + [A-Z] and ALT + [1-9] are 100% clash-free!
local workspace_mod = "ALT"
local workspace_move_mod = "ALT + SHIFT"

-- Single Alt tap to toggle overview (same as single Super tap)
pcall(function() hl.unbind("ALT + Alt_L") end)
pcall(function() hl.unbind("ALT + Alt_R") end)
hl.bind("ALT + Alt_L", hl.dsp.global("quickshell:searchToggleRelease"), { description = "AeroSpace: Toggle overview" })
hl.bind("ALT + Alt_R", hl.dsp.global("quickshell:searchToggleRelease"))

-- Hold Alt to preview workspace names/numbers on the bar (same as holding Super)
pcall(function() hl.unbind("Alt_L") end)
pcall(function() hl.unbind("Alt_R") end)
hl.bind("Alt_L", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true })
hl.bind("Alt_R", hl.dsp.global("quickshell:workspaceNumber"), { ignore_mods = true, transparent = true })
hl.bind("Alt_L", hl.dsp.global("quickshell:workspaceNumber"),
    { ignore_mods = true, transparent = true, release = true })
hl.bind("Alt_R", hl.dsp.global("quickshell:workspaceNumber"),
    { ignore_mods = true, transparent = true, release = true })

-- Whether to unbind dots-hyprland's default SUPER + Number workspace binds.
-- Set to true (recommended) to prevent accidentally triggering the default
-- 10-workspace group system and ensure a pure AeroSpace workflow.
local unbind_default_super_workspaces = true

if unbind_default_super_workspaces then
    local numberkeys = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
    local numpadkeys = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }

    for i = 0, 9 do
        pcall(function() hl.unbind("SUPER + " .. i) end)
        pcall(function() hl.unbind("SUPER + ALT + " .. i) end)
    end
    for _, code in ipairs(numberkeys) do
        pcall(function() hl.unbind("SUPER + code:" .. code) end)
    end
    for _, code in ipairs(numpadkeys) do
        pcall(function() hl.unbind("SUPER + code:" .. code) end)
        pcall(function() hl.unbind("SUPER + ALT + code:" .. code) end)
    end
end

-- Ensure touchpad swiping only cycles through active/occupied workspaces
-- in the exact order they appear in the Quickshell bar (without creating random new ones at the end).
hl.config({
    gestures = {
        workspace_swipe_create_new = false,
        workspace_swipe_use_r = false
    }
})

-- Rebind relative workspace step shortcuts (Ctrl+Super+Left/Right, Super+PageUp/PageDown, Super+Scroll)
-- to step through existing workspaces on the monitor (m-1 / m+1) in top-bar order.
for _, combo in ipairs({
    { "CTRL + SUPER + Left", "m-1" },
    { "CTRL + SUPER + Right", "m+1" },
    { "SUPER + Page_Up", "m-1" },
    { "SUPER + Page_Down", "m+1" },
    { "CTRL + SUPER + Page_Up", "m-1" },
    { "CTRL + SUPER + Page_Down", "m+1" },
    { "SUPER + mouse_up", "m-1" },
    { "SUPER + mouse_down", "m+1" },
    { "CTRL + SUPER + mouse_up", "m-1" },
    { "CTRL + SUPER + mouse_down", "m+1" }
}) do
    pcall(function() hl.unbind(combo[1]) end)
    hl.bind(combo[1], hl.dsp.focus({ workspace = combo[2] }))
end

-- Ordered list of workspace keys matching the Quickshell top bar and overview order:
-- Priority letters -> remaining letters (A-Z) -> numbers (1-9).
-- Assigning sequential Hyprland IDs (1..35) in this exact order ensures that
-- Hyprland's native touchpad swipe and animations follow the exact bar order.
local all_workspace_keys = {
    -- Priority letters
    "C", "V", "D", "P", "A", "T", "Z", "S",
    -- Remaining letters
    "B", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "Q", "R", "U", "W", "X", "Y",
    -- Numbers
    "1", "2", "3", "4", "5", "6", "7", "8", "9"
}

local move_locked = false

for id, key in ipairs(all_workspace_keys) do
    local bind_key = string.lower(key)

    -- Ensure no duplicate binds remain across config reloads
    pcall(function() hl.unbind(workspace_mod .. " + " .. key) end)
    pcall(function() hl.unbind(workspace_mod .. " + " .. bind_key) end)
    pcall(function() hl.unbind(workspace_move_mod .. " + " .. key) end)
    pcall(function() hl.unbind(workspace_move_mod .. " + " .. bind_key) end)

    -- Focus workspace: ALT + <key>
    hl.bind(workspace_mod .. " + " .. bind_key, function()
        hl.dispatch(hl.dsp.global("quickshell:searchToggleReleaseInterrupt"))
        hl.dispatch(hl.dsp.focus({ workspace = id }))
    end, { description = "AeroSpace: Focus workspace " .. key })

    -- Move window to workspace: ALT + SHIFT + <key>
    hl.bind(workspace_move_mod .. " + " .. bind_key, function()
        hl.dispatch(hl.dsp.global("quickshell:searchToggleReleaseInterrupt"))
        if move_locked then
            return
        end
        move_locked = true
        hl.timer(function()
            move_locked = false
        end, { timeout = 200, type = "oneshot" })
        hl.dispatch(hl.dsp.window.move({ workspace = id, follow = false }))
    end, { description = "AeroSpace: Move to workspace " .. key })

    -- Register workspace name in Hyprland
    hl.config({
        workspace = {
            string.format("%d, defaultName:%s", id, key)
        }
    })
end
-- <<< END AEROSPACE WORKSPACES <<<
