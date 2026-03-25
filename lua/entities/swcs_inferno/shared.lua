AddCSLuaFile()
AddCSLuaFile("cl_init.lua")

game.AddDecal("MolotovScorch", "decals/molotovscorch")

local InfernoPerFlameSpawnDuration = CreateConVar("inferno_per_flame_spawn_duration", "3", FCVAR_REPLICATED, "Duration each new flame will attempt to spawn new flames")
local InfernoInitialSpawnInterval = CreateConVar("inferno_initial_spawn_interval", "0.02", FCVAR_REPLICATED, "Time between spawning flames for first fire")
local InfernoChildSpawnIntervalMultiplier = CreateConVar("inferno_child_spawn_interval_multiplier", "0.1", FCVAR_REPLICATED, "Amount spawn interval increases for each child")
local InfernoMaxChildSpawnInterval = CreateConVar("inferno_max_child_spawn_interval", "0.5", FCVAR_REPLICATED, "Largest time interval for child flame spawning")
local InfernoSpawnAngle = CreateConVar("inferno_spawn_angle", "45", FCVAR_REPLICATED, "Angular change from parent")
local InfernoMaxFlames = CreateConVar("inferno_max_flames", "16", FCVAR_REPLICATED, "Maximum number of flames that can be created")
local InfernoFlameSpacing = CreateConVar("inferno_flame_spacing", "42", FCVAR_REPLICATED, "Minimum distance between separate flame spawns")
local InfernoFlameLifetime = CreateConVar("inferno_flame_lifetime", "7", FCVAR_REPLICATED, "Average lifetime of each flame in seconds")
local InfernoFriendlyFireDuration = CreateConVar("inferno_friendly_fire_duration", "6", FCVAR_REPLICATED, "For this long, FF is credited back to the thrower.")
local InfernoDebug = CreateConVar("inferno_debug", "0", FCVAR_REPLICATED)
local InfernoDamage = CreateConVar("inferno_damage", "40", FCVAR_REPLICATED, "Damage per second")
local InfernoMaxRange = CreateConVar("inferno_max_range", "150", FCVAR_REPLICATED, "Maximum distance flames can spread from their initial ignition point")
local InfernoVelocityFactor = CreateConVar("inferno_velocity_factor", "0.003", FCVAR_REPLICATED)
local InfernoVelocityDecayFactor = CreateConVar("inferno_velocity_decay_factor", "0.2", FCVAR_REPLICATED)
local InfernoVelocityNormalFactor = CreateConVar("inferno_velocity_normal_factor", "0", FCVAR_REPLICATED)
local InfernoSurfaceOffset = CreateConVar("inferno_surface_offset", "20", FCVAR_REPLICATED)
local InfernoChildSpawnMaxDepth = CreateConVar("inferno_child_spawn_max_depth", "4", FCVAR_REPLICATED)
local inferno_scorch_decals = CreateConVar("inferno_scorch_decals", "1", FCVAR_REPLICATED)
local inferno_max_trace_per_tick = CreateConVar("inferno_max_trace_per_tick", "16")
local inferno_forward_reduction_factor = CreateConVar("inferno_forward_reduction_factor", "0.9", FCVAR_REPLICATED)

-- sounds
do
	sound.Add({
		name = "Inferno.StartSweeten_IncGrenade",
		channel = CHAN_STATIC,
		volume = 0.6,
		level = 95,
		sound = Sound(")weapons/csgo/incgrenade/inc_grenade_detonate_swt_01.wav"),
	})
	sound.Add({
		name = "Inferno.Start",
		channel = CHAN_WEAPON,
		volume = 1.0,
		level = 95,
		sound = {Sound(")weapons/csgo/molotov/molotov_detonate_1.wav"), Sound(")weapons/csgo/molotov/molotov_detonate_2.wav"), Sound(")weapons/csgo/molotov/molotov_detonate_3.wav")},
	})
	sound.Add({
		name = "Inferno.StartSweeten",
		channel = CHAN_STATIC,
		volume = 0.5,
		level = 95,
		sound = Sound(")weapons/csgo/molotov/molotov_detonate_swt_01.wav"),
	})
	sound.Add({
		name = "Inferno.FadeOut",
		channel = CHAN_AUTO,
		volume = 0.1,
		level = 95,
		sound = Sound("weapons/csgo/molotov/fire_loop_fadeout_01.wav"),
	})
	sound.Add({
		name = "Inferno.Loop",
		channel = CHAN_BODY,
		volume = 0.5,
		sound = Sound("weapons/csgo/molotov/fire_loop_1.wav"),
	})
	sound.Add({
		name = "Inferno.Fire.Ignite",
		channel = CHAN_STATIC,
		volume = 0.3,
		level = 85,
		sound = {Sound(")weapons/csgo/molotov/fire_ignite_1.wav"), Sound(")weapons/csgo/molotov/fire_ignite_4.wav"), Sound(")weapons/csgo/molotov/fire_ignite_5.wav")},
	})
end

MAX_INFERNO_FIRES = 64

