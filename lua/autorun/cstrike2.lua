фCS2 = true
local MOVEMODE_WALK = 1
local MOVEMODE_SPRINT = 2
local dir = ")player/footsteps/CS2/%s"
local footstepSounds = {
    ["carpet"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "carpet/carpet1.ogg"),
            string.format(dir, "carpet/carpet2.ogg"),
            string.format(dir, "carpet/carpet3.ogg"),
            string.format(dir, "carpet/carpet4.ogg"),
            string.format(dir, "carpet/carpet5.ogg"),
            string.format(dir, "carpet/carpet6.ogg"),
            string.format(dir, "carpet/carpet7.ogg"),
            string.format(dir, "carpet/carpet8.ogg"),
            string.format(dir, "carpet/carpet9.ogg"),
            string.format(dir, "carpet/carpet10.ogg"),
            string.format(dir, "carpet/carpet11.ogg"),
            string.format(dir, "carpet/carpet12.ogg"),
            string.format(dir, "carpet/carpet13.ogg"),
            string.format(dir, "carpet/carpet14.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "carpet/carpet1.ogg"),
            string.format(dir, "carpet/carpet2.ogg"),
            string.format(dir, "carpet/carpet3.ogg"),
            string.format(dir, "carpet/carpet4.ogg"),
            string.format(dir, "carpet/carpet5.ogg"),
            string.format(dir, "carpet/carpet6.ogg"),
            string.format(dir, "carpet/carpet7.ogg"),
            string.format(dir, "carpet/carpet8.ogg"),
            string.format(dir, "carpet/carpet9.ogg"),
            string.format(dir, "carpet/carpet10.ogg"),
            string.format(dir, "carpet/carpet11.ogg"),
            string.format(dir, "carpet/carpet12.ogg"),
            string.format(dir, "carpet/carpet13.ogg"),
            string.format(dir, "carpet/carpet14.ogg")
        }
    },
    ["concrete"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "concrete/concrete1.ogg"),
            string.format(dir, "concrete/concrete2.ogg"),
            string.format(dir, "concrete/concrete3.ogg"),
            string.format(dir, "concrete/concrete4.ogg"),
            string.format(dir, "concrete/concrete5.ogg"),
            string.format(dir, "concrete/concrete6.ogg"),
            string.format(dir, "concrete/concrete7.ogg"),
            string.format(dir, "concrete/concrete8.ogg"),
            string.format(dir, "concrete/concrete9.ogg"),
            string.format(dir, "concrete/concrete10.ogg"),
            string.format(dir, "concrete/concrete11.ogg"),
            string.format(dir, "concrete/concrete12.ogg"),
            string.format(dir, "concrete/concrete13.ogg"),
            string.format(dir, "concrete/concrete14.ogg"),
            string.format(dir, "concrete/concrete15.ogg"),
            string.format(dir, "concrete/concrete16.ogg"),
            string.format(dir, "concrete/concrete17.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "concrete/concrete1.ogg"),
            string.format(dir, "concrete/concrete2.ogg"),
            string.format(dir, "concrete/concrete3.ogg"),
            string.format(dir, "concrete/concrete4.ogg"),
            string.format(dir, "concrete/concrete5.ogg"),
            string.format(dir, "concrete/concrete6.ogg"),
            string.format(dir, "concrete/concrete7.ogg"),
            string.format(dir, "concrete/concrete8.ogg"),
            string.format(dir, "concrete/concrete9.ogg"),
            string.format(dir, "concrete/concrete10.ogg"),
            string.format(dir, "concrete/concrete11.ogg"),
            string.format(dir, "concrete/concrete12.ogg"),
            string.format(dir, "concrete/concrete13.ogg"),
            string.format(dir, "concrete/concrete14.ogg"),
            string.format(dir, "concrete/concrete15.ogg"),
            string.format(dir, "concrete/concrete16.ogg"),
            string.format(dir, "concrete/concrete17.ogg")
        }
    },
    ["dirt"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "dirt/dirt_01.ogg"),
            string.format(dir, "dirt/dirt_02.ogg"),
            string.format(dir, "dirt/dirt_03.ogg"),
            string.format(dir, "dirt/dirt_04.ogg"),
            string.format(dir, "dirt/dirt_05.ogg"),
            string.format(dir, "dirt/dirt_06.ogg"),
            string.format(dir, "dirt/dirt_07.ogg"),
            string.format(dir, "dirt/dirt_08.ogg"),
            string.format(dir, "dirt/dirt_09.ogg"),
            string.format(dir, "dirt/dirt_010.ogg"),
            string.format(dir, "dirt/dirt_011.ogg"),
            string.format(dir, "dirt/dirt_012.ogg"),
            string.format(dir, "dirt/dirt_013.ogg"),
            string.format(dir, "dirt/dirt_014.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "dirt/dirt_01.ogg"),
            string.format(dir, "dirt/dirt_02.ogg"),
            string.format(dir, "dirt/dirt_03.ogg"),
            string.format(dir, "dirt/dirt_04.ogg"),
            string.format(dir, "dirt/dirt_05.ogg"),
            string.format(dir, "dirt/dirt_06.ogg"),
            string.format(dir, "dirt/dirt_07.ogg"),
            string.format(dir, "dirt/dirt_08.ogg"),
            string.format(dir, "dirt/dirt_09.ogg"),
            string.format(dir, "dirt/dirt_010.ogg"),
            string.format(dir, "dirt/dirt_011.ogg"),
            string.format(dir, "dirt/dirt_012.ogg"),
            string.format(dir, "dirt/dirt_013.ogg"),
            string.format(dir, "dirt/dirt_014.ogg")
        }
    },
    ["glass"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "glass/glass_01.ogg"),
            string.format(dir, "glass/glass_02.ogg"),
            string.format(dir, "glass/glass_03.ogg"),
            string.format(dir, "glass/glass_04.ogg"),
            string.format(dir, "glass/glass_05.ogg"),
            string.format(dir, "glass/glass_06.ogg"),
            string.format(dir, "glass/glass_07.ogg"),
            string.format(dir, "glass/glass_08.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "glass/glass_01.ogg"),
            string.format(dir, "glass/glass_02.ogg"),
            string.format(dir, "glass/glass_03.ogg"),
            string.format(dir, "glass/glass_04.ogg"),
            string.format(dir, "glass/glass_05.ogg"),
            string.format(dir, "glass/glass_06.ogg"),
            string.format(dir, "glass/glass_07.ogg"),
            string.format(dir, "glass/glass_08.ogg")
        }
    },
    ["grass"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "grass/grass_01.ogg"),
            string.format(dir, "grass/grass_02.ogg"),
            string.format(dir, "grass/grass_03.ogg"),
            string.format(dir, "grass/grass_04.ogg"),
            string.format(dir, "grass/grass_05.ogg"),
            string.format(dir, "grass/grass_06.ogg"),
            string.format(dir, "grass/grass_07.ogg"),
            string.format(dir, "grass/grass_08.ogg"),
            string.format(dir, "grass/grass_09.ogg"),
            string.format(dir, "grass/grass_010.ogg"),
            string.format(dir, "grass/grass_011.ogg"),
            string.format(dir, "grass/grass_012.ogg"),
            string.format(dir, "grass/grass_013.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "grass/grass_01.ogg"),
            string.format(dir, "grass/grass_02.ogg"),
            string.format(dir, "grass/grass_03.ogg"),
            string.format(dir, "grass/grass_04.ogg"),
            string.format(dir, "grass/grass_05.ogg"),
            string.format(dir, "grass/grass_06.ogg"),
            string.format(dir, "grass/grass_07.ogg"),
            string.format(dir, "grass/grass_08.ogg"),
            string.format(dir, "grass/grass_09.ogg"),
            string.format(dir, "grass/grass_010.ogg"),
            string.format(dir, "grass/grass_011.ogg"),
            string.format(dir, "grass/grass_012.ogg"),
            string.format(dir, "grass/grass_013.ogg")
        }
    },
    ["gravel"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "gravel/gravel_01.ogg"),
            string.format(dir, "gravel/gravel_02.ogg"),
            string.format(dir, "gravel/gravel_03.ogg"),
            string.format(dir, "gravel/gravel_04.ogg"),
            string.format(dir, "gravel/gravel_05.ogg"),
            string.format(dir, "gravel/gravel_06.ogg"),
            string.format(dir, "gravel/gravel_07.ogg"),
            string.format(dir, "gravel/gravel_08.ogg"),
            string.format(dir, "gravel/gravel_09.ogg"),
            string.format(dir, "gravel/gravel_010.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "gravel/gravel_01.ogg"),
            string.format(dir, "gravel/gravel_02.ogg"),
            string.format(dir, "gravel/gravel_03.ogg"),
            string.format(dir, "gravel/gravel_04.ogg"),
            string.format(dir, "gravel/gravel_05.ogg"),
            string.format(dir, "gravel/gravel_06.ogg"),
            string.format(dir, "gravel/gravel_07.ogg"),
            string.format(dir, "gravel/gravel_08.ogg"),
            string.format(dir, "gravel/gravel_09.ogg"),
            string.format(dir, "gravel/gravel_010.ogg")
        }
    },
    ["metal"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "metal/metal_solid_01.ogg"),
            string.format(dir, "metal/metal_solid_02.ogg"),
            string.format(dir, "metal/metal_solid_03.ogg"),
            string.format(dir, "metal/metal_solid_04.ogg"),
            string.format(dir, "metal/metal_solid_05.ogg"),
            string.format(dir, "metal/metal_solid_06.ogg"),
            string.format(dir, "metal/metal_solid_07.ogg"),
            string.format(dir, "metal/metal_solid_08.ogg"),
            string.format(dir, "metal/metal_solid_09.ogg"),
            string.format(dir, "metal/metal_solid_010.ogg"),
            string.format(dir, "metal/metal_solid_011.ogg"),
            string.format(dir, "metal/metal_solid_012.ogg"),
            string.format(dir, "metal/metal_solid_013.ogg"),
            string.format(dir, "metal/metal_solid_014.ogg"),
            string.format(dir, "metal/metal_solid_015.ogg"),
            string.format(dir, "metal/metal_solid_016.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "metal/metal_solid_01.ogg"),
            string.format(dir, "metal/metal_solid_02.ogg"),
            string.format(dir, "metal/metal_solid_03.ogg"),
            string.format(dir, "metal/metal_solid_04.ogg"),
            string.format(dir, "metal/metal_solid_05.ogg"),
            string.format(dir, "metal/metal_solid_06.ogg"),
            string.format(dir, "metal/metal_solid_07.ogg"),
            string.format(dir, "metal/metal_solid_08.ogg"),
            string.format(dir, "metal/metal_solid_09.ogg"),
            string.format(dir, "metal/metal_solid_010.ogg"),
            string.format(dir, "metal/metal_solid_011.ogg"),
            string.format(dir, "metal/metal_solid_012.ogg"),
            string.format(dir, "metal/metal_solid_013.ogg"),
            string.format(dir, "metal/metal_solid_014.ogg"),
            string.format(dir, "metal/metal_solid_015.ogg"),
            string.format(dir, "metal/metal_solid_016.ogg")
        }
    },
    ["metalgrate"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "metalgrate/metal_grate_01.ogg"),
            string.format(dir, "metalgrate/metal_grate_02.ogg"),
            string.format(dir, "metalgrate/metal_grate_03.ogg"),
            string.format(dir, "metalgrate/metal_grate_04.ogg"),
            string.format(dir, "metalgrate/metal_grate_05.ogg"),
            string.format(dir, "metalgrate/metal_grate_06.ogg"),
            string.format(dir, "metalgrate/metal_grate_07.ogg"),
            string.format(dir, "metalgrate/metal_grate_08.ogg"),
            string.format(dir, "metalgrate/metal_grate_09.ogg"),
            string.format(dir, "metalgrate/metal_grate_010.ogg"),
            string.format(dir, "metalgrate/metal_grate_011.ogg"),
            string.format(dir, "metalgrate/metal_grate_012.ogg"),
            string.format(dir, "metalgrate/metal_grate_013.ogg"),
            string.format(dir, "metalgrate/metal_grate_014.ogg"),
            string.format(dir, "metalgrate/metal_grate_015.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "metalgrate/metal_grate_01.ogg"),
            string.format(dir, "metalgrate/metal_grate_02.ogg"),
            string.format(dir, "metalgrate/metal_grate_03.ogg"),
            string.format(dir, "metalgrate/metal_grate_04.ogg"),
            string.format(dir, "metalgrate/metal_grate_05.ogg"),
            string.format(dir, "metalgrate/metal_grate_06.ogg"),
            string.format(dir, "metalgrate/metal_grate_07.ogg"),
            string.format(dir, "metalgrate/metal_grate_08.ogg"),
            string.format(dir, "metalgrate/metal_grate_09.ogg"),
            string.format(dir, "metalgrate/metal_grate_010.ogg"),
            string.format(dir, "metalgrate/metal_grate_011.ogg"),
            string.format(dir, "metalgrate/metal_grate_012.ogg"),
            string.format(dir, "metalgrate/metal_grate_013.ogg"),
            string.format(dir, "metalgrate/metal_grate_014.ogg"),
            string.format(dir, "metalgrate/metal_grate_015.ogg"),
        }
    },
    ["mud"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "mud/mud_01.ogg"),
            string.format(dir, "mud/mud_02.ogg"),
            string.format(dir, "mud/mud_03.ogg"),
            string.format(dir, "mud/mud_04.ogg"),
            string.format(dir, "mud/mud_05.ogg"),
            string.format(dir, "mud/mud_06.ogg"),
            string.format(dir, "mud/mud_07.ogg"),
            string.format(dir, "mud/mud_08.ogg"),
            string.format(dir, "mud/mud_09.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "mud/mud_01.ogg"),
            string.format(dir, "mud/mud_02.ogg"),
            string.format(dir, "mud/mud_03.ogg"),
            string.format(dir, "mud/mud_04.ogg"),
            string.format(dir, "mud/mud_05.ogg"),
            string.format(dir, "mud/mud_06.ogg"),
            string.format(dir, "mud/mud_07.ogg"),
            string.format(dir, "mud/mud_08.ogg"),
            string.format(dir, "mud/mud_09.ogg")
        }
    },
    ["sand"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "sand/sand_01.ogg"),
            string.format(dir, "sand/sand_02.ogg"),
            string.format(dir, "sand/sand_03.ogg"),
            string.format(dir, "sand/sand_04.ogg"),
            string.format(dir, "sand/sand_05.ogg"),
            string.format(dir, "sand/sand_06.ogg"),
            string.format(dir, "sand/sand_07.ogg"),
            string.format(dir, "sand/sand_08.ogg"),
            string.format(dir, "sand/sand_09.ogg"),
            string.format(dir, "sand/sand_010.ogg"),
            string.format(dir, "sand/sand_011.ogg"),
            string.format(dir, "sand/sand_012.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "sand/sand_01.ogg"),
            string.format(dir, "sand/sand_02.ogg"),
            string.format(dir, "sand/sand_03.ogg"),
            string.format(dir, "sand/sand_04.ogg"),
            string.format(dir, "sand/sand_05.ogg"),
            string.format(dir, "sand/sand_06.ogg"),
            string.format(dir, "sand/sand_07.ogg"),
            string.format(dir, "sand/sand_08.ogg"),
            string.format(dir, "sand/sand_09.ogg"),
            string.format(dir, "sand/sand_010.ogg"),
            string.format(dir, "sand/sand_011.ogg"),
            string.format(dir, "sand/sand_012.ogg"),
        }
    },
    ["snow"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "snow/snow_01.ogg"),
            string.format(dir, "snow/snow_02.ogg"),
            string.format(dir, "snow/snow_03.ogg"),
            string.format(dir, "snow/snow_04.ogg"),
            string.format(dir, "snow/snow_05.ogg"),
            string.format(dir, "snow/snow_06.ogg"),
            string.format(dir, "snow/snow_07.ogg"),
            string.format(dir, "snow/snow_08.ogg"),
            string.format(dir, "snow/snow_09.ogg"),
            string.format(dir, "snow/snow_010.ogg"),
            string.format(dir, "snow/snow_011.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "snow/snow_01.ogg"),
            string.format(dir, "snow/snow_02.ogg"),
            string.format(dir, "snow/snow_03.ogg"),
            string.format(dir, "snow/snow_04.ogg"),
            string.format(dir, "snow/snow_05.ogg"),
            string.format(dir, "snow/snow_06.ogg"),
            string.format(dir, "snow/snow_07.ogg"),
            string.format(dir, "snow/snow_08.ogg"),
            string.format(dir, "snow/snow_09.ogg"),
            string.format(dir, "snow/snow_010.ogg"),
            string.format(dir, "snow/snow_011.ogg")
        }
    },
    ["tile"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "tile/tile_1.ogg"),
            string.format(dir, "tile/tile_2.ogg"),
            string.format(dir, "tile/tile_3.ogg"),
            string.format(dir, "tile/tile_4.ogg"),
            string.format(dir, "tile/tile_5.ogg"),
            string.format(dir, "tile/tile_6.ogg"),
            string.format(dir, "tile/tile_7.ogg"),
            string.format(dir, "tile/tile_8.ogg"),
            string.format(dir, "tile/tile_9.ogg"),
            string.format(dir, "tile/tile_10.ogg"),
            string.format(dir, "tile/tile_11.ogg"),
            string.format(dir, "tile/tile_12.ogg"),
            string.format(dir, "tile/tile_13.ogg"),
            string.format(dir, "tile/tile_14.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "tile/tile_1.ogg"),
            string.format(dir, "tile/tile_2.ogg"),
            string.format(dir, "tile/tile_3.ogg"),
            string.format(dir, "tile/tile_4.ogg"),
            string.format(dir, "tile/tile_5.ogg"),
            string.format(dir, "tile/tile_6.ogg"),
            string.format(dir, "tile/tile_7.ogg"),
            string.format(dir, "tile/tile_8.ogg"),
            string.format(dir, "tile/tile_9.ogg"),
            string.format(dir, "tile/tile_10.ogg"),
            string.format(dir, "tile/tile_11.ogg"),
            string.format(dir, "tile/tile_12.ogg"),
            string.format(dir, "tile/tile_13.ogg"),
            string.format(dir, "tile/tile_14.ogg")
        }
    },
    ["wood"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "wood/wood_01.ogg"),
            string.format(dir, "wood/wood_02.ogg"),
            string.format(dir, "wood/wood_03.ogg"),
            string.format(dir, "wood/wood_04.ogg"),
            string.format(dir, "wood/wood_05.ogg"),
            string.format(dir, "wood/wood_06.ogg"),
            string.format(dir, "wood/wood_07.ogg"),
            string.format(dir, "wood/wood_08.ogg"),
            string.format(dir, "wood/wood_09.ogg"),
            string.format(dir, "wood/wood_010.ogg"),
            string.format(dir, "wood/wood_011.ogg"),
            string.format(dir, "wood/wood_012.ogg"),
            string.format(dir, "wood/wood_013.ogg"),
            string.format(dir, "wood/wood_014.ogg"),
            string.format(dir, "wood/wood_015.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "wood/wood_01.ogg"),
            string.format(dir, "wood/wood_02.ogg"),
            string.format(dir, "wood/wood_03.ogg"),
            string.format(dir, "wood/wood_04.ogg"),
            string.format(dir, "wood/wood_05.ogg"),
            string.format(dir, "wood/wood_06.ogg"),
            string.format(dir, "wood/wood_07.ogg"),
            string.format(dir, "wood/wood_08.ogg"),
            string.format(dir, "wood/wood_09.ogg"),
            string.format(dir, "wood/wood_010.ogg"),
            string.format(dir, "wood/wood_011.ogg"),
            string.format(dir, "wood/wood_012.ogg"),
            string.format(dir, "wood/wood_013.ogg"),
            string.format(dir, "wood/wood_014.ogg"),
            string.format(dir, "wood/wood_015.ogg")
        }
    },
    ["wood_panel"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "wood/wood_01.ogg"),
            string.format(dir, "wood/wood_02.ogg"),
            string.format(dir, "wood/wood_03.ogg"),
            string.format(dir, "wood/wood_04.ogg"),
            string.format(dir, "wood/wood_05.ogg"),
            string.format(dir, "wood/wood_06.ogg"),
            string.format(dir, "wood/wood_07.ogg"),
            string.format(dir, "wood/wood_08.ogg"),
            string.format(dir, "wood/wood_09.ogg"),
            string.format(dir, "wood/wood_010.ogg"),
            string.format(dir, "wood/wood_011.ogg"),
            string.format(dir, "wood/wood_012.ogg"),
            string.format(dir, "wood/wood_013.ogg"),
            string.format(dir, "wood/wood_014.ogg"),
            string.format(dir, "wood/wood_015.ogg")
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "wood/wood_01.ogg"),
            string.format(dir, "wood/wood_02.ogg"),
            string.format(dir, "wood/wood_03.ogg"),
            string.format(dir, "wood/wood_04.ogg"),
            string.format(dir, "wood/wood_05.ogg"),
            string.format(dir, "wood/wood_06.ogg"),
            string.format(dir, "wood/wood_07.ogg"),
            string.format(dir, "wood/wood_08.ogg"),
            string.format(dir, "wood/wood_09.ogg"),
            string.format(dir, "wood/wood_010.ogg"),
            string.format(dir, "wood/wood_011.ogg"),
            string.format(dir, "wood/wood_012.ogg"),
            string.format(dir, "wood/wood_013.ogg"),
            string.format(dir, "wood/wood_014.ogg"),
            string.format(dir, "wood/wood_015.ogg")
        }
    },

    ["water"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "water/water_01.ogg"),
            string.format(dir, "water/water_02.ogg"),
            string.format(dir, "water/water_03.ogg"),
            string.format(dir, "water/water_04.ogg"),
            string.format(dir, "water/water_05.ogg"),
            string.format(dir, "water/water_06.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "water/water_01.ogg"),
            string.format(dir, "water/water_02.ogg"),
            string.format(dir, "water/water_03.ogg"),
            string.format(dir, "water/water_04.ogg"),
            string.format(dir, "water/water_05.ogg"),
            string.format(dir, "water/water_06.ogg"),
        }
    },

    ["rubber"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "rubber/rubber_01.ogg"),
            string.format(dir, "rubber/rubber_02.ogg"),
            string.format(dir, "rubber/rubber_03.ogg"),
            string.format(dir, "rubber/rubber_04.ogg"),
            string.format(dir, "rubber/rubber_05.ogg"),
            string.format(dir, "rubber/rubber_06.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "rubber/rubber_01.ogg"),
            string.format(dir, "rubber/rubber_02.ogg"),
            string.format(dir, "rubber/rubber_03.ogg"),
            string.format(dir, "rubber/rubber_04.ogg"),
            string.format(dir, "rubber/rubber_05.ogg"),
            string.format(dir, "rubber/rubber_06.ogg"),
        }
    },

    ["chainlink"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "chainlink/chainlink_01.ogg"),
            string.format(dir, "chainlink/chainlink_02.ogg"),
            string.format(dir, "chainlink/chainlink_03.ogg"),
            string.format(dir, "chainlink/chainlink_04.ogg"),
            string.format(dir, "chainlink/chainlink_05.ogg"),
            string.format(dir, "chainlink/chainlink_06.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "chainlink/chainlink_01.ogg"),
            string.format(dir, "chainlink/chainlink_02.ogg"),
            string.format(dir, "chainlink/chainlink_03.ogg"),
            string.format(dir, "chainlink/chainlink_04.ogg"),
            string.format(dir, "chainlink/chainlink_05.ogg"),
            string.format(dir, "chainlink/chainlink_06.ogg"),
        }
    },
    ["metalhollow"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "vent/metalvent_01.ogg"),
            string.format(dir, "vent/metalvent_02.ogg"),
            string.format(dir, "vent/metalvent_03.ogg"),
            string.format(dir, "vent/metalvent_04.ogg"),
            string.format(dir, "vent/metalvent_05.ogg"),
            string.format(dir, "vent/metalvent_06.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "vent/metalvent_01.ogg"),
            string.format(dir, "vent/metalvent_02.ogg"),
            string.format(dir, "vent/metalvent_03.ogg"),
            string.format(dir, "vent/metalvent_04.ogg"),
            string.format(dir, "vent/metalvent_05.ogg"),
            string.format(dir, "vent/metalvent_06.ogg"),
        },
    },

    ["metalvent"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "vent/metalvent_01.ogg"),
            string.format(dir, "vent/metalvent_02.ogg"),
            string.format(dir, "vent/metalvent_03.ogg"),
            string.format(dir, "vent/metalvent_04.ogg"),
            string.format(dir, "vent/metalvent_05.ogg"),
            string.format(dir, "vent/metalvent_06.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "vent/metalvent_01.ogg"),
            string.format(dir, "vent/metalvent_02.ogg"),
            string.format(dir, "vent/metalvent_03.ogg"),
            string.format(dir, "vent/metalvent_04.ogg"),
            string.format(dir, "vent/metalvent_05.ogg"),
            string.format(dir, "vent/metalvent_06.ogg"),
        },
    },

    ["flesh"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "body/body_01.ogg"),
            string.format(dir, "body/body_02.ogg"),
            string.format(dir, "body/body_03.ogg"),
            string.format(dir, "body/body_04.ogg"),
            string.format(dir, "body/body_05.ogg"),
            string.format(dir, "body/body_06.ogg"),
            string.format(dir, "body/body_07.ogg"),
            string.format(dir, "body/body_08.ogg"),
            string.format(dir, "body/body_09.ogg"),
            string.format(dir, "body/body_010.ogg"),
            string.format(dir, "body/body_011.ogg"),
            string.format(dir, "body/body_012.ogg"),
            string.format(dir, "body/body_013.ogg"),
            string.format(dir, "body/body_014.ogg"),
            string.format(dir, "body/body_015.ogg"),
            string.format(dir, "body/body_016.ogg"),
            string.format(dir, "body/body_018.ogg"),
            string.format(dir, "body/body_019.ogg"),
            string.format(dir, "body/body_020.ogg"),
            string.format(dir, "body/body_021.ogg"),
            string.format(dir, "body/body_022.ogg"),
            string.format(dir, "body/body_023.ogg"),
            string.format(dir, "body/body_024.ogg"),
            string.format(dir, "body/body_025.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "body/body_01.ogg"),
            string.format(dir, "body/body_02.ogg"),
            string.format(dir, "body/body_03.ogg"),
            string.format(dir, "body/body_04.ogg"),
            string.format(dir, "body/body_05.ogg"),
            string.format(dir, "body/body_06.ogg"),
            string.format(dir, "body/body_07.ogg"),
            string.format(dir, "body/body_08.ogg"),
            string.format(dir, "body/body_09.ogg"),
            string.format(dir, "body/body_010.ogg"),
            string.format(dir, "body/body_011.ogg"),
            string.format(dir, "body/body_012.ogg"),
            string.format(dir, "body/body_013.ogg"),
            string.format(dir, "body/body_014.ogg"),
            string.format(dir, "body/body_015.ogg"),
            string.format(dir, "body/body_016.ogg"),
            string.format(dir, "body/body_018.ogg"),
            string.format(dir, "body/body_019.ogg"),
            string.format(dir, "body/body_020.ogg"),
            string.format(dir, "body/body_021.ogg"),
            string.format(dir, "body/body_022.ogg"),
            string.format(dir, "body/body_023.ogg"),
            string.format(dir, "body/body_024.ogg"),
            string.format(dir, "body/body_025.ogg"),
        },
    },
    
    ["metal_box"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "vent/metalvent_01.ogg"),
            string.format(dir, "vent/metalvent_02.ogg"),
            string.format(dir, "vent/metalvent_03.ogg"),
            string.format(dir, "vent/metalvent_04.ogg"),
            string.format(dir, "vent/metalvent_05.ogg"),
            string.format(dir, "vent/metalvent_06.ogg"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "vent/metalvent_01.ogg"),
            string.format(dir, "vent/metalvent_02.ogg"),
            string.format(dir, "vent/metalvent_03.ogg"),
            string.format(dir, "vent/metalvent_04.ogg"),
            string.format(dir, "vent/metalvent_05.ogg"),
            string.format(dir, "vent/metalvent_06.ogg"),
        },
    },
        ["plaster"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "plastic/plastic_barrel_01.wav"),
            string.format(dir, "plastic/plastic_barrel_02.wav"),
            string.format(dir, "plastic/plastic_barrel_03.wav"),
            string.format(dir, "plastic/plastic_barrel_04.wav"),
            string.format(dir, "plastic/plastic_barrel_05.wav"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "plastic/plastic_barrel_01.wav"),
            string.format(dir, "plastic/plastic_barrel_02.wav"),
            string.format(dir, "plastic/plastic_barrel_03.wav"),
            string.format(dir, "plastic/plastic_barrel_04.wav"),
            string.format(dir, "plastic/plastic_barrel_05.wav"),
        },
    },
        ["plastic"] = {
        [MOVEMODE_WALK] = {
            string.format(dir, "plastic/plastic_barrel_01.wav"),
            string.format(dir, "plastic/plastic_barrel_02.wav"),
            string.format(dir, "plastic/plastic_barrel_03.wav"),
            string.format(dir, "plastic/plastic_barrel_04.wav"),
            string.format(dir, "plastic/plastic_barrel_05.wav"),
        },
        [MOVEMODE_SPRINT] = {
            string.format(dir, "plastic/plastic_barrel_01.wav"),
            string.format(dir, "plastic/plastic_barrel_02.wav"),
            string.format(dir, "plastic/plastic_barrel_03.wav"),
            string.format(dir, "plastic/plastic_barrel_04.wav"),
            string.format(dir, "plastic/plastic_barrel_05.wav"),
        },
    },
}

