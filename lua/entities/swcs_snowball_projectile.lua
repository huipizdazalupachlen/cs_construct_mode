AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = math.huge
ENT.PrintName = "Snowball"

DEFINE_BASECLASS(ENT.Base)

function ENT:Create(pos, angs, vel, angvel, owner)
	self:SetPos(pos)
	self:SetAngles(angs)

	self:SetVelocity(vel)
	self:SetInitialVelocity(vel)

	if IsValid(owner) then
		self:SetThrower(owner)
		self:SetOwner(owner)
	end

	self:SetDetonateTimerLength(self.m_flTimeToDetonate)

	self:SetLocalAngularVelocity(angvel)
	self:SetFinalAngularVelocity(angvel)
	self:SetActualCollisionGroup(COLLISION_GROUP_PROJECTILE)

	-- we have to reset these here because we set the model late and it resets the collision
	local min = Vector(-SWCS_GRENADE_DEFAULT_SIZE, -SWCS_GRENADE_DEFAULT_SIZE, -SWCS_GRENADE_DEFAULT_SIZE)
	local max = Vector(SWCS_GRENADE_DEFAULT_SIZE, SWCS_GRENADE_DEFAULT_SIZE, SWCS_GRENADE_DEFAULT_SIZE)
	self:SetCollisionBounds(min, max)

	return self
end

function ENT:Initialize()
	self:SetModel("models/weapons/csgo/w_eq_snowball_dropped.mdl")

	BaseClass.Initialize(self)

	if CLIENT then
		self:CreateParticleEffect("weapon_snowball_trail", -1)
	end
end

function ENT:SnowballRadiusBlind(hAttacker, flDamage, iClassIgnore, bitsDamageType)
	local vecSrc = self:Get_Pos()
	vecSrc.z = vecSrc.z + 1 -- in case grenade is lying on the ground

	if not hAttacker:IsValid() then
		hAttacker = self
	end

	local flRadius = 62
	local falloff = flDamage / flRadius

	local flAdjustedDamage = 0
	local flDot = 0
	local vecEyePos = Vector()
	local vecLOS = Vector()
	local vForward = Vector()

	local fadeTime, fadeHold = 0, 0

	local filter = SERVER and RecipientFilter()

	for _, pEntity in ipairs(ents.FindInSphere(vecSrc, flRadius)) do
		if not pEntity:IsPlayer() then continue end

		vecEyePos:Set(pEntity:EyePos())

		local percentageOfFlash = swcs.PercentageOfFlashForPlayer(pEntity, vecSrc, self)
		if percentageOfFlash > 0 then
			flAdjustedDamage = flDamage - vecSrc:Distance(pEntity:EyePos()) * falloff

			if flAdjustedDamage > 0 then
				vForward:Set(pEntity:EyeAngles():Forward())
				vecLOS:Set(vecSrc)
				vecLOS:Sub(vecEyePos)

				-- Normalize both vectors so the dotproduct is in the range -1.0 <= x <= 1.0
				vecLOS:Normalize()

				flDot = vecLOS:Dot(vForward)

				local startingAlpha = 110.0

				-- if target is facing the bomb, the effect lasts longer
				if flDot >= 0.6 then
					-- looking at the bang
					fadeTime = flAdjustedDamage * 0.8
					fadeHold = flAdjustedDamage * 0.1
				elseif flDot >= 0.3 then
					-- looking to the side
					fadeTime = flAdjustedDamage * 0.45
					fadeHold = flAdjustedDamage * 0.1
				elseif flDot <= 0 then
					-- facing away
					fadeTime = flAdjustedDamage * 0.2
					fadeHold = flAdjustedDamage * 0.01
				end

				fadeTime = fadeTime * percentageOfFlash
				fadeHold = fadeHold * percentageOfFlash

				pEntity:SWCS_Blind(fadeHold, fadeTime, startingAlpha)

				if filter then
					filter:AddPlayer(pEntity)
				end
			end
		end
	end

	swcs.SendParticle("snow_hit_player_screeneffect", Vector(), Angle(), nil, nil, nil, filter)
end

local sv_snowball_strength = CreateConVar("swcs_snowball_strength", "12.0", {FCVAR_REPLICATED}, nil, 0)
function ENT:OnBounced(trace, other)
	if other:IsFlagSet(bit.bor(FSOLID_TRIGGER, FSOLID_VOLUME_CONTENTS)) then return end

	if other == self:GetOwner() then return end

	local class = other:GetClass()
	if class == "func_breakable" or class == "func_breakable_surf" or class == "func_ladder" then return end

	if SERVER then
		self:SnowballRadiusBlind(self:GetOwner(), sv_snowball_strength:GetFloat(), CLASS_NONE, DMG_GENERIC)

		local forward = trace.HitNormal
		local ang = forward:Angle()

		local right = ang:Right()
		local up = ang:Up()

		local vCorrectedDir = up

		swcs.SendParticle("weapon_snowball_impact", trace.HitPos, vCorrectedDir:Angle())

		--local flDot = trace.Normal:Dot(trace.HitNormal)
		--local vecReflect = trace.Normal + (trace.HitNormal * (-2.0 * flDot))
		--
		--forward = vecReflect
		--ang = forward:Angle()
		--right = ang:Right()
		--up = ang:Up()
		--
		--debugoverlay.Box(trace.HitPos, -Vector(1,1,1), Vector(1,1,1), 10, Color(255,0,0,16), true)
		--
		--debugoverlay.Line(trace.HitPos, trace.HitPos + (forward * 10), 10, Color(255,0,0), true)
		--debugoverlay.Line(trace.HitPos, trace.HitPos + (right * 10), 10, Color(0,255,0), true)
		--debugoverlay.Line(trace.HitPos, trace.HitPos + (up * 10), 10, Color(0,0,255), true)
	else
		local up, right = Vector(), Vector()
		swcs.VectorVectors(-trace.HitNormal, right, up)

		--local particle = CreateParticleSystemNoEntity("weapon_snowball_impact", trace.HitPos, Angle())
		--particle:SetControlPointOrientation(0, trace.HitNormal, right, up)
		--particle:SetControlPoint(0, trace.HitPos)
		--particle:SetControlPointOrientation(1, -trace.HitNormal, right, up)

		--local particle = CreateParticleSystemNoEntity("snow_hit_player_screeneffect", trace.HitPos, Angle())
		--particle:SetControlPointOrientation(0, up, right, -trace.HitNormal)
		--particle:SetControlPoint(0, trace.HitPos)

		--print("HIT")
	end

	if other:IsValid() and (other:IsNPC() or other:IsPlayer() or other:IsNextBot()) then
		if other:IsPlayer() then
			other:EmitSound("Snowball.HitPlayerFace")
		end
	else
		if SERVER or (CLIENT and IsFirstTimePredicted()) then
			self:EmitSound("Snowball.Impact")
		end

		if SERVER then
			swcs.SendParticle("weapon_snowball_impact_stuck_wall", trace.HitPos, trace.HitNormal:Angle(), false, nil, other:IsWorld() and other)
			swcs.SendParticle("weapon_snowball_impact_splat", trace.HitPos, -trace.HitNormal:Angle(), false, nil, other:IsWorld() and other)
		end
	end

	if SERVER then SafeRemoveEntity(self) end
end

local CONTENTS_GRENADECLIP = 0x80000
local solidmask = bit.band(bit.bor(CONTENTS_GRENADECLIP, MASK_SOLID, MASK_VISIBLE_AND_NPCS), bit.bnot(CONTENTS_DEBRIS))
function ENT:GetSolidMask()
	return solidmask
end

function ENT:GetImpactDamage()
	return 5
end
