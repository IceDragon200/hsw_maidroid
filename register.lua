------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

mod.register_egg(mod:make_name("empty_egg"), {
	description     = mod.S("Empty Egg"),
	inventory_image = "maidroid_empty_egg.png",
})

for i = 1, 15 do
	local product_name = mod:make_name("maidroid_mk" .. tostring(i))
	local texture_name = "maidroid_maidroid_mk" .. tostring(i) .. ".png"
	local egg_img_name = "maidroid_maidroid_mk" .. tostring(i) .. "_egg.png"
	mod.register_maidroid(product_name, {
		hp_max     = 10,
		weight     = 20,
		mesh       = "maidroid.b3d",
		textures   = {texture_name},
		egg_image  = egg_img_name,
	})
end