footstepSounds.fabric = footstepSounds.carpet

local MAT_GRAVEL = 91
local MAT_WOODPANEL = 92
local MAT_CARPET = 93
local MAT_RUBBER = 94
local MAT_CHAINLINK = 95
local MAT_DUCT = 96
local MAT_LADDER = 97
local MAT_FLESH = 98
local MAT_METAL_BOX = 99
local MAT_METALVEHICLE = 100
local MAT_FABRIC = 101
local MAT_PLASTIC = 102
local MAT_PLASTER = 103
local MAT_CARDBOARD = 104
local MAT_SOFA = 105
local MAT_CLOTH = 106
local MAT_FABRIC = 107
local matSndTypes = {
    
    [MAT_GRASS] = "grass",
    [MAT_CONCRETE] = "concrete",
    [MAT_TILE] = "tile",
    [MAT_DIRT] = "dirt",
    [MAT_SAND] = "sand",
    [MAT_SNOW] = "snow",
    [MAT_METAL] = "metal",
    [MAT_GRATE] = "metalgrate",
    [MAT_WOOD] = "wood",
    [MAT_GLASS] = "glass",
    [MAT_SLOSH] = "mud",
    [MAT_PLASTER] = "plaster",
    [MAT_COMPUTER] = "metal",
    [MAT_DUCT] = "metalvent",
    [MAT_GRAVEL] = "gravel",
    [MAT_WOODPANEL] = "wood_panel",
    [MAT_CARPET] = "carpet",
    [MAT_RUBBER] = "rubber",
    [MAT_CHAINLINK] = "chainlink",
    [MAT_LADDER] = "ladder",
    [MAT_FLESH] = "flesh",
    [MAT_METAL_BOX] = "metal_box",
    [MAT_METALVEHICLE] = "metalhollow",
    [MAT_FABRIC] = "carpet",
    [MAT_PLASTIC] = "plastic",
    [MAT_CARDBOARD] = "cardboard",
    [MAT_SOFA] = "carpet",
    [MAT_CLOTH] = "carpet",
}

