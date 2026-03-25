SWEP.Base = "weapon_swcs_base_item"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Primary.Ammo = "swcs_healthshot"

if swcs.InTTT then
	SWEP.AutoSpawnable = false

	SWEP.Slot = 7

	SWEP.CanBuy = {ROLE_TRAITOR, ROLE_DETECTIVE}

	SWEP.Kind = WEAPON_EQUIP2

	if CLIENT then
		SWEP.EquipMenuData = {
			type = "item_weapon",
			desc = "Restores a portion of your health and provides\na brief speed boost.",
		}
	end
end

SWEP.PrintName = "Medi-Shot"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_healthshot.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_healthshot.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/healthshot.png", "smooth")
end

DEFINE_BASECLASS(SWEP.Base)

sound.Add({
	name = "Healthshot.Success",
	channel = CHAN_STATIC,
	level = 75,
	volume = 0.6,
	sound = Sound(")items/csgo/healthshot_success_01.wav"),
})
sound.Add({
	name = "Healthshot.Thud",
	channel = CHAN_STATIC,
	level = 75,
	volume = 0.6,
	sound = Sound(")items/csgo/healthshot_thud_01.wav"),
})
sound.Add({
	name = "Healthshot.Prepare",
	channel = CHAN_STATIC,
	level = 75,
	volume = 1.0,
	sound = Sound(")items/csgo/healthshot_prepare_01.wav"),
})

SWEP.ItemDefAttributes = [=["attributes 08/25/2023" {
	"max player speed"		"250"
	"in game price"		"0"
	"armor ratio"		"1.000000"
	"penetration"		"1"
	"crosshair min distance"		"6"
	"damage"		"50"
	"range"		"4096"
	"range modifier"		"0.990000"
	"weapon weight"		"0"
	"max player speed alt"		"250"
	"itemflag exhaustible"		"1"
	"primary default clip size"		"1"
	"secondary default clip size"		"1"
}]=]
SWEP.ItemDefVisuals = [=["visuals 08/25/2023" {
	"weapon_type"		"StackableItem"
	"player_animation_extension"		"c4"
	"grenade_smoke_color"		"0.0 0.8 0.0"
	"primary_ammo"		"swcs_healthshot"
	"sound_single_shot"		"c4.plant"
	"sound_empty"		"c4.click"
	"sound_burst"		"c4.explode"
	"sound_special1"		"c4.disarmstart"
	"sound_special2"		"c4.disarmfinish"
	"sound_special3"		"c4.ExplodeWarning"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

local healthshot_allow_use_at_full = CreateConVar("swcs_healthshot_allow_use_at_full", "1", FCVAR_REPLICATED, "Whether or not the healthshot can be used when the player is at full health.", 0)
local healthshot_health = CreateConVar("swcs_healthshot_health", "50", FCVAR_REPLICATED, "The number of HP that is restored on usage, maxing out at the player's max_health", 0)
local healthshot_approach = CreateConVar("swcs_healthshot_approach_enabled", "1", FCVAR_REPLICATED, "Whether or not the HP are granted at once (0) or over time (1).")
local healthshot_approach_speed = CreateConVar("swcs_healthshot_approach_speed", "20", FCVAR_REPLICATED, "The rate at which the healing is granted, in HP per second, only if swcs_healthshot_approach_enabled is 1. Non-positive values result in no healing.")

function SWEP:CanUseOnSelf(ply)
	if not IsValid(ply) then return false end

	-- already at max
	if not healthshot_allow_use_at_full:GetBool() and ply:Health() >= ply:GetMaxHealth() then
		return false
	end

	return true
end

local HEALTHSHOT_INJECT_TIME = 1.65
function SWEP:GetUseTimerDuration()
	return HEALTHSHOT_INJECT_TIME
end

hook.Add("PlayerTick", "swcs.healthshot", function(ply, mv)
	if CLIENT and (ply ~= LocalPlayer() or not IsFirstTimePredicted()) then return end

	local iHealthRestore = math.floor(ply:GetNWInt("swcs.health_restore", 0))
	if iHealthRestore > 0 then
		if healthshot_approach_speed:GetInt() <= 0 then
			ply:SetNWInt("swcs.health_restore", 0)
			return
		end

		local iRestore = math.max(math.floor(healthshot_approach_speed:GetInt() * engine.TickInterval()), 1)

		ply:SetNWInt("swcs.health_restore", iHealthRestore - iRestore)

		local iHealth = ply:Health()
		ply:SetHealth(math.min(iHealth + iRestore, math.max(iHealth, ply:GetMaxHealth())))
	end
end)

function SWEP:OnVisualUse()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	self:CallOnClient("OnVisualUse")

	self:SetVisuallyUsed(true)

	-- heal the user for 50 health points over 2 seconds
	if healthshot_approach:GetBool() then
		owner:SetNWInt("swcs.health_restore", healthshot_health:GetInt())
	else
		self:SetRedraw(true)
		self.m_UseTimer:Invalidate()
		self:CompleteUse(owner)
	end
end

function SWEP:CompleteUse(ply)
	if not self:GetVisuallyUsed() then return end
	if not IsValid(ply) then return end

	--if SERVER then
	--	SuppressHostEvents(ply)
	--end
	self:EmitSound("Healthshot.Success")

	-- Give half health buffer
	local bInstant = not healthshot_approach:GetBool()
	if bInstant then
		ply:SetHealth(math.min(ply:Health() + healthshot_health:GetInt(), ply:GetMaxHealth()))
		ply:RemoveAmmo(1, self:GetPrimaryAmmoType())
		self:SetVisuallyUsed(false)
	end

	-- emit event
	hook.Run("SWCSPlayerUsedHealthshot", ply, self)

	return bInstant
end

function SWEP:WasBought(buyer)
	if IsValid(buyer) then -- probably already self:GetOwner()
		buyer:GiveAmmo(1, "swcs_healthshot")
	end
end

if CLIENT then
	local ENTITY = FindMetaTable("Entity")
	---@diagnostic disable: need-check-nil
	local ENT_DrawModel = ENTITY.DrawModel
	local ENT_GetOwner = ENTITY.GetOwner
	local ENT_SetBodygroup = ENTITY.SetBodygroup
	---@diagnostic enable: need-check-nil

	function SWEP:DrawWorldModel(flags)
		if not ENT_GetOwner(self):IsValid() then
			ENT_SetBodygroup(self, 0, 1)
		else
			ENT_SetBodygroup(self, 0, 0)
		end

		ENT_DrawModel(self, flags)
	end
end
