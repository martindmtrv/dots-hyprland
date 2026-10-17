hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- >>> BEGIN AEROSPACE WORKSPACES >>>
--------------------------------------------------------------------------------
-- AeroSpace-Style Workspaces on SUPER (A-Z and 1-9)
--------------------------------------------------------------------------------
-- Navigation modifier:
--   - Focus workspace: SUPER + <key>
--   - Move active window: SUPER + SHIFT + <key>
-- System and app shortcuts previously using SUPER + Letter are cleanly remapped
-- to SUPER + CTRL + <key> (or standard keys like SUPER + Backspace / Print) so
-- in-window ALT shortcuts (Alt+F, Alt+B, Alt+D, Alt+1..9) remain 100% free!
local workspace_mod = "SUPER"
local workspace_move_mod = "SUPER + SHIFT"

--------------------------------------------------------------------------------
-- 1. Unbind default dots-hyprland shortcuts that clash with SUPER + [A-Z, 1-9]
--------------------------------------------------------------------------------
local clashes_to_unbind = {
    -- Window & Workspace controls
    "SUPER + Q",
    "SUPER + F",
    "SUPER + D",
    "SUPER + P",
    "SUPER + S",
    "SUPER + ALT + S",
    -- App launchers
    "SUPER + T",
    "SUPER + W",
    "SUPER + E",
    "SUPER + C",
    "SUPER + X",
    "SUPER + I",
    -- Shell panels & sidebars
    "SUPER + V",
    "SUPER + A",
    "SUPER + B",
    "SUPER + O",
    "SUPER + N",
    "SUPER + G",
    "SUPER + J",
    "SUPER + K",
    "SUPER + M",
    "SUPER + L",
    "SUPER + SHIFT + L",
    -- Utilities & Media
    "SUPER + SHIFT + S",
    "SUPER + SHIFT + R",
    "SUPER + ALT + R",
    "SUPER + SHIFT + A",
    "SUPER + SHIFT + C",
    "SUPER + SHIFT + T",
    "SUPER + SHIFT + X",
    "SUPER + SHIFT + M",
    "SUPER + SHIFT + N",
    "SUPER + SHIFT + P",
    "SUPER + SHIFT + B",
}

for _, bind in ipairs(clashes_to_unbind) do
    pcall(function() hl.unbind(bind) end)
end

-- Also unbind legacy default 10-group workspace bindings
local numberkeys = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
local numpadkeys = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }

for i = 0, 9 do
    pcall(function() hl.unbind("SUPER + " .. i) end)
    pcall(function() hl.unbind("SUPER + SHIFT + " .. i) end)
    pcall(function() hl.unbind("SUPER + ALT + " .. i) end)
end
for _, code in ipairs(numberkeys) do
    pcall(function() hl.unbind("SUPER + code:" .. code) end)
    pcall(function() hl.unbind("SUPER + SHIFT + code:" .. code) end)
end
for _, code in ipairs(numpadkeys) do
    pcall(function() hl.unbind("SUPER + code:" .. code) end)
    pcall(function() hl.unbind("SUPER + SHIFT + code:" .. code) end)
    pcall(function() hl.unbind("SUPER + ALT + code:" .. code) end)
end

