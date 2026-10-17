#!/usr/bin/env bash
# apply-aerospace-workspaces.sh
# Manages AeroSpace-style dynamic named workspaces for dots-hyprland.
# Supports automatic backups, safe application, and clean reversion.
#
# Usage:
#   ./apply-aerospace-workspaces.sh          # Backup & apply
#   ./apply-aerospace-workspaces.sh --revert # Restore original files & settings
#   ./apply-aerospace-workspaces.sh --status # Check current state

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
HYPR_CUSTOM_DIR="$CONFIG_DIR/hypr/custom"
QUICKSHELL_DIR="$CONFIG_DIR/quickshell/ii"
II_CONFIG_FILE="$CONFIG_DIR/illogical-impulse/config.json"
BACKUP_BASE_DIR="$CONFIG_DIR/aerospace-workspaces-backup"
LATEST_BACKUP="$BACKUP_BASE_DIR/latest"

reload_services() {
    if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null; then
        echo "==> Reloading Hyprland..."
        hyprctl reload || true
    fi

    if command -v qs &>/dev/null; then
        echo "==> Restarting Quickshell..."
        killall qs quickshell 2>/dev/null || true
        sleep 0.3
        if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null; then
            hyprctl dispatch 'hl.dsp.exec_cmd("qs -c ii")' >/dev/null 2>&1 || hyprctl dispatch exec "qs -c ii" >/dev/null 2>&1 || (nohup qs -c ii >/dev/null 2>&1 &)
        else
            nohup qs -c ii >/dev/null 2>&1 &
        fi
    fi
}

merge_keybinds() {
    local src="$1"
    local dst="$2"

    python3 -c "
import sys, re, os

src_file = sys.argv[1]
dst_file = sys.argv[2]

with open(src_file, 'r') as f:
    src_content = f.read()

start_marker = '-- >>> BEGIN AEROSPACE WORKSPACES >>>'
end_marker = '-- <<< END AEROSPACE WORKSPACES <<<'

match = re.search(r'(' + re.escape(start_marker) + r'.*?' + re.escape(end_marker) + r')', src_content, re.DOTALL)
if match:
    block = match.group(1)
else:
    block = start_marker + '\n' + src_content.strip() + '\n' + end_marker

if not os.path.exists(dst_file):
    os.makedirs(os.path.dirname(dst_file), exist_ok=True)
    with open(dst_file, 'w') as f:
        f.write(block + '\n')
    print('==> Created ' + dst_file + ' with AeroSpace keybinds.')
else:
    with open(dst_file, 'r') as f:
        dst_content = f.read()

    pattern = re.compile(re.escape(start_marker) + r'.*?' + re.escape(end_marker), re.DOTALL)
    if pattern.search(dst_content):
        new_content = pattern.sub(block, dst_content)
        print('==> Updated existing AeroSpace block in ' + dst_file + ' (preserved your existing custom keybinds).')
    else:
        new_content = dst_content.rstrip() + '\n\n' + block + '\n'
        print('==> Appended AeroSpace keybinds into ' + dst_file + ' (preserved your existing custom keybinds).')

    with open(dst_file, 'w') as f:
        f.write(new_content)
" "$src" "$dst"
}

do_status() {
    echo "=== AeroSpace Dynamic Workspaces Status ==="
    if [ -f "$HYPR_CUSTOM_DIR/keybinds.lua" ] && grep -q "AeroSpace-Style Workspaces" "$HYPR_CUSTOM_DIR/keybinds.lua" 2>/dev/null; then
        echo "• Hyprland Keybinds: APPLIED (ALT + A-Z, 1-9 in $HYPR_CUSTOM_DIR/keybinds.lua)"
    else
        echo "• Hyprland Keybinds: STOCK / NOT APPLIED"
    fi

    if [ -f "$QUICKSHELL_DIR/modules/common/models/WorkspaceModel.qml" ] && grep -q "dynamicMode" "$QUICKSHELL_DIR/modules/common/models/WorkspaceModel.qml" 2>/dev/null; then
        echo "• Quickshell Bar:     APPLIED (dynamic mode supported)"
    else
        echo "• Quickshell Bar:     STOCK / NOT APPLIED"
    fi

    if [ -d "$LATEST_BACKUP" ]; then
        echo "• Available Backup:   YES ($LATEST_BACKUP)"
    else
        echo "• Available Backup:   NONE"
    fi
}

