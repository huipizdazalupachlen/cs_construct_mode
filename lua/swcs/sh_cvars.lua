AddCSLuaFile()

SWCS_DEBUG_AE = CreateConVar("swcs_debug_animevent", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "")
SWCS_DEBUG_RECOIL = CreateConVar("swcs_debug_recoil", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "")
SWCS_DEBUG_RECOIL_DECAY = CreateConVar("swcs_debug_decay", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "")
SWCS_DEBUG_PENETRATION = CreateConVar("swcs_debug_penetration", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "")

SWCS_SPREAD_MAX_SEEDS = CreateConVar("swcs_weapon_max_spread_seed", "255", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "how many spread seeds csgo weapons can have")
SWCS_SPREAD_SHARE_SEED = CreateConVar("swcs_weapon_sync_seed", "1", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "synchronize spread seeds on server and client")

SWCS_DEPLOY_OVERRIDE = CreateConVar("swcs_deploy_override", "1", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "deploy speed override multiplier")
SWCS_INDIVIDUAL_AMMO = CreateConVar("swcs_weapon_individual_ammo", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "weapons store their own ammo, and don't pull from player's ammo")
SWCS_UNLIMITED_RANGE = CreateConVar("swcs_weapon_unlimited_range", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "weapons have unlimited range")

CreateConVar("swcs_helmet_on_spawn", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "give players helmets when respawning")
CreateConVar("swcs_defuser_on_spawn", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "give players defusers when respawning")

if CLIENT then
	CreateClientConVar("swcs_crosshair_use_spectator", "1", true, nil, "Use the crosshair of the player you're spectating")
	CreateClientConVar("swcs_crosshair_recoil", "0", true, nil, "Recoil/aimpunch will move the user's crosshair to show the effect")
	CreateClientConVar("swcs_crosshair_fixedgap", "3", true, nil, "How big to make the gap between the pips in the fixed crosshair")
	CreateClientConVar("cl_bob_lower_amt", "21", nil, nil, "The amount the viewmodel lowers when running", 5, 30)
	CreateClientConVar("swcs_crosshairstyle", "4", true, nil, "0 = DEFAULT, 1 = DEFAULT STATIC, 2 = ACCURATE SPLIT (accurate recoil/spread feedback with a fixed inner part) 3 = ACCURATE DYNAMIC (accurate recoil/spread feedback) 4 = CLASSIC STATIC, 5 = OLD CS STYLE (fake recoil - inaccurate feedback)")
	CreateClientConVar("swcs_crosshairdot", "1", true)
	CreateClientConVar("swcs_crosshair_t", "0", true, nil, "T style crosshair")
	CreateClientConVar("swcs_crosshairthickness", "1", true)
	CreateClientConVar("swcs_crosshairsize", "5", true)
	CreateClientConVar("swcs_crosshairgap", "0", true)
	CreateClientConVar("swcs_crosshairgap_useweaponvalue", "0", true, nil, "If set to 1, the gap will update dynamically based on which weapon is currently equipped")
	CreateClientConVar("swcs_crosshair_drawoutline", "1", true)
	CreateClientConVar("swcs_crosshair_outlinethickness", "1", true, nil, "Set how thick you want your crosshair outline to draw (0.1-3)")
	CreateClientConVar("swcs_crosshair_dynamic_splitdist", "7", true, nil, "If using swcs_crosshairstyle 2, this is the distance that the crosshair pips will split into 2. (default is 7)")
	CreateClientConVar("swcs_crosshair_dynamic_splitalpha_innermod", "1", true, nil, "If using swcs_crosshairstyle 2, this is the alpha modification that will be used for the INNER crosshair pips once they've split. [0 - 1]")
	CreateClientConVar("swcs_crosshair_dynamic_splitalpha_outermod", "0.5", true, nil, "If using swcs_crosshairstyle 2, this is the alpha modification that will be used for the OUTER crosshair pips once they've split. [0.3 - 1]")
	CreateClientConVar("swcs_crosshair_dynamic_maxdist_splitratio", "0.35", true, nil, "If using swcs_crosshairstyle 2, this is the ratio used to determine how long the inner and outer xhair pips will be. [inner = swcs_crosshairsize*(1-swcs_crosshair_dynamic_maxdist_splitratio) outer = swcs_crosshairsize*swcs_crosshair_dynamic_maxdist_splitratio]  [0 - 1]")
	CreateClientConVar("swcs_crosshaircolor", "1", true)
	CreateClientConVar("swcs_crosshairusealpha", "0", true)
	CreateClientConVar("swcs_crosshaircolor_r", "255", true)
	CreateClientConVar("swcs_crosshaircolor_g", "0", true)
	CreateClientConVar("swcs_crosshaircolor_b", "255", true)
	CreateClientConVar("swcs_crosshairalpha", "200", true)
	CreateClientConVar("swcs_crosshair_sniper_width", "1", true, nil, "If >1 sniper scope cross lines gain extra width (1 for single-pixel hairline)")

	CreateClientConVar("viewmodel_offset_x", "0.0", true)
	CreateClientConVar("viewmodel_offset_y", "0.0", true)
	CreateClientConVar("viewmodel_offset_z", "0.0", true)

	-- used for view model to follow spray pattern
	CreateClientConVar("viewmodel_recoil", "1.0", true, nil, "Amount of weapon recoil/aimpunch to display on viewmodel")
	CreateClientConVar("swcs_crosshair", "1", true, nil, "Enable custom crosshair")
	CreateClientConVar("swcs_righthand", "1", true, true, "Enable right handed view models")

	CreateClientConVar("swcs_enable_zoom", "1", true, true, "Enable HL2 zoom functionality")
	CreateClientConVar("swcs_contextual_zoom", "1", true, true, "Enable contextual zoom when using scoped weapon")

	CreateClientConVar("swcs_halloween_casings", "1", true, true, "Enable halloween themed shell casings during Halloween")