local k_ECreateFireResult_OK = 0
local k_ECreateFireResult_LimitExceeded = 1
local k_ECreateFireResult_AlreadyOnFire = 2
local k_ECreateFireResult_InSmoke = 3
local k_ECreateFireResult_AllSolid = 4

-- Inferno trace masks can allow to do different traces for spreading fire
local INFERNO_MASK_TO_GROUND = bit.band(MASK_SOLID_BRUSHONLY, bit.bnot(CONTENTS_GRATE))
local INFERNO_MASK_LOS_CHECK = bit.bor(INFERNO_MASK_TO_GROUND, CONTENTS_MONSTER)
local INFERNO_MASK_DAMAGE = INFERNO_MASK_LOS_CHECK

-- Smoke grenade radius constant is actually tuned for the bots
-- and not for gameplay. Visualizing smoke will show that it goes
-- up from the emitter by 128 units (fuzzy top), nothing goes down,
-- and it makes a wide XY-donut with a radius of *128* units (fuzzy edges).
--ASSERT_INVARIANT( CONSTANT_UNITS_SMOKEGRENADERADIUS == 166 )
-- When interacting with fire we don't want any vertical interactions unless
-- contact points are definitely in smoke vertically.
local SmokeGrenadeRadius_InfernoAffectingZ = 120.0
-- When interacting with fire on the same plane we don't want alpha depth-fighting
-- in the most common case, so leave a grace margin between the smoke particles
-- and the fire particles.
local SmokeGrenadeRadius_InfernoAffectingXY_topedge = 100.0
local SmokeGrenadeRadius_InfernoAffectingXY_equator = 150.0
local SmokeGrenadeRadius_InfernoAffectingXY_bottomedge = 128.0

local CONSTANT_UNITS_SMOKEGRENADERADIUS = 166
--local CONSTANT_UNITS_GENERICGRENADERADIUS = 115

local SmokeGrenadeRadius = CONSTANT_UNITS_SMOKEGRENADERADIUS
--local FlashbangGrenadeRadius = CONSTANT_UNITS_GENERICGRENADERADIUS
--local HEGrenadeRadius = CONSTANT_UNITS_GENERICGRENADERADIUS
--local MolotovGrenadeRadius = CONSTANT_UNITS_GENERICGRENADERADIUS
--local DecoyGrenadeRadius = CONSTANT_UNITS_GENERICGRENADERADIUS

-- Fire burning things and smoke constants
local InfernoFire_HalfWidth = 30.0
local InfernoFire_FullHeight = 80.0

local RemapValClamped = swcs.RemapClamped

local function BCheckFirePointInSmokeCloud(vecFirePoint, vecSmokeOrigin)
	local flFireUpToSmokeCheckHeight = 2 * InfernoFire_HalfWidth + 4.0
	local flFireAboveSmokeZ = vecFirePoint.z - vecSmokeOrigin.z

	if flFireAboveSmokeZ < -flFireUpToSmokeCheckHeight then
		return false -- fire not tall enough to burn up to smoke
	end
	if flFireAboveSmokeZ > SmokeGrenadeRadius_InfernoAffectingZ then
		return false -- smoke cloud not tall enough to reach to the fire
	end

	-- Now we know that fire is in XY-slice containing the smoke cloud
	-- Figure out if we are in the equator XY-plane or in the shrinking edge XY-plane
	local flRadiusSquaredTest = SmokeGrenadeRadius_InfernoAffectingXY_equator * SmokeGrenadeRadius_InfernoAffectingXY_equator
	if flFireAboveSmokeZ > SmokeGrenadeRadius_InfernoAffectingZ * 0.6 then
		local flPctFromEquatorToEdge = RemapValClamped(flFireAboveSmokeZ, SmokeGrenadeRadius_InfernoAffectingZ * 0.6, SmokeGrenadeRadius_InfernoAffectingZ, 0.0, 1.0)
		flPctFromEquatorToEdge = flPctFromEquatorToEdge * flPctFromEquatorToEdge -- 0.0 still equator; 1.0 edge (squaring makes things feel quadratically closer to equator)
		flRadiusSquaredTest = RemapValClamped(flPctFromEquatorToEdge, 0.0, 1.0, flRadiusSquaredTest, SmokeGrenadeRadius_InfernoAffectingXY_topedge * SmokeGrenadeRadius_InfernoAffectingXY_topedge)
	elseif flFireAboveSmokeZ < SmokeGrenadeRadius_InfernoAffectingZ * 0.15 then
		local flPctFromEquatorToEdge = RemapValClamped(flFireAboveSmokeZ, SmokeGrenadeRadius_InfernoAffectingZ * 0.1, -flFireUpToSmokeCheckHeight, 0.0, 1.0)
		flPctFromEquatorToEdge = flPctFromEquatorToEdge * flPctFromEquatorToEdge -- 0.0 still equator; 1.0 edge (squaring makes things feel quadratically closer to equator)
		flRadiusSquaredTest = RemapValClamped(flPctFromEquatorToEdge, 0.0, 1.0, flRadiusSquaredTest, SmokeGrenadeRadius_InfernoAffectingXY_bottomedge * SmokeGrenadeRadius_InfernoAffectingXY_bottomedge)
	end

	-- Check if it is within XY-plane radius now
	local lenXYsqr = (vecFirePoint - vecSmokeOrigin):Length2DSqr()
	return lenXYsqr <= flRadiusSquaredTest