if SERVER then
    AddCSLuaFile()
end
if SERVER then
    AddCSLuaFile()
end

local cf = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)

-- CONVARS
local CS2Enabled      = CreateConVar("sv_CS2_enable",        1,   cf, "Enables/disables custom footsteps.",                0, 1)
local CS2FootVol      = CreateConVar("sv_CS2_footstep_vol",  "1", cf, "Footstep volume (0-1).",                           0, 1)
local CS2JumpVol      = CreateConVar("sv_CS2_jump_vol",      "1", cf, "Jump volume (0-1).",                               0, 1)
local CS2LandVol      = CreateConVar("sv_CS2_land_vol",      "1", cf, "Landing volume (0-1).",                            0, 1)
local CS2CrouchSteps  = CreateConVar("sv_CS2_crouch", 1, cf, "Enable footsteps while crouched.", 0, 1)
local CS2SlowSteps = CreateConVar(
    "sv_CS2_slowsteps",  0, cf,  "Enable footsteps while +walk is held (slow walk).",  0,1)

local trAddEndPos = Vector(0, 0, -25)
local trAddPly    = Vector(0, 0, 9)

local surfaceMats = {
    ["plaster"]      = MAT_PLASTER,
    ["rubber"]       = MAT_RUBBER,
    ["wood_panel"]   = MAT_WOODPANEL,
    ["mud"]          = MAT_SLOSH,
    ["gravel"]       = MAT_GRAVEL,
    ["chainlink"]    = MAT_CHAINLINK,
    ["carpet"]       = MAT_CARPET,
    ["metalvent"]    = MAT_DUCT,
    ["ladder"]       = MAT_LADDER,
    ["flesh"]        = MAT_FLESH,
    ["metal_box"]    = MAT_METAL_BOX,
    ["metalhollow"]  = MAT_METALVEHICLE,
    ["plastic"]      = MAT_PLASTIC,
    ["cardboard"]    = MAT_CARDBOARD,
    ["carpet"]       = MAT_SOFA,
    ["carpet"]       = MAT_CLOTH,
    ["carpet"]       = MAT_FABRIC,
    ["metalvehicle"] = MAT_METALVEHICLE,
    ["metal_car"]    = MAT_METALVEHICLE,
    ["metalhollow"]  = MAT_METALVEHICLE,
    ["vehicle"]      = MAT_METALVEHICLE,
    ["car"]          = MAT_METALVEHICLE, 
    ["metalcar"]     = MAT_METALVEHICLE,
    ["metal_panel"]  = MAT_METALVEHICLE,

}

