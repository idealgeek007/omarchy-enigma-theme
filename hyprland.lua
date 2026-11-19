-- Panacea Dark: Nothing-style window chrome.
-- Thin red-to-white border, soft 12px corners (Panacea's rounding), no glow.
local active_border_color = { colors = { "rgba(d71921ff)", "rgba(ffffff99)" }, angle = 45 }
local inactive_border_color = "rgba(1c1c1cff)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },
  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },
  decoration = {
    rounding = 12,
    rounding_power = 4.0,
    shadow = { enabled = false },
  },
})

-- Panacea motion: soft popin windows, liquid fades, smooth workspace slide.
hl.curve("panaceaPop",    { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.curve("panaceaQuint",  { type = "bezier", points = { { 0.23, 1.0 }, { 0.32, 1.0 } } })
hl.curve("panaceaLiquid", { type = "bezier", points = { { 0.16, 1.0 }, { 0.3, 1.0 } } })

hl.animation({ leaf = "windows",     enabled = true, speed = 7, bezier = "panaceaPop",    style = "popin 80%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 7, bezier = "panaceaPop",    style = "popin 80%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 6, bezier = "panaceaLiquid", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 6, bezier = "panaceaLiquid" })
hl.animation({ leaf = "layers",      enabled = true, speed = 6, bezier = "panaceaLiquid", style = "fade" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 6, bezier = "panaceaLiquid", style = "fade" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 5, bezier = "panaceaLiquid", style = "fade" })
hl.animation({ leaf = "fade",        enabled = true, speed = 6, bezier = "panaceaLiquid" })
hl.animation({ leaf = "border",      enabled = true, speed = 8, bezier = "panaceaLiquid" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 7, bezier = "panaceaQuint",  style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 6, bezier = "panaceaLiquid", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "panaceaLiquid", style = "fade" })
