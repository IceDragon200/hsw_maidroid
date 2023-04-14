------------------------------------------------------------
-- Copyright (c) 2023 IceDragon.
-- https://github.com/IceDragon200/hsw_maidroid
------------------------------------------------------------
local mod = assert(hsw_maidroid)

mod.autotest_suite:define_model("core_writer", {
  state = {
    node = { name = mod:make_name("core_writer") },
  },

  properties = {
    {
      property = "is_core_writer",
    },
  }
})