local trAddEndPos = Vector(0, 0, -64)
local trAddPly    = Vector(0, 0, 16)

local footAreaOffsets = {
    Vector(0, 0, 0),
    Vector(10, 0, 0),
    Vector(-10, 0, 0),
    Vector(0, 10, 0),
    Vector(0, -10, 0),
    Vector(10, 10, 0),
    Vector(10, -10, 0),
    Vector(-10, 10, 0),
    Vector(-10, -10, 0),
}

local function DoFootTrace(ply, worldPos)
    return util.TraceLine({
        start  = worldPos,
        endpos = worldPos + trAddEndPos,
        mask   = MASK_PLAYERSOLID,
        filter = ply
    })
end

local function GetFootSurface(ply, startPos, footOffset)
    local footTr

    footTr = DoFootTrace(ply, startPos)

    if not footTr.Hit then
        footTr = DoFootTrace(ply, ply:LocalToWorld(Vector(0, -footOffset, 16)))
    end

    if not footTr.Hit then
        local base = ply:GetPos() + trAddPly
        for _, off in ipairs(footAreaOffsets) do
            local pos = base + off
            footTr = DoFootTrace(ply, pos)
            if footTr.Hit then break end
        end
    end

    if not footTr or not footTr.Hit then
        return nil
    end

    local matType = footTr.MatType
    local surfaceProp = util.GetSurfacePropName(footTr.SurfaceProps)


    if IsValid(footTr.Entity) then
        local mdl = string.lower(footTr.Entity:GetModel() or "")
        if mdl:find("couch") or mdl:find("sofa") then
            return MAT_CARPET
        end
    end

    matType = surfaceMats[surfaceProp] or matType
    return matType
