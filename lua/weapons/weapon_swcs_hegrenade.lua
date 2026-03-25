SWEP.Base = "weapon_swcs_base_grenade"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Slot = 4

if swcs.InTTT then
	SWEP.AutoSpawnable = false

	SWEP.Slot = 3

	SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy

	SWEP.IsSilent = false
	SWEP.Kind = WEAPON_NADE

	if CLIENT then
		SWEP.EquipMenuData = {
			type = "item_weapon",
			desc = "The high explosive fragmentation grenade\nadministers high damage through a wide area,\nmaking it ideal for clearing out hostile rooms.",
		}
	end
end

SWEP.Primary.Ammo = swcs.InTTT and "none" or "swcs_hegrenade"
SWEP.AutoSpawnable = false

SWEP.PrintName = "HE Grenade"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_fraggrenade.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_eq_fraggrenade.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/hegrenade.png", "smooth")
end


sound.Add({
	name = "HEGrenade.PullPin_Grenade_Start",
	channel = CHAN_WEAPON,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound("weapons/csgo/hegrenade/pinpull.wav"),
})
sound.Add({
	name = "HEGrenade.PullPin_Grenade",
	channel = CHAN_ITEM,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound("weapons/csgo/hegrenade/pinpull_start.wav"),
})
sound.Add({
	name = "HEGrenade.Throw",
	channel = CHAN_STATIC,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound(")weapons/csgo/hegrenade/grenade_throw.wav"),
})
sound.Add({
	name = "HEGrenade.Draw",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.3,
	pitch = 100,
	sound = Sound(")weapons/csgo/hegrenade/he_draw.wav"),
})
sound.Add({
	name = "HEGrenade.Bounce",
	channel = CHAN_ITEM,
	volume = 0.6,
	level = 75,
	pitch = 100,
	sound = Sound(")weapons/csgo/hegrenade/he_bounce-1.wav"),
})
sound.Add({
	name = "HEGrenade.Explode",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 140,
	pitch = 100,
	sound = {Sound(")weapons/csgo/hegrenade/hegrenade_detonate_02.wav"), Sound(")weapons/csgo/hegrenade/hegrenade_detonate_03.wav")},
})

SWEP.ItemDefAttributes = [=["attributes 09/03/2020" {
	"max player speed"		"245"
	"in game price"		"200"
	"crosshair min distance"		"7"
	"penetration"		"1"
	"armor ratio"		"1.200000"
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
	"sound_single_shot"		"HEGrenade.Throw"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:EmitGrenade()
	if SERVER then
		local selfTable = self:GetTable()
		local ent = ents.Create("swcs_hegrenade_projectile")
		local entTable = ent:GetTable()
		entTable.ItemAttributes = selfTable.ItemAttributes
		entTable.ItemVisuals = selfTable.ItemVisuals

		return ent
	else
		return NULL
	end
end
