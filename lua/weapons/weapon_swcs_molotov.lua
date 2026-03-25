SWEP.Base = "weapon_swcs_base_grenade"
SWEP.Category = "#spawnmenu.category.swcs"

DEFINE_BASECLASS(SWEP.Base)

SWEP.Slot = 4

SWEP.Primary.Ammo = swcs.InTTT and "none" or "swcs_firegrenade"

SWEP.PrintName = "Molotov"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_molotov.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_eq_molotov.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/molotov.png", "smooth")
end

sound.Add({
	name = "Molotov.Throw",
	channel = CHAN_ITEM,
	level = 65,
	volume = 1,
	pitch = 100,
	sound = Sound("weapons/csgo/molotov/fire_ignite_2.wav"),
})
sound.Add({
	name = "Molotov.Draw",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.3,
	pitch = 100,
	sound = Sound("weapons/csgo/molotov/molotov_draw.wav"),
})
sound.Add({
	name = "Molotov.Loop",
	channel = CHAN_STATIC,
	volume = 0.6,
	sound = Sound("weapons/csgo/molotov/fire_loop_1.wav"),
})
sound.Add({
	name = "Molotov.IdleLoop",
	channel = CHAN_STATIC,
	volume = 0.6,
	sound = Sound("weapons/csgo/molotov/fire_idle_loop_1.wav"),
})
sound.Add({
	name = "Molotov.Extinguish",
	channel = CHAN_STATIC,
	level = 95,
	volume = 0.6,
	sound = Sound(")weapons/csgo/molotov/molotov_extinguish.wav"),
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
	"sound_single_shot"		"Molotov.Throw"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:EmitGrenade()
	local selfTable = self:GetTable()
	self:StopSound("Molotov.IdleLoop")

	if selfTable.m_molotovParticleEffect and selfTable.m_molotovParticleEffect:IsValid() then
		selfTable.m_molotovParticleEffect:StopEmission(false, false)
		selfTable.m_molotovParticleEffect = NULL
	end

	if SERVER then
		local ent = ents.Create("swcs_molotov_projectile")
		local entTable = ent:GetTable()
		entTable.ItemAttributes = selfTable.ItemAttributes
		entTable.ItemVisuals = selfTable.ItemVisuals
		entTable.SetIsIncGrenade(ent, false)

		return ent
	else
		return NULL
	end
end

SWEP.m_molotovParticleEffect = NULL
function SWEP:UpdateParticles()
	local selfTable = self:GetTable()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local vm = owner:GetViewModel(self:ViewModelIndex())
	if not vm:IsValid() then return end

	local bIsFirstOrThirdpersonMolotovVisible = self:IsWeaponVisible()

	if bIsFirstOrThirdpersonMolotovVisible then
		if selfTable.GetPinPulled(self) then
			if not (selfTable.m_molotovParticleEffect and selfTable.m_molotovParticleEffect:IsValid()) then
				local iAttachment = self:LookupAttachment("Wick")

				if iAttachment >= 0 then
					selfTable.m_molotovParticleEffect = CreateParticleSystem(vm, "weapon_molotov_held", PATTACH_POINT_FOLLOW, iAttachment, Vector(10, 0, 0))
					--selfTable.m_molotovParticleEffect:SetShouldDraw(false)
					self:EmitSound("Molotov.IdleLoop")
				end
			end
		end
	end
end

function SWEP:Holster(nextWep)
	self:StopSound("Molotov.IdleLoop")

	return BaseClass.Holster(self, nextWep)
end

function SWEP:Think()
	BaseClass.Think(self)

	if CLIENT then
		self:UpdateParticles()
	end
end

-- the lit rag particle effect was rendering twice
-- i toggle rendering before/after viewmodel pass in order to prevent that
function SWEP:PreDrawViewModel(vm, _, owner)
	local selfTable = self:GetTable()
	if selfTable.m_molotovParticleEffect and selfTable.m_molotovParticleEffect:IsValid() then
		selfTable.m_molotovParticleEffect:SetShouldDraw(false)
	end

	return BaseClass.PreDrawViewModel(self, vm, _, owner)
end

function SWEP:PostDrawViewModel(vm, _, ply)
	local selfTable = self:GetTable()
	BaseClass.PostDrawViewModel(self, vm, _, ply)

	if selfTable.m_molotovParticleEffect and selfTable.m_molotovParticleEffect:IsValid() then
		selfTable.m_molotovParticleEffect:SetShouldDraw(true)
	end
end