end

swcs.CheckFirePointInSmokeCloud = BCheckFirePointInSmokeCloud

game.AddParticles("particles/csgo/inferno_fx.pcf")
PrecacheParticleSystem("incgrenade_thrown_trail")
PrecacheParticleSystem("extinguish_fire")
PrecacheParticleSystem("molotov_groundfire")
PrecacheParticleSystem("molotov_explosion")
PrecacheParticleSystem("weapon_molotov_thrown")
PrecacheParticleSystem("explosion_molotov_air")

INFERNO_TYPE_FIRE = 0
INFERNO_TYPE_INCGREN_FIRE = 1 -- incendiary grenade fire, used to play a different sound
INFERNO_TYPE_FIREWORKS = 2

ENT.Type = "anim"

ENT.m_fire = {}
ENT.m_fireXDelta = {}
ENT.m_fireYDelta = {}
ENT.m_fireZDelta = {}
ENT.m_bFireIsBurning = {}
ENT.m_BurnNormal = {}
ENT.m_fireSpawnOffset = 0

ENT.m_extent = {
	lo = Vector(),
	hi = Vector(),
}

ENT.m_bWasCreatedInSmoke = false
ENT.m_nMaxFlames = 0
ENT.m_startPos = Vector()
ENT.m_startNormal = Vector()
ENT.m_startVelocity = Vector()
ENT.m_splashVelocity = Vector()

ENT.m_activeTimer = swcs.IntervalTimer()
ENT.m_damageRampTimer = swcs.CountdownTimer()
ENT.m_damageTimer = swcs.CountdownTimer()
ENT.m_NextSpreadTimer = swcs.CountdownTimer()
ENT.m_BookkeepingTimer = swcs.CountdownTimer()

AccessorFunc(ENT, "m_bWasCreatedInSmoke", "WasCreatedInSmoke", FORCE_BOOL)
AccessorFunc(ENT, "m_nMaxFlames", "MaxFlames", FORCE_NUMBER)

function ENT:CanHarm(ent)
	return true
end
function ENT:GetDamageType()
	return DMG_BURN
end

function ENT:GetParticleEffectName()
	return "molotov_groundfire"
end
function ENT:GetImpactParticleEffectName()
	return "molotov_explosion"
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "InfernoType")
	self:NetworkVar("Int", 1, "FireCount")
end

local damageRampUpTime = 2.0
function ENT:Initialize()
	self:DrawShadow(false)
	self:SetMaxFlames(InfernoMaxFlames:GetInt())
	self:SetWasCreatedInSmoke(false)

	self:SetFireCount(0)

	local tbl = self:GetTable()

	tbl.m_damageRampTimer:Start(damageRampUpTime)

	tbl.m_NextSpreadTimer:Start(self:GetFlameSpreadDelay())

	tbl.m_extent = {
		lo = Vector(),
		hi = Vector(),
	}

	tbl.m_fireXDelta = {}
	tbl.m_fireYDelta = {}
	tbl.m_fireZDelta = {}
	tbl.m_bFireIsBurning = {}
	tbl.m_BurnNormal = {}

	tbl.m_startPos = Vector()
	tbl.m_startNormal = Vector()
	tbl.m_startVelocity = Vector()

	self:AddFlags(FL_ONFIRE)

	self:SetInfernoType(INFERNO_TYPE_FIRE)

	if SERVER then
		hook.Add("SWCSSmokeGrenadeDetonated", self, tbl.OnSmokeGrenadeDetonated)
	end
end

function ENT:ExtinguishIndividualFlameBySmokeGrenade(iFire, vecStart)
	local fires = self.m_fire
	fires[iFire].m_lifetime:Invalidate()

	local vecAngleAway = fires[iFire].m_pos - vecStart
	vecAngleAway:Normalize()

	local angParticle = vecAngleAway:Angle()
	ParticleEffect("extinguish_fire", fires[iFire].m_pos, angParticle)
end

function ENT:ExtinguishFlamesAroundSmokeGrenade(vecStart, hSmokeGrenade)
	local bExtinguished = false
	local bCheckDistanceForFlames = true
	local nNumExtinguished = 0

	local fires = self.m_fire

	-- if the radius overlaps the center, extinguish the whole flame
	if (BCheckFirePointInSmokeCloud(self.m_startPos, vecStart)) then
		bCheckDistanceForFlames = false
	end

	for i = 0, self:GetFireCount() - 1 do
		-- if this fire just died, propagate over the network
		if (fires[i] and fires[i].m_burning and (
				not bCheckDistanceForFlames or BCheckFirePointInSmokeCloud(fires[i].m_pos, vecStart)
			)) then
			self:ExtinguishIndividualFlameBySmokeGrenade(i, vecStart)
			bExtinguished = true
			nNumExtinguished = nNumExtinguished + 1
		end
	end

	-- if we extinguished third or more of our fire, just put out the rest
	if (not bCheckDistanceForFlames and nNumExtinguished >= (self:GetFireCount() / 3)) then
		for i = 0, self:GetFireCount() - 1 do
			-- if this fire just died, propagate over the network
			if (fires[i] and not fires[i].m_lifetime:IsElapsed()) then
				self:ExtinguishIndividualFlameBySmokeGrenade(i, vecStart)
				nNumExtinguished = nNumExtinguished + 1
			end
		end
	end

	if (bExtinguished) then
		self:EmitSound("Molotov.Extinguish")

		hook.Run("SWCSInfernoExtinguished", self, hSmokeGrenade)
	end

	return nNumExtinguished
