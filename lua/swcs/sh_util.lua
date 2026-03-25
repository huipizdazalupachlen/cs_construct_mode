AddCSLuaFile()

function swcs.Approach(target, value, speed)
	local delta = target - value

	if (delta > speed) then
		value = value + speed
	elseif (delta < -speed) then
		value = value - speed
	else
		value = target
	end

	return value
end

IN_ATTACK3 = bit.lshift(1, 25)

function swcs.ImpactTrace(tr, iDamageType, ply, trace_filter)
	if not tr.Entity or tr.HitSky then return end
	if tr.HitNoDraw then return end

	local data = EffectData()
	data:SetOrigin(tr.HitPos)
	data:SetStart(tr.StartPos)
	data:SetSurfaceProp(tr.SurfaceProps)
	data:SetDamageType(iDamageType)
	data:SetHitBox(tr.HitBox)
	data:SetEntity(tr.Entity)
	if SERVER then
		data:SetEntIndex(tr.Entity:EntIndex())
	end

	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		swcs.fx.ImpactEffect(data, ply, trace_filter)
	end
end

function swcs.BulletImpact(tr, ply, dmgtype, trace_filter)
	swcs.ImpactTrace(tr, dmgtype, ply, trace_filter)
end

function swcs.RemapClamped(val, a, b, c, d)
	if a == b then
		return (val - b) >= 0 and d or c
	end

	local cVal = (val - a) / (b - a)
	if cVal < 0 then
		cVal = 0
	elseif cVal > 1 then
		cVal = 1
	end
	return c + (d - c) * cVal
end

local lastAmt = -1
local lastExponent = -1
function swcs.Bias(x, biasAmt)
	if lastAmt ~= biasAmt then
		lastExponent = math.log(biasAmt) * -1.4427 -- (-1.4427 = 1 / log(0.5))
	end

	return math.pow(x, lastExponent)
end

function swcs.Gain(x, biasAmt)
	if x < 0.5 then
		return 0.5 * swcs.Bias(2 * x, 1 - biasAmt)
	else
		return 1 - 0.5 * swcs.Bias(2 - 2 * x, 1 - biasAmt)
	end
end

local phys_pushscale = GetConVar("phys_pushscale")

function swcs.CalculateBulletDamageForce(iBulletType, vecBulletDir, flScale)
	local vecForce = Vector(vecBulletDir)

	vecForce:Normalize()
	local force = game.GetAmmoForce(iBulletType)
	if force ~= 0 then vecForce:Mul(force) end
	vecForce:Mul(phys_pushscale:GetFloat())
	vecForce:Mul(flScale or 1)

	return vecForce
end

-- NOTE: not lag compensated by default
--       you must call player:LagCompensation
--       otherwise ur a retard
local weapon_accuracy_shotgun_spread_patterns = GetConVar"weapon_accuracy_shotgun_spread_patterns"
local weapon_debug_max_inaccuracy = CreateConVar("weapon_debug_max_inaccuracy", "0", FCVAR_REPLICATED, "Force all shots to have maximum inaccuracy")
local weapon_debug_inaccuracy_only_up = CreateConVar("weapon_debug_inaccuracy_only_up", "0", FCVAR_REPLICATED, "Force weapon inaccuracy to be in exactly the up direction")

function swcs.filter_IgnoreOwner(ent, filter)
	return function(trEnt)
		if trEnt == ent then return false end
		if trEnt:GetOwner() == ent then return false end

		for i = 1, #filter do
			local v = filter[i]
			if trEnt == v or trEnt:GetClass() == v then
				return false
			end
		end

		return true
	end
end

function swcs.FireBullets(wep, bulletInfo)
	if not (isentity(wep) and wep:IsValid() and wep.IsSWCSWeapon) then return end

	local owner = wep:GetOwner()
	if not owner:IsValid() then return end

	local info_copy = table.Copy(bulletInfo)
	local bRet = hook.Run("EntityFireBullets", owner, info_copy)
	if bRet == true then
		bulletInfo = info_copy
	elseif bRet == false then
		return
	end

	local wepTable = wep:GetTable()

	local filter = {bulletInfo.IgnoreEntity}
	local filterfunc = swcs.filter_IgnoreOwner(owner, filter)
	--if g_CapsuleHitboxes then
	--    filter = g_CapsuleHitboxes:GetEntitiesWithCapsuleHitboxes(owner)
	--end

	-- don't shoot yourself, loser
	--table.insert(filter, owner)

	local bForceMaxInaccuracy = weapon_debug_max_inaccuracy:GetBool()
	local bForceInaccuracyDirection = weapon_debug_inaccuracy_only_up:GetBool()

	local iSeed = wep:GetRandomSeed()
	iSeed = iSeed + 1

	local rand = UniformRandomStream(iSeed) -- init random system with this seed

	local iNumBullets = bulletInfo.Num

	local x1, y1 = {}, {}
	assert(iNumBullets <= 16, "too many bullets in weapon")

	local tr = {}

	local dmg = DamageInfo()
	dmg:SetAttacker(bulletInfo.Attacker)
	dmg:SetInflictor(wep)
	dmg:SetBaseDamage(bulletInfo.Damage)
	dmg:SetReportedPosition(bulletInfo.Src)

	local iAmmoID = game.GetAmmoID(bulletInfo.AmmoType)
	dmg:SetAmmoType(iAmmoID)

	if wep:GetClass() == "weapon_swcs_taser" then
		dmg:SetDamageType(bit.bor(DMG_SHOCK, DMG_NEVERGIB))
	else
		dmg:SetDamageType(DMG_BULLET)
	end

	if iNumBullets > 0 then
		local ang = bulletInfo.Dir:Angle()
		local vecRight, vecUp = ang:Right(), ang:Up()

		local bShotgunSpreadPatterns = weapon_accuracy_shotgun_spread_patterns:GetBool()

		local fInaccuracy = wepTable.GetInaccuracy(wep, false)
		local flRecoilIndex = wepTable.GetRecoilIndex(wep)
		local iWeaponMode = wepTable.GetWeaponMode(wep)

		local fnCallback = bulletInfo.Callback

		-- calculate random spread for every bullet
		local flSpreadCurveDensity, x0, y0 = 0, 0, 0

		local arrPendingDamage = {}

		for iBullet = 1, iNumBullets do
			local fTheta1 = 0

			if iBullet == 1 then
				-- Accuracy curve density adjustment FOR R8 REVOLVER SECONDARY FIRE, NEGEV WILD BEAST
				local flRadiusCurveDensity = rand:RandomFloat()
				if wepTable.IsR8Revolver and iWeaponMode == Secondary_Mode then -- R8 REVOLVER SECONDARY FIRE
					flRadiusCurveDensity = 1 - (flRadiusCurveDensity * flRadiusCurveDensity)
				elseif wepTable.IsNegev and flRecoilIndex < 3 then -- NEGEV WILD BEAST
					for j = 3, flRecoilIndex, -1 do
						flRadiusCurveDensity = flRadiusCurveDensity * flRadiusCurveDensity
					end

					flRadiusCurveDensity = 1 - flRadiusCurveDensity
				end

				if bForceMaxInaccuracy then
					flRadiusCurveDensity = 1
				end

				-- Get accuracy displacement
				local fTheta0 = rand:RandomFloat(0, 2 * math.pi)
				if bForceInaccuracyDirection then
					fTheta0 = math.pi * 0.5
				end

				local fRadius0 = flRadiusCurveDensity * fInaccuracy
				x0 = fRadius0 * math.cos(fTheta0)
				y0 = fRadius0 * math.sin(fTheta0)
			end

			if bShotgunSpreadPatterns then
				--print("i", iNumBullets, math.floor(iBullet + (iNumBullets * flRecoilIndex) - 1))
				fTheta1, flSpreadCurveDensity = wepTable.GetSpreadOffset(wep, rand, math.floor(iBullet + (iNumBullets * flRecoilIndex) - 1))
			else
				flSpreadCurveDensity = rand:RandomFloat()
				fTheta1 = rand:RandomFloat(0, 2 * math.pi)

				--print("SPREAD", rand, flSpreadCurveDensity, fTheta1, iBullet)
			end

			if wepTable:GetIsRevolver() and iWeaponMode == Secondary_Mode then
				flSpreadCurveDensity = 1 - (flSpreadCurveDensity * flSpreadCurveDensity)
			elseif wepTable.IsNegev and flRecoilIndex < 3 then
				for j = 3, flRecoilIndex, -1 do
					flSpreadCurveDensity = flSpreadCurveDensity * flSpreadCurveDensity
				end

				flSpreadCurveDensity = 1 - flSpreadCurveDensity
			end

			local fRadius1 = flSpreadCurveDensity * wepTable.GetSpread(wep)
			x1[iBullet] = x0 + fRadius1 * math.cos(fTheta1)
			y1[iBullet] = y0 + fRadius1 * math.sin(fTheta1)

			local bulletDir = bulletInfo.Dir + (x1[iBullet] * vecRight) + (y1[iBullet] * vecUp)
			local vEndPos = bulletInfo.Src + (bulletDir * bulletInfo.Distance)

			util.TraceLine({
				start = bulletInfo.Src,
				endpos = vEndPos,
				mask = CS_MASK_SHOOT,
				filter = filterfunc,
				output = tr,
			})

			if tr.Entity == NULL then
				tr.Entity = game.GetWorld()
			end

			wepTable.DoTracer(wep, wepTable.ItemVisuals.tracer_effect, tr.StartPos, tr.HitPos, bulletInfo.Tracer)

			local fDamage = bulletInfo.Damage * math.pow(wepTable:GetRangeModifier(), tr.StartPos:Distance(tr.HitPos) / 500)

			dmg:SetDamageBonus(fDamage)
			dmg:SetDamage(fDamage)

			dmg:SetDamagePosition(tr.HitPos)
			dmg:SetDamageForce(swcs.CalculateBulletDamageForce(iAmmoID, tr.Normal))

			if wepTable.PostHitCallback then
				wepTable.PostHitCallback(wep, tr.Entity, table.Copy(tr))
			end

			bRet = hook.Run("PostEntityFireBullets", owner, {
				AmmoType = bulletInfo.AmmoType,
				Attacker = bulletInfo.Attacker,
				Damage = fDamage,
				Force = 1,
				TracerName = bulletInfo.TracerName or "",
				Tracer = bulletInfo.Tracer or 1,
				Trace = table.Copy(tr),
			})

			-- suppress bullet if PostEntityFireBullets returns false
			if bRet == false then continue end

			if isfunction(fnCallback) then
				bRet = fnCallback(owner, table.Copy(tr), dmg)
			end

			local bDoEffects, bDoDamage = true, true

			if istable(bRet) then
				bDoEffects = bRet.effects ~= nil and bRet.effects == true
				bDoDamage = bRet.damage ~= nil and bRet.damage == true
			end

			if bDoEffects then
				swcs.BulletImpact(tr, owner, dmg:GetDamageType(), filterfunc)
			end

			if bDoDamage then
				if tr.Entity:IsValid() or tr.Entity:IsWorld() then
					table.insert(arrPendingDamage, {
						ent = tr.Entity,
						dmg = fDamage,
						trace = tr,
						mainTrace = true,
					})
				end

				-- WALL PENETRATION!!!
				wepTable.PerformBulletPenetration(wep, owner, tr, dmg, filter, arrPendingDamage)
			end
		end

		if #arrPendingDamage > 0 then
			local arrAlreadyHit = { --[[ [tr.Entity] = true]] }
			for _, t in ipairs(arrPendingDamage) do
				local hitEnt = t.ent

				-- we can hit world multiple times in one attack.
				-- and if we don't DispatchTraceAttack() every hit on world, then sometimes you can penetrate a material
				-- that a broken pane of glass is in front of, and the glass will not break.
				if (arrAlreadyHit[hitEnt] and not t.mainTrace) and not hitEnt:IsWorld() then continue end

				dmg:SetDamage(t.dmg)
				dmg:SetDamagePosition(t.trace.HitPos)
				dmg:SetReportedPosition(t.trace.StartPos)

				if not hitEnt:IsPlayer() or hook.Run("PlayerTraceAttack", hitEnt, dmg, t.trace.Normal, t.trace) ~= true then
					if hitEnt:IsPlayer() then
						if SERVER then hitEnt:SetLastHitGroup(t.trace.HitGroup) end
						--    if hook.Run("ScalePlayerDamage", hitEnt, t.trace.HitGroup, dmg) == true then return end
						--elseif hitEnt:IsNPC() or hitEnt:IsNextBot() then
						--    hook.Run("ScaleNPCDamage", hitEnt, t.trace.HitGroup, dmg)
					end

					-- disable player pushback on bullet damage
					-- what the fuck
					if hitEnt:IsPlayer() then
						owner:AddSolidFlags(FSOLID_TRIGGER)
					end

					hook.Run("SWCSBulletTraceDamage", t, dmg)

					swcs.fx.TraceAttack(hitEnt, dmg, t.trace.Normal, t.trace)
					hitEnt:DispatchTraceAttack(dmg, t.trace)

					if hitEnt:IsPlayer() then
						owner:RemoveSolidFlags(FSOLID_TRIGGER)
					end

					if wep.PostHitCallback then
						wep:PostHitCallback(hitEnt, t.trace)
					end
				end

				arrAlreadyHit[hitEnt] = true
			end
		end
	end