--------------------------------------------------------------------------------
-- 2. Remap system actions to clean shortcuts (automatically listed in SUPER + /)
--------------------------------------------------------------------------------
-- Window Management
hl.bind("SUPER + Backspace", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("SUPER + CTRL + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "Window: Toggle fullscreen" })
hl.bind("SUPER + CTRL + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), { description = "Window: Toggle maximize" })
hl.bind("SUPER + CTRL + P", hl.dsp.window.pin(), { description = "Window: Pin" })

-- Scratchpad / Special Workspace (Grave key = ` / ~)
hl.bind("SUPER + Grave", hl.dsp.workspace.toggle_special("special"), { description = "Workspace: Toggle scratchpad" })
hl.bind("SUPER + CTRL + S", hl.dsp.workspace.toggle_special("special"))
hl.bind("SUPER + SHIFT + Grave", hl.dsp.window.move({ workspace = "special:special", follow = false }), { description = "Workspace: Send to scratchpad" })
hl.bind("SUPER + CTRL + SHIFT + S", hl.dsp.window.move({ workspace = "special:special", follow = false }))

-- Clipboard History
hl.bind("SUPER + Space", hl.dsp.global("quickshell:overviewClipboardToggle"), { description = "Shell: Clipboard history" })
hl.bind("SUPER + CTRL + V", hl.dsp.global("quickshell:overviewClipboardToggle"))

-- Screen Capture & Utilities
hl.bind("Print", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })
hl.bind("SUPER + Print", hl.dsp.global("quickshell:regionScreenshot"))
hl.bind("SUPER + CTRL + S", hl.dsp.global("quickshell:regionScreenshot"))
hl.bind("SUPER + CTRL + R", hl.dsp.global("quickshell:regionRecord"), { description = "Utilities: Screen record" })
hl.bind("SUPER + CTRL + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Utilities: Color picker" })
hl.bind("SUPER + CTRL + SHIFT + A", hl.dsp.global("quickshell:regionSearch"), { description = "Utilities: Google Lens" })
hl.bind("SUPER + CTRL + SHIFT + X", hl.dsp.global("quickshell:regionOcr"), { description = "Utilities: Screen OCR" })
hl.bind("SUPER + CTRL + SHIFT + T", hl.dsp.global("quickshell:screenTranslate"), { description = "Utilities: Screen translate" })

-- App Launchers (Terminal is already SUPER + Return)
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd(browser), { description = "App: Browser" })
hl.bind("SUPER + CTRL + E", hl.dsp.exec_cmd(fileManager), { description = "App: File manager" })
hl.bind("SUPER + CTRL + C", hl.dsp.exec_cmd(codeEditor), { description = "App: Code editor" })
hl.bind("SUPER + CTRL + X", hl.dsp.exec_cmd(textEditor), { description = "App: Text editor" })
hl.bind("SUPER + CTRL + I", hl.dsp.exec_cmd(settingsApp), { description = "App: Settings app" })

-- Shell Panels & Session
hl.bind("SUPER + CTRL + A", hl.dsp.global("quickshell:sidebarLeftToggle"), { description = "Shell: Toggle left sidebar" })
hl.bind("SUPER + CTRL + N", hl.dsp.global("quickshell:sidebarRightToggle"), { description = "Shell: Toggle right sidebar" })
hl.bind("SUPER + CTRL + G", hl.dsp.global("quickshell:overlayToggle"), { description = "Shell: Toggle widget overlay" })
hl.bind("SUPER + CTRL + J", hl.dsp.global("quickshell:barToggle"), { description = "Shell: Toggle bar" })
hl.bind("SUPER + CTRL + K", hl.dsp.global("quickshell:oskToggle"), { description = "Shell: Toggle on-screen keyboard" })
hl.bind("SUPER + CTRL + M", hl.dsp.global("quickshell:mediaControlsToggle"), { description = "Shell: Toggle media controls" })
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Session: Lock" })
hl.bind("SUPER + CTRL + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"), { description = "Session: Suspend" })

--------------------------------------------------------------------------------
-- 3. Touchpad Swiping Configuration (Bounded)
--------------------------------------------------------------------------------
hl.config({
    gestures = {
        workspace_swipe_create_new = false,
        workspace_swipe_use_r = false
    }
})

-- Rebind relative workspace step shortcuts
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

--------------------------------------------------------------------------------
-- 4. AeroSpace Workspaces (SUPER + [A-Z] and SUPER + [1-9])
--------------------------------------------------------------------------------
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

    pcall(function() hl.unbind(workspace_mod .. " + " .. key) end)
    pcall(function() hl.unbind(workspace_mod .. " + " .. bind_key) end)
    pcall(function() hl.unbind(workspace_move_mod .. " + " .. key) end)
    pcall(function() hl.unbind(workspace_move_mod .. " + " .. bind_key) end)

    local is_first = (id == 1)
    local focus_desc = is_first and { description = "Workspace: Focus workspace" } or {}
    local move_desc = is_first and { description = "Workspace: Move window to workspace" } or {}

    -- Focus workspace: SUPER + <key>
    hl.bind(workspace_mod .. " + " .. bind_key, function()
        hl.dispatch(hl.dsp.global("quickshell:searchToggleReleaseInterrupt"))
        hl.dispatch(hl.dsp.focus({ workspace = id }))
    end, focus_desc)

    -- Move window to workspace: SUPER + SHIFT + <key>
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
    end, move_desc)

    -- Register workspace default name in Hyprland
    hl.workspace_rule({
        workspace = tostring(id),
        default_name = key
    })
end

-- Also register default names for subsequent numbered workspaces (10..24 -> IDs 36..50)
for num = 10, 24 do
    local id = 26 + num
    hl.workspace_rule({
        workspace = tostring(id),
        default_name = tostring(num)
    })
end
-- <<< END AEROSPACE WORKSPACES <<<
