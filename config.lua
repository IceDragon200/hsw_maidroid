--
-- HSW Maidroid Config
--

--- @namespace hsw_maidroid
local mod = assert(hsw_maidroid)

local fspec = assert(foundation.com.formspec.api)
local Color = assert(foundation.com.Color)

mod.config = mod.config or {}

-- Default Skin Tones
mod.config.skin_tones = mod.config.skin_tones or {}

--- @type SkinTone: {
---   description: String,
---   color: Color,
--- }

--- @spec get_skin_tone(name: String): SkinTone
function mod.get_skin_tone(name)
  return mod.config.skin_tones[name]
end

--- @spec fetch_skin_tone(name: String): SkinTone
function mod.fetch_skin_tone(name)
  local result = mod.config.skin_tones[name]
  if not result then
    error("skin tone name=" .. name .. " not found")
  end
  return result
end

--- @spec register_skin_tone(name: String, description: String, color: Color): SkinTone
function mod.register_skin_tone(name, description, color)
  local def = {
    name = name,
    description = assert(description),
    color = assert(color),
    color_string = Color.to_string24(color),
  }
  mod.config.skin_tones[name] = def
  mod.config.skin_tone_cache = nil
  return def
end

function mod.get_skin_tone_cache()
  if not mod.config.skin_tone_cache then
    local defa = mod.config.skin_tones["default"]
    local base = foundation.com.table_copy(mod.config.skin_tones)
    base["default"] = nil
    local skin_tones = foundation.com.table_values(base)
    skin_tones = foundation.com.list_sort_by(skin_tones, function (skin_tone)
      return skin_tone.name
    end)

    local ordered = foundation.com.list_concat({defa}, skin_tones)
    mod.config.skin_tone_cache = {
      count = #ordered,
      ordered = ordered,
    }
  end

  return mod.config.skin_tone_cache
end

--- @type RenderSkinTonePalleteOptions: {
---   basename?: String = "swt_",
---   x: Number,
---   y: Number,
---   w: Number,
---   h: Number,
---   cols?: Number | Boolean = 1,
---   current_value?: String,
---   show_label?: Boolean = false,
---   show_tooltip?: Boolean = false
--- }

--- @spec mod.render_skin_tone_palette(options: RenderSkinTonePalleteOptions): String
function mod.render_skin_tone_palette(options)
  local cache = mod.get_skin_tone_cache()

  local formspec = ""

  local basename = options.basename or "swt_"

  local x = options.x
  local y = options.y
  local w = options.w
  local h = options.h -- kind of unusued?
  local cols = options.cols

  if cols == true then
    -- shoutout to chatgpt, because I'm a dumb-dumb and couldn't figure this one out on my own.
    local area = assert(w, "expected w(idth)") * assert(h, "expected h(eight)")
    local area_per_cell = area / cache.count
    local acw = math.sqrt(area_per_cell)
    cols = math.floor(w / acw)
  elseif cols == false then
    cols = 1
  else
    cols = cols or 1
  end

  local cw = w / cols
  local ch = cw

  local cx
  local cy

  local texture_name
  local label
  local element_name

  local current_value = options.current_value
  local show_label = options.show_label or false
  local show_tooltip = options.show_tooltip or false

  for idx, skin_tone in ipairs(cache.ordered) do
    cx = (idx - 1) % cols
    cy = math.floor((idx - 1) / cols)

    texture_name = "maidroid_gui_swatch_button.png^[multiply:"..skin_tone.color_string

    if current_value == skin_tone.name then
      texture_name = texture_name .. "^maidroid_gui_swatch_border.png"
    end

    if show_label then
      label = skin_tone.description
    else
      label = ""
    end

    element_name = basename .. skin_tone.name

    formspec = formspec
      .. fspec.image_button(
        x + cx * cw,
        y + cy * ch,
        cw,
        ch,
        texture_name,
        element_name,
        label
      )

    if show_tooltip then
      formspec = formspec
        .. fspec.tooltip_element(element_name, skin_tone.description)
    end
  end

  return formspec
end

--- Very dark
mod.register_skin_tone("gunmetal",   "Gunmetal",   Color.new( 41,  39,  41))
--- Natural Skin Tones
mod.register_skin_tone("chocolate",  "Chocolate",  Color.new( 40,  23,  11))
mod.register_skin_tone("espresso",   "Espresso",   Color.new( 97,  51,  16))
mod.register_skin_tone("golden",     "Golden",     Color.new(121,  66,  27))
mod.register_skin_tone("umber",      "Umber",      Color.new(181, 102,  68))
mod.register_skin_tone("bronze",     "Bronze",     Color.new(121,  66,  27))
mod.register_skin_tone("almond",     "Almond",     Color.new(146,  95,  58))
mod.register_skin_tone("band",       "Band",       Color.new(173, 137,  96))
mod.register_skin_tone("honey",      "Honey",      Color.new(205, 150,  90))
mod.register_skin_tone("amber",      "Amber",      Color.new(189, 100,  52))
mod.register_skin_tone("sienna",     "Sienna",     Color.new(210, 158, 119))
mod.register_skin_tone("beige",      "Beige",      Color.new(245, 193, 129))
mod.register_skin_tone("limestone",  "Limestone",  Color.new(239, 192, 145))
mod.register_skin_tone("rose_beige", "Rose Beige", Color.new(248, 213, 161))
mod.register_skin_tone("sand",       "Sand",       Color.new(248, 217, 151))
mod.register_skin_tone("warm_ivory", "Warm Ivory", Color.new(253, 231, 169))
mod.register_skin_tone("pale_ivory", "Pale Ivory", Color.new(252, 224, 195))
--- Maidroid Original Skin Tone
mod.register_skin_tone("default",    "Default",    Color.new(253, 218, 198))
