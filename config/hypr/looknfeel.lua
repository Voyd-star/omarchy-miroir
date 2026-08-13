-- Miroir polish — motion & decoration (overrides Omarchy defaults).
-- Composite-only (transform/opacity), 60fps. Border/shadow follow the theme
-- accent live via ~/.local/bin/miroir-theme-apply.

hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 12,
    border_size = 2,
    col = {
      -- Sensible violet default; the theme hook overrides these live per theme.
      active_border = { colors = { "rgba(a97bf0ee)", "rgba(4fd6e0ee)" }, angle = 45 },
      inactive_border = "rgba(1b1730aa)",
    },
  },
  decoration = {
    rounding = 11,
    dim_inactive = true,
    dim_strength = 0.08,
    active_opacity = 1.0,
    inactive_opacity = 0.96,
    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      new_optimizations = true,
      ignore_opacity = true,
      popups = true,
    },
    shadow = {
      enabled = true,
      range = 15,
      render_power = 3,
      color = "rgba(a97bf066)",          -- accent glow, softer (overridden live per theme)
      color_inactive = "rgba(00000000)",
    },
  },
})

-- Snappier, more alive motion. easeOutExpo-ish curve, subtle scale on windows,
-- and workspaces now slide (Omarchy default had them disabled).
hl.curve("miroirOut", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("miroirBack", { type = "bezier", points = { { 0.34, 1.28 }, { 0.64, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4.4, bezier = "miroirOut", style = "popin 80%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.8, bezier = "miroirBack", style = "popin 78%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3.6, bezier = "miroirOut", style = "popin 82%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "miroirOut" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "miroirOut" })
hl.animation({ leaf = "fade", enabled = true, speed = 4.2, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5.2, bezier = "miroirOut", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4.4, bezier = "miroirOut", style = "slidevert" })
hl.animation({ leaf = "layers", enabled = true, speed = 4.4, bezier = "miroirOut", style = "popin 90%" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4.6, bezier = "miroirOut", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "almostLinear", style = "fade" })

-- Theme-adaptive border + shadow (regenerated live by miroir-theme-apply, then hyprctl reload).
local _mt = os.getenv("HOME") .. "/.config/hypr/miroir-theme.lua"
local _f = io.open(_mt, "r")
if _f then
  _f:close()
  dofile(_mt)
end
