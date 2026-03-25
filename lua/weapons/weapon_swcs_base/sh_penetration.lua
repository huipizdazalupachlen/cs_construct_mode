AddCSLuaFile()

local sv_showimpacts = GetConVar("sv_showimpacts")
local sv_showimpacts_penetration = GetConVar("sv_showimpacts_penetration")
local sv_showimpacts_time = GetConVar("sv_showimpacts_time")

local SWITCH_BulletTypeParameters = {
	["BULLET_PLAYER_50AE"] = {
		fPenetrationPower = 30,
		flPenetrationDistance = 1000,
	},
	["BULLET_PLAYER_762MM"] = {
		fPenetrationPower = 39,
		flPenetrationDistance = 5000,
	},
	["BULLET_PLAYER_556MM"] = {
		fPenetrationPower = 35,
		flPenetrationDistance = 4000,
	},
	["BULLET_PLAYER_338MAG"] = {
		fPenetrationPower = 45,
		flPenetrationDistance = 8000,
	},
	["BULLET_PLAYER_9MM"] = {
		fPenetrationPower = 21,
		flPenetrationDistance = 800,
	},
	["BULLET_PLAYER_BUCKSHOT"] = {
		fPenetrationPower = 0,
		flPenetrationDistance = 0,
	},
	["BULLET_PLAYER_45ACP"] = {
		fPenetrationPower = 15,
		flPenetrationDistance = 500,
	},
	["BULLET_PLAYER_357SIG"] = {
		fPenetrationPower = 25,
		flPenetrationDistance = 800,
	},
	["BULLET_PLAYER_57MM"] = {
		fPenetrationPower = 30,
		flPenetrationDistance = 2000,
	},
	["AMMO_TYPE_TASERCHARGE"] = {
		fPenetrationPower = 0,
		flPenetrationDistance = 0,
	},
}
SWITCH_BulletTypeParameters["BULLET_PLAYER_556MM_SMALL"] = SWITCH_BulletTypeParameters["BULLET_PLAYER_556MM"]
SWITCH_BulletTypeParameters["BULLET_PLAYER_556MM_BOX"] = SWITCH_BulletTypeParameters["BULLET_PLAYER_556MM"]
SWITCH_BulletTypeParameters["BULLET_PLAYER_357SIG_SMALL"] = SWITCH_BulletTypeParameters["BULLET_PLAYER_357SIG"]
SWITCH_BulletTypeParameters["BULLET_PLAYER_357SIG_P250"] = SWITCH_BulletTypeParameters["BULLET_PLAYER_357SIG"]
SWITCH_BulletTypeParameters["BULLET_PLAYER_357SIG_MIN"] = SWITCH_BulletTypeParameters["BULLET_PLAYER_357SIG"]

local CHAR_TEX_CARDBOARD = -1

local sv_penetration_type = CreateConVar("swcs_penetration_type", "1", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "What type of penetration to use. 0 = off, 1 = new penetration, 2 = old CS")
local MAX_PENETRATION_DISTANCE = 90 -- this is 7.5 feet

-- maybe check material kvs?
swcs.BulletPenetrationIgnoreTextures = {
	["tools/toolsblockbullets"] = true,
}