end


local function IsSliding(ply)
    if CSlide then
        return ply:IsSliding()
    end

    return ply:GetNWBool("SlidingAbilityIsSliding", false)
end

---mat---
matSndTypes = matSndTypes or {
    [MAT_CONCRETE]     = "concrete",
    [MAT_METAL]        = "metal",
    [MAT_DIRT]         = "dirt",
    [MAT_VENT]         = "metalvent",
    [MAT_GRATE]        = "metalgrate",
    [MAT_TILE]         = "tile",
    [MAT_SLOSH]        = "water",
    [MAT_WOOD]         = "wood",
    [MAT_WOODPANEL]    = "wood_panel",
    [MAT_SAND]         = "sand",
    [MAT_SNOW]         = "snow",
    [MAT_GRAVEL]       = "gravel",
    [MAT_CARPET]       = "carpet",
    [MAT_GLASS]        = "glass",
    [MAT_RUBBER]       = "rubber",
    [MAT_FLESH]        = "flesh",
    [MAT_METAL_BOX]    = "metal_box",
    [MAT_METALVEHICLE] = "metalhollow",
    [MAT_PLASTIC]      = "plastic",
    [MAT_PLASTER]      = "plaster",
    [MAT_CARDBOARD]    = "cardboard",
    [MAT_SOFA]         = "carpet",
    [MAT_CLOTH]        = "carpet",
    [MAT_FABRIC]       = "carpet",
}