end

function swcs.IsBreakableEntity(ent)
	if not IsValid(ent) then return false end

	-- first check to see if it's already broken
	if ent:Health() < 0 and ent:GetMaxHealth() > 0 then
		return true
	end

	-- If we won't be able to break it, don't try
	if SERVER then
		local var = ent:GetInternalVariable("m_takedamage")
		if tonumber(var) and tonumber(var) ~= 2 then
			return false
		end
	end

	if ent:GetCollisionGroup() ~= COLLISION_GROUP_PUSHAWAY and ent:GetCollisionGroup() ~= COLLISION_GROUP_BREAKABLE_GLASS and ent:GetCollisionGroup() ~= COLLISION_GROUP_NONE then
		return false
	end

	local iHealth = ent:Health()
	if iHealth > 200 then
		return false
	end

	if ent:GetClass() == "func_breakable" or ent:GetClass() == "func_breakable_surf" then
		return true
	end

	return iHealth > 0
end

local IsGunWeapon = {
	["pistol"] = true,
	["submachinegun"] = true,
	["rifle"] = true,
	["shotgun"] = true,
	["sniperrifle"] = true,
	["machinegun"] = true,
}
function swcs.IsGunWeapon(wep_type)
	return IsGunWeapon[wep_type] == true
end

--============================================================================================================
-- Utility functions for physics damage force calculation
--============================================================================================================
-------------------------------------------------------------------------------
-- Purpose: Returns an impulse scale required to push an object.
-- Input  : flTargetMass - Mass of the target object, in kg
--			flDesiredSpeed - Desired speed of the target, in inches/sec.
-------------------------------------------------------------------------------
function swcs.ImpulseScale(flTargetMass, flDesiredSpeed)
	return flTargetMass * flDesiredSpeed
end

-------------------------------------------------------------------------------
-- Purpose: Fill out a takedamageinfo with a damage force for an explosive
-------------------------------------------------------------------------------
function swcs.CalculateExplosiveDamageForce(info, vecDir, vecForceOrigin, flScale)
	info:SetDamagePosition(vecForceOrigin)

	local flClampForce = swcs.ImpulseScale(75, 400)

	-- Calculate an impulse large enough to push a 75kg man 4 in/sec per point of damage
	local flForceScale = info:GetBaseDamage() * swcs.ImpulseScale(75, 4)

	if flForceScale > flClampForce then
		flForceScale = flClampForce
	end

	-- Fudge blast forces a little bit, so that each
	-- victim gets a slightly different trajectory.
	-- This simulates features that usually vary from
	-- person-to-person variables such as bodyweight,
	-- which are all indentical for characters using the same model.
	flForceScale = flForceScale * g_ursRandom:RandomFloat(0.85, 1.15)

	-- Calculate the vector and stuff it into the takedamageinfo
	local vecForce = vecDir
	vecForce:Normalize()
	vecForce:Mul(flForceScale)
	vecForce:Mul(phys_pushscale:GetFloat())
	vecForce:Mul(flScale)
	info:SetDamageForce(vecForce)
end