function SWEP:PerformBulletPenetration(atk, bulletTr, dmg, filter, outArrPendingDamage)
	local owner = self:GetOwner()

	local nPenetrationCount = 4
	local iDamage = dmg:GetDamageBonus()
	local vecDirShooting = bulletTr.Normal

	local fCurrentDamage = iDamage -- damage of the bullet at its current trajectory
	local flCurrentDistance = 0 -- distance that the bullet has traveled so far

	local flPenetration = self:GetPenetration()
	local flPenetrationPower = 0 -- thickness of a wall that this bullet can penetrate
	local flPenetrationDistance = 0 -- distance at which the bullet is capable of penetrating a wall
	local flDamageModifier = 0.5 -- default modification of bullets power after they go through a wall.
	local flPenetrationModifier = 1.0

	local params = SWITCH_BulletTypeParameters[self.ItemVisuals.primary_ammo]
	if sv_penetration_type:GetInt() == 1 then
		-- we use the max penetrations on this gun to figure out how much penetration it's capable of
		flPenetrationPower = self:GetPenetration()
		flPenetrationDistance = 3000
	elseif params then
		flPenetrationPower = params.fPenetrationPower
		flPenetrationDistance = params.flPenetrationDistance
	end

	local bFirstHit = true
	local lastPlayerHit = NULL -- includes players, bots, and npcs

	local vecWallBangHitStart, vecWallBangHitEnd = Vector(), Vector()
	local bWallBangStarted = false
	local bWallBangEnded = false
	local bWallBangHeavyVersion = false

	local bBulletHitPlayer = false

	local flDistance = self:GetRange()
	local vecSrc = bulletTr.StartPos

	local iDamageType = bit.bor(DMG_BULLET, DMG_NEVERGIB)
	if self:GetClass() == "weapon_swcs_taser" then
		iDamageType = bit.bor(DMG_SHOCK, DMG_NEVERGIB)
	end
	dmg:SetDamageType(iDamageType)

	filter = table.Copy(filter)
	local filterfunc = swcs.filter_IgnoreOwner(owner, filter)

	local iShowImpacts = sv_showimpacts:GetInt()
	local iShowPenetration = sv_showimpacts_penetration:GetInt()
	local bDrawDebug = (CLIENT and (iShowImpacts == 1 or iShowImpacts == 2) and IsFirstTimePredicted()) or (SERVER and (iShowImpacts == 1 or iShowImpacts == 3))
	local flDebugTime = 0

	if bDrawDebug then
		flDebugTime = sv_showimpacts_time:GetFloat()
	end

	local tr = {} -- main enter bullet trace
	local traceData = {
		start = Vector(),
		endpos = Vector(),
		mask = bit.bor(CS_MASK_SHOOT, CONTENTS_HITBOX),
		filter = filterfunc,
		collisiongroup = COLLISION_GROUP_NONE,
		output = tr,
	}

	while fCurrentDamage > 0 do
		traceData.start:Set(vecSrc)
		traceData.endpos:Set(vecDirShooting)
		traceData.endpos:Mul(flDistance - flCurrentDistance)
		traceData.endpos:Add(vecSrc)

		--local filter = {owner, lastPlayerHit}

		--if g_CapsuleHitboxes then
		--    traceData.filter = g_CapsuleHitboxes:GetEntitiesWithCapsuleHitboxes(owner)
		--end

		if lastPlayerHit:IsValid() then
			table.insert(filter, lastPlayerHit)
		end
		table.insert(filter, owner)

		hook.Run("SWCSPenetratationIgnoreEntities", self, owner, filter)

		util.TraceLine(traceData)

		--if g_CapsuleHitboxes then
		--    table.remove(filter) -- remove owner from filter
		--    --if lastPlayerHit:IsValid() then
		--    --    table.remove(filter) -- remove last hit player from filter
		--    --end
		--    g_CapsuleHitboxes:IntersectRayWithEntities(tr, filter)
		--end

		-- we didn't hit anything, stop tracing shoot
		if tr.Fraction == 1 then break end

		if tr.Entity:IsPlayer() then
			lastPlayerHit = tr.Entity
			bBulletHitPlayer = true
		elseif tr.Entity.IsSWCSShield then
			break
		end

		-- wallbang bools
		if not bWallBangStarted and not bBulletHitPlayer then
			vecWallBangHitStart:Set(tr.HitPos)
			vecWallBangHitEnd:Set(tr.HitPos)
			bWallBangStarted = true

			if (fCurrentDamage > 20) then
				bWallBangHeavyVersion = true
			end
		elseif not bWallBangEnded then
			vecWallBangHitEnd:Set(tr.HitPos)

			if bBulletHitPlayer then
				bWallBangEnded = true
			end
		end

		flCurrentDistance = flCurrentDistance + (tr.Fraction * (flDistance - flCurrentDistance))
		fCurrentDamage = fCurrentDamage * math.pow(self:GetRangeModifier(), flCurrentDistance / 500)

		if bFirstHit then
			dmg:SetDamage(fCurrentDamage)
		else
			swcs.BulletImpact(tr, owner, dmg:GetDamageType(), {owner, lastPlayerHit})
		end

		bFirstHit = false

		--[[
			client accuracy debug here
		]]

		-- /************* MATERIAL DETECTION ***********/
		local iEnterMaterial
		if tr.SurfaceProps == -1 then
			if SWCS_DEBUG_PENETRATION:GetBool() then
				print(Format("enter material not engine registered at (%f %f %f), using default instead",
					tr.HitPos.x, tr.HitPos.y, tr.HitPos.z))
			end
			tr.SurfaceProps = 0
		end

		local enterData = util.GetSurfaceData(tr.SurfaceProps)

		if enterData then
			iEnterMaterial = enterData.material
		end

		local pen_mat = swcs.SurfaceInfo[swcs.SurfaceProps[tr.SurfaceProps]]
		if not pen_mat then
			if SWCS_DEBUG_PENETRATION:GetBool() then
				print(Format("no penetration material for %s, using default instead", util.GetSurfacePropName(tr.SurfaceProps)))
			end

			pen_mat = swcs.SurfaceInfo.default
		end

		flPenetrationModifier = pen_mat.penmod
		flDamageModifier = pen_mat.dmgmod

		local bHitGrate = bit.band(tr.Contents, CONTENTS_GRATE) ~= 0

		if bDrawDebug then
			-- draw red client impact markers
			-- draw blue server impact markers
			debugoverlay.Box(tr.HitPos, -Vector(2, 2, 2), Vector(2, 2, 2), flDebugTime, CLIENT and Color(255, 0, 0, 127) or Color(0, 0, 255, 127))
		end

		-- check if we reach penetration distance, no more penetrations after that
		-- or if our modifyer is super low, just stop the bullet
		if (flCurrentDistance > flPenetrationDistance and flPenetration > 0) or
			flPenetrationModifier < 0.1 then
			-- Setting nPenetrationCount to zero prevents the bullet from penetrating object at max distance
			-- and will no longer trace beyond the exit point, however "numPenetrationsInitiallyAllowedForThisBullet"
			-- is saved off to allow correct determination whether the hit on the object at max distance had
			-- *previously* penetrated anything or not. In case of a direct hit over 3000 units the saved off
			-- value would be max penetrations value and will determine a direct hit and not a penetration hit.
			-- However it is important that all tracing further stops past this point (as the code does at
			-- the time of writing) because otherwise next trace will think that 4 penetrations have already
			-- occurred.
			nPenetrationCount = 0
		end

		if iShowPenetration > 0 then
			local text = "^"
			local text2 = Format("%s%d", iShowPenetration == 2 and "" or "DAMAGE APPLIED:  ", math.ceil(fCurrentDamage))
			local text3
			-- convert to meters
			--(100%% of shots will fall within a 30cm circle.)
			local flDistMeters = flCurrentDistance * 0.0254
			if flDistMeters >= 1 then
				text3 = Format("%s%0.1fm", iShowPenetration == 2 and "" or "TOTAL DISTANCE:  ", flDistMeters)
			else
				text3 = Format("%s%0.1fcm", iShowPenetration == 2 and "" or "TOTAL DISTANCE:  ", flDistMeters / 0.01)
			end

			local textPos = tr.HitPos

			debugoverlay.EntityTextAtPosition(textPos, 1, text, flDebugTime, Color(255, 128, 64, 255))
			debugoverlay.EntityTextAtPosition(textPos, 2, text2, flDebugTime, Color(255, 64, 0, 255))
			debugoverlay.EntityTextAtPosition(textPos, 3, text3, flDebugTime, Color(255, 128, 0, 255))

			debugoverlay.Box(tr.HitPos, -Vector(0.8, 0.8, 0.8), Vector(0.8, 0.8, 0.8), flDebugTime, Color(255, 100, 50, 64))
		end

		-- actually damaged an ent
		if tr.Entity:IsValid() or tr.Entity:IsWorld() then
			table.insert(outArrPendingDamage, {
				ent = tr.Entity,
				dmg = math.ceil(fCurrentDamage),
				trace = table.Copy(tr),
			})
		end

		local bulletStopped
		bulletStopped, nPenetrationCount, flPenetration, fCurrentDamage = self:HandleBulletPenetration(flPenetration, iEnterMaterial, bHitGrate, tr, vecDirShooting, flPenetrationModifier,
			flDamageModifier, iDamageType, flPenetrationPower, nPenetrationCount, vecSrc, flDistance,
			flCurrentDistance, fCurrentDamage)

		if bulletStopped then break end
	end

	-- wallbang effects
	if bWallBangStarted then
		local flWallBangLength = vecWallBangHitStart:Distance(vecWallBangHitEnd)

		if flWallBangLength > 0 and flWallBangLength < 800 then
			if bWallBangHeavyVersion then
				util.ParticleTracerEx("impact_wallbang_heavy", vecWallBangHitStart, vecWallBangHitEnd, true, self:EntIndex(), -1)
			else
				util.ParticleTracerEx("impact_wallbang_light", vecWallBangHitStart, vecWallBangHitEnd, true, self:EntIndex(), -1)
			end
		end
	end

	return false
