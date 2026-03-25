AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = 1.5
ENT.PrintName = "HE Grenade"

DEFINE_BASECLASS(ENT.Base)

local GRENADE_MODEL = "models/weapons/csgo/w_eq_fraggrenade_thrown.mdl"

AccessorFunc(ENT, "m_flDamage", "Damage", FORCE_NUMBER)
AccessorFunc(ENT, "m_DmgRadius", "Range", FORCE_NUMBER)

function ENT:GetBlastForce()
	return vector_origin
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

	self:SetLocalAngularVelocity(angvel)
	self:SetFinalAngularVelocity(angvel)
	self:SetActualCollisionGroup(COLLISION_GROUP_PROJECTILE)

	self:SetDamage(self.ItemAttributes and self.ItemAttributes["damage"] or 99)
	self:SetRange(self.ItemAttributes and self.ItemAttributes["range"] or 350)

	return self
end

function ENT:Initialize()
	self:SetModel(GRENADE_MODEL)

	self:SetDetonateTimerLength(self.m_flTimeToDetonate)

	BaseClass.Initialize(self)
end

function ENT:Detonate()
	local tr = {}
	local vecSpot = self:GetPos() -- trace starts here!
	vecSpot.z = vecSpot.z + 8

	util.TraceLine({
		output = tr,

		start = vecSpot,
		endpos = vecSpot + Vector(0, 0, -32),
		mask = MASK_SHOT_HULL,
		filter = self,
		collisiongroup = COLLISION_GROUP_NONE,
	})

	if tr.StartSolid then
		-- Since we blindly moved the explosion origin vertically, we may have inadvertently moved the explosion into a solid,
		-- in which case nothing is going to be harmed by the grenade's explosion because all subsequent traces will startsolid.
		-- If this is the case, we do the downward trace again from the actual origin of the grenade. (sjb) 3/8/2007  (for ep2_outland_09)
		util.TraceLine({
			output = tr,

			start = self:GetPos(),
			endpos = self:GetPos() + Vector(0, 0, -32),
			mask = MASK_SHOT_HULL,
			filter = self,
			collisiongroup = COLLISION_GROUP_NONE,
		})
	end

	self:Explode(tr, DMG_BLAST)

	-- GetShakeAmplitude() == 25 ?; 0 is falsy
	if SERVER then
		util.ScreenShake(self:GetPos(), 25, 150, 1, 250)
	end

	if SERVER then
		self:EmitSound("HEGrenade.Explode")
	end

	if SERVER then
		SafeRemoveEntity(self)
	end
end

local MAX_WATER_SURFACE_DISTANCE = 512
function ENT:Explode(tr, dmgtype)
	self:AddSolidFlags(FSOLID_NOT_SOLID)
	if SERVER then self:SetSaveValue("m_takedamage", 0) end

	-- Pull out of the wall a bit
	if tr.Fraction ~= 1.0 then
		self:Set_Pos(tr.HitPos + (tr.HitNormal * 0.6))
		self:SetPos(self:Get_Pos())
	end

	local vecReported = self:GetOwner():IsValid() and self:GetOwner():GetPos() or vector_origin

	if SERVER then
		local info = DamageInfo()
		info:SetInflictor(self)
		info:SetAttacker(self:GetOwner():IsValid() and self:GetOwner() or self)
		info:SetDamageForce(self:GetBlastForce())
		info:SetDamagePosition(self:GetPos())
		info:SetDamage(self:GetDamage())
		info:SetDamageType(dmgtype)
		info:SetReportedPosition(vecReported)

		sound.EmitHint(bit.bor(SOUND_COMBAT, SOUND_CONTEXT_EXPLOSION), self:GetPos(), 1024, 3)
		swcs.RadiusDamage(info, self:GetPos(), self:GetRange(), false)
	end

	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		util.Decal("Scorch", tr.StartPos, tr.HitPos - Vector(0, 0, 1), self)

		local vecParticleOrigin = self:GetPos()
		local contents = util.PointContents(vecParticleOrigin)
		local surfacedata = util.GetSurfaceData(tr.SurfaceProps)

		local effectName = self:GetParticleSystemName(contents, surfacedata)
		if bit.band(contents, MASK_WATER) ~= 0 then
			-- Find our water surface by tracing up till we're out of the water
			local tr2 = util.TraceLine({
				start = vecParticleOrigin,
				endpos = vecParticleOrigin + Vector(0, 0, MAX_WATER_SURFACE_DISTANCE),
				mask = MASK_WATER,
			})

			-- if we didn't start in water, we're above it
			if not tr2.StartSolid then
				-- look downward to find the surface
				util.TraceLine({
					start = vecParticleOrigin,
					endpos = vecParticleOrigin - Vector(0, 0, MAX_WATER_SURFACE_DISTANCE),
					mask = MASK_WATER,
					output = tr2,
				})

				-- if we hit it, setup the explosion
				if tr2.Fraction < 1 then
					vecParticleOrigin:Set(tr2.HitPos)
				end
			elseif tr2.FractionLeftSolid > 0 then
				-- otherwise we came out of the water at this point
				vecParticleOrigin.z = vecParticleOrigin.z + (MAX_WATER_SURFACE_DISTANCE * tr2.FractionLeftSolid)
			end
		end

		ParticleEffect(effectName, vecParticleOrigin, Angle())
	end

	self:SetSolid(SOLID_NONE)
	if CLIENT then self:AddEffects(EF_NODRAW) end
	self:SetFinalVelocity(vector_origin)
	self:SetVelocity(vector_origin)
end

function ENT:GetParticleSystemName(pointcontents, surfData)
	if bit.band(pointcontents, MASK_WATER) ~= 0 then
		return "explosion_basic_water"
	end

	if surfData then
		local mat = surfData.material

		if mat == MAT_DIRT or
			mat == MAT_SAND or
			mat == MAT_GRASS or
			--mat == MAT_MUD or
			mat == MAT_FOLIAGE
		then
			return "explosion_hegrenade_dirt"
		elseif mat == MAT_SNOW then
			return "explosion_hegrenade_snow"
		end
	end

	return "explosion_basic"
end

function ENT:BounceSound()
	self:EmitSound("HEGrenade.Bounce")
end

function ENT:AcceptInput(strInput, actor, caller, data)
	if string.lower(strInput) == "settimer" then
		self.m_flTimeToDetonate = tonumber(data)
		self:SetDetonateTimerLength(self.m_flTimeToDetonate)
	end
end