end
--CreateConVar("sv_showimpacts", "0", FCVAR_REPLICATED, "Shows client (red) and server (blue) bullet impact point (1=both, 2=client-only, 3=server-only)")
CreateConVar("sv_showimpacts_penetration", "0", FCVAR_REPLICATED, "Shows extra data when bullets penetrate. (use sv_showimpacts_time to increase time shown)")
CreateConVar("sv_showimpacts_time", "4", FCVAR_REPLICATED, "Duration bullet impact indicators remain before disappearing")

-- used in calcview to follow spray pattern
CreateConVar("view_recoil_tracking", "0.45", FCVAR_REPLICATED, "How closely the view tracks with the aim punch from weapon recoil")

if CLIENT then
	CreateConVar("weapon_debug_spread_show", "0", FCVAR_REPLICATED, "Enables display of weapon accuracy; 1: show accuracy box, 3: show accuracy with dynamic crosshair")
end
CreateConVar("weapon_near_empty_sound", "1", FCVAR_REPLICATED, "")
CreateConVar("weapon_air_spread_scale", "1.0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Scale factor for jumping inaccuracy, set to 0 to make jumping accuracy equal to standing")
CreateConVar("weapon_recoil_decay_coefficient", "2.0", FCVAR_REPLICATED, "")
CreateConVar("weapon_accuracy_forcespread", "0", FCVAR_REPLICATED, "Force spread to the specified value.")
CreateConVar("weapon_accuracy_nospread", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Disable weapon inaccuracy spread")
CreateConVar("weapon_accuracy_shotgun_spread_patterns", "1", {FCVAR_REPLICATED, FCVAR_ARCHIVE})
CreateConVar("weapon_recoil_cooldown", "0.55", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Amount of time needed between shots before restarting recoil")
CreateConVar("weapon_recoil_scale", "2", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Overall scale factor for recoil.")
CreateConVar("weapon_recoil_view_punch_extra", "0.055", {FCVAR_REPLICATED, FCVAR_ARCHIVE}, "Additional (non-aim) punched added to view from recoil")
