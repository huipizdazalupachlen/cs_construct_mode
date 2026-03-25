SWEP.Base = "weapon_swcs_base_grenade"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Slot = 4

SWEP.Primary.Ammo = swcs.InTTT and "none" or "swcs_firegrenade"

SWEP.PrintName = "Incendiary Grenade"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_incendiarygrenade.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_eq_incendiarygrenade.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/incgrenade.png", "smooth")
end

sound.Add({
	name = "IncGrenade.Bounce",
	channel = CHAN_STATIC,
	volume = 0.6,
	sound = Sound(")weapons/csgo/incgrenade/inc_grenade_bounce-1.wav"),
})
sound.Add({
	name = "IncGrenade.PullPin_Grenade_Start",
	channel = CHAN_ITEM,
	volume = 1.0,
	pitch = 100,
	level = 65,
	sound = Sound("weapons/csgo/incgrenade/pinpull_start.wav"),
})
sound.Add({
	name = "IncGrenade.PullPin_Grenade",
	channel = CHAN_WEAPON,
	volume = 1.0,
	pitch = 100,
	level = 65,
	sound = Sound("weapons/csgo/incgrenade/pinpull.wav"),
})
sound.Add({
	name = "IncGrenade.Draw",
	channel = CHAN_STATIC,
	volume = 0.3,
	pitch = 100,
	level = 65,
	sound = Sound("weapons/csgo/incgrenade/inc_grenade_draw.wav"),
})
sound.Add({
	name = "IncGrenade.Throw",
	channel = CHAN_ITEM,
	volume = 0.3,
	pitch = 100,
	level = 65,
	sound = Sound("weapons/csgo/incgrenade/inc_grenade_throw.wav"),
})
sound.Add({
	name = "Inferno.Start_IncGrenade",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 95,
	sound = {Sound("weapons/csgo/incgrenade/inc_grenade_detonate_1.wav"), Sound("weapons/csgo/incgrenade/inc_grenade_detonate_2.wav"), Sound("weapons/csgo/incgrenade/inc_grenade_detonate_3.wav")},
})

SWEP.ItemDefAttributes = [=["attributes 09/03/2020" {
	"max player speed"		"245"
	"in game price"		"200"
	"crosshair min distance"		"7"
	"penetration"		"1"
	"damage"		"99"
	"range"		"350"
	"range modifier"		"0.990000"
	"throw velocity"		"750.000000"
	"primary default clip size"		"1"
	"secondary default clip size"		"1"
	"weapon weight"		"1"
	"itemflag exhaustible"		"1"
	"max player speed alt"		"245"
}]=]
SWEP.ItemDefVisuals = [=["visuals 09/03/2020" {
	"weapon_type"		"Grenade"
	"player_animation_extension"		"gren"
	"primary_ammo"		"AMMO_TYPE_FLASHBANG"
	"sound_single_shot"		"IncGrenade.Throw"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:EmitGrenade()
	if SERVER then
		local selfTable = self:GetTable()
		local ent = ents.Create("swcs_molotov_projectile")
		local entTable = ent:GetTable()
		entTable.ItemAttributes = selfTable.ItemAttributes
		entTable.ItemVisuals = selfTable.ItemVisuals
		entTable.SetIsIncGrenade(ent, true)

		return ent
	else
		return NULL
	end
end