end

function SWEP:TraceToExit(start, dir, endpos, trEnter, trExit, flStepSize, flMaxDistance)
	local flDistance = 0
	local nStartContents = 0
	local owner = self:GetPlayerOwner()

	while flDistance <= flMaxDistance do
		flDistance = flDistance + flStepSize

		endpos:Set(start + (flDistance * dir))

		local vecTrEnd = endpos - (flStepSize * dir)

		if nStartContents == 0 then
			nStartContents = bit.band(util.PointContents(endpos), bit.bor(CS_MASK_SHOOT, CONTENTS_HITBOX))
		end

		local nCurrentContents = bit.band(util.PointContents(endpos), bit.bor(CS_MASK_SHOOT, CONTENTS_HITBOX))

		if bit.band(nCurrentContents, CS_MASK_SHOOT) == 0 or ((bit.band(nCurrentContents, CONTENTS_HITBOX) ~= 0) and nStartContents ~= nCurrentContents) then
			-- this gets a bit more complicated and expensive when we have to deal with displacements
			local filter = {}
			--if g_CapsuleHitboxes then
			--    filter = g_CapsuleHitboxes:GetEntitiesWithCapsuleHitboxes(owner)
			--end
			table.insert(filter, owner)

			util.TraceLine({
				start = endpos,
				endpos = vecTrEnd,
				mask = bit.bor(CS_MASK_SHOOT, CONTENTS_HITBOX),
				filter = filter,
				output = trExit,
			})

			--if g_CapsuleHitboxes then
			--    table.remove(filter) -- remove owner from filter
			--    g_CapsuleHitboxes:IntersectRayWithEntities(trExit, filter)
			--end

			-- for idx, data in pairs(saveTrace) do
			--     print(string.format("Tracedata %s %s unmodified tracedata.", idx, Either(data == trExit[idx], "matches", "does not match")))
			-- end

			--debugoverlay.Cross(trExit.HitPos, 3, 5, HSVToColor(180, flDistance / flMaxDistance, 1), true)
			----debugoverlay.Box(trExit.HitPos, -Vector(2,2,2),Vector(2,2,2),5, Color(0,255,255))
			--debugoverlay.Box(trExit.StartPos, -Vector(2,2,2),Vector(2,2,2),5, trExit.StartSolid and Color(255,0,0, 64) or Color(0,255,0, 64))

			--print(trExit.StartSolid, trExit.SurfaceFlags)

			-- we exited the wall into a player's hitbox
			if trExit.StartSolid and (bit.band(trExit.SurfaceFlags, SURF_HITBOX) ~= 0) then
				--debugoverlay.Box(trExit.HitPos, -Vector(1,1,1), Vector(1,1,1), 5, Color(0,0,255, 64))
				--print("into hitbox")
				-- do another trace, but skip the player to get the actual exit surface
				util.TraceLine({
					start = endpos,
					endpos = start,
					mask = bit.bor(CS_MASK_SHOOT, CONTENTS_HITBOX),
					filter = filter,
					collisiongroup = COLLISION_GROUP_NONE,
					output = trExit,
				})

				--if g_CapsuleHitboxes then
				--g_CapsuleHitboxes:IntersectRayWithEntities(trExit, filter)
				--end

				--debugoverlay.Cross(trExit.HitPos, 3, 5, Color(255,0,0), true)

				if trExit.Hit and not trExit.StartSolid then
					endpos:Set(trExit.HitPos)
					return true
				end
			elseif trExit.Hit and not trExit.StartSolid then
				local bStartIsNodraw = bit.band(trEnter.SurfaceFlags, SURF_NODRAW) ~= 0
				local bExitIsNodraw = bit.band(trExit.SurfaceFlags, SURF_NODRAW) ~= 0

				if bExitIsNodraw and swcs.IsBreakableEntity(trExit.Entity) and swcs.IsBreakableEntity(trEnter.Entity) then
					-- we have a case where we have a breakable object, but the mapper put a nodraw on the backside
					endpos:Set(trExit.HitPos)
					return true
				elseif not bExitIsNodraw or (bStartIsNodraw and bExitIsNodraw) then -- exit nodraw is only valid if our entrace is also nodraw
					local vecNormal = trExit.HitNormal
					local flDot = dir:Dot(vecNormal)
					if flDot <= 1 then
						-- get the real end pos
						endpos:Set(endpos - ((flStepSize * trExit.Fraction) * dir))
						return true
					end
				end
			elseif not trEnter.Entity:IsWorld() and swcs.IsBreakableEntity(trEnter.Entity) then
				-- if we hit a breakable, make the assumption that we broke it if we can't find an exit (hopefully..)
				-- fake the end pos
				table.CopyFromTo(trEnter, trExit)
				trExit.HitPos = start + (1 * dir)
				return true
			end
		end
	end

	return false
