#!/bin/bash
# Enigma theme extras: everything an Omarchy theme can't ship by itself.
# Safe to re-run. Backs up anything it replaces as <file>.bak.<timestamp>.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS=$(date +%s)
backup() { [[ -e $1 && ! -L $1 ]] && cp -a "$1" "$1.bak.$TS" || true; }
say() { printf '\e[31m●\e[0m %s\n' "$*"; }

# 1. Dot-matrix font (Doto ExtraBold, SIL OFL)
mkdir -p ~/.local/share/fonts/doto
cp "$HERE/fonts/Doto-ExtraBold.ttf" ~/.local/share/fonts/doto/
fc-cache -f ~/.local/share/fonts >/dev/null
say "Font: Doto installed"

# 2. Bar plugins: dot-matrix clock + calendar, workspace dots, CPU/RAM
mkdir -p ~/.config/omarchy/plugins
rm -rf ~/.config/omarchy/plugins/panacea.*   # older name of these plugins
for p in "$HERE"/plugins/*/; do
  rm -rf ~/.config/omarchy/plugins/"$(basename "$p")"
  cp -r "$p" ~/.config/omarchy/plugins/
done
SHELL_JSON=~/.config/omarchy/shell.json
if [[ -f $SHELL_JSON ]]; then
  backup "$SHELL_JSON"
  python3 -I - "$SHELL_JSON" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
# Point the bar at the enigma.* clones (also migrates older panacea.* ids).
swap = {}
for name in ("menu", "clock", "workspaces", "system-stats", "network", "bluetooth", "audio", "power", "weather"):
    for old in ("omarchy.", "panacea."):
        swap[old + name] = "enigma." + name
def walk(o):
    if isinstance(o, dict):
        return {k: (swap.get(v, v) if k in ("id", "centerAnchor") and isinstance(v, str) else walk(v)) for k, v in o.items()}
    if isinstance(o, list):
        return [walk(x) for x in o]
    return o
d = walk(d)
center = d.get("bar", {}).get("layout", {}).get("center")
if isinstance(center, list) and not any(isinstance(e, dict) and e.get("id") == "enigma.system-stats" for e in center):
    i = next((n + 1 for n, e in enumerate(center) if isinstance(e, dict) and e.get("id") == "enigma.clock"), len(center))
    center.insert(i, {"id": "enigma.system-stats"})
json.dump(d, open(p, "w"), indent=2)
PY
  say "Bar: enigma clock, calendar, workspaces, CPU/RAM, Wi-Fi, Bluetooth, audio, power, weather"
fi

# 3. Hyprland motion, borders, rounding (only active while the theme is)
cp "$HERE/hypr/enigma.lua" ~/.config/hypr/enigma.lua
# migrate the older panacea-dark hook
rm -f ~/.config/hypr/panacea-dark.lua
sed -i '/Panacea Dark theme extras/d; /require("hypr.panacea-dark")/d' ~/.config/hypr/hyprland.lua
grep -q 'hypr.enigma' ~/.config/hypr/hyprland.lua || \
  printf '\n-- Enigma theme extras (no-op under other themes)\nrequire("hypr.enigma")\n' >> ~/.config/hypr/hyprland.lua
say "Hyprland: animations + borders"

# 4. Fish prompt and theme-aware syntax colours
if command -v fish >/dev/null; then
  mkdir -p ~/.config/fish/conf.d ~/.config/fish/functions
  backup ~/.config/fish/functions/fish_prompt.fish
  cp "$HERE/fish/conf.d/omarchy_theme_colors.fish" ~/.config/fish/conf.d/
  cp "$HERE/fish/functions/fish_prompt.fish" ~/.config/fish/functions/
  say "Fish: prompt + colours"
fi

# 5. Fastfetch
mkdir -p ~/.config/fastfetch
backup ~/.config/fastfetch/config.jsonc
cp "$HERE/fastfetch/config.jsonc" ~/.config/fastfetch/
say "Fastfetch: dotted layout"

# 6. Code - OSS theme sync (Arch's `code`), runs on every theme change
mkdir -p ~/.config/omarchy/hooks/theme-set.d
install -m 755 "$HERE/hooks/code-oss-theme.hook" ~/.config/omarchy/hooks/theme-set.d/
say "VS Code (Code - OSS): theme sync hook"

# 7. Font + apply
omarchy font set "JetBrainsMono Nerd Font" >/dev/null 2>&1 || true
omarchy theme set enigma >/dev/null 2>&1 || true
omarchy restart shell >/dev/null 2>&1 || true
say "Done. Reload VS Code windows to pick up the colours."