footstepSounds = footstepSounds or {}

local MOVEMODE_WALK   = MOVEMODE_WALK   or 1
local MOVEMODE_SPRINT = MOVEMODE_SPRINT or 2
local lastFootstepIdx = {}
local function GetFootstepSound(ply, matType, moveMode)
    local material = matSndTypes[matType]

    if ply:WaterLevel() > 0 then
        material = "water"
    end

    local matSounds = footstepSounds[material] or footstepSounds.concrete
    local snds = matSounds and matSounds[moveMode]
    if not snds or #snds == 0 then return end
    local key = ply
    local idx = (lastFootstepIdx[key] or 0) + 1
    if idx > #snds then
        idx = 1
    end
    lastFootstepIdx[key] = idx

    return snds[idx]
end

---footsteps makin---
local function DoFootstepSound(ply, foot, filter, lvl, moveMode)
    if pk_pills and pk_pills.getMappedEnt and pk_pills.getMappedEnt(ply) then return end
    if not ply:IsFlagSet(FL_ONGROUND) then return end

    local vel = ply:GetVelocity()
    local speed2D = Vector(vel.x, vel.y, 0):Length()

    local isCrouch = ply:Crouching()
    local isAlt = ply:IsWalking()

    if isCrouch and not CS2CrouchSteps:GetBool() then
        return
    end

    if isAlt and not CS2SlowSteps:GetBool() then
        return
    end
    if not isCrouch and not isAlt then
        if speed2D < 150 then
            return
        end
    end

    local footOffset = (foot - 0.5) * 12
    local startPos   = ply:LocalToWorld(Vector(0, footOffset, 16))
    local matType    = GetFootSurface(ply, startPos, footOffset)
    if not matType then return end

    local isSprinting = ply:IsSprinting()
    moveMode = moveMode or (isSprinting and MOVEMODE_SPRINT or MOVEMODE_WALK)
    local footstepSnd = GetFootstepSound(ply, matType, moveMode)
    if not footstepSnd then return end

    ply:EmitSound(footstepSnd, lvl or 75, 100, CS2FootVol:GetFloat(), CHAN_STATIC, 0, 0, filter)
end


-- LADDAR snd (standoff2)

local ladderSounds = {
    ladder = {
        ")player/footsteps/CS2/ladder/ladder_01.ogg",
        ")player/footsteps/CS2/ladder/ladder_02.ogg",
        ")player/footsteps/CS2/ladder/ladder_03.ogg",
        ")player/footsteps/CS2/ladder/ladder_04.ogg",
    }
}   

