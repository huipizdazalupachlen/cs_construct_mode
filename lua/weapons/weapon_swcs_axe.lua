SWEP.Base = "weapon_swcs_base_melee_throwable"
SWEP.Category = "#spawnmenu.category.swcs"

DEFINE_BASECLASS(SWEP.Base)

SWEP.Slot = 0

SWEP.PrintName = "Axe"
SWEP.Spawnable = true
SWEP.HoldType = "knife"

SWEP.WorldModel = Model("models/weapons/csgo/w_axe.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_axe.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/axe.png", "smooth")
end

SWEP.Swing1Damage = 24
SWEP.Swing2Damage = 20

SWEP.BackstabPrimaryDamage = 40

SWEP.ItemDefAttributes = [=["attributes 08/03/2020" {
	"primary clip size" "-1"
	"is full auto" "1"
	"armor ratio"		"1.700000"
	"recoil seed" "0"
	"recoil angle variance" "0"
	"recoil magnitude" "0"
	"recoil magnitude variance" "0"
	"recoil angle variance alt" "0"
	"recoil magnitude alt" "0"
	"recoil magnitude variance alt" "0"
}]=]
SWEP.ItemDefVisuals = [=["visuals 08/03/2020" {
	"weapon_type" "Melee"
}]=]

SWEP.IsKnife = true
SWEP.AutoSpawnable = false
SWEP.TTTPreventSpawning = true
