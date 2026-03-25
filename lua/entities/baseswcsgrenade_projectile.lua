AddCSLuaFile()

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

ENT.m_tTouchTrace = {}

SWCS_GRENADE_DEFAULT_SIZE = 2.0
SWCS_GRENADE_FAILSAFE_MAX_BOUNCES = 20

ENT.GrenadeSize = SWCS_GRENADE_DEFAULT_SIZE

local CONTENTS_GRENADECLIP = 0x80000

ENT.IsSWCSGrenade = true
ENT.m_hOriginalThrower = NULL

function ENT:GetGrenadeGravity() return 0.4 end
function ENT:GetGrenadeFriction() return 0.2 end
function ENT:GetGrenadeElasticity() return 0.45 end

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "InitialVelocity")
	self:NetworkVar("Vector", 1, "_Pos")
	self:NetworkVar("Vector", 2, "FinalVelocity")
	self:NetworkVar("Angle", 0, "FinalAngularVelocity")
	self:NetworkVar("Int", 0, "Bounces")
	self:NetworkVar("Int", 1, "NWMoveType")
	self:NetworkVar("Int", 2, "ActualCollisionGroup")
	self:NetworkVar("Float", 0, "TimeToDetonate")
	self:NetworkVar("Entity", 0, "NWThrower")
end

function ENT:GetThrower()
	local hThrower = self:GetNWThrower()
	local hOwner = self:GetOwner()

	if hThrower:IsValid() then
		return hThrower
	elseif hOwner:IsValid() then
		return hOwner
	end

	return NULL
end

function ENT:SetThrower(hThrower)
	self:SetNWThrower(hThrower)

	if not self.m_hOriginalThrower:IsValid() then
		self.m_hOriginalThrower = hThrower
	end
end

local sv_gravity = GetConVar"sv_gravity"

function ENT:Initialize()
	self:SetSolidFlags(FSOLID_NOT_STANDABLE)

	if SERVER then
		self:PhysicsInitBox(-Vector(1, 1, 1), Vector(1, 1, 1))
	end

	self:SetMoveType(MOVETYPE_FLYGRAVITY)
	self:SetSolid(SOLID_BBOX) -- So it will collide with physics props!
	self:AddFlags(FL_GRENADE)

	if SERVER then
		self.m_LastHitPlayer = NULL
	end

	if SERVER then
		-- smaller, cube bounding box so we rest on the ground
		local size = self.GrenadeSize or SWCS_GRENADE_DEFAULT_SIZE
		local min = Vector(-size, -size, -size)
		local max = Vector(size, size, size)
		self:SetCollisionBounds(min, max)
	end

	self:SetBounces(0)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMass(0.4) -- 0.4 kg == 0.88 lbs
		phys:Wake()
	end

	self:Set_Pos(self:GetPos())
	self:SetFinalVelocity(self:GetInitialVelocity())
	self:SetNWMoveType(self:GetMoveType())

	self:SetActualCollisionGroup(self:GetCollisionGroup())
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	if SERVER then
		self:StartMotionController()
	end

	local flSvGravity, flGravityMult = sv_gravity:GetFloat(), 1

	-- gmod's gravity is 600, csgo's gravity is 800
	-- do this little fudge to make it so that gravity is the same
	if flSvGravity == 600 then
		flGravityMult = 800 / 600
	end

	self:SetMoveCollide(MOVECOLLIDE_FLY_BOUNCE)

	self:SetGravity(self:GetGrenadeGravity() * flGravityMult)

	self:SetFriction(self:GetGrenadeFriction())
	self:SetElasticity(self:GetGrenadeElasticity())

	-- cheaters were somehow causing grenades to detonate instantly/very delayed
	self:NextThink(engine.TickCount() * engine.TickInterval())

	self:UpdateWaterState()
end

function ENT:BounceSound() end

function ENT:OnBounced() end

-- Sets the time at which the grenade will explode
function ENT:SetDetonateTimerLength(flTimer)
	self:SetTimeToDetonate((engine.TickCount() * engine.TickInterval()) + flTimer)
end

function ENT:DetonateOnNextThink()
	self:SetDetonateTimerLength(0)
end

function ENT:Detonate()
	--assert(false, "baseswcsgrenade_projectile:Detonate() should not be called. Make sure to implement this in your subclass!\n")
end

function ENT:OnLostParent(parent) end