end

function ENT:OnSmokeGrenadeDetonated(hSmokeGrenade)
	if hSmokeGrenade:GetPos():DistToSqr(self:GetPos()) < SmokeGrenadeRadius * SmokeGrenadeRadius * 4 then
		local extinguishCount = self:ExtinguishFlamesAroundSmokeGrenade(hSmokeGrenade:GetPos(), hSmokeGrenade)

		if extinguishCount == self:GetFireCount() then
			-- death
		end
	end
end

function ENT:GetFlameSpreadDelay()
	return 0
end

function ENT:OnRemove()
	local infernotype = self:GetInfernoType()
	if infernotype == INFERNO_TYPE_FIRE or infernotype == INFERNO_TYPE_INCGREN_FIRE then
		self:EmitSound("Inferno.Fadeout")
		self:StopSound("Inferno.Loop")
	elseif infernotype == INFERNO_TYPE_FIREWORKS then
		self:EmitSound("FireworksCrate.Stop")
		self:StopSound("FireworksCrate.Start")
	end
end

function ENT:GetDamagePerSecond()
	return InfernoDamage:GetFloat()
end

function ENT:GetFlameLifetime()
	return InfernoFlameLifetime:GetFloat()
end

function ENT:StartBurning(pos, normal, velocity, initialDepth)
	local selfTable = self:GetTable()

	selfTable.m_startNormal:Set(normal)
	selfTable.m_startVelocity:Set(velocity)

	selfTable.m_startPos:Set(pos)
	selfTable.m_startPos.x = selfTable.m_startPos.x + InfernoSurfaceOffset:GetFloat() * normal.x
	selfTable.m_startPos.y = selfTable.m_startPos.y + InfernoSurfaceOffset:GetFloat() * normal.y

	-- reflect velocity off of surface
	local splash = velocity:Dot(normal)
	local remainder = velocity - normal * splash

	selfTable.m_splashVelocity = remainder - InfernoVelocityNormalFactor:GetFloat() * normal * splash

	local splashAngle = velocity:Angle()

	-- LUA: gmod doesnt have particle operator for tracing to floor
	-- so we 0 out the pitch :/
	--splashAngle.p = 0
	ParticleEffect(selfTable.GetImpactParticleEffectName(self), pos, splashAngle)

	if InfernoDebug:GetBool() then
		debugoverlay.Sphere(pos, 0.5 * InfernoFire_HalfWidth, 10, Color(0, 255, 0))
		debugoverlay.Sphere(selfTable.m_startPos, 0.5 * InfernoFire_HalfWidth, 10, Color(255, 255, 0))
	end

	if selfTable.CreateFire(self, selfTable.m_startPos, normal, nil, initialDepth) == k_ECreateFireResult_OK then
		local infernotype = selfTable.GetInfernoType(self)

		if infernotype == INFERNO_TYPE_FIRE then
			self:EmitSound("Inferno.Start")
			self:EmitSound("Inferno.StartSweeten")
			self:EmitSound("Inferno.Loop")
		elseif infernotype == INFERNO_TYPE_INCGREN_FIRE then
			self:EmitSound("Inferno.Start_IncGrenade")
			self:EmitSound("Inferno.StartSweeten_IncGrenade")
			self:EmitSound("Inferno.Loop")
		elseif infernotype == INFERNO_TYPE_FIREWORKS then
			self:EmitSound("FireworksCrate.Start")
		end

		selfTable.m_startPos:Set(selfTable.m_fire[0].m_pos)
		self:SetPos(selfTable.m_startPos)

		hook.Run("SWCSInfernoStartBurn", self)

		selfTable.m_activeTimer:Start()
	else
		self:EmitSound("Molotov.Extinguish")
		ParticleEffect("extinguish_fire", selfTable.m_startPos, splashAngle)
		self:Remove()
	end
end

function ENT:IsFirePosInSmokeCloud(pos)
	local tEnts = ents.FindInSphere(pos, SmokeGrenadeRadius)

	for _, ent in pairs(tEnts) do
		if ent:GetClass() ~= "swcs_smokegrenade_projectile" then continue end

		if ent:GetDidSmokeEffect() and BCheckFirePointInSmokeCloud(pos, ent:GetPos()) then
			return true
		end
	end

	return false
end

