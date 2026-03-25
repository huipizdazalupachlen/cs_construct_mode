AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = 1.5
ENT.m_stillTimer = util.Timer()
ENT.m_stillTimer:Reset()

DEFINE_BASECLASS(ENT.Base)

local molotov_throw_detonate_time = CreateConVar("molotov_throw_detonate_time", "2.0", FCVAR_REPLICATED)
local weapon_molotov_maxdetonateslope = CreateConVar("weapon_molotov_maxdetonateslope", "30.0", FCVAR_REPLICATED, "Maximum angle of slope on which the molotov will detonate", 0, 90)

local MOLOTOV_MODEL = "models/weapons/csgo/w_eq_molotov_thrown.mdl"
local INCGREN_MODEL = "models/weapons/csgo/w_eq_incendiarygrenade_thrown.mdl"

AccessorFunc(ENT, "m_flDamage", "Damage", FORCE_NUMBER)
AccessorFunc(ENT, "m_DmgRadius", "Range", FORCE_NUMBER)

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", 0, "IsIncGrenade")
end

function ENT:Create(pos, angs, vel, angvel, owner)
	self:SetPos(pos)
	self:SetAngles(angs)

	self:SetVelocity(vel)
	self:SetInitialVelocity(vel)

	if IsValid(owner) then
		self:SetThrower(owner)
		self:SetOwner(owner)
	end

	self:SetDetonateTimerLength(molotov_throw_detonate_time:GetFloat())

	self:SetLocalAngularVelocity(angvel)
	self:SetFinalAngularVelocity(angvel)
	self:SetActualCollisionGroup(COLLISION_GROUP_PROJECTILE)

	self:SetDamage(200)
	self:SetRange(300)

	self:EmitSound("Molotov.Throw")
	self:EmitSound("Molotov.Loop")

	-- we have to reset these here because we set the model late and it resets the collision
	local min = Vector(-SWCS_GRENADE_DEFAULT_SIZE, -SWCS_GRENADE_DEFAULT_SIZE, -SWCS_GRENADE_DEFAULT_SIZE)
	local max = Vector(SWCS_GRENADE_DEFAULT_SIZE, SWCS_GRENADE_DEFAULT_SIZE, SWCS_GRENADE_DEFAULT_SIZE)
	self:SetCollisionBounds(min, max)

	return self
end

function ENT:Initialize()
	if self:GetIsIncGrenade() then
		self:SetModel(INCGREN_MODEL)
		self.PrintName = "Incendiary Grenade"
	else
		self:SetModel(MOLOTOV_MODEL)
		self.PrintName = "Molotov"
	end

	BaseClass.Initialize(self)
end

ENT.m_molotovParticleEffect = NULL
function ENT:ClientThink()
	if not self.m_molotovParticleEffect or not self.m_molotovParticleEffect:IsValid() then
		if self:GetIsIncGrenade() then
			local iAttachment = self:LookupAttachment("trail")
			self.m_molotovParticleEffect = CreateParticleSystem(self, "incgrenade_thrown_trail", PATTACH_POINT_FOLLOW, iAttachment)
		else
			local iAttachment = self:LookupAttachment("Wick")
			self.m_molotovParticleEffect = CreateParticleSystem(self, "weapon_molotov_thrown", PATTACH_POINT_FOLLOW, iAttachment)
		end
	else
		self.m_molotovParticleEffect:SetSortOrigin(self:GetPos())
		-- update
	end
end

function ENT:AirExplosionEffect()
	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		if self:GetIsIncGrenade() then
			self:EmitSound("Inferno.Start_IncGrenade")
		else
			self:EmitSound("Inferno.Start")
		end

		ParticleEffect("explosion_molotov_air", self:GetPos(), Angle())
	end
end

