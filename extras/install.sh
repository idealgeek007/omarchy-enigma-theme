#!/bin/bash
# Panacea Dark extras: everything an Omarchy theme can't ship by itself.
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

# 2. Bar plugins: dot-matrix clock + Panacea calendar, workspace dots, CPU/RAM
mkdir -p ~/.config/omarchy/plugins
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
swap = {"omarchy.clock": "panacea.clock", "omarchy.workspaces": "panacea.workspaces"}
swap.update({k.replace("omarchy.", "enigma."): v for k, v in swap.items()})
swap["enigma.system-stats"] = "panacea.system-stats"
def walk(o):
    if isinstance(o, dict):
        return {k: (swap.get(v, v) if k in ("id", "centerAnchor") and isinstance(v, str) else walk(v)) for k, v in o.items()}
    if isinstance(o, list):
        return [walk(x) for x in o]
    return o
d = walk(d)
center = d.get("layout", {}).get("center")
if isinstance(center, list) and not any(isinstance(e, dict) and e.get("id") == "panacea.system-stats" for e in center):
    i = next((n + 1 for n, e in enumerate(center) if isinstance(e, dict) and e.get("id") == "panacea.clock"), len(center))
    center.insert(i, {"id": "panacea.system-stats"})
json.dump(d, open(p, "w"), indent=2)
PY
  say "Bar: panacea.clock, panacea.workspaces, panacea.system-stats"
fi

# 3. Hyprland motion, borders, rounding (only active while the theme is)
cp "$HERE/hypr/panacea-dark.lua" ~/.config/hypr/panacea-dark.lua
grep -q 'hypr.panacea-dark' ~/.config/hypr/hyprland.lua || \
  printf '\n-- Panacea Dark theme extras (no-op under other themes)\nrequire("hypr.panacea-dark")\n' >> ~/.config/hypr/hyprland.lua
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
say "Fastfetch: Panacea layout"

# 6. Code - OSS theme sync (Arch's `code`), runs on every theme change
mkdir -p ~/.config/omarchy/hooks/theme-set.d
install -m 755 "$HERE/hooks/code-oss-theme.hook" ~/.config/omarchy/hooks/theme-set.d/
say "VS Code (Code - OSS): theme sync hook"

# 7. Font + apply
omarchy font set "JetBrainsMono Nerd Font" >/dev/null 2>&1 || true
omarchy theme set panacea-dark >/dev/null 2>&1 || true
omarchy restart shell >/dev/null 2>&1 || true
say "Done. Reload VS Code windows to pick up the colours."
