------------------------------------------------------------
-- Copyright (c) 2016 tacigar. All rights reserved.
-- https://github.com/tacigar/maidroid
------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------

local mod = assert(hsw_maidroid)

mod:require("cores/_aux.lua")
mod:require("cores/empty.lua")
mod:require("cores/basic.lua")
mod:require("cores/farming.lua")
mod:require("cores/torcher.lua")
if minetest.global_exists("pdisc") then
  mod:require("cores/ocr.lua")
end
