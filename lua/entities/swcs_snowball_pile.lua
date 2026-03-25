AddCSLuaFile()

ENT.Type = "anim"
ENT.Spawnable = true
ENT.Category = "#spawnmenu.category.swcs"
ENT.RenderGroup = RENDERGROUP_OPAQUE
ENT.PrintName = "#swcs_snowball_pile"
ENT.PhysicsSounds = true

function ENT:Initialize()
	self:SetModel("models/props_holiday/snowball/snowball_pile.mdl")

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(false)
		end

		self:SetUseType(SIMPLE_USE)
	end

	--ParticleEffect("snowball_pile", self:GetPos(), self:GetAngles(), self)
end

function ENT:Use(actor, caller)
	if not (actor:IsValid() and actor:IsPlayer()) then return end

	local wep = actor:GetWeapon("weapon_swcs_snowball")

	if not wep:IsValid() then
		wep = actor:Give("weapon_swcs_snowball")
	end

	local iPrimaryAmmo = -1
	if wep:IsValid() then
		iPrimaryAmmo = wep:GetPrimaryAmmoType()
	end

	if iPrimaryAmmo ~= -1 and actor:GiveAmmo(3, iPrimaryAmmo, true) > 0 then
		actor:EmitSound("Player.SnowballPickup")
	end
end

if CLIENT then
	ENT.m_Particle = NULL
	ENT.m_bAttemptedParticleSpawn = false
	function ENT:Think()
		if not IsValid(self.m_Particle) and not self.m_bAttemptedParticleSpawn then
			self.m_bAttemptedParticleSpawn = true
			self.m_Particle = CreateParticleSystem(self, "snowball_pile", PATTACH_ABSORIGIN_FOLLOW, 0)
		end
	end
end