---landingssss---
local landSounds = {
    concrete = {
        ")player/footsteps/CS2/land/concrete_land_01.ogg",
        ")player/footsteps/CS2/land/concrete_land_02.ogg",
        ")player/footsteps/CS2/land/concrete_land_03.ogg",
        ")player/footsteps/CS2/land/concrete_land_04.ogg",
    },
    wood = {
        ")player/footsteps/CS2/land/land_wood_01.ogg",
        ")player/footsteps/CS2/land/land_wood_02.ogg",
        ")player/footsteps/CS2/land/land_wood_03.ogg",
        ")player/footsteps/CS2/land/land_wood_04.ogg",
        ")player/footsteps/CS2/land/land_wood_05.ogg",
    },
    wood_panel = {
        ")player/footsteps/CS2/land/land_wood_01.ogg",
        ")player/footsteps/CS2/land/land_wood_02.ogg",
        ")player/footsteps/CS2/land/land_wood_03.ogg",
        ")player/footsteps/CS2/land/land_wood_04.ogg",
        ")player/footsteps/CS2/land/land_wood_05.ogg",
    },
    metal = {
        ")player/footsteps/CS2/land/land_metal_solid_01.ogg",
        ")player/footsteps/CS2/land/land_metal_solid_02.ogg",
        ")player/footsteps/CS2/land/land_metal_solid_03.ogg",
        ")player/footsteps/CS2/land/land_metal_solid_04.ogg",
        ")player/footsteps/CS2/land/land_metal_solid_05.ogg",
        ")player/footsteps/CS2/land/land_metal_solid_06.ogg",
    },
    metalhollow = {
        ")player/footsteps/CS2/land/land_auto_01.ogg",
        ")player/footsteps/CS2/land/land_auto_02.ogg",
        ")player/footsteps/CS2/land/land_auto_03.ogg",
        ")player/footsteps/CS2/land/land_auto_04.ogg",
        ")player/footsteps/CS2/land/land_auto_05.ogg",
    },
    grass = {
        ")player/footsteps/CS2/land/land_grass_01.ogg",
        ")player/footsteps/CS2/land/land_grass_02.ogg",
        ")player/footsteps/CS2/land/land_grass_03.ogg",
        ")player/footsteps/CS2/land/land_grass_04.ogg",
        ")player/footsteps/CS2/land/land_grass_05.ogg",
    },
    carpet = {
        ")player/footsteps/CS2/land/land_carpet_01.ogg",
        ")player/footsteps/CS2/land/land_carpet_02.ogg",
        ")player/footsteps/CS2/land/land_carpet_03.ogg",
        ")player/footsteps/CS2/land/land_carpet_04.ogg",
        ")player/footsteps/CS2/land/land_carpet_05.ogg",
    },
    gravel = {
        ")player/footsteps/CS2/land/land_gravel_01.ogg",
        ")player/footsteps/CS2/land/land_gravel_02.ogg",
        ")player/footsteps/CS2/land/land_gravel_03.ogg",
        ")player/footsteps/CS2/land/land_gravel_04.ogg",
        ")player/footsteps/CS2/land/land_gravel_05.ogg",
    },
    sand = {
        ")player/footsteps/CS2/land/land_sand_01.ogg",
        ")player/footsteps/CS2/land/land_sand_02.ogg",
        ")player/footsteps/CS2/land/land_sand_03.ogg",
        ")player/footsteps/CS2/land/land_sand_04.ogg",
        ")player/footsteps/CS2/land/land_sand_05.ogg",
        ")player/footsteps/CS2/land/land_sand_06.ogg",
    },
    snow = {
        ")player/footsteps/CS2/land/land_snow_01.ogg",
        ")player/footsteps/CS2/land/land_snow_02.ogg",
        ")player/footsteps/CS2/land/land_snow_03.ogg",
        ")player/footsteps/CS2/land/land_snow_04.ogg",
        ")player/footsteps/CS2/land/land_snow_05.ogg",
        ")player/footsteps/CS2/land/land_snow_06.ogg",
    },
    mud = {
        ")player/footsteps/CS2/land/land_mud_01.ogg",
        ")player/footsteps/CS2/land/land_mud_02.ogg",
        ")player/footsteps/CS2/land/land_mud_03.ogg",
        ")player/footsteps/CS2/land/land_mud_04.ogg",
        ")player/footsteps/CS2/land/land_mud_05.ogg",
    },
    metalgrate = {
        ")player/footsteps/CS2/land/land_metal_grate_01.ogg",
        ")player/footsteps/CS2/land/land_metal_grate_02.ogg",
        ")player/footsteps/CS2/land/land_metal_grate_03.ogg",
        ")player/footsteps/CS2/land/land_metal_grate_04.ogg",
        ")player/footsteps/CS2/land/land_metal_grate_05.ogg",
    },
    metalvent = {
        ")player/footsteps/CS2/land/land_metal_vent_01.ogg",
        ")player/footsteps/CS2/land/land_metal_vent_02.ogg",
        ")player/footsteps/CS2/land/land_metal_vent_03.ogg",
        ")player/footsteps/CS2/land/land_metal_vent_04.ogg",
        ")player/footsteps/CS2/land/land_metal_vent_05.ogg",
        ")player/footsteps/CS2/land/land_metal_vent_06.ogg",
    },
    tile = {
        ")player/footsteps/CS2/land/land_tile_1.ogg",
        ")player/footsteps/CS2/land/land_tile_2.ogg",
        ")player/footsteps/CS2/land/land_tile_3.ogg",
        ")player/footsteps/CS2/land/land_tile_4.ogg",
        ")player/footsteps/CS2/land/land_tile_5.ogg",
    },
    rubber = {
        ")player/footsteps/CS2/land/land_rubber_01.ogg",
        ")player/footsteps/CS2/land/land_rubber_02.ogg",
        ")player/footsteps/CS2/land/land_rubber_03.ogg",
        ")player/footsteps/CS2/land/land_rubber_04.ogg",
        ")player/footsteps/CS2/land/land_rubber_05.ogg",
        ")player/footsteps/CS2/land/land_rubber_06.ogg",
    },
    glass = {
        ")player/footsteps/CS2/land/land_glass_01.ogg",
        ")player/footsteps/CS2/land/land_glass_02.ogg",
        ")player/footsteps/CS2/land/land_glass_03.ogg",
        ")player/footsteps/CS2/land/land_glass_04.ogg",
        ")player/footsteps/CS2/land/land_glass_05.ogg",
    },
    dirt = {
        ")player/footsteps/CS2/land/land_dirt_01.ogg",
        ")player/footsteps/CS2/land/land_dirt_02.ogg",
        ")player/footsteps/CS2/land/land_dirt_03.ogg",
        ")player/footsteps/CS2/land/land_dirt_04.ogg",
        ")player/footsteps/CS2/land/land_dirt_05.ogg",
    },
    water = {
        ")player/footsteps/CS2/land/land_wata_01.ogg",
        ")player/footsteps/CS2/land/land_wata_02.ogg",
        ")player/footsteps/CS2/land/land_wata_03.ogg",
        ")player/footsteps/CS2/land/land_wata_04.ogg",
    },
    chainlink = {
        ")player/footsteps/CS2/land/land_chainlink_01.ogg",
        ")player/footsteps/CS2/land/land_chainlink_02.ogg",
        ")player/footsteps/CS2/land/land_chainlink_03.ogg",
        ")player/footsteps/CS2/land/land_chainlink_04.ogg",
    },
    flesh = {
        ")player/footsteps/CS2/land/land_body_01.ogg",
        ")player/footsteps/CS2/land/land_body_02.ogg",
        ")player/footsteps/CS2/land/land_body_03.ogg",
        ")player/footsteps/CS2/land/land_body_04.ogg",
        ")player/footsteps/CS2/land/land_body_05.ogg",
        ")player/footsteps/CS2/land/land_body_06.ogg",
    },
    plastic = {
        ")player/footsteps/CS2/land/land_plastic_milkcrates_01.wav",
        ")player/footsteps/CS2/land/land_plastic_milkcrates_02.wav",
        ")player/footsteps/CS2/land/land_plastic_milkcrates_03.wav",
        ")player/footsteps/CS2/land/land_plastic_milkcrates_04.wav",
    },
    plaster = {
        ")player/footsteps/CS2/land/land_plastic_milkcrates_01.wav",
        ")player/footsteps/CS2/land/land_plastic_milkcrates_02.wav",
        ")player/footsteps/CS2/land/land_plastic_milkcrates_03.wav",
        ")player/footsteps/CS2/land/land_plastic_milkcrates_04.wav",
    },
    metal_box = {
        ")player/footsteps/CS2/land/land_metal_barrel_01.ogg",
        ")player/footsteps/CS2/land/land_metal_barrel_02.ogg",
        ")player/footsteps/CS2/land/land_metal_barrel_03.ogg",
    },
    cardboard = {
        ")player/footsteps/CS2/land/land_cardboard_01.ogg",
        ")player/footsteps/CS2/land/land_cardboard_02.ogg",
        ")player/footsteps/CS2/land/land_cardboard_03.ogg",
    },
}


---hooks land and jump
local JUMP_SOUND = ")player/footsteps/CS2/jump_launch_01.ogg"
local PLAYER_FALL_PUNCH_THRESHOLD = 150

hook.Add("OnPlayerJump", "CS2.JumpSound", function(ply, speed)
    if not CS2Enabled:GetBool() then return end

    local filter
    if SERVER and not game.SinglePlayer() then
        filter = RecipientFilter()
        filter:AddPAS(ply:GetPos())
        filter:RemovePlayer(ply)
    end

    ply:EmitSound(JUMP_SOUND, 90, 100, CS2JumpVol:GetFloat(), CHAN_STATIC, 0, 0, filter)
end)

