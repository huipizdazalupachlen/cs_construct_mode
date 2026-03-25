SWEP.Base = "weapon_swcs_base_grenade"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Slot = 4

SWEP.Primary.Ammo = "pistol"

SWEP.PrintName = "Test Grenade"
SWEP.Spawnable = false
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_snowball_dropped.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_eq_smokegrenade.mdl")

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
	"sound_single_shot"		"Flashbang.Throw"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:EmitGrenade()
	if SERVER then
		return ents.Create("swcs_testnade_projectile")
	else
		return NULL
	end
end