do_revert() {
    echo "==> Reverting AeroSpace dynamic workspaces..."

    if [ ! -d "$LATEST_BACKUP" ]; then
        echo "Error: No backup found in $LATEST_BACKUP"
        echo "Cannot automatically restore files without a backup."
        exit 1
    fi

    # 1. Restore Hyprland custom keybinds
    if [ -f "$LATEST_BACKUP/keybinds.lua" ]; then
        echo "==> Restoring $HYPR_CUSTOM_DIR/keybinds.lua from backup"
        cp -f "$LATEST_BACKUP/keybinds.lua" "$HYPR_CUSTOM_DIR/keybinds.lua"
    elif [ -f "$LATEST_BACKUP/.keybinds_did_not_exist" ]; then
        echo "==> Removing $HYPR_CUSTOM_DIR/keybinds.lua (did not exist before apply)"
        rm -f "$HYPR_CUSTOM_DIR/keybinds.lua"
    fi

    # 2. Restore Quickshell files
    if [ -d "$QUICKSHELL_DIR" ]; then
        for file in "modules/common/Config.qml" \
                    "modules/common/models/WorkspaceModel.qml" \
                    "modules/ii/bar/Workspaces.qml" \
                    "modules/ii/overview/OverviewWidget.qml" \
                    "modules/settings/BarConfig.qml" \
                    "modules/ii/cheatsheet/CheatsheetKeybindsCategory.qml"; do
            if [ -f "$LATEST_BACKUP/quickshell/$file" ]; then
                echo "==> Restoring $QUICKSHELL_DIR/$file"
                mkdir -p "$(dirname "$QUICKSHELL_DIR/$file")"
                cp -f "$LATEST_BACKUP/quickshell/$file" "$QUICKSHELL_DIR/$file"
            elif [ -f "$QUICKSHELL_DIR/$file" ]; then
                echo "==> Removing $QUICKSHELL_DIR/$file (did not exist before apply)"
                rm -f "$QUICKSHELL_DIR/$file"
            fi
        done
    fi

    # 3. Restore or disable in illogical-impulse config.json
    if [ -f "$LATEST_BACKUP/config.json" ]; then
        echo "==> Restoring original $II_CONFIG_FILE"
        cp -f "$LATEST_BACKUP/config.json" "$II_CONFIG_FILE"
    elif [ -f "$II_CONFIG_FILE" ]; then
        echo "==> Disabling dynamicWorkspaces in $II_CONFIG_FILE"
        python3 -c "
import json
path = '$II_CONFIG_FILE'
try:
    with open(path, 'r') as f:
        data = json.load(f)
    if 'bar' in data and 'workspaces' in data['bar']:
        data['bar']['workspaces']['dynamicWorkspaces'] = False
    with open(path, 'w') as f:
        json.dump(data, f, indent=4)
except Exception:
    pass
" || true
    fi

    # 4. Reload services
    reload_services

    echo "==> Reversion complete! Your setup has been restored to the pre-apply state."
}