-- returns k_ECreateFireResult
function ENT:CreateFire(pos, normal, parent, depth)
	local selfTable = self:GetTable()

	if selfTable.GetFireCount(self) >= math.min(MAX_INFERNO_FIRES, selfTable.GetMaxFlames(self)) then
		return k_ECreateFireResult_LimitExceeded
	end

	depth = depth or 0

	if selfTable.IsTouchingRay(self, pos, pos) then
		-- we already created a fire here
		return k_ECreateFireResult_AlreadyOnFire
	end

	-- if we throw down a molly in the middle of a smoke grenade, DENY!
	if selfTable.IsFirePosInSmokeCloud(self, pos) then
		selfTable.SetWasCreatedInSmoke(self, true)
		return k_ECreateFireResult_InSmoke
	end

	if InfernoDebug:GetBool() and parent then
		debugoverlay.Line(parent.m_pos, pos, 10, Color(0, 255, 255))
	end

	local firePos = Vector(pos)
	local overWater = false

	local tr = {}
	local contents = util.PointContents(pos)
	if bit.band(contents, bit.bor(CONTENTS_WATER, CONTENTS_SLIME)) ~= 0 then
		local fireHeight = Vector(0, 0, 30)
		local mask = bit.bor(MASK_SOLID_BRUSHONLY, CONTENTS_SLIME, CONTENTS_WATER)

		util.TraceLine({
			start = pos + fireHeight,
			endpos = pos,
			mask = mask,
			output = tr,
		})

		if tr.AllSolid then
			return k_ECreateFireResult_AllSolid
		else
			firePos:Set(tr.HitPos)
			overWater = true
		end
	end

	local fire = {
		m_pos = firePos,
		m_center = firePos + Vector(0, 0, 0.5 * InfernoFire_FullHeight),
		m_normal = normal,
		m_parent = parent,
		m_treeDepth = depth,
		m_spawnCount = 0,
		m_flWaterHeight = firePos.z - pos.z,
		m_burning = true,
		m_spawnLifetime = swcs.CountdownTimer(),
		m_spawnTimer = swcs.CountdownTimer(),
		m_lifetime = swcs.CountdownTimer(),
	}

	-- all control points on the client die down at the same time, so the server needs to match this
	if selfTable.m_activeTimer:HasStarted() then
		fire.m_lifetime:Start(selfTable.GetFlameLifetime(self) - selfTable.m_activeTimer:GetElapsedTime())
	else
		fire.m_lifetime:Start(selfTable.GetFlameLifetime(self))
	end

	if parent then
		fire.m_spawnLifetime:Start(parent.m_spawnLifetime:GetCountdownDuration())

		local duration = InfernoChildSpawnIntervalMultiplier:GetFloat() * parent.m_spawnTimer:GetCountdownDuration()

		if duration > InfernoMaxChildSpawnInterval:GetFloat() then
			duration = InfernoMaxChildSpawnInterval:GetFloat()
		end

		fire.m_spawnTimer:Start(duration)
	else
		fire.m_spawnLifetime:Start(InfernoPerFlameSpawnDuration:GetFloat())
		fire.m_spawnTimer:Start(InfernoInitialSpawnInterval:GetFloat())
	end

	local iFireCount = selfTable.GetFireCount(self)
	-- keep a simple array of all active fires
	selfTable.m_fire[iFireCount] = fire

	-- propogate across the network

	-- Compute this fire's position relative to the Inferno entity.
	local vecDelta = fire.m_pos - self:GetPos()

	selfTable.m_fireXDelta[iFireCount] = math.floor(vecDelta.x)
	selfTable.m_fireYDelta[iFireCount] = math.floor(vecDelta.y)
	selfTable.m_fireZDelta[iFireCount] = math.floor(vecDelta.z)
	selfTable.m_bFireIsBurning[iFireCount] = true
	selfTable.m_BurnNormal[iFireCount] = normal

	selfTable.SetFireCount(self, iFireCount + 1)

	if SERVER then
		if not selfTable.m_NetworkFilter then
			selfTable.m_NetworkFilter = RecipientFilter()
			selfTable.m_NetworkFilter:AddPVS(self:GetPos())
		end

		net.Start(self:GetClass())
		net.WriteEntity(self)
		net.WriteBool(false) -- not a full update

		net.WriteUInt(iFireCount, 6)

		net.WriteFloat(selfTable.m_fireXDelta[iFireCount])
		net.WriteFloat(selfTable.m_fireYDelta[iFireCount])
		net.WriteFloat(selfTable.m_fireZDelta[iFireCount])
		net.WriteBool(selfTable.m_bFireIsBurning[iFireCount])
		net.WriteNormal(selfTable.m_BurnNormal[iFireCount])
		net.Send(selfTable.m_NetworkFilter)
	end

	selfTable.RecomputeExtent(self)

	-- emit a small flame burst sound
	if selfTable.GetInfernoType(self) == INFERNO_TYPE_FIRE or selfTable.GetInfernoType(self) == INFERNO_TYPE_INCGREN_FIRE then
		sound.Play("Inferno.Fire.Ignite", fire.m_pos)

		if inferno_scorch_decals:GetBool() and not overWater then
			local trace = util.TraceLine({
				start = fire.m_pos,
				endpos = fire.m_pos + Vector(0, 0, -100),
				mask = MASK_OPAQUE,
			})

			util.Decal("MolotovScorch", trace.StartPos, trace.HitPos + (trace.Normal * 1.1))
		end
	end

	return k_ECreateFireResult_OK