ENT.m_bHasParent = false
function ENT:Think()
	local selfTable = self:GetTable()

	-- HACK fix for angular velocity being reset on bouncing
	local angularVel = self:GetLocalAngularVelocity()
	if angularVel:IsZero() then
		self:SetLocalAngularVelocity(selfTable.GetFinalAngularVelocity(self))
	end

	self:SetMoveType(selfTable.GetNWMoveType(self))

	-- no parent
	local parent = self:GetParent()
	if not parent:IsValid() then
		-- lost parent
		if selfTable.m_bHasParent then
			if not self:IsSolid() then
				self:SetNotSolid(false)
			end

			selfTable.SetNWMoveType(self, MOVETYPE_FLYGRAVITY)
			selfTable.m_bHasParent = false

			--self:OnLostParent(NULL)
		end

		self:SetPos(selfTable.Get_Pos(self))
	elseif not selfTable.m_bHasParent then
		selfTable.m_bHasParent = true
	elseif parent:IsPlayer() or parent:IsNPC() or parent:IsNextBot() then
		-- parent has died, we need to fall off
		if (parent.Alive and not parent:Alive()) or parent:Health() <= 0 then
			selfTable.SetNWMoveType(self, MOVETYPE_FLYGRAVITY)
			self:SetParent(nil)

			selfTable.Set_Pos(self, self:GetPos())

			selfTable.OnLostParent(self, parent)
		end
	end

	self:NextThink(CurTime() + 0.2)

	if self:WaterLevel() ~= 0 then
		selfTable.SetFinalVelocity(self, selfTable.GetFinalVelocity(self) * 0.5)
	end

	if selfTable.AdditionalThink(self, selfTable) then
		return true
	end

	if CurTime() > selfTable.GetTimeToDetonate(self) then
		selfTable.Detonate(self)
	end

	return true
end

function ENT:AdditionalThink(selfTable) end

--[[
function ENT:UpdateTransmitState()
	-- always call ShouldTransmit() for grenades
	return self:ShouldTransmit()
end
]]

function ENT:ShouldTransmit()
	--[[CBaseEntity *pRecipientEntity = CBaseEntity::Instance( pInfo->m_pClientEnt );
	if ( pRecipientEntity->IsPlayer() )
	{
		CBasePlayer *pRecipientPlayer = static_cast<CBasePlayer*>( pRecipientEntity );

		// always transmit to the thrower of the grenade
		if ( pRecipientPlayer && ( (GetThrower() && pRecipientPlayer == GetThrower()) ||
			pRecipientPlayer->GetTeamNumber() == TEAM_SPECTATOR) )
		{
			return FL_EDICT_ALWAYS;
		}
	}

	return FL_EDICT_PVSCHECK;]]
end

function ENT:PhysicsSimulate(phys, dTime)
	local selfTable = self:GetTable()
	if not self:GetParent():IsValid() and selfTable.GetNWMoveType(self) == MOVETYPE_FLYGRAVITY then
		selfTable.PhysicsToss(self, phys, dTime, selfTable)

		--phys:SetPos(self:GetPos())
		--phys:SetVelocity(self:GetFinalVelocity())
		--self:SetVelocity(vector_origin)
	end

	return SIM_NOTHING
end

local function IsStandable(pEnt)
	if bit.band(pEnt:GetSolidFlags(), FSOLID_NOT_STANDABLE) ~= 0 then
		return false
	end

	local iSolid = pEnt:GetSolid()
	if iSolid == SOLID_BSP or iSolid == SOLID_VPHYSICS or iSolid == SOLID_BBOX then
		return true
	end

	return swcs.IsBSPModel(pEnt)
end

-- Purpose: Bounds velocity
local sv_maxvelocity = GetConVar"sv_maxvelocity"
function ENT:PhysicsCheckVelocity(selfTable)
	selfTable = selfTable or self:GetTable()

	local vecAbsVelocity = selfTable.GetFinalVelocity(self)

	local bReset = false
	local flMaxVelocity = sv_maxvelocity:GetFloat()

	for i = 1, 3 do
		--[[
		if ( IS_NAN(vecAbsVelocity[i]) )
		{
			Msg( "Got a NaN velocity on %s\n", GetClassname() )
			vecAbsVelocity[i] = 0
			bReset = true
		}
		if ( IS_NAN(origin[i]) )
		{
			Msg( "Got a NaN origin on %s\n", GetClassname() )
			origin[i] = 0
			bReset = true
		}
		]]

		if vecAbsVelocity[i] > flMaxVelocity then
			vecAbsVelocity[i] = flMaxVelocity
			bReset = true
		elseif (vecAbsVelocity[i] < -flMaxVelocity) then
			vecAbsVelocity[i] = -flMaxVelocity
			bReset = true
		end
	end

	if bReset then
		selfTable.SetFinalVelocity(self, vecAbsVelocity)
	end
end