hook.Add("OnPlayerHitGround", "CS2.CustomLandMaterial", function(ply, inWater, onFloater, speed)
    if not CS2Enabled:GetBool() or (CLIENT and not IsFirstTimePredicted()) then
        return
    end

    local footOffset = 0
    local startPos = ply:LocalToWorld(Vector(0, footOffset, 16))
    local matType = GetFootSurface(ply, startPos, footOffset)
    if not matType then return end

    local material = matSndTypes[matType] or "concrete"
    local snds = landSounds[material]
    if not snds or #snds == 0 then return end

    local idx = math.Round(util.SharedRandom("CS2.LandSound", 1, #snds))
    local landSnd = snds[idx]

    local filter
    if SERVER and not game.SinglePlayer() then
        filter = RecipientFilter()
        filter:AddPAS(ply:GetPos())
        filter:RemovePlayer(ply)
    end

    local vol = CS2LandVol:GetFloat()
    if speed > PLAYER_FALL_PUNCH_THRESHOLD then
        vol = math.min(vol * 1.2, 1)
    end

    ply:EmitSound(landSnd, 90, 100, vol, CHAN_STATIC, 0, 0, filter)
end)



local enforcedSnds = {}
local footstepPath = "player/footsteps/"
local altPaths = {
    ["physics/plaster/drywall_footst"]     = false,
    ["physics/glass/glass_sheet_step"]    = true,
    ["physics/plaster/ceiling_tile_s"]    = false,
    ["physics/body/medium_impact_soft7"]  = true,
    ["physics/body/medium_impact_hard"]   = true,
    ["physics/flesh/medium_impact_hard"]  = true,
    ["physics/metal/metal_box_footstep1"] = true,
    ["physics/metal/metal_box_footstep2"] = true,
    ["physics/metal/metal_box_footstep3"] = true,
    ["physics/metal/metal_box_footstep4"] = true,
}

hook.Add("PlayerFootstep", "CS2.FootstepSound", function(ply, pos, foot, snd, vol, filter)
    if not CS2Enabled:GetBool() or IsSliding(ply) then
        return
    end

    if CS2SlowSteps:GetBool() and ply:IsWalking() and not CS2SlowSteps:GetBool() then
    end
    if CLIENT and ply == LocalPlayer() then
        foot = (foot == 0) and 1 or 0
    end
    local sndName = string.sub(snd, 18, -6)
    if enforcedSnds[sndName] then
        return
    end

    DoFootstepSound(ply, foot, filter)
    return true
end)

hook.Add("EntityEmitSound", "CS2.MaskDefaultSteps", function(t)
    if not CS2Enabled:GetBool() then return end

    local snd   = t.OriginalSoundName
    local fPath = string.Left(snd, 17)

    if fPath == footstepPath or altPaths[string.Left(snd, 30)] then
        return false
    end
end)
---npc support--

local npcNoCustomSteps = {
    ["npc_hunter"]              = true,
    ["npc_zombie_torso"]        = true,
    ["npc_fastzombie_torso"]    = true,
    ["npc_zombie"]              = false,
    ["npc_fastzombie"]          = true,
    ["npc_poisonzombie"]        = true,
    ["npc_cscanner"]            = true,
    ["npc_helicopter"]          = true,
    ["npc_manhack"]             = true,
    ["npc_rollermine"]          = true,
    ["npc_rollermine_friendly"] = true,
    ["npc_rollermine_hacked"]   = true,
    ["npc_clawscanner"]         = true,
    ["npc_combinegunship"]      = true,
    ["npc_combinedropship"]     = true,
    ["npc_strider"]             = true,
    ["npc_antlion"]             = true,
    ["npc_antlionguard"]        = true,
    ["npc_antlionguardian"]     = true,
    ["npc_stalker"]             = true,
    ["npc_dog"]                 = true,
}

local npcStepPrefixes = {
    ["npc/"]             = true,
    ["npc_zombie/"]      = true,
    ["npc_fastzombie/"]  = true,
    ["npc_combine/"]     = true,
    ["npc_metropolice/"] = true,
    ["npc_citizen/"]     = true,
}

local function IsNPCStepSound(snd)
    snd = string.lower(snd or "")

    if string.find(snd, "land", 1, true)
    or string.find(snd, "landing", 1, true)
    or string.find(snd, "jump", 1, true)
    or string.find(snd, "fall", 1, true) then
        return false
    end

    if string.find(snd, "footstep", 1, true)
    or string.find(snd, "step", 1, true)
    or string.find(snd, "run", 1, true)
    or string.find(snd, "walk", 1, true) then
        return true
    end

    for pref in pairs(npcStepPrefixes) do
        if string.StartWith(snd, pref)
        and not string.find(snd, "land", 1, true)
        and not string.find(snd, "jump", 1, true)
        and not string.find(snd, "fall", 1, true) then
            return true
        end
    end

    return false
end

hook.Add("EntityEmitSound", "CS2.NPC_CustomFootsteps", function(t)
    if not CS2Enabled:GetBool() then return end

    local ent = t.Entity
    local snd = t.OriginalSoundName or ""

    local fPath = string.Left(snd, 17)
    if fPath == footstepPath or altPaths[string.Left(snd, 30)] then
        return false
    end

    if not (IsValid(ent) and ent:IsNPC() and IsNPCStepSound(snd)) then
        return
    end

    local class = ent:GetClass()
    if npcNoCustomSteps[class] then
        return
    end

    local npc = ent
    local vel = npc:GetVelocity()
    local speed2D = Vector(vel.x, vel.y, 0):Length()

    local moveMode
    if speed2D < 90 then
        moveMode = MOVEMODE_SLOWWALK
    else
        moveMode = MOVEMODE_WALK
    end

    local footOffset = 0
    local startPos   = npc:LocalToWorld(Vector(0, footOffset, 16))
    local matType    = GetFootSurface(npc, startPos, footOffset) or MAT_CONCRETE

    local footstepSnd = GetFootstepSound(npc, matType, moveMode)
    if not footstepSnd then
        return false
    end
    if SERVER then
    util.AddNetworkString("CS2.SyncSlowSteps")

    cvars.AddChangeCallback("sv_CS2_slowsteps", function(_, _, new)
        net.Start("CS2.SyncSlowSteps")
        net.WriteBool(tonumber(new) == 1)
        net.Broadcast()
    end)

    hook.Add("PlayerInitialSpawn", "CS2.SyncSlowStepsInit", function(ply)
        timer.Simple(1, function()
            if not IsValid(ply) then return end
            net.Start("CS2.SyncSlowSteps")
            net.WriteBool(CS2SlowSteps:GetBool())
            net.Send(ply)
        end)
    end)
end

if CLIENT then
    cvars.AddChangeCallback("cl_CS2_slowsteps", function(_, _, new)
        RunConsoleCommand("sv_CS2_slowsteps", new)
    end)

    net.Receive("CS2.SyncSlowSteps", function()
        local enabled = net.ReadBool() and "1" or "0"
        RunConsoleCommand("cl_CS2_slowsteps", enabled)
    end)
end


    sound.Play(footstepSnd, t.Pos or npc:GetPos(), 75, 100, CS2FootVol:GetFloat())
    return false
end)
if CLIENT then
    hook.Add("AddToolMenuTabs", "CS2FeetAddTab", function()
        spawnmenu.AddToolTab("CS2Feet", "CS2 Feet", "icon16/sound.png")
    end)

    hook.Add("PopulateToolMenu", "CS2FeetPopulate", function()
        spawnmenu.AddToolMenuOption("CS2Feet", "Settings", "CS2FootFetishConfigzamn", "Footsteps", "", "", function(panel)
            panel:ClearControls()
            panel:CheckBox("Enable CS2 footsteps", "sv_CS2_enable")
            panel:CheckBox("Footsteps while crouched", "sv_CS2_crouch")
            panel:CheckBox("Slow walk footsteps (+walk/ALT)", "sv_CS2_slowsteps")
            panel:NumSlider("Footstep volume", "sv_CS2_footstep_vol", 0, 1, 2)
            panel:NumSlider("Landing sound volume", "sv_CS2_land_vol", 0, 1, 2)
        end)
    end)
end