ENT.m_bStillDetonate = false
function ENT:AdditionalThink(selfTable)
	selfTable = selfTable or self:GetTable()
	if CLIENT then
		selfTable.ClientThink(self)
	end

	if self:GetVelocity():Length() > 5 then
		selfTable.m_stillTimer:Reset()
	elseif not selfTable.m_stillTimer:Started() then
		selfTable.m_stillTimer:Start(0.5)
	end

	if selfTable.m_stillTimer:Started() and selfTable.m_stillTimer:Elapsed() then
		selfTable.m_bStillDetonate = true
		selfTable.Detonate(self)
	else
		self:NextThink(CurTime() + 0.1)
	end
end

function ENT:OnRemove()
	if SERVER then
		self:StopSound("Molotov.Loop")
	end
end

function ENT:Detonate(hitTrace)
	-- BOOM
	hitTrace = hitTrace or self.m_tTouchTrace

	if bit.band(hitTrace.SurfaceFlags or 0, SURF_SKY) ~= 0 then
		if self.m_bStillDetonate then
			self:AirExplosionEffect()

			if SERVER then
				SafeRemoveEntity(self)
			end
		end

		return
	end

	local burnPos, splashNormal = Vector(), Vector()

	if hitTrace.HitWorld then
		-- hit the world, just explode at that position
		burnPos:Set(hitTrace.HitPos)
		splashNormal:Set(hitTrace.HitNormal)
	else
		-- exploded in the air, or hit an object or player.
		-- find the world normal under them (if close enough) and explode there
		local tr = util.TraceLine({
			start = self:GetPos() + Vector(0, 0, 10),
			endpos = self:GetPos() - Vector(0, 0, 128),
			mask = MASK_SOLID,
			filter = self,
		})

		if tr.Fraction == 1 then
			-- Too high, just play explosion effect and don't start a fire
			self:AirExplosionEffect()

			-- explosion effect ???

			if SERVER then
				SafeRemoveEntityDelayed(self, 0)
			end

			return
		elseif bit.band(tr.SurfaceFlags, SURF_SKY) ~= 0 then
			-- just bounce
			return
		end

		-- otherwise explode normally
		burnPos:Set(tr.HitPos)
		splashNormal:Set(tr.HitNormal)
	end

	local inferno = NULL
	if SERVER then
		inferno = ents.Create("swcs_inferno")
	end

	if inferno:IsValid() then
		inferno:SetPos(burnPos)
		inferno:SetOwner(self:GetThrower())

		local vBurnDir = self:GetInitialVelocity()
		vBurnDir:Normalize()
		vBurnDir:Mul(self:GetFinalVelocity():Length())
		inferno.ItemAttributes = self.ItemAttributes

		inferno:Spawn()

		if self:GetIsIncGrenade() then
			inferno:SetInfernoType(INFERNO_TYPE_INCGREN_FIRE)
		else
			inferno:SetInfernoType(INFERNO_TYPE_FIRE)
		end

		inferno:StartBurning(burnPos, splashNormal, vBurnDir, 0)

		-- if in smoke check, add extra flags
	end

	if SERVER then
		SafeRemoveEntity(self)
	end
end

function ENT:BounceSound()
	if self:GetIsIncGrenade() then
		self:EmitSound("IncGrenade.Bounce")
	else
		self:EmitSound("GlassBottle.ImpactHard")
	end
end

function ENT:OnBounced(trace, other)
	if other:IsFlagSet(bit.bor(FSOLID_TRIGGER, FSOLID_VOLUME_CONTENTS)) then return end
	if other == self:GetOwner() then return end

	local class = other:GetClass()
	if class == "func_breakable" or class == "func_breakable_surf" or class == "func_ladder" then return end

	if other:IsValid() and (other:IsNPC() or other:IsPlayer() or other:IsNextBot()) then
		-- don't break if we hit an actor - wait until we hit the environment
		return
	else
		local kMinCos = math.cos(math.rad(weapon_molotov_maxdetonateslope:GetFloat()))
		if trace.HitNormal.z >= kMinCos then
			self:Detonate(trace)
		end
	end
end

function ENT:AcceptInput(strInput, actor, caller, data)
	if string.lower(strInput) == "settimer" then
		self.m_flTimeToDetonate = tonumber(data)
		self:SetDetonateTimerLength(self.m_flTimeToDetonate)
	end
end