do_apply() {
    echo "==> Preparing to apply AeroSpace dynamic named workspaces..."

    if [ ! -d "$LATEST_BACKUP" ] || [ ! -f "$QUICKSHELL_DIR/modules/common/models/WorkspaceModel.qml" ]; then
        # Create backup directory timestamped and link latest
        TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
        BACKUP_DIR="$BACKUP_BASE_DIR/$TIMESTAMP"
        mkdir -p "$BACKUP_DIR/quickshell"

        echo "==> Creating backup in $BACKUP_DIR..."

        # 1. Backup Hyprland custom keybinds
        if [ -f "$HYPR_CUSTOM_DIR/keybinds.lua" ]; then
            cp -f "$HYPR_CUSTOM_DIR/keybinds.lua" "$BACKUP_DIR/keybinds.lua"
        else
            touch "$BACKUP_DIR/.keybinds_did_not_exist"
        fi

        # 2. Backup Quickshell components
        if [ -d "$QUICKSHELL_DIR" ]; then
            for file in "modules/common/Config.qml" \
                        "modules/common/models/WorkspaceModel.qml" \
                        "modules/ii/bar/Workspaces.qml" \
                        "modules/ii/overview/OverviewWidget.qml" \
                        "modules/settings/BarConfig.qml" \
                        "modules/ii/cheatsheet/CheatsheetKeybindsCategory.qml"; do
                if [ -f "$QUICKSHELL_DIR/$file" ]; then
                    mkdir -p "$(dirname "$BACKUP_DIR/quickshell/$file")"
                    cp -f "$QUICKSHELL_DIR/$file" "$BACKUP_DIR/quickshell/$file"
                fi
            done
        fi

        # 3. Backup config.json
        if [ -f "$II_CONFIG_FILE" ]; then
            cp -f "$II_CONFIG_FILE" "$BACKUP_DIR/config.json"
        fi

        # Update 'latest' symlink
        rm -rf "$LATEST_BACKUP"
        ln -sfn "$BACKUP_DIR" "$LATEST_BACKUP"
        echo "==> Backup created and linked to $LATEST_BACKUP"
    else
        echo "==> Already applied; preserving existing clean backup at $LATEST_BACKUP"
    fi

    # --- APPLY CHANGES ---

    # 1. Hyprland keybinds
    mkdir -p "$HYPR_CUSTOM_DIR"
    KEYBINDS_SRC="$SCRIPT_DIR/dots/.config/hypr/custom/keybinds.lua"
    KEYBINDS_DST="$HYPR_CUSTOM_DIR/keybinds.lua"
    if [ -f "$KEYBINDS_SRC" ]; then
        echo "==> Configuring Hyprland keybinds in $KEYBINDS_DST..."
        merge_keybinds "$KEYBINDS_SRC" "$KEYBINDS_DST"
    fi

    # 2. Quickshell components
    if [ -d "$QUICKSHELL_DIR" ]; then
        echo "==> Updating Quickshell workspace components in $QUICKSHELL_DIR"
        cp -f "$SCRIPT_DIR/dots/.config/quickshell/ii/modules/common/Config.qml" "$QUICKSHELL_DIR/modules/common/Config.qml"
        cp -f "$SCRIPT_DIR/dots/.config/quickshell/ii/modules/common/models/WorkspaceModel.qml" "$QUICKSHELL_DIR/modules/common/models/WorkspaceModel.qml"
        cp -f "$SCRIPT_DIR/dots/.config/quickshell/ii/modules/ii/bar/Workspaces.qml" "$QUICKSHELL_DIR/modules/ii/bar/Workspaces.qml"
        cp -f "$SCRIPT_DIR/dots/.config/quickshell/ii/modules/ii/overview/OverviewWidget.qml" "$QUICKSHELL_DIR/modules/ii/overview/OverviewWidget.qml"
        cp -f "$SCRIPT_DIR/dots/.config/quickshell/ii/modules/settings/BarConfig.qml" "$QUICKSHELL_DIR/modules/settings/BarConfig.qml"
        cp -f "$SCRIPT_DIR/dots/.config/quickshell/ii/modules/ii/cheatsheet/CheatsheetKeybindsCategory.qml" "$QUICKSHELL_DIR/modules/ii/cheatsheet/CheatsheetKeybindsCategory.qml"
    fi

    # 3. Enable in ~/.config/illogical-impulse/config.json
    if [ -f "$II_CONFIG_FILE" ]; then
        echo "==> Enabling dynamic workspaces in $II_CONFIG_FILE"
        python3 -c "
import json

path = '$II_CONFIG_FILE'
try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}

if 'bar' not in data:
    data['bar'] = {}
if 'workspaces' not in data['bar']:
    data['bar']['workspaces'] = {}

data['bar']['workspaces']['dynamicWorkspaces'] = True
data['bar']['workspaces']['workspaceNames'] = [
    'C', 'V', 'D', 'P', 'A', 'T', 'Z', 'S',
    'B', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'Q', 'R', 'U', 'W', 'X', 'Y',
    '1', '2', '3', '4', '5', '6', '7', '8', '9'
]
data['bar']['workspaces']['showActiveEvenIfEmpty'] = True

with open(path, 'w') as f:
    json.dump(data, f, indent=4)
"
        echo "==> Configuration updated successfully."
    else
        echo "==> Note: $II_CONFIG_FILE not found yet (will be created automatically when Quickshell runs)."
    fi

    # 4. Reload services
    reload_services

    echo "==> Done! AeroSpace dynamic workspaces are now active."
    echo "==> If you ever want to revert, run: $0 --revert"
}

# Command dispatch
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-apply}" in
        revert|--revert|-r)
            do_revert
            ;;
        status|--status|-s)
            do_status
            ;;
        apply|--apply|-a)
            do_apply
            ;;
        help|--help|-h)
            echo "Usage: $0 [apply|revert|status]"
            echo "  apply   (default) Back up existing files and apply AeroSpace dynamic workspaces"
            echo "  revert  Restore original files from the latest backup"
            echo "  status  Show current status of AeroSpace workspaces"
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [apply|revert|status]"
            exit 1
            ;;
    esac
fi
