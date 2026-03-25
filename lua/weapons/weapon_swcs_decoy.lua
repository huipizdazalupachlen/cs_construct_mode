SWEP.Base = "weapon_swcs_base_grenade"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Slot = 4

SWEP.Primary.Ammo = swcs.InTTT and "none" or "swcs_decoygrenade"

SWEP.PrintName = "Decoy"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_decoy.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_eq_decoy.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/decoy.png", "smooth")
end


sound.Add({
	name = "Decoy.PullPin_Grenade",
	channel = CHAN_WEAPON,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound("weapons/csgo/decoy/pinpull.wav"),
})
sound.Add({
	name = "Decoy.PullPin_Grenade_Start",
	channel = CHAN_ITEM,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound("weapons/csgo/decoy/pinpull_start.wav"),
})
sound.Add({
	name = "Decoy.Draw",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.3,
	pitch = 100,
	sound = Sound("weapons/csgo/decoy/decoy_draw.wav"),
})
sound.Add({
	name = "Decoy.Throw",
	channel = CHAN_STATIC,
	level = 75,
	volume = 1,
	pitch = 100,
	sound = Sound("weapons/csgo/decoy/grenade_throw.wav"),
})

SWEP.ItemDefAttributes = [=["attributes 10/14/23" {
	"max player speed"		"245"
	"in game price"		"50"
	"penetration"		"1"
	"damage"		"50"
	"range"		"4096"
	"range modifier"		"0.990000"
	"throw velocity"		"750.000000"
	"primary default clip size"		"1"
	"secondary default clip size"		"1"
	"weapon weight"		"1"
	"itemflag exhaustible"		"1"
	"max player speed alt"		"245"
}]=]
SWEP.ItemDefVisuals = [=["visuals 10/14/23" {
	"weapon_type"		"Grenade"
	"player_animation_extension"		"gren"
	"primary_ammo"		"AMMO_TYPE_DECOY"
	"sound_single_shot"		"Decoy.Throw"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:EmitGrenade()
	if SERVER then
		local selfTable = self:GetTable()
		local ent = ents.Create("swcs_decoy_projectile")
		local entTable = ent:GetTable()
		entTable.ItemAttributes = selfTable.ItemAttributes
		entTable.ItemVisuals = selfTable.ItemVisuals
		return ent
	else
		return NULL
	end
end