function swcs.RadiusDamage(info, vecSrcIn, flRadius, bIgnoreWorld)
	local tr = {}
	local falloff, damagePercentage
	local vecSpot, vecToTarget, vecEndPos = Vector(), Vector(), Vector()

	local vecSrc = Vector(vecSrcIn)

	damagePercentage = 1.0

	if flRadius > 0 then
		falloff = info:GetDamage() / flRadius
	else
		falloff = 1.0
	end

	local flInitialDamage = info:GetDamage()

	vecSrc.z = vecSrc.z + 1 -- in case grenade is lying on the ground

	-- Let the world know if this was an explosion.
	if info:IsDamageType(DMG_BLAST) then
		-- Even the tiniest explosion gets attention. Don't let the radius
		-- be less than 128 units.
		local soundRadius = math.max(128.0, flRadius * 1.5)
		sound.EmitHint(bit.bor(SOUND_COMBAT, SOUND_CONTEXT_EXPLOSION), vecSrc, soundRadius, 0.25)
	end

	-- iterate on all entities in the vicinity
	for _, pEntity in ipairs(ents.FindInSphere(vecSrc, flRadius)) do
		-- we have to save whether or not the player is killed so we don't give credit
		-- for pre-dead players.

		if pEntity:GetInternalVariable("m_takedamage") == 0 or (pEntity:IsPlayer() and not pEntity:Alive()) then
			continue
		end

		vecSpot:Set(pEntity:WorldSpaceCenter())

		local bHit = false

		if bIgnoreWorld then
			vecEndPos:Set(vecSpot)
			bHit = true
		else
			-- get the percentage of the target entity that is visible from the
			-- explosion position.
			damagePercentage = swcs.GetAmountOfEntityVisible(vecSrc, pEntity)
			if damagePercentage > 0.0 then
				vecEndPos = vecSpot
				bHit = true
			end
		end

		if bHit then
			if pEntity:GetClass() == "swcs_breachcharge_projectile" then
				pEntity:SignalDetonate(0)
				continue
			end

			-- the explosion can 'see' this entity, so hurt them!
			vecToTarget:Set(vecEndPos)
			vecToTarget:Sub(vecSrc)

			-- use a Gaussian function to describe the damage falloff over distance, with flRadius equal to 3 * sigma
			-- this results in the following values:
			--
			-- Range Fraction  Damage
			--		0.0			100%
			-- 		0.1			96%
			-- 		0.2			84%
			-- 		0.3			67%
			-- 		0.4			49%
			-- 		0.5			32%
			-- 		0.6			20%
			-- 		0.7			11%
			-- 		0.8			 6%
			-- 		0.9			 3%
			-- 		1.0			 1%

			local fDist = vecToTarget:Length()
			local fSigma = flRadius / 3.0 -- flRadius specifies 3rd standard deviation (0.0111 damage at this range)
			local fGaussianFalloff = math.exp(-fDist * fDist / (2.0 * fSigma * fSigma))
			local flAdjustedDamage = flInitialDamage * fGaussianFalloff * damagePercentage

			if (flAdjustedDamage > 0) then
				info:SetDamage(flAdjustedDamage)

				vecToTarget:Normalize()

				-- If we don't have a damage force, manufacture one
				if info:GetDamagePosition():IsZero() or info:GetDamageForce():IsZero() then
					swcs.CalculateExplosiveDamageForce(info, vecToTarget, vecSrc, 1.5 --[[ explosion scale! ]])
				else
					-- Assume the force passed in is the maximum force. Decay it based on falloff.
					local flForce = info:GetDamageForce():Length() * falloff
					info:SetDamageForce(vecToTarget * flForce)
					info:SetDamagePosition(vecSrc)
				end

				util.TraceLine({
					start = vecSrc,
					endpos = pEntity:WorldSpaceCenter(),
					mask = MASK_SHOT,
					filter = info:GetInflictor(),
					collisiongroup = COLLISION_GROUP_NONE,
					output = tr,
				})

				-- blasts always hit chest
				tr.HitGroup = HITGROUP_GENERIC
				if pEntity:IsPlayer() then
					pEntity:SetLastHitGroup(HITGROUP_GENERIC)
				end

				if (tr.Fraction ~= 1.0) then
					-- this has to be done to make breakable glass work.
					--ClearMultiDamage( )
					swcs.fx.TraceAttack(pEntity, info, vecToTarget, tr)
					pEntity:DispatchTraceAttack(info, tr, vecToTarget)
					--ApplyMultiDamage()
				else
					pEntity:TakeDamageInfo(info)
				end

				--print("trigger meme")

				-- Now hit all triggers along the way that respond to damage...
				--pEntity:TraceAttackToTriggers( info, vecSrc, vecEndPos, vecToTarget )
			end
		end
	end
end

local DENSITY_ABSORB_ALL_DAMAGE = 3000.0

-- return a multiplier that should adjust the damage done by a blast at position vecSrc to something at the position
-- vecEnd.  This will take into account the density of an entity that blocks the line of sight from one position to
-- the other.
--
-- this algorithm was taken from the HL2 version of RadiusDamage.
local tr = {}
function swcs.GetExplosionDamageAdjustment(vecSrc, vecEnd, pEntityToIgnore)
	local retval = 0.0

	util.TraceLine({
		start = vecSrc,
		endpos = vecEnd,
		mask = MASK_SHOT,
		filter = pEntityToIgnore,
		collisiongroup = COLLISION_GROUP_NONE,
		output = tr,
	})

	if tr.Fraction == 1.0 then
		retval = 1.0
	elseif not tr.HitWorld and tr.Entity:IsValid() and tr.Entity ~= pEntityToIgnore and tr.Entity:GetOwner() ~= pEntityToIgnore then
		-- if we didn't hit world geometry perhaps there's still damage to be done here.

		local blockingEntity, iSurfaceProps = tr.Entity, 0
		if blockingEntity:IsValid() then
			iSurfaceProps = tr.SurfaceProps
		end

		-- check to see if this part of the player is visible if entities are ignored.
		util.TraceLine({
			start = vecSrc,
			endpos = vecEnd,
			mask = CONTENTS_SOLID,
			filter = NULL,
			collisiongroup = COLLISION_GROUP_NONE,
			output = tr,
		})

		if tr.Fraction == 1.0 then
			if blockingEntity:IsValid() and blockingEntity:GetPhysicsObject():IsValid() and not blockingEntity.IsSWCSGrenade then
				local flDensity

				local surf_data = iSurfaceProps > 0 and util.GetSurfaceData(iSurfaceProps)
				if surf_data then
					flDensity = surf_data.density
				else
					-- iSurfaceProps was likely -1. use safe default of non-penetration.
					flDensity = DENSITY_ABSORB_ALL_DAMAGE
				end

				local scale = flDensity / DENSITY_ABSORB_ALL_DAMAGE
				if ((scale >= 0.0) and (scale < 1.0)) then
					retval = 1.0 - scale
				elseif scale < 0.0 then
					-- should never happen, but just in case.
					retval = 1.0
				end
			else
				retval = 0.75 -- we're blocked by something that isn't an entity with a physics model or world geometry, just cut damage in half for now.
			end
		end
	end

	return retval
end

local damagePercentageChest = 0.40
local damagePercentageHead = 0.20
local damagePercentageFeet = 0.20
local damagePercentageRightSide = 0.10
local damagePercentageLeftSide = 0.10

local HalfHumanWidth = 16
local HumanHeight = 71

-- returns the percentage of the player that is visible from the given point in the world.
-- return value is between 0 and 1.
local GetExplosionDamageAdjustment = swcs.GetExplosionDamageAdjustment
function swcs.GetAmountOfEntityVisible(vecSrc, entity)
	local retval = 0.0

	if not entity:IsPlayer() then
		-- the entity is not a player, so the damage is all or nothing.
		return GetExplosionDamageAdjustment(vecSrc, entity:WorldSpaceCenter(), entity)
	end

	local ply = entity

	-- check what parts of the player we can see from this point and modify the return value accordingly.
	local chestHeightFromFeet

	local armDistanceFromChest = HalfHumanWidth

	-- calculate positions of various points on the target player's body
	local vecFeet = ply:GetPos()

	local vecChest = ply:WorldSpaceCenter()
	chestHeightFromFeet = vecChest.z - vecFeet.z -- compute the distance from the chest to the feet. (this accounts for ducking and the like)

	local vecHead = ply:GetPos()
	vecHead.z = vecHead.z + HumanHeight

	local vecRightFacing = ply:GetAngles():Right()
	vecRightFacing:Normalize()
	vecRightFacing:Mul(armDistanceFromChest)

	local vecLeftSide = vecFeet
	vecLeftSide.x = vecLeftSide.x - vecRightFacing.x
	vecLeftSide.y = vecLeftSide.y - vecRightFacing.y
	vecLeftSide.z = vecLeftSide.z + chestHeightFromFeet

	local vecRightSide = vecFeet
	vecRightSide.x = vecRightSide.x + vecRightFacing.x
	vecRightSide.y = vecRightSide.y + vecRightFacing.y
	vecRightSide.z = vecRightSide.z + chestHeightFromFeet

	-- check chest
	local damageAdjustment = GetExplosionDamageAdjustment(vecSrc, vecChest, entity)
	retval = retval + (damagePercentageChest * damageAdjustment)

	-- check top of head
	damageAdjustment = GetExplosionDamageAdjustment(vecSrc, vecHead, entity)
	retval = retval + (damagePercentageHead * damageAdjustment)

	-- check feet
	damageAdjustment = GetExplosionDamageAdjustment(vecSrc, vecFeet, entity)
	retval = retval + (damagePercentageFeet * damageAdjustment)

	-- check left "edge"
	damageAdjustment = GetExplosionDamageAdjustment(vecSrc, vecLeftSide, entity)
	retval = retval + (damagePercentageLeftSide * damageAdjustment)

	-- check right "edge"
	damageAdjustment = GetExplosionDamageAdjustment(vecSrc, vecRightSide, entity)
	retval = retval + (damagePercentageRightSide * damageAdjustment)

	return retval
