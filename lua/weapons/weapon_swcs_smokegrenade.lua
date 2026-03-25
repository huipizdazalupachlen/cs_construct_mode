SWEP.Base = "weapon_swcs_base_grenade"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Slot = 4

SWEP.Primary.Ammo = swcs.InTTT and "none" or "swcs_smokegrenade"

SWEP.PrintName = "Smoke Grenade"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_smokegrenade.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_eq_smokegrenade.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/smokegrenade.png", "smooth")
end

sound.Add({
	name = "SmokeGrenade.PullPin_Grenade_Start",
	channel = CHAN_WEAPON,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound("weapons/csgo/smokegrenade/pinpull.wav"),
})
sound.Add({
	name = "SmokeGrenade.PullPin_Grenade",
	channel = CHAN_ITEM,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound("weapons/csgo/smokegrenade/pinpull_start.wav"),
})
sound.Add({
	name = "SmokeGrenade.Draw",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.3,
	pitch = 100,
	sound = Sound(")weapons/csgo/smokegrenade/smokegrenade_draw.wav"),
})
sound.Add({
	name = "SmokeGrenade_CSGO.Throw",
	channel = CHAN_STATIC,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound(")weapons/csgo/smokegrenade/grenade_throw.wav"),
})
sound.Add({
	name = "SmokeGrenade_CSGO.Bounce",
	channel = CHAN_STATIC,
	level = 75,
	volume = 0.6,
	pitch = 100,
	sound = Sound(")weapons/csgo/smokegrenade/grenade_hit1.wav"),
})

SWEP.ItemDefAttributes = [=["attributes 09/03/2020" {
	"max player speed"		"245"
	"in game price"		"200"
	"crosshair min distance"		"7"
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
SWEP.ItemDefVisuals = [=["visuals 09/03/2020" {
	"weapon_type"		"Grenade"
	"player_animation_extension"		"gren"
	"primary_ammo"		"AMMO_TYPE_FLASHBANG"
	"sound_single_shot"		"SmokeGrenade_CSGO.Throw"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:EmitGrenade()
	if SERVER then
		return ents.Create("swcs_smokegrenade_projectile")
	else
		return NULL
	end
end
