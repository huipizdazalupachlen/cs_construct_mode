AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = 1.5
ENT.IsSWCSGrenade = true
ENT.PrintName = "Flashbang"

DEFINE_BASECLASS(ENT.Base)

local GRENADE_MODEL = "models/weapons/csgo/w_eq_flashbang_thrown.mdl"

function ENT:Create(pos, angs, vel, angvel, owner)
	self:SetPos(pos)
	self:SetAngles(angs)

	self:SetVelocity(vel)
	self:SetInitialVelocity(vel)

	if IsValid(owner) then
		self:SetThrower(owner)
		self:SetOwner(owner)
	end

	self:SetLocalAngularVelocity(angvel)
	self:SetFinalAngularVelocity(angvel)
	self:SetActualCollisionGroup(COLLISION_GROUP_PROJECTILE)

	return self
end

function ENT:Initialize()
	self:SetModel(GRENADE_MODEL)

	self:SetDetonateTimerLength(self.m_flTimeToDetonate)

	BaseClass.Initialize(self)
end

local sv_flashbang_strength = CreateConVar("sv_flashbang_strength", "3.55", FCVAR_REPLICATED, "Flashbang strength")
function ENT:Detonate()
	if SERVER then
		swcs.RadiusFlash(self:GetPos(), self, self:GetOwner(), sv_flashbang_strength:GetInt(), CLASS_NONE, DMG_BLAST) --, m_numOpponentsHit, &m_numTeammatesHit )
	end
	if CLIENT then
		local light = DynamicLight(self:EntIndex())
		light.pos = self:GetPos()
		light.r = 255
		light.g = 255
		light.b = 255
		light.brightness = 2.0
		light.size = 400
		light.dietime = CurTime() + 0.1
		light.decay = 768
	end

	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		self:EmitSound("Flashbang.Explode")
		local vecSpot = self:GetPos() + Vector(0, 0, 2)
		util.Decal("Scorch", vecSpot, vecSpot + Vector(0, 0, -64), self)
	end

	-- Because we don't chain to base, tell ogs to record this detonation here
	--RecordDetonation()

	if SERVER then SafeRemoveEntity(self) end
end

function ENT:BounceSound()
	self:EmitSound("Flashbang.Bounce")
end

function ENT:AcceptInput(strInput, actor, caller, data)
	if string.lower(strInput) == "settimer" then
		self.m_flTimeToDetonate = tonumber(data)
		self:SetDetonateTimerLength(self.m_flTimeToDetonate)
	end
end
