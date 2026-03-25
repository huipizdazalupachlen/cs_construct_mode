AddCSLuaFile()
ENT.Type = "anim"
ENT.Spawnable = true
ENT.Category = "#spawnmenu.category.swcs"
ENT.Model = Model("models/props_survival/crates/crate_ammobox.mdl")
ENT.PrintName = "#swcs_ammo_generic"
ENT.PhysicsSounds = true

ENT.m_iCharges = 4
AccessorFunc(ENT, "m_iCharges", "Charges", FORCE_NUMBER)

function ENT:Initialize()
	self:SetModel(self.Model)

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
		end

		self:SetUseType(SIMPLE_USE)
	end
end

sound.Add({
	name = "SWCS.AmmoPickup",
	channel = CHAN_STATIC,
	volume = 0.2,
	sound = Sound("items/csgo/pickup_ammo_02.wav"),
})

function ENT:Use(actor, caller)
	if not (actor:IsValid() and actor:IsPlayer()) then
		return
	end
	if self:GetCharges() <= 0 then
		return
	end

	local iPrimaryAmmo = -1
	local wep = actor:GetActiveWeapon()

	if wep:IsValid() then
		-- no clip
		if wep:GetMaxClip1() == -1 then
			return
		end

		iPrimaryAmmo = wep:GetPrimaryAmmoType()
	end

	local bGaveAmmo = false
	if iPrimaryAmmo ~= -1 then
		local iAmmoGiven = 0

		if SWCS_INDIVIDUAL_AMMO:GetBool() and wep.IsSWCSWeapon then
			wep:SetReserveAmmo(wep:GetReserveAmmo() + wep:GetMaxClip1())
			iAmmoGiven = wep:GetMaxClip1()
		else
			iAmmoGiven = actor:GiveAmmo(wep:GetMaxClip1(), iPrimaryAmmo, true)
		end

		if (iAmmoGiven or 0) > 0 then
			actor:EmitSound("SWCS.AmmoPickup")

			self:SetCharges(self:GetCharges() - 1)
			bGaveAmmo = true
		end
	end

	if bGaveAmmo then
		local iBodyGroupNum = 4 - self:GetCharges()
		local iBodyGroup = self:FindBodygroupByName(Format("box%d", iBodyGroupNum))
		if iBodyGroup ~= -1 then
			self:SetBodygroup(iBodyGroup, 1)
		end
	end

	if self:GetCharges() <= 0 then
		self:SetSkin(1)
		SafeRemoveEntityDelayed(self, 1)
	end
end
