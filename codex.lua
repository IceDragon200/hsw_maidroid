local mod = assert(hsw_maidroid)

yatm.codex.register_entry(mod:make_name("core_writer"), {
  pages = {
    {
      heading_item = {
        context = true,
        default = mod:make_name("core_writer"),
      },
      heading = mod.S("Core Writer"),
      lines = {
      },
    },
  },
})

yatm.codex.register_entry(mod:make_name("egg_writer"), {
  pages = {
    {
      heading_item = {
        context = true,
        default = mod:make_name("egg_writer"),
      },
      heading = mod.S("Dust Bin"),
      lines = {
        "A simple machine for cutting wood into more components.",
      },
    },
  },
})