end

function SWEP:HandleBulletPenetration(
	flPenetration,
	iEnterMaterial,
	bHitGrate,
	tr,
	vecDir,
	flPenetrationModifier,
	flDamageModifier,
	iDamageType,
	flPenetrationPower,
	nPenetrationCount,
	vecSrc,
	flDistance,
	flCurrentDistance,
	fCurrentDamage
)
	local bIsNodraw = bit.band(tr.SurfaceFlags, SURF_NODRAW) ~= 0
	local bFailedPenetrate = false

	-- check if bullet can penetrarte another entity
	if nPenetrationCount == 0 and not bHitGrate and not bIsNodraw
		and iEnterMaterial ~= MAT_GLASS and iEnterMaterial ~= MAT_GRATE then
		bFailedPenetrate = true -- no, stop
	end

	-- If we hit a grate with iPenetration == 0, stop on the next thing we hit
	if flPenetration <= 0 or nPenetrationCount <= 0 then
		bFailedPenetrate = true
	end

	local penetrationEnd = Vector()

	-- find exact penetration exit
	local exitTr = {}
	if not self:TraceToExit(tr.HitPos, vecDir, penetrationEnd, tr, exitTr, 4, MAX_PENETRATION_DISTANCE) then
		-- ended in solid
		if bit.band(util.PointContents(tr.HitPos), CS_MASK_SHOOT) == 0 then
			bFailedPenetrate = true
		end
	end

	if swcs.BulletPenetrationIgnoreTextures[string.lower(tr.HitTexture)] then
		bFailedPenetrate = true
		flPenetrationModifier = 0.01
	end

	if bFailedPenetrate then
		local flTraceDistance = (penetrationEnd - tr.HitPos):Length()

		-- this is copy pasted from below, it should probably be its own function
		local flPenMod = math.max(0, 1 / flPenetrationModifier)
		local flPercentDamageChunk = fCurrentDamage * 0.15
		local flDamageLostImpact = flPercentDamageChunk + math.max(0, (3 / flPenetrationPower) * 1.18) * (flPenMod * 2.8)

		local flLostDamageObject = ((flPenMod * (flTraceDistance * flTraceDistance)) / 24)
		local flTotalLostDamage = flDamageLostImpact + flLostDamageObject

		self:DisplayPenetrationDebug(tr.HitPos, penetrationEnd, flTraceDistance, fCurrentDamage, flDamageLostImpact, flTotalLostDamage, tr.SurfaceProps, -100)
		return true, nPenetrationCount, flPenetration, fCurrentDamage
	end

	local iExitMaterial
	if table.IsEmpty(exitTr) then
		if SWCS_DEBUG_PENETRATION:GetBool() then
			print("exit trace empty???, stopping penetration!!!!")
		end

		return true, nPenetrationCount, flPenetration, fCurrentDamage
	end
	local exitSurfaceData = util.GetSurfaceData(exitTr.SurfaceProps)

	if exitSurfaceData then
		iExitMaterial = exitSurfaceData.material
	end

	if not iExitMaterial then
		if SWCS_DEBUG_PENETRATION:GetBool() then
			print(Format("exit material not engine registered at (%f %f %f), using default instead",
				tr.HitPos.x, tr.HitPos.y, tr.HitPos.z))
		end
		iExitMaterial = util.GetSurfaceData(SURFACE_PROP_DEFAULT).material
	end

	local owner = self:GetOwner()

	-- new penetration method
	if sv_penetration_type:GetInt() == 1 then
		-- percent of total damage lost automatically on impacting a surface
		local flDamLostPercent = 0.16

		-- since some railings in de_inferno are CONTENTS_GRATE but CHAR_TEX_CONCRETE, we'll trust the
		-- CONTENTS_GRATE and use a high damage modifier.
		if bHitGrate or bIsNodraw or iEnterMaterial == MAT_GLASS or iEnterMaterial == MAT_GRATE then
			-- If we're a concrete grate (TOOLS/TOOLSINVISIBLE texture) allow more penetrating power.
			if iEnterMaterial == MAT_GRATE or iEnterMaterial == MAT_GRATE then
				flPenetrationModifier = 3
				flDamLostPercent = 0.05
			else
				flPenetrationModifier = 1
			end

			flDamageModifier = 0.99
		else
			-- check the exit material and average the exit and entrace values
			local pen_mat
			if exitSurfaceData then
				pen_mat = swcs.SurfaceInfo[swcs.SurfaceProps[exitTr.SurfaceProps]]
			end

			if not pen_mat then
				pen_mat = swcs.SurfaceInfo.default
			end

			local flExitPenetrationModifier = pen_mat.penmod
			local flExitDamageModifier = pen_mat.dmgmod
			flPenetrationModifier = (flPenetrationModifier + flExitPenetrationModifier) / 2
			flDamageModifier = (flDamageModifier + flExitDamageModifier) / 2
		end

		-- if enter & exit point is wood we assume this is
		-- a hollow crate and give a penetration bonus
		if iEnterMaterial == iExitMaterial then
			if iExitMaterial == MAT_WOOD or iExitMaterial == CHAR_TEX_CARDBOARD then
				flPenetrationModifier = 3
			elseif iExitMaterial == MAT_PLASTIC then
				flPenetrationModifier = 2
			end
		end

		local flTraceDistance = exitTr.HitPos:Distance(tr.HitPos)
		local flPenMod = math.max(0, 1 / flPenetrationModifier)

		local flPercentDamageChunk = fCurrentDamage * flDamLostPercent
		local flPenWepMod = flPercentDamageChunk + math.max(0, (3 / flPenetrationPower) * 1.25) * (flPenMod * 3)

		local flLostDamageObject = ((flPenMod * (flTraceDistance * flTraceDistance)) / 24)
		local flTotalLostDamage = flPenWepMod + flLostDamageObject

		if sv_showimpacts_penetration:GetInt() > 0 then
			local flTotalTraceDistance = penetrationEnd:Distance(tr.HitPos)
			-- extra shit here pls dont forget novus
			self:DisplayPenetrationDebug(tr.HitPos, penetrationEnd, flTotalTraceDistance, fCurrentDamage, flPenWepMod, flTotalLostDamage, tr.SurfaceProps, exitTr.SurfaceProps)
		end

		-- reduce damage each time we hit something other than a grate
		fCurrentDamage = fCurrentDamage - math.max(0, flTotalLostDamage)
		if fCurrentDamage < 1 then
			return true, nPenetrationCount, flPenetration, fCurrentDamage
		end

		-- penetration was successful

		-- bullet did penetrate object, exit Decal
		if owner:IsValid() then
			swcs.BulletImpact(exitTr, owner, iDamageType)
		end

		-- setup new start end parameters for successive trace
		flCurrentDistance = flCurrentDistance + flTraceDistance
		vecSrc:Set(exitTr.HitPos)
		flDistance = (flDistance - flCurrentDistance) * 0.5

		nPenetrationCount = nPenetrationCount - 1
		return false, nPenetrationCount, flPenetration, fCurrentDamage
	elseif sv_penetration_type:GetInt() > 1 then
		-- old penetration method
		-- since some railings in de_inferno are CONTENTS_GRATE but CHAR_TEX_CONCRETE, we'll trust the
		-- CONTENTS_GRATE and use a high damage modifier.

		if bHitGrate or bIsNodraw then
			-- if we're a concrete grate (TOOLS/TOOLSINVISIBLE texture) allow more penetrating power.
			flPenetrationModifier = 1
			flDamageModifier = 0.99
		else
			-- check the exit material to see if it is has less penetration than the entrance material.
			local pen_mat
			if exitSurfaceData then
				pen_mat = swcs.SurfaceInfo[swcs.SurfaceProps[exitTr.SurfaceProps]]
			end

			if not pen_mat then
				pen_mat = swcs.SurfaceInfo.default
			end

			local flExitPenetrationModifier = pen_mat.penmod
			local flExitDamageModifier = pen_mat.dmgmod

			if flExitPenetrationModifier < flPenetrationModifier then
				flPenetrationModifier = flExitPenetrationModifier
			end
			if flExitDamageModifier < flDamageModifier then
				flDamageModifier = flExitDamageModifier
			end
		end

		-- if enter & exit point is wood we assume this is
		-- a hollow crate and give a penetration bonus
		if iEnterMaterial == iExitMaterial then
			if iExitMaterial == MAT_WOOD or iExitMaterial == MAT_METAL then
				flPenetrationModifier = flPenetrationModifier * 2
			end
		end

		local flTraceDistance = exitTr.HitPos:Distance(tr.HitPos)

		--if sv_showimpacts_penetration:GetInt() > 0 then
		--	--debugoverlay.Box(exitTr.HitPos, -Vector(2,2,2), Vector(2,2,2), 8, Color(0, 255, 0, 127))
		--
		--	local flTotalTraceDistance = penetrationEnd:Distance(tr.HitPos)
		--	self:DisplayPenetrationDebug(tr.HitPos, penetrationEnd, flTotalTraceDistance, fCurrentDamage, fCurrentDamage * (1 - flDamageModifier), fCurrentDamage * (1 - flDamageModifier), tr.SurfaceProps, exitTr.SurfaceProps ) -- extra shit here pls dont forget novus
		--end

		-- check if bullet has enough power to penetrate this distance for this material
		if flTraceDistance > (flPenetrationPower * flPenetrationModifier) then
			return true, nPenetrationCount, flPenetration, fCurrentDamage
		end

		-- reduce damage power each time we hit something other than a grate
		fCurrentDamage = fCurrentDamage * flDamageModifier

		-- penetration was successful

		-- bullet did penetrate object, exit Decal
		if owner:IsValid() then
			swcs.BulletImpact(exitTr, owner, iDamageType)
		end

		-- setup new start end parameters for successive trace

		flPenetrationPower = flPenetrationPower - (flTraceDistance / flPenetrationModifier)
		flCurrentDistance = flCurrentDistance + flTraceDistance

		vecSrc:Set(exitTr.HitPos)
		flDistance = (flDistance - flCurrentDistance) * 0.5

		-- reduce penetration counter
		nPenetrationCount = nPenetrationCount - 1
		return false, nPenetrationCount, flPenetration, fCurrentDamage
	end

	return true, nPenetrationCount, flPenetration, fCurrentDamage