end

local LO_MAX = Vector(999999, 999999, 999999)
local HI_MAX = Vector(-999999, -999999, -999999)
function ENT:RecomputeExtent()
	local selfTable = self:GetTable()

	local lo = selfTable.m_extent.lo
	local hi = selfTable.m_extent.hi

	lo:Set(LO_MAX)
	hi:Set(HI_MAX)

	for i = 0, self:GetFireCount() - 1 do
		local fire = selfTable.m_fire[i]

		if fire.m_pos.x - InfernoFire_HalfWidth < lo.x then
			lo.x = fire.m_pos.x - InfernoFire_HalfWidth
		end

		if fire.m_pos.x + InfernoFire_HalfWidth > hi.x then
			hi.x = fire.m_pos.x + InfernoFire_HalfWidth
		end

		if fire.m_pos.y - InfernoFire_HalfWidth < lo.y then
			lo.y = fire.m_pos.y - InfernoFire_HalfWidth
		end

		if fire.m_pos.y + InfernoFire_HalfWidth > hi.y then
			hi.y = fire.m_pos.y + InfernoFire_HalfWidth
		end

		if fire.m_pos.z < lo.z then
			lo.z = fire.m_pos.z
		end

		if fire.m_pos.z + InfernoFire_FullHeight > hi.z then
			hi.z = fire.m_pos.z + InfernoFire_FullHeight
		end
	end
end

