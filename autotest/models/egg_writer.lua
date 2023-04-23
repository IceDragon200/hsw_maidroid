------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

mod.autotest_suite:define_model("egg_writer", {
  state = {
    node = { name = mod:make_name("egg_writer") },
  },

  properties = {
    {
      property = "is_egg_writer",
    },
  }
})
