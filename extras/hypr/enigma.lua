-- Enigma theme: window chrome + motion.
-- Omarchy drops .lua files from themes installed with `omarchy theme install`,
-- so extras/install.sh puts this file in ~/.config/hypr/ and requires it from
-- hyprland.lua. It only does anything while Enigma is the active theme.
local state = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/omarchy"
local f = io.open(state .. "/current/theme.name", "r")
local theme = f and f:read("*l") or ""
if f then f:close() end
if theme ~= "enigma" then return end

local active = { colors = { "rgba(d71921ff)", "rgba(ffffff99)" }, angle = 45 }
local inactive = "rgba(222222ff)"
hl.config({
  general = { col = { active_border = active, inactive_border = inactive } },
  group = { col = { border_active = active, border_inactive = inactive } },
})

-- The Omarchy shell rounds every panel, menu and notification to Hyprland's
-- decoration:rounding, so set it to 12px. Under the "no gaps"
-- toggle, keep tiled windows square with a window rule instead, so the
-- shell still gets its rounded panels.
hl.config({ decoration = { rounding = 12, rounding_power = 4.0 } })
local nogaps = io.open(state .. "/toggles/hypr/window-no-gaps.lua", "r")
if nogaps then
  nogaps:close()
  o.window({ float = false }, { rounding = 0 })
end

hl.curve("enigmaPop",    { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("enigmaQuint",  { type = "bezier", points = { { 0.23, 1.0 }, { 0.32, 1.0 } } })
hl.curve("enigmaLiquid", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })
hl.animation({ leaf = "windows",     enabled = true, speed = 7, bezier = "enigmaPop",    style = "popin 80%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 7, bezier = "enigmaPop",    style = "popin 80%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 6, bezier = "enigmaLiquid", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "enigmaLiquid" })
hl.animation({ leaf = "layers",      enabled = true, speed = 6, bezier = "enigmaLiquid", style = "fade" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 6, bezier = "enigmaLiquid", style = "fade" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 5, bezier = "enigmaLiquid", style = "fade" })
hl.animation({ leaf = "fade",        enabled = true, speed = 6, bezier = "enigmaLiquid" })
hl.animation({ leaf = "border",      enabled = true, speed = 8, bezier = "enigmaLiquid" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 7, bezier = "enigmaQuint",  style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 6, bezier = "enigmaLiquid", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "enigmaLiquid", style = "fade" })
