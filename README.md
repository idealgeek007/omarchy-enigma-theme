# Enigma — Omarchy theme

A dark, Nothing-style dotted theme for Omarchy: charcoal surfaces, soft grey
text, one signal red (`#d71921`), dot-matrix numbers and headings.

![preview](preview.png)

## Install

```bash
omarchy theme install https://github.com/idealgeek007/omarchy-enigma-theme
~/.config/omarchy/themes/enigma/extras/install.sh
```

The first line gives you colours, wallpapers, icons and the shell styling
(menus, launcher, notifications, lock screen). Omarchy won't let a theme
installed from git ship code, so the second line installs the rest. It backs
up anything it replaces as `*.bak.<timestamp>` and is safe to re-run.

## What the extras add

| Extra | What you get |
|---|---|
| `plugins/enigma.menu` | Menu with a dot-matrix title, depth dots (current level in red) and a red icon on the selected row |
| `plugins/enigma.clock` | Dot-matrix bar clock; calendar with dotted date, red "today" disc, year as a dot bar |
| `plugins/enigma.workspaces` | Workspace dots: red pill = focused, white = occupied, dim = empty |
| `plugins/enigma.system-stats` | CPU / RAM: dim labels, dotted values, red past 85% |
| `plugins/enigma.network` `.bluetooth` `.audio` `.power` `.weather` | The Wi‑Fi, Bluetooth, sound, power and weather panels with dotted numbers and headings, dot-style level indicators |
| `hypr/enigma.lua` | Soft pop-in animations, red→white borders, 12px rounded panels (only while Enigma is active; keeps windows square under the no-gaps toggle) |
| `fish/` | One-line prompt `▍dir  branch*  ⟢` (red on failure) and syntax colours read from the active theme |
| `fastfetch/` | Red logo and keys, dot bullets |
| `hooks/code-oss-theme.hook` | Syncs the theme into Code - OSS (Arch's `code`), which Omarchy skips |
| `fonts/Doto-ExtraBold.ttf` | Dot-matrix font, [Doto](https://github.com/oliverlalan/Doto), SIL OFL 1.1 |

## Credits

Wallpapers adapted (inverted to dark) from [EnsixD/Panacea](https://github.com/EnsixD/Panacea), MIT.
Doto font © The Doto Project Authors, SIL OFL 1.1.