function ENT:Spread(spreadVelocity)
	local selfTable = self:GetTable()

	if selfTable.m_NextSpreadTimer:HasStarted() and not selfTable.m_NextSpreadTimer:IsElapsed() then
		return
	end

	selfTable.m_NextSpreadTimer:Start(selfTable.GetFlameSpreadDelay(self))

	for i = 0, selfTable.GetFireCount(self) - 1 do
		-- attempt to spawn child-flames
		local fire = selfTable.m_fire[i]
		if not fire.m_burning or fire.m_lifetime:IsElapsed() then
			-- This flame has been extinguished or elapsed, shouldn't be spreading from here
			continue
		end

		if not fire.m_spawnLifetime:IsElapsed() and fire.m_spawnTimer:IsElapsed() then
			fire.m_spawnTimer:Reset()
			fire.m_spawnCount = fire.m_spawnCount + 1
		end
	end

	local traceCount = inferno_max_trace_per_tick:GetInt()
	local nextFireOffset = selfTable.m_fireSpawnOffset + 1
	local bDebug = InfernoDebug:GetBool()

	local i = 0
	repeat
		if selfTable.GetFireCount(self) >= math.min(MAX_INFERNO_FIRES, selfTable.GetMaxFlames(self)) then break end

		local fireIndex = (i + selfTable.m_fireSpawnOffset) % selfTable.GetFireCount(self)
		local fire = selfTable.m_fire[fireIndex]
		local depth = fire.m_treeDepth + 1
		local tr = {}

		nextFireOffset = fireIndex

		if fire.m_spawnCount == 0 then continue end

		-- This flame has been extinguished or elapsed, shouldn't be spreading from here
		if not fire.m_burning or fire.m_lifetime:IsElapsed() then continue end

		if depth >= InfernoChildSpawnMaxDepth:GetInt() then continue end

		fire.m_spawnCount = fire.m_spawnCount - 1

		-- const int maxRetry = 4
		for t = 0, 4 do
			local out = Vector()

			if not fire.m_parent then
				-- initial fire spreads outward in a circle
				local angle = g_ursRandom:RandomFloat(-math.pi, math.pi)
				out:SetUnpacked(math.cos(angle), math.sin(angle), 0)
			else
				-- child flames tend to spread away from their parent
				local to = fire.m_pos - fire.m_parent.m_pos
				to:Normalize()

				local angles = to:Angle()

				angles.y = angles.y + (g_ursRandom:RandomFloat(-InfernoSpawnAngle:GetFloat(), InfernoSpawnAngle:GetFloat()))

				out:Set(angles:Forward())
			end

			-- If we're going into a wall, don't keep trying to spread into a wall the entire lifetime - back off to
			-- a circular spread at the end.
			local velocityDecay = math.pow(InfernoVelocityDecayFactor:GetFloat(), fire.m_treeDepth)
			local timeAdjustedSpreadVelocity = spreadVelocity * fire.m_lifetime:GetRemainingRatio() * velocityDecay
			out:Add(InfernoVelocityFactor:GetFloat() * timeAdjustedSpreadVelocity)

			-- put fire on plane of ground
			local side = fire.m_normal:Cross(out)
			out:Set(side:Cross(fire.m_normal))

			local range = g_ursRandom:RandomFloat(50.0, 75.0)

			local pos = fire.m_pos + range * out

			-- limit maximum range of spread
			local fireDir = pos - selfTable.m_startPos
			if fireDir:Length() > InfernoMaxRange:GetFloat() then
				fireDir:Normalize()
				fireDir:Mul(InfernoMaxRange:GetFloat())
				pos:Set(selfTable.m_startPos + fireDir)
			end

			-- dont let flames fall too far
			--const float maxDrop = 200.0
			local endPos = Vector(pos)
			endPos.z = fire.m_pos.z - 200

			-- put fire on the ground
			util.TraceLine({
				start = pos + Vector(0, 0, 50),
				endpos = endPos,
				mask = INFERNO_MASK_TO_GROUND,
				output = tr,
			})
			traceCount = traceCount - 1

			if not tr.Hit then
				if bDebug then
					debugoverlay.Line(pos + Vector(0, 0, 50), endPos, 1, Color(255, 255, 0), true)
					debugoverlay.Cross(pos, 5, 1, Color(255, 0, 0), true)
				end

				selfTable.m_splashVelocity:Mul(inferno_forward_reduction_factor:GetFloat())
				continue
			end

			pos.z = tr.HitPos.z
			local normal = tr.HitNormal

			-- make sure we dont go through walls
			--const Vector fireHeight( 0, 0, InfernoFire_HalfWidth )
			local fireHeight = Vector(0, 0, InfernoFire_HalfWidth)
			util.TraceLine({
				start = fire.m_pos + fireHeight,
				endpos = pos + fireHeight,
				mask = INFERNO_MASK_LOS_CHECK,
				filter = function(ent)
					if ent:IsPlayer() then return false end
					if ent:IsNPC() then return false end
					if ent:IsNextBot() then return false end

					return true
				end,
				output = tr,
			})
			traceCount = traceCount - 1

			if tr.Fraction < 1 then
				if bDebug then
					debugoverlay.Line(fire.m_pos + fireHeight, pos + fireHeight, 1, Color(255, 0, 0), true)
				end

				selfTable.m_splashVelocity:Mul(inferno_forward_reduction_factor:GetFloat())
				continue
			end

			local eCreateFireResult = self:CreateFire(pos, normal, fire, depth)
			if eCreateFireResult == k_ECreateFireResult_OK or eCreateFireResult == k_ECreateFireResult_LimitExceeded then
				break
			elseif eCreateFireResult ~= k_ECreateFireResult_AlreadyOnFire then
				selfTable.m_splashVelocity:Mul(inferno_forward_reduction_factor:GetFloat())
			end

			if bDebug then
				if eCreateFireResult == k_ECreateFireResult_InSmoke then
					debugoverlay.Line(fire.m_pos + fireHeight, pos + fireHeight, 10, Color(255, 255, 0), true)
				elseif eCreateFireResult == k_ECreateFireResult_AlreadyOnFire then
					debugoverlay.Line(fire.m_pos + fireHeight, pos + fireHeight, 2, Color(255, 100, 100), true)
				else
					debugoverlay.Line(fire.m_pos + fireHeight, pos + fireHeight, 10, Color(255, 100, 0), true)
				end
			end
		end

		i = i + 1
	until i <= selfTable.GetFireCount(self) and traceCount > 0

	selfTable.m_fireSpawnOffset = nextFireOffset + 1
end

function ENT:IsTouchingEntity(ent, radius, checkLOS)
	if ent:IsValid() then
		local radiusSqr = radius * radius
		local bDebug = InfernoDebug:GetBool()

		local fires = self.m_fire

		for i = 0, self:GetFireCount() - 1 do
			local fire = fires[i]
			if not fire then continue end

			if not fire.m_burning or fire.m_lifetime:IsElapsed() then
				-- This flame has been extinguished or elapsed, shouldn't cause damage
				continue
			end

			-- Calculate the nearest point to our potential victim, from our center point
			local fireHeight = Vector(0, 0, InfernoFire_HalfWidth)

			local pos = Vector()
			local fireCheck = Vector(fire.m_center)

			if checkLOS then
				fireCheck:Add(fireHeight)
			end

			pos:Set(ent:NearestPoint(fireCheck))

			if pos:DistToSqr(fireCheck) < radiusSqr then
				-- touching at least one flame
				if checkLOS then
					-- doublecheck los if required
					local tr = util.TraceLine({
						start = fireCheck,
						endpos = pos,
						mask = INFERNO_MASK_DAMAGE,
						filter = ent,
					})

					if tr.Fraction < 1 then
						fireCheck:Set(fire.m_center)
						pos:Set(ent:NearestPoint(fireCheck))
						if pos:DistToSqr(fireCheck) < radiusSqr then
							util.TraceLine({
								start = fireCheck,
								endpos = pos,
								mask = INFERNO_MASK_DAMAGE,
								filter = ent,
								output = tr,
							})
						end
					end

					if tr.Fraction == 1 then
						if bDebug then
							debugoverlay.Line(fire.m_center, pos, 0.2, Color(255, 0, 255), true)
						end

						return true
					else
						if bDebug then
							debugoverlay.Line(fire.m_center, pos, 0.2, Color(255, 0, 0), true)
						end
					end
				else
					-- los not needed, it's touching

					if bDebug then
						debugoverlay.Line(fire.m_center, pos, 0.2, Color(255, 0, 255), true)
					end

					return true
				end
			end
		end
	end

	return false
