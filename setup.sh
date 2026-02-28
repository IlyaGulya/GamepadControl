#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓] $1${NC}"; }
warn()  { echo -e "${YELLOW}[!] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Install dependencies ---

echo ""
echo "=== Installing dependencies ==="

if ! command -v brew &>/dev/null; then
    error "Homebrew not found. Install it first: https://brew.sh"
fi

if ! command -v aerospace &>/dev/null; then
    echo "Installing AeroSpace..."
    brew install --cask nikitabobko/tap/aerospace
    info "AeroSpace installed"
else
    info "AeroSpace already installed"
fi

if ! brew list sdl2 &>/dev/null; then
    echo "Installing SDL2..."
    brew install sdl2
    info "SDL2 installed"
else
    info "SDL2 already installed"
fi

if ! command -v cargo &>/dev/null; then
    error "Rust/Cargo not found. Install it first: https://rustup.rs"
fi

GAMACROS_REPO="https://github.com/IlyaGulya/gamacros.git"
export LIBRARY_PATH="$(brew --prefix)/lib${LIBRARY_PATH:+:$LIBRARY_PATH}"

if ! command -v gamacrosd &>/dev/null; then
    echo "Installing gamacros from fork..."
    cargo install --git "$GAMACROS_REPO" gamacrosd
    info "gamacros installed"
else
    info "gamacros already installed (run 'LIBRARY_PATH=$(brew --prefix)/lib cargo install --git $GAMACROS_REPO gamacrosd --force' to update)"
fi

# --- Symlink configs ---

echo ""
echo "=== Linking configuration files ==="

# Gamacros config
GAMACROS_DIR="$HOME/Library/Application Support/gamacros"
mkdir -p "$GAMACROS_DIR"
GAMACROS_TARGET="$GAMACROS_DIR/gc_profile.yaml"
if [ -e "$GAMACROS_TARGET" ] && [ ! -L "$GAMACROS_TARGET" ]; then
    mv "$GAMACROS_TARGET" "${GAMACROS_TARGET}.bak"
    warn "Existing gc_profile.yaml backed up to gc_profile.yaml.bak"
fi
ln -sf "$SCRIPT_DIR/config/gc_profile.yaml" "$GAMACROS_TARGET"
info "Linked gc_profile.yaml"

# AeroSpace config
AEROSPACE_DIR="$HOME/.config/aerospace"
mkdir -p "$AEROSPACE_DIR"
AEROSPACE_TARGET="$AEROSPACE_DIR/aerospace.toml"
if [ -e "$AEROSPACE_TARGET" ] && [ ! -L "$AEROSPACE_TARGET" ]; then
    mv "$AEROSPACE_TARGET" "${AEROSPACE_TARGET}.bak"
    warn "Existing aerospace.toml backed up to aerospace.toml.bak"
fi
ln -sf "$SCRIPT_DIR/config/aerospace.toml" "$AEROSPACE_TARGET"
info "Linked aerospace.toml"

# --- Patch WezTerm config ---

echo ""
echo "=== Patching WezTerm config ==="

WEZTERM_CONFIG="$HOME/.wezterm.lua"

if [ ! -f "$WEZTERM_CONFIG" ]; then
    warn "~/.wezterm.lua not found, skipping WezTerm patch"
else
    if grep -q "Gamepad Control keybindings" "$WEZTERM_CONFIG"; then
        info "WezTerm already patched"
    else
        # Insert keybindings before "return config"
        PATCH='-- Gamepad Control keybindings
config.keys = {
  { key = "[", mods = "CMD|SHIFT", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "]", mods = "CMD|SHIFT", action = wezterm.action.ActivateTabRelative(1) },
  { key = "t", mods = "CMD", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "w", mods = "CMD", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
}'

        # Use sed to insert before "return config"
        sed -i '' "/^return config/i\\
\\
-- Gamepad Control keybindings\\
config.keys = {\\
  { key = \"[\", mods = \"CMD|SHIFT\", action = wezterm.action.ActivateTabRelative(-1) },\\
  { key = \"]\", mods = \"CMD|SHIFT\", action = wezterm.action.ActivateTabRelative(1) },\\
  { key = \"t\", mods = \"CMD\", action = wezterm.action.SpawnTab(\"CurrentPaneDomain\") },\\
  { key = \"w\", mods = \"CMD\", action = wezterm.action.CloseCurrentTab({ confirm = true }) },\\
}\\
" "$WEZTERM_CONFIG"
        info "WezTerm patched with tab keybindings"
    fi
fi

# --- Start services ---

echo ""
echo "=== Starting services ==="

if pgrep -x AeroSpace &>/dev/null; then
    info "AeroSpace already running"
else
    open -a AeroSpace 2>/dev/null && info "AeroSpace started" || warn "Could not start AeroSpace"
fi

echo ""
echo "=== Manual steps required ==="
echo ""
echo "  1. System Settings → Privacy & Security → Accessibility"
echo "     Add: gamacrosd, AeroSpace"
echo ""
echo "  2. Connect Xbox controller via Bluetooth"
echo ""
echo "  3. Test with:  gamacrosd run -v"
echo ""
echo "  4. Verification checklist:"
echo "     - gamacrosd observe → controller detected"
echo "     - Left stick moves cursor"
echo "     - A = click, X = right click, Y = double click"
echo "     - Right stick scrolls"
echo "     - LT+dpad_left/right switches tabs"
echo "     - RT+dpad moves focus between tiled windows"
echo "     - L1 = superwhisper, R1 = freeflow"
echo "     - Start = Enter, B = Escape"
echo ""
info "Setup complete!"