end

local ENTITY = FindMetaTable("Entity")
---@diagnostic disable: need-check-nil
function ENTITY:SWCS_Alive()
	if self:IsPlayer() then
		return self:Alive()
	end

	local life_state = self:GetInternalVariable("m_lifestate")
	if life_state and life_state == 0 then
		if self:GetMaxHealth() <= 0 then
			return false
		end

		return true
	end

	return false
end

function ENTITY:SetWaterLevel(nLevel)
	assert(isnumber(nLevel))
	self:SetSaveValue("m_nWaterLevel", nLevel)
end
---@diagnostic enable: need-check-nil

function swcs.FormatViewModelAttachment(vOrigin, bFrom --[[= false]])
	local vEyePos = Vector()
	local aEyesRot = Angle()
	local flViewFOV = 0
	local flViewModelFOV = 0

	if CLIENT then
		local viewSetup = render.GetViewSetup()
		flViewFOV = viewSetup.fov_unscaled
		flViewModelFOV = viewSetup.fovviewmodel_unscaled
		vEyePos:Set(viewSetup.origin)
		aEyesRot:Set(viewSetup.angles)
	elseif game.SinglePlayer() then
		local ply = Entity(1)

		vEyePos:Set(ply:EyePos())
		aEyesRot:Set(ply:EyeAngles())

		flViewFOV = ply:GetFOV()
		flViewModelFOV = ply:GetActiveWeapon().ViewModelFOV
	end

	local vOffset = vOrigin - vEyePos
	local vForward = aEyesRot:Forward()

	local nViewX = math.tan(flViewModelFOV * math.pi / 360)

	if (nViewX == 0) then
		vForward:Mul(vForward:Dot(vOffset))
		vEyePos:Add(vForward)

		return vEyePos
	end

	local nWorldX = math.tan(flViewFOV * math.pi / 360)

	if (nWorldX == 0) then
		vForward:Mul(vForward:Dot(vOffset))
		vEyePos:Add(vForward)

		return vEyePos
	end

	local vRight = aEyesRot:Right()
	local vUp = aEyesRot:Up()

	local nFactor = bFrom and (nWorldX / nViewX) or (nViewX / nWorldX)

	vRight:Mul(vRight:Dot(vOffset) * nFactor)
	vUp:Mul(vUp:Dot(vOffset) * nFactor)
	vForward:Mul(vForward:Dot(vOffset))

	vEyePos:Add(vRight)
	vEyePos:Add(vUp)
	vEyePos:Add(vForward)

	vForward:Normalize()
	vRight:Normalize()
	vUp:Normalize()

	return vEyePos, vForward, vRight, vUp
end

function swcs.ScaleFOVByAspectRatio(fovDegrees, ratio)
	local halfAngleRadians = fovDegrees * (0.5 * math.pi / 180.0)
	local halfTanScaled = math.tan(halfAngleRadians) * ratio
	return (180.0 / math.pi) * math.atan(halfTanScaled) * 2.0
end

-- returns a directional vector for a position on screen, corrects for mismatched fov
function swcs.ScreenToWorld(x, y)
	local view = render.GetViewSetup()
	local w, h = view.width, view.height
	local fov = view.fov_unscaled

	fov = swcs.ScaleFOVByAspectRatio(fov, (w / h) / (4 / 3))

	return util.AimVector(view.angles, fov, x, y, w, h)
end

-- transform in1 by the matrix in2
function swcs.VectorTransform(in1, in2, out)
	local in2Column0 = Vector(in2:GetField(1, 1), in2:GetField(1, 2), in2:GetField(1, 3))
	local in2Column1 = Vector(in2:GetField(2, 1), in2:GetField(2, 2), in2:GetField(2, 3))
	local in2Column2 = Vector(in2:GetField(3, 1), in2:GetField(3, 2), in2:GetField(3, 3))

	local x = in1:Dot(in2Column0) + in2:GetField(1, 4)
	local y = in1:Dot(in2Column1) + in2:GetField(2, 4)
	local z = in1:Dot(in2Column2) + in2:GetField(3, 4)

	if not out then
		return Vector(x, y, z)
	else
		out:SetUnpacked(x, y, z)
	end
end

-- August 16 to 23
-- CS birthday
function swcs.IsParty()
	--do return true end

	local t = os.date("!*t")

	return t.month == 8 and t.day >= 16 and t.day <= 23
end

-- October 1 to November 1
function swcs.IsHalloween()
	--do return true end

	local t = os.date("!*t")

	return (t.month == 10 and t.day >= 6) or (t.month == 11 and t.day <= 1)
end

-- December 1 to January 1
function swcs.IsChristmas()
	--do return true end

	local t = os.date("!*t")

	return (t.month == 12 and t.day >= 1) or (t.month == 1 and t.day <= 1)
end

local TICK_INTERVAL = engine.TickInterval()
local function TICK_TO_TIME(t)
	return t * TICK_INTERVAL
end

local floor = math.floor
local function TIME_TO_TICK(t)
	return floor(t / TICK_INTERVAL)
end

local swcs_experm_interp = CLIENT and CreateConVar("swcs_experm_interp", "0", {FCVAR_ARCHIVE}, "enable experimental interpolation for the weapon pack's networked variables", 0, 1)
function swcs.DefineInterpolatedVar(tab, keyName, getSetterName, defaultValue, bIsDTVar)
	local strGetUninterpolated = "GetUninterpolated" .. getSetterName
	local strSetUninterpolated = "SetUninterpolated" .. getSetterName
	local strGetLast = "GetLast" .. getSetterName
	local strSetLast = "SetLast" .. getSetterName
	local strSet = "Set" .. getSetterName
	local strGet = "Get" .. getSetterName

	-- handle DefineInterpolatedVar(tab, keyName, getSetterName, bIsDTVar)
	if bIsDTVar == nil then
		bIsDTVar = defaultValue
		defaultValue = nil
	end

	-- Get/Set Last val
	tab[strGetLast] = function(self)
		return self[keyName .. "Last"]
	end
	tab[strSetLast] = function(self, value)
		self[keyName .. "Last"] = value
	end

	-- Get/Set Uninterpolated val
	if bIsDTVar == true then
		tab[strGetUninterpolated] = tab[strGet]
		tab[strSetUninterpolated] = tab[strSet]
	else
		tab[strGetUninterpolated] = function(self)
			return self[keyName .. "Uninterpolated"]
		end
		tab[strSetUninterpolated] = function(self, value)
			self[keyName .. "Uninterpolated"] = value
		end
		tab[keyName .. "Last"] = defaultValue or tab[keyName]
		tab[keyName .. "Uninterpolated"] = defaultValue or tab[keyName]
	end

	local bIsSingleplayer = game.SinglePlayer()

	tab[strGet] = function(self, bInterpolated)
		if (bInterpolated == false or bIsSingleplayer or SERVER) or (swcs_experm_interp and not swcs_experm_interp:GetBool()) then
			return self[strGetUninterpolated](self)
		end

		local flTimeNow = CurTime()
		local flClientTick = TICK_TO_TIME(TIME_TO_TICK(flTimeNow) + 1)
		local flBetweenTickPercentage = (flClientTick - flTimeNow) / TICK_INTERVAL

		local prevVal = self[strGetLast](self)
		local uninterpVal = self[strGetUninterpolated](self)

		local prevLerp = (prevVal * flBetweenTickPercentage)
		local uninterpLerp = (uninterpVal * (1.0 - flBetweenTickPercentage))

		local fullLerp = prevLerp + uninterpLerp

		return fullLerp
	end
	tab[strSet] = function(self, value)
		if CLIENT and IsFirstTimePredicted() then
			self[strSetLast](self, self[strGetUninterpolated](self))
		end

		self[strSetUninterpolated](self, value)
	end
end

local host_timescale = GetConVar"host_timescale"
function swcs.FrameTime()
	if CLIENT then
		local bPaused = FrameTime() == 0

		if bPaused then
			return 0
		end

		local flTimeScale = host_timescale:GetFloat()

		return RealFrameTime() * flTimeScale
	else
		return FrameTime()
	end
end

