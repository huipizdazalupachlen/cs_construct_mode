SWEP.Base = "weapon_swcs_shield"
SWEP.Category = "#spawnmenu.category.swcs"

DEFINE_BASECLASS(SWEP.Base)

SWEP.Slot = 0

SWEP.PrintName = "Ballistic Shield"
SWEP.Spawnable = true
SWEP.HoldType = "melee2"
SWEP.NoCustomViewmodelPos = true
SWEP.IsShield = true

SWEP.ViewModel = Model("models/weapons/csgo/v_balshield.mdl")
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_balshield.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/balshield.png", "smooth")
end

util.PrecacheModel("models/weapons/csgo/w_eq_balshield.mdl")
for i = 1, 10 do
	util.PrecacheModel("models/weapons/csgo/balshield_gibs/shield_gib" .. i .. ".mdl")
end

SWEP.ShieldOffset = Vector(1.5, -0.75, -5)
SWEP.ShieldOffsetBack = Vector(-2, 0, 8)
SWEP.ShieldAngle = {165, 5, -90}
SWEP.ShieldAngleBack = {95, 185, -15}

if swcs.InTTT then
	SWEP.AutoSpawnable = false

	SWEP.Slot = 6

	SWEP.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

	SWEP.Kind = WEAPON_EQUIP

	if CLIENT then
		SWEP.EquipMenuData = {
			type = "item_weapon",
			desc = "A ballistic shield which can block a large amount\nof damage before being destroyed.",
		}
	end
end
