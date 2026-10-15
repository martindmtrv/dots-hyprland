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

-- Helper to assign unique, valid workspace IDs (1..100)
-- Numbers 1-9 -> IDs 1-9
-- Letters A-Z -> IDs 11-36
local function get_workspace_id(key)
    local num = tonumber(key)
    if num and num >= 1 and num <= 9 then
        return num
    end
    local byte = string.byte(string.upper(key))
    if byte >= 65 and byte <= 90 then -- A-Z
        return (byte - 65) + 11
    end
    return nil
end

-- All supported workspace keys: 1-9 and A-Z
local all_workspace_keys = {
    -- Numbers
    "1", "2", "3", "4", "5", "6", "7", "8", "9",
    -- Letters
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
}

for _, key in ipairs(all_workspace_keys) do
    local id = get_workspace_id(key)
    if id then
        -- Focus workspace: ALT + <key>
        hl.bind(workspace_mod .. " + " .. key, function()
            hl.dispatch(hl.dsp.focus({ workspace = id }))
        end, { description = "AeroSpace: Focus workspace " .. key })

        -- Move window to workspace: ALT + SHIFT + <key>
        hl.bind(workspace_move_mod .. " + " .. key, function()
            hl.dispatch(hl.dsp.window.move({ workspace = id, follow = false }))
        end, { description = "AeroSpace: Move to workspace " .. key })

        -- Register workspace name in Hyprland
        hl.config({
            workspace = {
                string.format("%d, defaultName:%s", id, key)
            }
        })
    end
end
-- <<< END AEROSPACE WORKSPACES <<<