function swcs.IsArmored(ent, nHitgroup)
	if not ent:IsPlayer() then return false end

	local bApplyArmor = false

	if ent:Armor() > 0 then
		if nHitgroup == HITGROUP_GENERIC or
			nHitgroup == HITGROUP_CHEST or
			nHitgroup == HITGROUP_STOMACH or
			nHitgroup == HITGROUP_LEFTARM or
			nHitgroup == HITGROUP_RIGHTARM
		then
			bApplyArmor = true
		elseif nHitgroup == HITGROUP_HEAD then
			if ent:HasHelmet() then
				bApplyArmor = true
			end
		end
	end

	return bApplyArmor
end

function swcs.AngleToScreenPixel(angInput)
	-- use camera angles as base
	local CameraAngle = EyeAngles()

	-- add in input to base
	CameraAngle:Add(angInput)
	CameraAngle:Normalize()

	-- get that bitch way out there
	local temp = CameraAngle:Forward()
	temp:Mul(0x7fff)

	-- add camera pos to make it relative to camera
	temp:Add(EyePos())

	local s = temp:ToScreen()

	-- returns absolute screen coordinates
	return math.Round(s.x), math.Round(s.y)
end

do
	local function MACRO__SetupItemDefGetter(tab, name, attribute, force_type, scale, default)
		local fnName = "Get" .. name
		scale = scale or 1
		default = default or 0

		local ItemAttributes = tab.ItemAttributes

		if force_type == FORCE_BOOL then
			tab[fnName] = function(self)
				local val = (ItemAttributes and ItemAttributes[attribute]) or default

				local num = tonumber(val)
				if num then
					return num >= 1
				end

				return tobool(val)
			end
		elseif force_type == FORCE_STRING then
			tab[fnName] = function(self)
				return tostring(ItemAttributes and ItemAttributes[attribute] or default)
			end
		else -- assume number
			tab[fnName] = function(self)
				if isnumber(default) then
					return (ItemAttributes and ItemAttributes[attribute] or default) * scale
				end

				return ItemAttributes and ItemAttributes[attribute] or default
			end
		end
	end
	local function MACRO__SetupItemDefGetterHasAlt(tab, name, attribute, force_type, scale, default)
		local fnName = "Get" .. name

		MACRO__SetupItemDefGetter(tab, name .. "1", attribute, force_type, scale, default)
		MACRO__SetupItemDefGetter(tab, name .. "2", attribute .. " alt", force_type, scale, default)

		tab[fnName] = function(self, weaponMode)
			local selfTable = self:GetTable()
			weaponMode = weaponMode == nil and selfTable.GetWeaponMode(self) or weaponMode

			if weaponMode == Primary_Mode then
				return selfTable["Get" .. name .. "1"](self)
			else
				return selfTable["Get" .. name .. "2"](self)
			end
		end
	end

	swcs.SetupItemDefGetter = MACRO__SetupItemDefGetter
	swcs.SetupItemDefGetterHasAlt = MACRO__SetupItemDefGetterHasAlt

	local USE_HL2_AMMO = CreateConVar("swcs_hl2_ammo", "0", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Whether or not weapons use Half-Life 2 ammo types", 0, 1)
	swcs.TypeToHL2Ammo = {
		Rifle = "AR2",
		SniperRifle = "XBowBolt", -- dont think about it too hard
		SubMachinegun = "SMG1",
		Pistol = "Pistol",
		Machinegun = "AR2",
		Shotgun = "Buckshot",
		Grenade = "Grenade",
		["Breach Charge"] = "slam",
	}

	swcs.RegisteredItems = swcs.RegisteredItems or {}

	function swcs.RegisterItem(ItemDefAttributes, ItemDefVisuals, ItemDefPrefab, SWEP, class)
		-- not loading a weapon
		if not SWEP then return end

		if not ItemDefAttributes and SWEP.Base then
			local BaseTable = weapons.GetStored(SWEP.Base)
			if BaseTable and BaseTable.ItemDefAttributes then
				ItemDefAttributes = BaseTable.ItemDefAttributes
				SWEP.ItemDefAttributes = ItemDefAttributes
			end
		end

		-- fix for level transition breaking itemdef data
		--local BaseTable = weapons.GetStored(SWEP.ClassName)
		--if BaseTable and BaseTable.ItemDefAttributes and BaseTable.ItemDefAttributes ~= SWEP.ItemDefAttributes then
		--    SWEP.ItemDefAttributes = BaseTable.ItemDefAttributes
		--end

		--if bSetSchemaData then
		local attributes
		if ItemDefAttributes then
			attributes = util.KeyValuesToTable(ItemDefAttributes, true, false)
			SWEP.ItemAttributes = attributes
		end

		local visuals
		if ItemDefVisuals then
			visuals = util.KeyValuesToTable(ItemDefVisuals, true, false)
			SWEP.ItemVisuals = visuals
		end

		local prefab
		if ItemDefPrefab then
			prefab = util.KeyValuesToTable(ItemDefPrefab, true, false)
			SWEP.ItemPrefab = prefab
		end
		--end

		-- sniper overlay customization
		if CLIENT and attributes then
			local strOverlay = attributes["scope overlay"]
			local strArc = attributes["scope arc"]

			if isstring(strOverlay) then
				if string.Trim(strOverlay) == "" then
					strOverlay = "null"
				end
				SWEP.m_matDust = Material(strOverlay)
			end

			if isstring(strArc) then
				if string.Trim(strArc) == "" then
					strArc = "null"
				end
				SWEP.m_matArc = Material(strArc)
			end
		end

		MACRO__SetupItemDefGetter(SWEP, "DefCycleTime", "cycletime")
		MACRO__SetupItemDefGetterHasAlt(SWEP, "MaxSpeed", "max player speed", nil, nil, 250)
		MACRO__SetupItemDefGetter(SWEP, "Damage", "damage")
		MACRO__SetupItemDefGetter(SWEP, "AttributeRange", "range")
		MACRO__SetupItemDefGetter(SWEP, "ClipSize", "primary clip size", nil, nil, -1)
		MACRO__SetupItemDefGetter(SWEP, "DefaultClipSize", "primary default clip size", nil, nil, -1)
		MACRO__SetupItemDefGetter(SWEP, "Penetration", "penetration")
		MACRO__SetupItemDefGetter(SWEP, "RangeModifier", "range modifier", nil, nil, 0.980000)
		MACRO__SetupItemDefGetter(SWEP, "Bullets", "bullets", nil, nil, 1)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "TracerFrequency", "tracer frequency")

		MACRO__SetupItemDefGetter(SWEP, "AttackMovespeedFactor", "attack movespeed factor", nil, nil, 1)

		MACRO__SetupItemDefGetterHasAlt(SWEP, "RecoilMagnitude", "recoil magnitude")

		MACRO__SetupItemDefGetter(SWEP, "SpreadSeed", "spread seed", nil, nil, 0)

		MACRO__SetupItemDefGetter(SWEP, "InaccuracyAltSwitch", "inaccuracy alt switch")
		MACRO__SetupItemDefGetterHasAlt(SWEP, "Spread", "spread", nil, 0.001)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "InaccuracyMove", "inaccuracy move", nil, 0.001)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "InaccuracyLadder", "inaccuracy ladder", nil, 0.001)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "InaccuracyFire", "inaccuracy fire", nil, 0.001)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "InaccuracyReload", "inaccuracy reload", nil, 0.001)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "InaccuracyCrouch", "inaccuracy crouch", nil, 0.001)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "InaccuracyStand", "inaccuracy stand", nil, 0.001)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "InaccuracyLand", "inaccuracy land", nil, 0.001)
		MACRO__SetupItemDefGetterHasAlt(SWEP, "InaccuracyJump", "inaccuracy jump", nil, 0.001)
		MACRO__SetupItemDefGetter(SWEP, "InaccuracyJumpApex", "inaccuracy jump apex", nil, 0.001, 0)
		MACRO__SetupItemDefGetter(SWEP, "InaccuracyJumpInitial", "inaccuracy jump initial", nil, 0.001)

		MACRO__SetupItemDefGetter(SWEP, "ScopeLensMaskModel", "aimsight lens mask", nil, nil, "")

		MACRO__SetupItemDefGetter(SWEP, "ZoomTime0", "zoom time 0")
		MACRO__SetupItemDefGetter(SWEP, "ZoomFOV1", "zoom fov 1")
		MACRO__SetupItemDefGetter(SWEP, "ZoomTime1", "zoom time 1")
		MACRO__SetupItemDefGetter(SWEP, "ZoomFOV2", "zoom fov 2")
		MACRO__SetupItemDefGetter(SWEP, "ZoomTime2", "zoom time 2")

		MACRO__SetupItemDefGetter(SWEP, "IdleInterval", "idle interval", nil, nil, 20)
		MACRO__SetupItemDefGetter(SWEP, "FlinchVelocityModifierLarge", "flinch velocity modifier large")
		MACRO__SetupItemDefGetter(SWEP, "FlinchVelocityModifierSmall", "flinch velocity modifier small")
		MACRO__SetupItemDefGetter(SWEP, "TimeToIdleAfterFire", "time to idle", nil, nil, 2)

		MACRO__SetupItemDefGetter(SWEP, "RecoveryTimeStand", "recovery time stand")
		MACRO__SetupItemDefGetter(SWEP, "RecoveryTimeStandFinal", "recovery time stand final")
		MACRO__SetupItemDefGetter(SWEP, "RecoveryTimeCrouch", "recovery time crouch")
		MACRO__SetupItemDefGetter(SWEP, "RecoveryTimeCrouchFinal", "recovery time crouch final")

		MACRO__SetupItemDefGetter(SWEP, "RecoveryTransitionStartBullet", "recovery transition start bullet")
		MACRO__SetupItemDefGetter(SWEP, "RecoveryTransitionEndBullet", "recovery transition end bullet")

		MACRO__SetupItemDefGetter(SWEP, "CrosshairDeltaDistance", "crosshair delta distance")
		MACRO__SetupItemDefGetter(SWEP, "CrosshairMinDistance", "crosshair min distance")

		MACRO__SetupItemDefGetter(SWEP, "PrimaryReserveMax", "primary reserve ammo max", nil, nil, 40)

		MACRO__SetupItemDefGetter(SWEP, "HeatPerShot", "heat per shot")

		MACRO__SetupItemDefGetter(SWEP, "IsRevolver", "is revolver", FORCE_BOOL)
		MACRO__SetupItemDefGetter(SWEP, "DoesUnzoomAfterShoot", "unzoom after shot", FORCE_BOOL)
		MACRO__SetupItemDefGetter(SWEP, "HasBurstMode", "has burst mode", FORCE_BOOL)
		MACRO__SetupItemDefGetter(SWEP, "DoesHideViewModelWhenZoomed", "hide view model zoomed", FORCE_BOOL)

		-- sound pitch thing that is only used by the negev
		MACRO__SetupItemDefGetter(SWEP, "InaccuracyPitchShift", "inaccuracy pitch shift")
		MACRO__SetupItemDefGetter(SWEP, "InaccuracyAltSoundThreshold", "inaccuracy alt sound threshold")

		MACRO__SetupItemDefGetter(SWEP, "KillAward", "kill award")

		MACRO__SetupItemDefGetter(SWEP, "Exhaustible", "itemflag exhaustible", FORCE_BOOL)
		MACRO__SetupItemDefGetter(SWEP, "ArmorRatio", "armor ratio")

		-- secondary fire modes
		MACRO__SetupItemDefGetter(SWEP, "HasSilencer", "has silencer", FORCE_BOOL)
		MACRO__SetupItemDefGetter(SWEP, "ZoomLevels", "zoom levels")
		MACRO__SetupItemDefGetter(SWEP, "TimeBetweenBurstShots", "time between burst shots")
		MACRO__SetupItemDefGetter(SWEP, "CycleTimeInBurstMode", "cycletime when in burst mode")
		MACRO__SetupItemDefGetter(SWEP, "CycleTimeInZoom", "cycletime when zoomed")

		MACRO__SetupItemDefGetter(SWEP, "IsFullAuto", "is full auto", FORCE_BOOL)

		SWEP.HasBuiltinSilencer = function(self)
			local iHasSilencer = tonumber(attributes["has silencer"] or 0)

			if iHasSilencer == 2 then
				return true
			end

			return false
		end

		--SWEP:SetSilencerOn(SWEP:GetHasSilencer())
		--SWEP:SetWeaponMode(SWEP:GetHasSilencer() and Secondary_Mode or Primary_Mode)

		SWEP.m_sWeaponType = string.lower(visuals and visuals.weapon_type or "weapon")

		SWEP.m_RecoilData = {}
		SWEP.m_SpreadData = {}

		--if swcs.IsGunWeapon(SWEP:GetWeaponType()) then

		-- LUA: not a traditional recoil seed
		local recoilSeed = attributes and attributes["recoil seed"]
		if attributes and not tonumber(recoilSeed) then
			local toCRC
			local bHasSeed = false

			if recoilSeed then
				toCRC = recoilSeed
				bHasSeed = true
			else
				toCRC = SWEP.ClassName or class or SWEP.PrintName
			end

			-- create a temporary seed value based on a hash of the weapon name
			local crc = util.CRC(toCRC)
			attributes["recoil seed"] = bit.band(crc --[[@as number]], 0xFFFF)

			if not bHasSeed then
				--Msg( Format("RECOIL: No seed found for weapon %s, generated placeholder seed %i\n", SWEP:GetClass(), attributes["recoil seed"] ))
			end
		end

		-- recoil shit defaults
		if attributes then
			if not attributes["recoil angle"] then
				attributes["recoil angle"] = 0
			end
			if not attributes["recoil angle alt"] then
				attributes["recoil angle alt"] = 0
			end
			if not attributes["recoil angle variance"] then
				attributes["recoil angle variance"] = 0
			end
			if not attributes["recoil angle variance alt"] then
				attributes["recoil angle variance alt"] = 0
			end
			if not attributes["recoil magnitude"] then
				attributes["recoil magnitude"] = 0
			end
			if not attributes["recoil magnitude alt"] then
				attributes["recoil magnitude alt"] = 0
			end
			if not attributes["recoil magnitude variance"] then
				attributes["recoil magnitude variance"] = 0
			end
			if not attributes["recoil magnitude variance alt"] then
				attributes["recoil magnitude variance alt"] = 0
			end
		end

		--[[
			SWEP:GenerateRecoilTable(SWEP.m_RecoilData)
			SWEP:GenerateSpreadTable(SWEP.m_SpreadData)
		]]
		--end

		--SWEP:SetIronSightMode(IronSight_should_approach_unsighted)
		--SWEP:UpdateIronSightController()

		if prefab then
			SWEP.m_sZoomOutSound = prefab.zoom_out_sound or ""
			SWEP.m_sZoomInSound = prefab.zoom_in_sound or ""
		end

		if visuals then
			if not swcs.InTTT then
				if USE_HL2_AMMO:GetBool() and visuals.primary_ammo ~= "AMMO_TYPE_DECOY" then
					SWEP._OriginalAmmo = SWEP.Primary.Ammo or visuals.primary_ammo or "none"
					if visuals.primary_ammo == "BULLET_PLAYER_50AE" then
						SWEP.Primary.Ammo = "357"
					else
						SWEP.Primary.Ammo = swcs.TypeToHL2Ammo[visuals.weapon_type] or visuals.primary_ammo or "none"
					end
				elseif not SWEP.Primary.Ammo then
					SWEP.Primary.Ammo = visuals.primary_ammo or "none"
				end
			end

			SWEP.SND_SINGLE = visuals.sound_single_shot -- default primary attack sound
			SWEP.SND_SINGLE_ACCURATE = visuals.sound_single_shot_accurate -- negev uses this
			SWEP.SND_SPECIAL1 = visuals.sound_special1 -- silenced weps use this
			SWEP.SND_NEARLY_EMPTY = visuals.sound_nearlyempty

			if visuals.muzzle_flash_effect_1st_person and #visuals.muzzle_flash_effect_1st_person > 0 then
				PrecacheParticleSystem(visuals.muzzle_flash_effect_1st_person)
			end
			if visuals.muzzle_flash_effect_1st_person_alt and #visuals.muzzle_flash_effect_1st_person_alt > 0 then
				PrecacheParticleSystem(visuals.muzzle_flash_effect_1st_person_alt)
			end
			if visuals.muzzle_flash_effect_3rd_person and #visuals.muzzle_flash_effect_3rd_person > 0 then
				PrecacheParticleSystem(visuals.muzzle_flash_effect_3rd_person)
			end
			if visuals.muzzle_flash_effect_3rd_person_alt and #visuals.muzzle_flash_effect_3rd_person_alt > 0 then
				PrecacheParticleSystem(visuals.muzzle_flash_effect_3rd_person_alt)
			end
			if visuals.heat_effect and #visuals.heat_effect > 0 then
				PrecacheParticleSystem(visuals.heat_effect)
			end
			if visuals.eject_brass_effect and #visuals.eject_brass_effect > 0 then
				PrecacheParticleSystem(visuals.eject_brass_effect)
			end
			if visuals.tracer_effect and #visuals.tracer_effect > 0 then
				PrecacheParticleSystem(visuals.tracer_effect)
			end
		end

		SWEP.Primary.ClipSize = SWEP:GetClipSize()

		local iDefaultClip = SWEP.Primary.DefaultClip or SWEP:GetDefaultClipSize()

		-- no default clip, fall back to guns' max primary reserve
		if iDefaultClip == -1 and swcs.IsGunWeapon(SWEP.m_sWeaponType) then
			-- add in enough to fill the first clip as well as reserve
			iDefaultClip = SWEP:GetPrimaryReserveMax() + SWEP.Primary.ClipSize
		end

		if swcs.InTTT then
			SWEP.Primary.DefaultClip = SWEP.Primary.ClipSize
		else
			SWEP.Primary.DefaultClip = iDefaultClip
		end

		SWEP.Primary.Automatic = SWEP:GetIsFullAuto()

		--print("LOAD", SWEP:GetClipSize(), iDefaultClip)

		--if SERVER and iDefaultClip > 0 then
		--    local owner = SWEP:GetOwner()
		--    if owner:IsValid() and owner:IsPlayer() and not swcs.InTTT then
		--        owner:GiveAmmo(iDefaultClip, SWEP:GetPrimaryAmmoType())
		--    end
		--end

		--if bSetAmmo and SWEP.ItemAttributes then
		--    SWEP:SetClip1(SWEP.Primary.ClipSize)
		--
		--    if not swcs.InTTT then
		--        SWEP:SetReserveAmmo(SWEP:GetPrimaryReserveMax())
		--    end
		--end
	end

	hook.Add("PreRegisterSWEP", "swcs.register", function(swep, class)
		local BaseName = swep.Base

		if BaseName then
			if BaseName == "weapon_swcs_base" or weapons.IsBasedOn(BaseName, "weapon_swcs_base") then
				swcs.RegisterItem(swep.ItemDefAttributes, swep.ItemDefVisuals, swep.ItemDefPrefab, swep, class)

				swcs.RegisteredItems[class] = swep
				swep.ScriptedEntityType = "swcs_weapon"

				if swcs.IsGunWeapon(swep.m_sWeaponType) then
					list.Set("NPCUsableWeapons", class, {
						category = "#spawnmenu.category.swcs",
						class = class,
						title = swep.PrintName,
					})
				end
			elseif BaseName == "weapon_swcs_knife" or weapons.IsBasedOn(BaseName, "weapon_swcs_knife") then
				swcs.RegisteredItems[class] = swep
				swep.ScriptedEntityType = "swcs_weapon"
			end
		end
	end)

	local function SyncHL2Ammo()
		if swcs.InTTT then return end
		local enabled = USE_HL2_AMMO:GetBool()

		for class in next, swcs.RegisteredItems do
			local swep = weapons.GetStored(class)
			local visuals = swep.ItemVisuals
			if not visuals then continue end

			local ammoName = ""
			if enabled then
				if visuals.primary_ammo == "BULLET_PLAYER_50AE" then
					ammoName = "357"
				else
					ammoName = swcs.TypeToHL2Ammo[visuals.weapon_type] or visuals.primary_ammo or "none"
				end
			else
				ammoName = swep._OriginalAmmo or visuals.primary_ammo or "none"
			end

			swep.Primary.Ammo = ammoName

			for _, ent in ipairs(ents.FindByClass(class)) do
				ent.Primary.Ammo = ammoName
			end
		end
	end

	if SERVER then
		cvars.AddChangeCallback("swcs_hl2_ammo", SyncHL2Ammo)
	else
		-- garrysmod-issues#3740 fixed when :(
		local hl2ammo_old = USE_HL2_AMMO:GetBool()
		hook.Add("Think", "swcs.hl2_ammo", function()
			local hl2ammo_new = USE_HL2_AMMO:GetBool()
			if hl2ammo_new ~= hl2ammo_old then
				SyncHL2Ammo()
				hl2ammo_old = hl2ammo_new
			end
		end)
	end

	local function TestBone(ent, boneName)
		if not ent and ent:IsValid() then return end

		--if CLIENT then
		--	ent:SetupBones()
		--else
		--
		--end

		local iBoneIndex = ent:LookupBone(boneName)
		if iBoneIndex then
			--local matrix = ent:GetBoneMatrix(iBoneIndex)
			--local bPos, bAng = matrix:GetTranslation(), matrix:GetAngles()
			--
			--bPos:Set(ent:WorldToLocal(bPos))
			--
			--if bPos:IsZero() then
			--    return false
			--end

			return true
		else
			return false
		end
	end

	local MODEL_TEST_ENT = NULL
	hook.Add("InitPostEntity", "swcs.register", function()
		if VERSION >= 250403 then -- rubat please dont change the main branch version number without this function :(
			for class, swep in next, swcs.RegisteredItems do
				if swep.IsBase then continue end
				if not swep.ViewModel or #swep.ViewModel == 0 then continue end

				if swep.SupportsNameTags == nil or swep.SupportsStatTracks == nil then
					local modelInfo = util.GetModelInfo(swep.ViewModel)
					if not modelInfo then continue end

					for i = 1, #modelInfo.Bones do
						local Bone = modelInfo.Bones[i]
						if swep.SupportsNameTags == nil and Bone.Name == "v_weapon.uid" then
							swep.SupportsNameTags = true
						elseif swep.SupportsStatTracks == nil and Bone.Name == "v_weapon.stattrack" then
							swep.SupportsStatTracks = true
						end

						if swep.SupportsNameTags and swep.SupportsStatTracks then
							break
						end
					end
				end
			end
		else
			if SERVER and not MODEL_TEST_ENT:IsValid() then
				MODEL_TEST_ENT = ents.Create("prop_dynamic")
				MODEL_TEST_ENT:SetModel("models/weapons/csgo/v_rif_ak47.mdl")
				MODEL_TEST_ENT:Spawn()
			elseif CLIENT and not MODEL_TEST_ENT:IsValid() then
				MODEL_TEST_ENT = ClientsideModel("models/weapons/csgo/v_rif_ak47.mdl")
				MODEL_TEST_ENT:SetNoDraw(true)
			end

			for class, swep in next, swcs.RegisteredItems do
				if swep.IsBase then continue end

				if swep.ViewModel and #swep.ViewModel > 0 and (swep.SupportsNameTags == nil or swep.SupportsStatTracks == nil) then
					MODEL_TEST_ENT:SetModel(swep.ViewModel)

					if swep.SupportsNameTags == nil then
						swep.SupportsNameTags = TestBone(MODEL_TEST_ENT, "v_weapon.uid")
					end
					if swep.SupportsStatTracks == nil then
						swep.SupportsStatTracks = TestBone(MODEL_TEST_ENT, "v_weapon.stattrack")
					end
				end
			end

			MODEL_TEST_ENT:Remove()
		end
	end)
end

function swcs.IsBSPModel(pEnt)
	local iSolid = pEnt:GetSolid()
	if iSolid == SOLID_BSP then
		return true
	end

	local model = pEnt:GetModel()

	if iSolid == SOLID_VPHYSICS and model:find("^%*(%d+)") then
		return true
	end

	return false
end

function swcs.CheckTotalSmokedLength(flSmokeRadiusSq, vecGrenadePos, from, to)
	local sightDir = (to - from)
	local sightLength = sightDir:Length()
	sightDir:Normalize()

	-- the detonation position is the actual position of the smoke grenade, but the smoke volume center is actually some number of units above that

	local vecSmokeCenterOffset = Vector(0, 0, 60)
	local smokeOrigin = vecGrenadePos + vecSmokeCenterOffset

	local flSmokeRadius = math.sqrt(flSmokeRadiusSq)

	-- if the start point or the end point is inside the radius of the smoke, then the line goes through the smoke
	if smokeOrigin:Distance(from) < flSmokeRadius * 0.95 or smokeOrigin:Distance(to) < flSmokeRadius then
		return -1
	end

	local toGrenade = smokeOrigin - from

	local alongDist = toGrenade:Dot(sightDir)

	-- compute closest point to grenade along line of sight ray
	local close = Vector()

	-- constrain closest point to line segment
	if alongDist < 0 then
		close:Set(from)
	elseif alongDist >= sightLength then
		close:Set(to)
	else
		close:Set(from)
		close:Add(sightDir * alongDist)
	end

	-- if closest point is within smoke radius, the line overlaps the smoke cloud
	local toClose = close - smokeOrigin
	local lengthSq = toClose:LengthSqr()

	if close:DistToSqr(smokeOrigin) < flSmokeRadiusSq then
		-- some portion of the ray intersects the cloud

		-- 'from' and 'to' lie outside of the cloud - the line of sight completely crosses it
		-- determine the length of the chord that crosses the cloud
		local smokedLength = 2.0 * math.sqrt(flSmokeRadiusSq - lengthSq)
		return smokedLength
	end

	return 0
end

local CONSTANT_UNITS_SMOKEGRENADERADIUS = 166
local CONSTANT_UNITS_GENERICGRENADERADIUS = 115

--const float SmokeGrenadeRadius = CONSTANT_UNITS_SMOKEGRENADERADIUS;
--const float FlashbangGrenadeRadius = CONSTANT_UNITS_GENERICGRENADERADIUS;
--const float HEGrenadeRadius = CONSTANT_UNITS_GENERICGRENADERADIUS;
--const float MolotovGrenadeRadius = CONSTANT_UNITS_GENERICGRENADERADIUS;
--const float DecoyGrenadeRadius = CONSTANT_UNITS_GENERICGRENADERADIUS;

-- define how much smoke a bot can see thru
local maxSmokedLength = CONSTANT_UNITS_SMOKEGRENADERADIUS * 0.7

function swcs.IsLineBlockedBySmoke(from, to, grenadeBloat)
	local totalSmokedLength = 0.0 -- distance along line of sight covered by smoke

	-- compute unit vector and length of line of sight segment
	for _, gren in next, ents.FindByClass("swcs_smokegrenade_projectile") do
		if not gren:GetDidSmokeEffect() then continue end

		local smokeRadiusSq = CONSTANT_UNITS_SMOKEGRENADERADIUS * CONSTANT_UNITS_SMOKEGRENADERADIUS * grenadeBloat * grenadeBloat

		local flLengthAdd = swcs.CheckTotalSmokedLength(smokeRadiusSq, gren:GetPos(), from, to)
		-- get the totalSmokedLength and check to see if the line starts or stops in smoke.  If it does this will return -1 and we should just bail early
		if flLengthAdd == -1 then
			return true
		end

		totalSmokedLength = totalSmokedLength + flLengthAdd
	end

	-- return true if the total length of smoke-covered line-of-sight is too much
	return totalSmokedLength > maxSmokedLength
end

-- extra use handling hook
do
	EPriority_Default = 0
	EPriority_Hostage = 1
	EPriority_Bomb = 2

	EDistanceCheckType_3D = 0
	EDistanceCheckType_2D = 1

	EPlayerUseType_Start = 0 -- Player wants to initiate the use
	EPlayerUseType_Progress = 1 -- Player wants to make progress using the entity

	swcs.EntityUseConfigurations = {
		swcs_planted_c4 = {
			m_ePriority = EPriority_Bomb,
			m_eDistanceCheckType = EDistanceCheckType_2D,
			m_pos = Vector(0, 0, 0),
			m_offset = Vector(0, 0, 3), -- optional offset added to position used for check
			m_flMaxUseDistance = 62, -- Cannot use if > 62 units away
			m_flLosCheckDistance = 36, -- Check LOS if > 36 units away (2D)
			m_flDotCheckAngle = -0.7, -- 0.7 taken from Goldsrc, +/- ~45 degrees
			m_flDotCheckAngleMax = -0.5, -- 0.3 for it going outside the range during continuous use (120-degree cone)
		},
		swcs_breachcharge_projectile = {
			m_ePriority = EPriority_Bomb,
			m_eDistanceCheckType = EDistanceCheckType_3D,
			m_pos = Vector(0, 0, 0),
			m_offset = Vector(0, 0, 3),
			m_flMaxUseDistance = 92, -- Cannot use if > X units away
			m_flLosCheckDistance = 62, -- Check LOS if > X units away (2D)
			m_flDotCheckAngle = math.cos(math.rad(30)) * -1, -- 30 degrees
			m_flDotCheckAngleMax = -0.5, -- 0.3 for it going outside the range during continuous use (120-degree cone)
		},
	}

	function swcs.GetUseConfigurationForHighPriorityUseEntity(ent)
		local classname = ent:GetClass()

		local base = swcs.EntityUseConfigurations[classname]

		local cfg
		if base then
			cfg = table.Copy(base)

			cfg.m_pEntity = ent

			cfg.m_pos:Set(ent:GetPos())
			if isvector(cfg.m_offset) then
				cfg.m_pos:Add(cfg.m_offset)
			end
		end

		return cfg
	end

	function swcs.IsBetterForUseThan(this, other)
		if not this.m_pEntity:IsValid() then
			return false
		end
		if not other.m_pEntity:IsValid() then
			return true
		end
		if this.m_ePriority < other.m_ePriority then
			return false
		end
		if this.m_ePriority > other.m_ePriority then
			return true
		end
		if this.m_flDotCheckAngleMax < other.m_flDotCheckAngleMax then -- We are looking at it with a better angle
			return true
		end
		if this.m_flMaxUseDistance < other.m_flMaxUseDistance then -- This entity is closer to user
			return true
		end

		return false
	end

	function swcs.UseByPlayerNow(this, ply, ePlayerUseType)
		if not ply:IsValid() then
			return false
		end

		-- entity is close enough, now make sure the player is facing the bomb.
		local flDistTo = math.huge
		if this.m_eDistanceCheckType == EDistanceCheckType_2D then
			flDistTo = ply:WorldSpaceCenter():Distance2D(this.m_pos)
		elseif this.m_eDistanceCheckType == EDistanceCheckType_3D then
			flDistTo = ply:WorldSpaceCenter():Distance(this.m_pos)
		end

		-- UTIL_EntitiesInSphere gives strange results where I can find it when my eyes are at an angle, but not when I'm right on top of it
		-- because of that, make sure it's in our radius, but check the 2d los and make sure we are as close or closer than we need to be in 1.6
		if flDistTo > this.m_flMaxUseDistance then
			return false
		end

		-- if it's more than 36 units away (2d), we should check LOS
		if flDistTo > this.m_flLosCheckDistance then
			local tr = util.TraceLine({
				startpos = ply:EyePos(),
				endpos = this.m_pos,
				mask = bit.bor(MASK_VISIBLE, CONTENTS_WATER, CONTENTS_SLIME),
				filter = ply,
				collisiongroup = COLLISION_GROUP_DEBRIS,
			})

			-- if we can't trace to the bomb at this distance, then we fail
			if tr.Fraction < 0.98 then
				return false
			end
		end

		local vecLOS = ply:EyePos() - this.m_pos
		local forward = ply:EyeAngles():Forward()

		vecLOS:Normalize()

		local flDot = forward:Dot(vecLOS)
		local flCheckAngle = (ePlayerUseType == EPlayerUseType_Start) and this.m_flDotCheckAngle or this.m_flDotCheckAngleMax
		if flDot >= flCheckAngle then
			return false
		end

		-- Remember the actual settings of this entity
		this.m_flDotCheckAngle, this.m_flDotCheckAngleMax = flDot, flDot
		this.m_flLosCheckDistance, this.m_flMaxUseDistance = flDistTo, flDistTo

		return true
	end

	function swcs.GetUsableHighPriorityEntity(ply)
		local entsNearPlayer = ents.FindInSphere(ply:EyePos(), 128)

		if #entsNearPlayer > 0 then
			local cfgBestHighPriorityEntity = {}
			cfgBestHighPriorityEntity.m_pEntity = NULL
			cfgBestHighPriorityEntity.m_ePriority = EPriority_Default

			for _, ent in ipairs(entsNearPlayer) do
				if ent:GetParent() == ply then continue end

				local cfgUseSettings = swcs.GetUseConfigurationForHighPriorityUseEntity(ent)

				-- not a high-priority entity
				if not cfgUseSettings then continue end

				-- not used by the player
				if not cfgUseSettings.m_pEntity:IsValid() then continue end

				-- we already have a higher priority entity
				if cfgUseSettings.m_ePriority < cfgBestHighPriorityEntity.m_ePriority then continue end

				-- cannot start use by the player right now
				if not swcs.UseByPlayerNow(cfgUseSettings, ply, EPlayerUseType_Start) then continue end

				-- This high-priority entity passes the checks, remember it as best
				if swcs.IsBetterForUseThan(cfgUseSettings, cfgBestHighPriorityEntity) then
					cfgBestHighPriorityEntity = cfgUseSettings
				end
			end

			return cfgBestHighPriorityEntity.m_pEntity
		end

		return NULL
	end

	hook.Add("FindUseEntity", "swcs.c4", function(ply, default)
		local ent = swcs.GetUsableHighPriorityEntity(ply)

		if ent:IsValid() then
			return ent
		end
	end)
end

function swcs.VectorVectors(forward, right, up)
	local ang = forward:Angle()
	up:Set(ang:Up())
	right:Set(ang:Right())
end
