AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = math.huge
ENT.IsSWCSGrenade = true

DEFINE_BASECLASS(ENT.Base)

local GRENADE_MODEL = Model"models/Items/Flare.mdl"

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

ENT.m_bJustLanded = false
function ENT:AdditionalThink(selfTable)
	selfTable = selfTable or self:GetTable()
	if selfTable.GetFinalVelocity(self):Length() > 0.1 then
		-- Still moving. Don't detonate yet.
		return true
	end

	if not selfTable.m_bJustLanded then
		selfTable.m_bJustLanded = true
		selfTable.SetDetonateTimerLength(self, 1)
	end

	--self:Detonate()
end

function ENT:Detonate()
	--if self:GetTimeToDetonate() < CurTime() then return end
	-- poof!!!

	if IsFirstTimePredicted() then
		-- predicted random bc im cool B)
		g_ursRandom:SetSeed(engine.TickCount())
		local col = Color(
			g_ursRandom:RandomInt(0, 255),
			g_ursRandom:RandomInt(0, 255),
			g_ursRandom:RandomInt(0, 255)
		)

		if CLIENT then
			local light = DynamicLight(self:EntIndex())
			light.pos = self:GetPos()
			light.r = col.r
			light.g = col.g
			light.b = col.b
			light.brightness = 2
			light.size = 400
			light.dietime = CurTime() + 0.1
			light.decay = 768
		end

		local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
		effectdata:SetStart(Vector(col.r, col.g, col.b))
		util.Effect("balloon_pop", effectdata)
	end

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