end

function SWEP:DisplayPenetrationDebug(vecEnter, vecExit, flDistance, flInitialDamage, flDamageLostImpact, flTotalLostDamage, nEnterSurf, nExitSurf)
	local iShowImpactsPenetration = sv_showimpacts_penetration:GetInt()

	if iShowImpactsPenetration > 0 then
		local vecStart = vecEnter
		local vecEnd = vecExit
		local flTotalTraceDistance = (vecExit - vecEnd):Length()

		if flTotalLostDamage >= flInitialDamage then
			nExitSurf = -100

			local flLostDamageObject = (flTotalLostDamage - flDamageLostImpact)
			local flFrac = math.max(0, (flInitialDamage - flDamageLostImpact) / flLostDamageObject)
			vecEnd = vecEnd - vecStart
			vecEnd:Normalize()
			vecEnd = vecStart + (vecEnd * flTotalTraceDistance * flFrac)

			if flDamageLostImpact >= flInitialDamage then
				flDistance = 0
				vecStart = vecEnd
			end

			flTotalLostDamage = math.ceil(flInitialDamage)
		end

		local textPos = vecEnd * 1
		local text = ""

		if flTotalLostDamage < flInitialDamage then
			local flDistMeters = flDistance * 0.0254
			if flDistMeters >= 1 then
				text = Format("%s%0.1fm", iShowImpactsPenetration == 2 and "" or "THICKNESS:		", flDistMeters)
			else
				text = Format("%s%0.1fcm", iShowImpactsPenetration == 2 and "" or "THICKNESS:		", flDistMeters / 0.01)
			end
		else
			text = "STOPPED!"
		end

		local flTime = sv_showimpacts_time:GetFloat()

		debugoverlay.EntityTextAtPosition(textPos, -3, text, flTime, Color(220, 128, 128, 255))

		local text3 = Format("%s%0.1f", iShowImpactsPenetration == 2 and "-" or "LOST DAMAGE:		", flTotalLostDamage)
		debugoverlay.EntityTextAtPosition(textPos, -2, text3, flTime, Color(90, 22, 0, 160))

		local textmat1 = Format("%s", nEnterSurf and util.GetSurfacePropName(nEnterSurf) or "nil")
		debugoverlay.EntityTextAtPosition(vecStart, -1, textmat1, flTime, Color(0, 255, 0, 128))

		if nExitSurf ~= -100 then
			debugoverlay.Box(vecStart, -Vector(0.4, 0.4, 0.4), Vector(0.4, 0.4, 0.4), flTime, Color(0, 255, 0, 128))

			local textmat2 = Format("%s", nExitSurf and nExitSurf == -1 and "" or (nExitSurf and util.GetSurfacePropName(nExitSurf) or "nil"))
			debugoverlay.Box(vecEnd, -Vector(0.4, 0.4, 0.4), Vector(0.4, 0.4, 0.4), flTime, Color(0, 128, 255, 128))
			debugoverlay.EntityTextAtPosition(vecEnd, -1, textmat2, flTime, Color(0, 128, 255, 128))

			if flDistance > 0 and vecStart ~= vecEnd then
				debugoverlay.Line(vecStart, vecEnd, flTime, Color(0, 190, 190), true)
			end
		else
			-- different color
			debugoverlay.Box(vecStart, -Vector(0.4, 0.4, 0.4), Vector(0.4, 0.4, 0.4), flTime, Color(160, 255, 0, 128))
			debugoverlay.Line(vecStart, vecEnd, flTime, Color(190, 190, 0), true)
		end
	end
end
