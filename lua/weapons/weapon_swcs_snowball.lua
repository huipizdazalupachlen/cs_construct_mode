SWEP.Base = "weapon_swcs_base_grenade"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Slot = 4

SWEP.Primary.Ammo = swcs.InTTT and "none" or "swcs_snowball"
SWEP.AutoSpawnable = false
SWEP.TTTPreventSpawning = true

SWEP.PrintName = "Snowball"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_snowball.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_eq_snowball.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/snowball.png", "smooth")
end

sound.Add({
	name = "Snowball.Impact",
	--channel = CHAN_STATIC,
	level = 65,
	volume = 0.95,
	pitch = 100,
	sound = {
		Sound("physics/surfaces/sand_impact_bullet1.wav"),
		Sound("physics/surfaces/sand_impact_bullet2.wav"),
		Sound("physics/surfaces/sand_impact_bullet3.wav"),
		Sound("physics/surfaces/sand_impact_bullet4.wav"),
	},
})
sound.Add({
	name = "Snowball.HitPlayerFace",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.7,
	pitch = 100,
	sound = {
		Sound("physics/body/body_impact_self_06.wav"),
		Sound("physics/body/body_impact_self_07.wav"),
		Sound("physics/body/body_impact_self_08.wav"),
	},
})
sound.Add({
	name = "Player.SnowballThrow",
	channel = CHAN_STATIC,
	level = 75,
	volume = 0.5,
	pitch = {98, 102},
	sound = {
		Sound(")player/csgo/winter/snowball_throw_02.wav"),
		Sound(")player/csgo/winter/snowball_throw_03.wav"),
		Sound(")player/csgo/winter/snowball_throw_04.wav"),
	},
})
sound.Add({
	name = "Player.SnowballEquip",
	channel = CHAN_STATIC,
	level = 75,
	volume = 0.2,
	pitch = {98, 102},
	sound = {
		Sound("player/csgo/winter/snowball_equip_01.wav"),
		Sound("player/csgo/winter/snowball_equip_02.wav"),
		Sound("player/csgo/winter/snowball_equip_03.wav"),
	},
})
sound.Add({
	name = "Player.SnowballPickup",
	channel = CHAN_STATIC,
	level = 75,
	volume = {0.5, 1},
	pitch = {95, 110},
	sound = {
		Sound("player/csgo/winter/snowball_pickup_01.wav"),
		Sound("player/csgo/winter/snowball_pickup_02.wav"),
		Sound("player/csgo/winter/snowball_pickup_03.wav"),
	},
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
	"sound_single_shot"		"Player.SnowballThrow"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:EmitGrenade()
	if SERVER then
		return ents.Create("swcs_snowball_projectile")
	end

	return NULL
end