end

local function ClosestPointOnRay(pos, rayStart, rayEnd, pointOnRay)
	local to = pos - rayStart
	local dir = rayEnd - rayStart
	local length = dir:Length()
	dir:Normalize()

	local rangeAlong = dir:Dot(to)

	if rangeAlong < 0.0 then
		-- off start point
		pointOnRay:Set(rayStart)
		return false
	elseif rangeAlong > length then
		-- off end point
		pointOnRay:Set(rayEnd)
		return false
	else -- within ray bounds
		local onRay = rayStart + (rangeAlong * dir)
		pointOnRay:Set(onRay)
		return true
	end
end

function ENT:IsTouchingRay(to, from, where)
	local fires = self.m_fire
	for i = 0, self:GetFireCount() - 1 do
		local fire = fires[i]
		if not fire then continue end

		-- This flame has been extinguished or elapsed, shouldn't be considered touching
		if not fire.m_burning or fire.m_lifetime:IsElapsed() then continue end

		local pointOnRay = Vector()
		ClosestPointOnRay(fire.m_center, from, to, pointOnRay)

		local radius = 2.0 * InfernoFire_HalfWidth
		if pointOnRay:Distance(fire.m_center) < radius then
			if where then
				where:Set(pointOnRay)
			end

			return true
		end
	end

	return false
end

function ENT:CheckExpired()
	local bIsAttachedToMovingObject = self:GetParent():IsValid()
	local vecInfernoOrigin = self:GetPos()

	local isDone = true

	local selfTable = self:GetTable()
	local bDebug = InfernoDebug:GetBool()

	-- check lifetime of flames
	for i = 0, selfTable.GetFireCount(self) - 1 do
		local fire = selfTable.m_fire[i]
		if not fire then continue end

		-- Already dead.
		if not fire.m_burning then continue end

		-- if this fire just died, propogate over the network
		if fire.m_lifetime:IsElapsed() then
			fire.m_pos:Zero()
			fire.m_burning = false
			selfTable.m_bFireIsBurning[i] = false

			continue
		end

		-- still at least one fire alive
		isDone = false

		fire.m_pos:Set(vecInfernoOrigin)
		fire.m_pos.x = fire.m_pos.x + selfTable.m_fireXDelta[i]
		fire.m_pos.y = fire.m_pos.y + selfTable.m_fireYDelta[i]
		fire.m_pos.z = fire.m_pos.z + selfTable.m_fireZDelta[i]

		if bIsAttachedToMovingObject then
			selfTable.RecomputeExtent(self)
		end

		if bDebug then
			debugoverlay.Sphere(fire.m_pos, 2 * InfernoFire_HalfWidth, 0.1, Color(255, 100, 0), true)
		end
	end

	if isDone then
		-- notify inferno expired
		hook.Run("SWCSInfernoExpired", self)

		if SERVER then
			self:Remove()
		end

		-- Expired!
		return true
	end

	-- Not expired
	return false
end

local radius = 2.0 * InfernoFire_HalfWidth;
function ENT:BShouldExtinguishSmokeGrenadeBounce(ent, posDropSmoke)
	local fires = self.m_fire
	local bDebug = InfernoDebug:GetBool()

	local owner = self:GetOwner()
	local traceFilter = {ent, owner, owner:IsValid() and unpack(owner:GetChildren())}

	for i = 0, self:GetFireCount() do
		local fire = fires[i]
		if not fire then continue end

		if not fire.m_burning or fire.m_lifetime:IsElapsed() then
			continue -- This flame has been extinguished or elapsed, shouldn't cause damage
		end

		if (posDropSmoke - fire.m_center):Length() < radius then
			-- doublecheck los if required
			local tr = util.TraceLine({
				start = fire.m_center + Vector(0, 0, InfernoFire_HalfWidth),
				endpos = posDropSmoke,
				mask = INFERNO_MASK_DAMAGE,
				filter = traceFilter,
				collisiongroup = COLLISION_GROUP_NONE,
			})

			if tr.Fraction < 1.0 then
				util.TraceLine({
					start = fire.m_center,
					endpos = posDropSmoke,
					mask = INFERNO_MASK_DAMAGE,
					filter = traceFilter,
					collisiongroup = COLLISION_GROUP_NONE,
					output = tr,
				})
			end

			if tr.Fraction == 1.0 then
				if bDebug then
					debugoverlay.Line(fire.m_center, posDropSmoke, 50.2, Color(255, 0, 255), true)
				end

				return true
			else
				if bDebug then
					debugoverlay.Line(fire.m_center, posDropSmoke, 50.2, Color(255, 0, 0), true)
				end
			end
		end
	end

	return false
end