local sv_grenade_trajectory = CreateConVar("swcs_debug_grenade_trajectory", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Shows grenade trajectory visualization in-game.")
local sv_grenade_trajectory_thickness = CreateConVar("swcs_debug_grenade_trajectory_thickness", "0.2", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Visible thickness of grenade trajectory arc", 0.1, 1)
local sv_grenade_trajectory_time = CreateConVar("swcs_debug_grenade_trajectory_time", "20", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Length of time grenade trajectory remains visible.", 0.1, 20)
local sv_grenade_trajectory_dash = CreateConVar("swcs_debug_grenade_trajectory_dash", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "Dot-dash style grenade trajectory arc")
local kSleepVelocity = 20
local kSleepVelocitySquared = kSleepVelocity * kSleepVelocity
function ENT:PhysicsToss(phys, dTime, selfTable)
	selfTable = selfTable or self:GetTable()

	local trace = selfTable.m_tTouchTrace
	local move = selfTable.GetFinalVelocity(self) * dTime

	-- Moving upward, off the ground, or resting on a client/monster, remove FL_ONGROUND
	if selfTable.GetFinalVelocity(self).z > 0 or selfTable.GetFinalVelocity(self):LengthSqr() > kSleepVelocitySquared or not self:GetGroundEntity():IsValid() or not IsStandable(self:GetGroundEntity()) then
		self:SetGroundEntity(NULL)
	end

	local flags = self:GetFlags()

	-- Check to see if entity is on the ground at rest
	if bit.band(flags, FL_ONGROUND) ~= 0 and (selfTable.GetFinalVelocity(self):IsZero()) then
		-- Clear rotation if not moving (even if on a conveyor)
		self:SetLocalAngularVelocity(angle_zero)
		selfTable.SetFinalAngularVelocity(self, angle_zero)
		if (selfTable.GetFinalVelocity(self):IsZero()) then
			return
		end
	end

	selfTable.PhysicsCheckVelocity(self, selfTable)

	-- add gravity
	if (selfTable.GetNWMoveType(self) == MOVETYPE_FLYGRAVITY and (bit.band(flags, FL_FLY) == 0)) then
		selfTable.PhysicsAddGravityMove(self, move, dTime, selfTable)
	else
		-- Base velocity is not properly accounted for since this entity will move again after the bounce without
		-- taking it into account
		move:Set(selfTable.GetFinalVelocity(self))
		move:Mul(dTime)
		selfTable.PhysicsCheckVelocity(self, selfTable)
	end

	-- move angles
	--SimulateAngles( dTime )

	-- move origin
	selfTable.PhysicsPushEntity(self, move, trace, selfTable)

	if phys:IsValid() then
		phys:UpdateShadow(trace.HitPos, Angle(), dTime)
	end

	selfTable.PhysicsCheckVelocity(self, selfTable)

	if (SERVER and sv_grenade_trajectory:GetInt() ~= 0 and bit.band(flags, FL_GRENADE) ~= 0) then
		local vec3tempOrientation = (trace.HitPos - trace.StartPos)
		local angGrTrajAngles = vec3tempOrientation:Angle()

		local flGrTraThickness = sv_grenade_trajectory_thickness:GetFloat()
		local vec3_GrTrajMin = Vector(1, -flGrTraThickness, -flGrTraThickness)
		local vec3_GrTrajMax = Vector(vec3tempOrientation:Length() + 1, flGrTraThickness, flGrTraThickness)
		local bDash = (sv_grenade_trajectory_dash:GetInt() ~= 0 and CurTime() % 0.1 < 0.05)

		-- extruded "line" is really a box for more visible thickness
		debugoverlay.BoxAngles(trace.StartPos, vec3_GrTrajMin, vec3_GrTrajMax, angGrTrajAngles, sv_grenade_trajectory_time:GetFloat(), Color(0, bDash and 20 or 200, 0, 255))

		-- per-bounce box
		if (trace.Fraction ~= 1.0) then
			debugoverlay.Box(trace.HitPos, -Vector(SWCS_GRENADE_DEFAULT_SIZE, SWCS_GRENADE_DEFAULT_SIZE, SWCS_GRENADE_DEFAULT_SIZE), Vector(SWCS_GRENADE_DEFAULT_SIZE, SWCS_GRENADE_DEFAULT_SIZE, SWCS_GRENADE_DEFAULT_SIZE), 5, Color(220, 0, 0, 190))
		end
	end

	-- bonked into something
	if (trace.Fraction ~= 1.0) then
		selfTable.ResolveFlyCollisionCustom(self, trace, move, dTime, selfTable)
	end

	-- check for in water
	selfTable.PhysicsCheckWaterTransition(self, selfTable)
end

ENT.m_nWaterType = 0
function ENT:SetWaterType(nType)
	local iWaterType = 0

	if bit.band(nType, CONTENTS_WATER) ~= 0 then
		iWaterType = bit.bor(iWaterType, 1)
	end

	if bit.band(nType, CONTENTS_SLIME) ~= 0 then
		iWaterType = bit.bor(iWaterType, 2)
	end

	self.m_nWaterType = iWaterType
end

function ENT:GetWaterType()
	local out = 0

	if bit.band(self.m_nWaterType, 1) ~= 0 then
		out = bit.bor(out, CONTENTS_WATER)
	end

	if bit.band(self.m_nWaterType, 2) ~= 0 then
		out = bit.bor(out, CONTENTS_SLIME)
	end

	return out
end

local MAX_WATER_SURFACE_DISTANCE = 512
function ENT:Splash(selfTable)
	selfTable = selfTable or self:GetTable()

	local centerPoint = selfTable.Get_Pos(self)
	local normal = Vector(0, 0, 1)

	-- Find our water surface by tracing up till we're out of the water
	local vecTrace = Vector(0, 0, MAX_WATER_SURFACE_DISTANCE)
	local tr = util.TraceLine({
		start = centerPoint,
		endpos = centerPoint + vecTrace,
		mask = MASK_WATER,
		filter = self,
		collisiongroup = COLLISION_GROUP_NONE,
	})

	-- If we didn't start in water, we're above it
	if not tr.StartSolid then
		-- Look downward to find the surface
		vecTrace:SetUnpacked(0, 0, -MAX_WATER_SURFACE_DISTANCE)
		util.TraceLine({
			start = centerPoint,
			endpos = centerPoint + vecTrace,
			mask = MASK_WATER,
			filter = self,
			collisiongroup = COLLISION_GROUP_NONE,
			output = tr,
		})

		-- If we hit it, setup the explosion
		if tr.fraction < 1.0 then
			centerPoint = tr.endpos
		else
			--NOTENOTE: We somehow got into a splash without being near water?
			--Assert( 0 )
			return
		end
	elseif tr.FractionLeftSolid ~= 0 then
		-- Otherwise we came out of the water at this point
		centerPoint = centerPoint + (vecTrace * tr.FractionLeftSolid)
	else
		-- Use default values, we're really deep
	end

	ParticleEffect("impact_water_csgo", centerPoint, angle_zero, nil)
	sound.Play("Water.BulletImpact", centerPoint)

	--CEffectData	data
	--data.m_vOrigin = centerPoint
	--data.m_vNormal = normal
	--data.m_flScale = random->RandomFloat( 1.0f, 2.0f )
	--
	--if ( GetWaterType() & CONTENTS_SLIME )
	--{
	--	data.m_fFlags |= FX_WATER_IN_SLIME
	--}
	--
	--DispatchEffect( "gunshotsplash", data )
end

function ENT:PhysicsCheckWaterTransition(selfTable)
	selfTable = selfTable or self:GetTable()

	local oldcont = selfTable.GetWaterType(self)
	selfTable.UpdateWaterState(self)
	local cont = selfTable.GetWaterType(self)

	if self:GetMoveParent():IsValid() then
		return
	end

	if bit.band(cont, MASK_WATER) ~= 0 then
		if oldcont == CONTENTS_EMPTY then
			if CLIENT then
				selfTable.Splash(self, selfTable)
			end

			-- just crossed into water
			self:EmitSound("BaseEntity.EnterWater")

			if not self:IsEFlagSet(EFL_NO_WATER_VELOCITY_CHANGE) then
				local vecAbsVelocity = self:GetFinalVelocity()
				vecAbsVelocity.z = vecAbsVelocity.z * 0.5
				selfTable.SetFinalVelocity(self, vecAbsVelocity)
			end
		end
	elseif oldcont ~= CONTENTS_EMPTY then
		-- just crossed out of water
		self:EmitSound("BaseEntity.ExitWater")
	end
end

function ENT:UpdateWaterState()
	-- Compute the point to check for water state
	local point = self:WorldSpaceCenter()

	self:SetWaterLevel(0)
	self:SetWaterType(CONTENTS_EMPTY)
	local cont = util.PointContents(point)

	if bit.band(cont, MASK_WATER) == 0 then
		return
	end

	self:SetWaterType(cont)
	self:SetWaterLevel(1)

	-- point sized entities are always fully submerged
	if self:BoundingRadius() == 0 then
		self:SetWaterLevel(3)
	else
		-- Check the exact center of the box
		point.z = self:WorldSpaceCenter().z

		local midcont = util.PointContents(point)
		if bit.band(midcont, MASK_WATER) ~= 0 then
			-- Now check where the eyes are...
			self:SetWaterLevel(2)

			local eyecont = util.PointContents(self:EyePos())
			if bit.band(eyecont, MASK_WATER) ~= 0 then
				self:SetWaterLevel(3)
			end
		end
	end
end

function ENT:GetImpactDamage()
	return 2
end

function ENT:ResolveFlyCollisionCustom(trace, vecMove, dTime, selfTable)
	selfTable = selfTable or self:GetTable()

	local pEntity = trace.Entity

	-- this is necessary so that we can hit the world
	if pEntity and not pEntity:IsValid() and not pEntity:IsWorld() then
		return
	end

	-- if its breakable glass and we kill it, don't bounce.
	-- give some damage to the glass, and if it breaks, pass
	-- through it.
	local breakthrough = false

	local classname = pEntity:GetClass()

	if classname == "func_breakable" then
		breakthrough = true
	end

	if classname == "func_breakable_surf" then
		breakthrough = true
	end

	local m_takedamage = pEntity:GetInternalVariable("m_takedamage")
	if classname == "prop_physics_multiplayer" and pEntity:GetMaxHealth() > 0 and m_takedamage == 2 then
		breakthrough = true
	end

	-- this one is tricky because BounceTouch hits breakable propers before we hit this function and the damage is already applied there (CBaseGrenade::BounceTouch( CBaseEntity *ppEntity ))
	-- by the time we hit this, the prop hasn't been removed yet, but it broke, is set to not take anymore damage and is marked for deletion - we have to cover this case here
	if classname == "prop_dynamic" and pEntity:GetMaxHealth() > 0 and (m_takedamage == 2 or (m_takedamage == 0 and pEntity:IsEFlagSet(EFL_KILLME))) then
		breakthrough = true
	end

	if breakthrough then
		if SERVER then
			local info = DamageInfo()
			info:SetInflictor(self)
			info:SetAttacker(self:GetOwner():IsValid() and self:GetOwner() or self)
			info:SetDamage(10)
			info:SetDamageType(DMG_CLUB)
			pEntity:DispatchTraceAttack(info, trace, selfTable.GetFinalVelocity(self):GetNormalized())
		end

		if pEntity:Health() <= 0 then
			-- slow our flight a little bit
			local vel = selfTable.GetFinalVelocity(self)

			vel:Mul(0.4)

			selfTable.SetFinalVelocity(self, vel)
			return
		end
	end

	--Assume all surfaces have the same elasticity
	local flSurfaceElasticity = 1.0

	--Don't bounce off of players with perfect elasticity
	if pEntity:IsPlayer() then
		flSurfaceElasticity = 0.3

		-- and do slight damage to players on the opposite team
		if SERVER then
			pEntity:SetLastHitGroup(HITGROUP_GENERIC)

			local dmg = DamageInfo()
			dmg:SetAttacker(self:GetOwner():IsValid() and self:GetOwner() or self)
			dmg:SetInflictor(self)
			dmg:SetDamage(selfTable.GetImpactDamage(self))
			dmg:SetDamageType(DMG_GENERIC)
			dmg:SetReportedPosition(trace.HitPos)
			dmg:SetDamagePosition(trace.HitPos)
			pEntity:TakeDamageInfo(dmg)
		end
	end

	--Don't bounce twice on a selection of problematic entities
	local bIsProjectile = pEntity.IsSWCSGrenade == true
	if not pEntity:IsWorld() and selfTable.m_lastHitPlayer == pEntity then
		local bIsNPC = pEntity:IsNPC() or pEntity:IsNextBot() --dynamic_cast< CHostage* >( pEntity ) != NULL;

		if pEntity:IsPlayer() or bIsNPC or bIsProjectile then
			selfTable.SetActualCollisionGroup(self, COLLISION_GROUP_DEBRIS)

			if bIsProjectile then
				pEntity:SetActualCollisionGroup(COLLISION_GROUP_DEBRIS)
			end

			return
		end
	end

	selfTable.m_lastHitPlayer = pEntity

	local flTotalElasticity = selfTable.GetGrenadeElasticity(self) * flSurfaceElasticity
	flTotalElasticity = math.Clamp(flTotalElasticity, 0.0, 0.9)

	-- NOTE: A backoff of 2.0f is a reflection
	local vecAbsVelocity = Vector()
	selfTable.PhysicsClipVelocity(self, selfTable.GetFinalVelocity(self), trace.HitNormal, vecAbsVelocity, 2)
	vecAbsVelocity:Mul(flTotalElasticity)
	selfTable.SetFinalVelocity(self, vecAbsVelocity)

	-- Get the total velocity (player + conveyors, etc.)
	vecMove:Set(vecAbsVelocity) -- + self:GetBaseVelocity())
	local flSpeedSqr = vecMove:LengthSqr()

	local bIsWeapon = pEntity:IsWeapon()

	local hCollisionEntity = trace.Entity
	local tSavedTouchTrace = table.Copy(trace)
	-- Stop if on ground or if we bounce and our velocity is really low (keeps it from bouncing infinitely)
	if ((trace.HitNormal.z > 0.7) or (trace.HitNormal.z > 0.1 and flSpeedSqr < kSleepVelocitySquared)) and
		(IsStandable(pEntity) or bIsProjectile or bIsWeapon or pEntity:IsWorld())
	then
		-- clip it again to emulate old behavior and keep it from bouncing up like crazy when you throw it at the ground on the first toss
		if (flSpeedSqr > 96000) then
			local alongDist = vecAbsVelocity:GetNormalized():Dot(trace.HitNormal)
			if (alongDist > 0.5) then
				local flBouncePadding = (1.0 - alongDist) + 0.5
				vecAbsVelocity:Mul(flBouncePadding)
			end
		end

		selfTable.SetFinalVelocity(self, vecAbsVelocity)

		if (flSpeedSqr < kSleepVelocitySquared) then
			-- stop moving

			self:SetGroundEntity(pEntity)
			selfTable.SetNWMoveType(self, MOVETYPE_NONE)

			-- Reset velocities.
			self:SetVelocity(vector_origin)
			self:SetLocalAngularVelocity(angle_zero)
			selfTable.SetFinalAngularVelocity(self, angle_zero)
			selfTable.SetFinalVelocity(self, vector_origin)

			--align to the ground so we're not standing on end
			local angle = trace.HitNormal:Angle()

			-- rotate randomly in yaw
			angle:RotateAroundAxis(angle:Forward(), g_ursRandom:RandomFloat(0, 360))
			--angle[2] = g_ursRandom:RandomFloat( 0, 360 )

			-- TODO: rotate around trace.plane.normal

			self:SetAngles(angle)
		else
			-- bounce off floor

			local vecBaseDir = selfTable.GetFinalVelocity(self)
			if (not vecBaseDir:IsZero()) then
				vecBaseDir:Normalize()
				local vecDelta = selfTable.GetFinalVelocity(self) - vecAbsVelocity
				local flScale = vecDelta:LengthSqr(vecBaseDir)
				vecAbsVelocity:Add(selfTable.GetFinalVelocity(self) * flScale)
			end

			vecMove:Set(vecAbsVelocity)
			vecMove:Mul((1 - trace.Fraction) * dTime)

			selfTable.PhysicsPushEntity(self, vecMove, trace, selfTable)

			selfTable.SetFinalVelocity(self, vecAbsVelocity)
		end
	else
		-- bounce off wall

		selfTable.SetFinalVelocity(self, vecAbsVelocity)
		vecMove:Set(vecAbsVelocity)
		vecMove:Mul(trace.Fraction)
		vecMove:Mul(dTime)

		selfTable.PhysicsPushEntity(self, vecMove, trace, selfTable)
	end

	local hOurPhys = self:GetPhysicsObject()
	local hOtherPhys = pEntity:GetPhysicsObject()
	if not pEntity:IsWorld() and hOtherPhys:IsValid() then
		-- The impulse to be applied in kg*source_unit/s. (World frame)

		local flImpulse = hOurPhys:GetMass() * self:GetFinalVelocity():Length()
		local vImpulse = trace.Normal * -flImpulse

		hOtherPhys:ApplyForceOffset(vImpulse, trace.HitPos)
	end

	if SERVER and self:GetCreationTime() < CurTime() - 0.5 then
		sound.EmitHint(SOUND_DANGER, self:GetPos(), 256, 0.1)
	end

	self:SetAbsVelocity(selfTable.GetFinalVelocity(self))
	if IsFirstTimePredicted() then
		selfTable.BounceSound(self)
	end
	selfTable.OnBounced(self, tSavedTouchTrace, hCollisionEntity, selfTable)

	if selfTable.GetBounces(self) > SWCS_GRENADE_FAILSAFE_MAX_BOUNCES then
		-- failsafe detonate after 20 bounces
		self:SetVelocity(vector_origin)
		selfTable.SetFinalVelocity(self, vector_origin)
		selfTable.DetonateOnNextThink(self)
		selfTable.SetNWMoveType(self, MOVETYPE_NONE)
	else
		selfTable.SetBounces(self, selfTable.GetBounces(self) + 1)
	end
end

local function UTIL_TraceEntity(pEntity, vecAbsStart, vecAbsEnd, mask, pTr)
	return util.TraceEntity({
		start = vecAbsStart,
		endpos = vecAbsEnd,
		filter = function(ent)
			if ent == pEntity or ent == pEntity:GetOwner() then
				return false
			end

			if ent.IsSWCSGrenade then return false end
			return true
		end,
		output = pTr,
		mask = mask,
	}, pEntity)
end

local function Physics_TraceEntity(self, vecAbsStart, vecAbsEnd, mask, pTr, selfTable)
	selfTable = selfTable or self:GetTable()

	--if (pBaseEntity->GetDamageType() != DMG_GENERIC) then
	--    GameRules()->WeaponTraceEntity( pBaseEntity, vecAbsStart, vecAbsEnd, mask, ptr );
	--else
	UTIL_TraceEntity(self, vecAbsStart, vecAbsEnd, mask, pTr)

	-- perform an additional trace if this is a grenade projectile hitting a player
	--CBaseCSGrenadeProjectile* pGrenadeProjectile = dynamic_cast<CBaseCSGrenadeProjectile*>( pBaseEntity );

	if pTr.StartSolid and bit.band(pTr.Contents, CONTENTS_GRENADECLIP) ~= 0 then
		-- HACK HACK: players don't collide with CONTENTS_GRENADECLIP, so it's possible (but very inadvisable) for maps to contain
		-- CONTENTS_GRENADECLIP brushes that are big enough for the player to throw a grenade from INSIDE one. To account for this
		-- in the simplest and most straightforward way, I'm just running the trace again to let grenades fly OUT of CONTENTS_GRENADECLIP
		-- volumes, just not INTO them.
		--UTIL_ClearTrace( *pTr )
		UTIL_TraceEntity(self, vecAbsStart, vecAbsEnd, bit.band(mask, bit.bnot(CONTENTS_GRENADECLIP)), pTr)
	end

	if (pTr.Fraction < 1 or pTr.AllSolid or pTr.StartSolid) and pTr.Entity:IsValid() and pTr.Entity:IsPlayer() and bit.band(mask, CONTENTS_HITBOX) ~= 0 then
		--UTIL_ClearTrace( *pTr );
		--why does traceline respect hitboxes in the mask param but traceentity and tracehull do not?
		util.TraceLine({
			start = vecAbsStart,
			endpos = vecAbsEnd,
			mask = mask,
			filter = function(ent)
				if ent == self or ent == self:GetOwner() then
					return false
				end

				if ent.IsSWCSGrenade then return false end
				return true
			end,
			collisiongroup = selfTable.GetActualCollisionGroup(self),
			output = pTr,
		})
	end
	--end
end

function ENT:GetSolidMask(selfTable)
	selfTable = selfTable or self:GetTable()
	if selfTable.GetActualCollisionGroup(self) == COLLISION_GROUP_DEBRIS then
		return bit.band(bit.bor(CONTENTS_GRENADECLIP, MASK_SOLID), bit.bnot(CONTENTS_MONSTER))
	else
		return bit.band(bit.bor(CONTENTS_GRENADECLIP, MASK_SOLID, MASK_VISIBLE_AND_NPCS, CONTENTS_HITBOX), bit.bnot(CONTENTS_DEBRIS))
	end
end

local function PhysicsCheckSweep(self, vecAbsStart, vecAbsDelta, pTrace, selfTable)
	selfTable = selfTable or self:GetTable()

	local mask = selfTable.GetSolidMask(self, selfTable)

	local vecAbsEnd = vecAbsStart + vecAbsDelta

	-- Set collision type
	if not self:IsSolid() or bit.band(self:GetSolidFlags(), FSOLID_VOLUME_CONTENTS) ~= 0 then
		if self:GetMoveParent():IsValid() then
			-- UTIL_ClearTrace( *pTrace )
			--table.Empty(pTrace)

			return
		end

		-- don't collide with monsters
		mask = bit.band(mask, bit.bnot(CONTENTS_MONSTER))
	end

	Physics_TraceEntity(self, vecAbsStart, vecAbsEnd, mask, pTrace)
end

function ENT:PhysicsPushEntity(push, pTrace, selfTable)
	if self:GetMoveParent():IsValid() then
		return
	end

	-- NOTE: absorigin and origin must be equal because there is no moveparent
	local prevOrigin = selfTable.Get_Pos(self)

	PhysicsCheckSweep(self, prevOrigin, push, pTrace)

	-- if the sweep check starts inside a solid surface, try once more from the last origin
	if pTrace.StartSolid then
		selfTable.SetActualCollisionGroup(self, COLLISION_GROUP_INTERACTIVE_DEBRIS)
		util.TraceLine({
			start = prevOrigin - push,
			endpos = prevOrigin + push,
			mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_WINDOW, CONTENTS_GRATE),
			filter = function(ent)
				if ent == self or ent == self:GetOwner() then
					return false
				end

				if ent.IsSWCSGrenade then return false end
				return true
			end,
			collisiongroup = selfTable.GetActualCollisionGroup(self),
			output = pTrace,
		})
	end

	if pTrace.Fraction ~= 0 then
		selfTable.Set_Pos(self, pTrace.HitPos)
	end

	-- Passing in the previous abs origin here will cause the relinker
	-- to test the swept ray from previous to current location for trigger intersections
	--PhysicsTouchTriggers( &prevOrigin );

	if pTrace.Entity:IsValid() then
		--PhysicsImpact( pTrace->m_pEnt, *pTrace );
	end
end

local STOP_EPSILON = 0.1
function ENT:PhysicsClipVelocity(vin, normal, out, overbounce)
	local backoff
	local change
	local angle
	local blocked

	blocked = 0

	angle = normal[3]

	if angle > 0 then
		blocked = bit.bor(blocked, 1) -- floor
	end
	if angle == 0 then
		blocked = bit.bor(blocked, 2) -- step
	end

	backoff = vin:Dot(normal) * overbounce

	for i = 1, 3 do
		change = normal[i] * backoff
		out[i] = vin[i] - change
		if (out[i] > -STOP_EPSILON and out[i] < STOP_EPSILON) then
			out[i] = 0
		end
	end

	return blocked
end

function ENT:PhysicsAddGravityMove(move, dTime, selfTable)
	selfTable = selfTable or self:GetTable()

	local vecAbsVelocity = selfTable.GetFinalVelocity(self)

	local baseVel = self:GetBaseVelocity()
	move.x = (vecAbsVelocity.x + baseVel.x) * dTime
	move.y = (vecAbsVelocity.y + baseVel.y) * dTime

	--[[
	if ( bit.band(self:GetFlags(), FL_ONGROUND) ~= 0 ) then
		move.z = baseVel.z * dTime
		return
	end
	--]]

	-- linear acceleration due to gravity
	local newZVelocity = vecAbsVelocity.z - sv_gravity:GetFloat() * self:GetGravity() * dTime

	move.z = (((vecAbsVelocity.z + newZVelocity) * 0.5) + baseVel.z) * dTime

	--local vecBaseVelocity = baseVel
	--vecBaseVelocity.z = 0.0
	--self:SetBaseVelocity( vecBaseVelocity )

	vecAbsVelocity.z = newZVelocity
	selfTable.SetFinalVelocity(self, vecAbsVelocity)
	--self:SetAbsVelocity( vecAbsVelocity )

	-- Bound velocity
	selfTable.PhysicsCheckVelocity(self)
end

if SERVER then
	local SHOULD_BYPASS = CreateConVar("swcs_grenades_always_trigger_triggers", "1", FCVAR_ARCHIVE, "Should grenades disobey a trigger's spawnflags\n0 - No, 1 - Yes, 2 - Only if trigger is set for physics objects\n**This will not properly call trigger outputs**")
	local SPOOF_TRIGGERS = CreateConVar("swcs_grenades_spoof_triggers", "1", FCVAR_ARCHIVE, "Should grenades spoof flags to activate a trigger?")

	ENT.m_hTouching = setmetatable({}, {__mode = "k"})
	local trigger_cache = setmetatable({}, {__mode = "k"})

	SF_TRIGGER_ALLOW_CLIENTS = 0x01 -- Players can fire this trigger
	SF_TRIGGER_ALLOW_NPCS = 0x02 -- NPCS can fire this trigger
	SF_TRIGGER_ALLOW_PUSHABLES = 0x04 -- Pushables can fire this trigger
	SF_TRIGGER_ALLOW_PHYSICS = 0x08 -- Physics objects can fire this trigger
	SF_TRIGGER_ONLY_PLAYER_ALLY_NPCS = 0x10 -- *if* NPCs can fire this trigger, this flag means only player allies do so
	SF_TRIGGER_ONLY_CLIENTS_IN_VEHICLES = 0x20 -- *if* Players can fire this trigger, this flag means only players inside vehicles can
	SF_TRIGGER_ALLOW_ALL = 0x40 -- Everything can fire this trigger EXCEPT DEBRIS!
	SF_TRIGGER_ONLY_CLIENTS_OUT_OF_VEHICLES = 0x200 -- *if* Players can fire this trigger, this flag means only players outside vehicles can
	SF_TRIG_TOUCH_DEBRIS = 0x400 -- Will touch physics debris objects
	SF_TRIGGER_ONLY_NPCS_IN_VEHICLES = 0x800 -- *if* NPCs can fire this trigger, only NPCs in vehicles do so (respects player ally flag too)
	SF_TRIGGER_DISALLOW_BOTS = 0x1000 -- Bots are not allowed to fire this trigger

	function ENT:CalcAbsolutePosition(pos, ang)
		if self:IsFlagSet(FL_DONTTOUCH) then return pos, ang end
		if SHOULD_BYPASS:GetInt() == 0 then return pos, ang end

		for ent in next, self.m_hTouching do
			if not ent:IsValid() then
				self.m_hTouching[ent] = nil
				continue
			end

			local stillTouching = util.IsOBBIntersectingOBB(ent:GetPos(), ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), pos, ang, self:OBBMins(), self:OBBMaxs(), 0)

			if not stillTouching then
				if bit.band(ent:GetSolidFlags(), FSOLID_TRIGGER) ~= 0 and SPOOF_TRIGGERS:GetBool() then
					if ent:HasSpawnFlags(SF_TRIGGER_ALLOW_CLIENTS) then
						self:RemoveFlags(FL_CLIENT)
					end
					if ent:HasSpawnFlags(SF_TRIGGER_ALLOW_NPCS) then
						self:RemoveFlags(FL_NPC)
					end
					if ent:HasSpawnFlags(SF_TRIGGER_ALLOW_PHYSICS) then
						self:SetMoveType(MOVETYPE_FLYGRAVITY)
					end
					if ent:HasSpawnFlags(SF_TRIG_TOUCH_DEBRIS) then
						self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
					end
				end
				self.m_hTouching[ent] = nil
			end
		end

		local mins, maxs = self:WorldSpaceAABB()
		local touching = ents.FindInBox(mins, maxs)

		for _, ent in ipairs(touching) do
			if ent:GetInternalVariable("m_bDisabled") then continue end
			if self.m_hTouching[ent] == true then continue end

			self.m_hTouching[ent] = true
			if bit.band(ent:GetSolidFlags(), FSOLID_TRIGGER) ~= 0 then
				local physOnly = ent:HasSpawnFlags(SF_TRIGGER_ALLOW_PHYSICS)
				if not physOnly and SHOULD_BYPASS:GetInt() == 2 then continue end

				if SPOOF_TRIGGERS:GetBool() then
					if ent:HasSpawnFlags(SF_TRIGGER_ALLOW_CLIENTS) then
						self:AddFlags(FL_CLIENT)
					end
					if ent:HasSpawnFlags(SF_TRIGGER_ALLOW_NPCS) then
						self:AddFlags(FL_NPC)
					end
					if physOnly then
						self:SetMoveType(MOVETYPE_VPHYSICS)
					end
					if ent:HasSpawnFlags(SF_TRIG_TOUCH_DEBRIS) then
						self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
					end
				end

				if ent:GetClass() == "trigger_teleport" then
					local cache = trigger_cache[ent]
					if cache then
						pos = cache[1]
						ang = cache[2]
					else
						local dest = ents.FindByName(ent:GetInternalVariable("target"))[1]
						if IsValid(dest) then
							pos = dest:GetPos()
							ang = dest:GetAngles()
							trigger_cache[ent] = {pos, ang}
						end
					end

					self:SetPos(pos)
					self:Set_Pos(pos)
					self:SetAngles(ang)
				end
			end
		end
		return pos, ang
	end
end

