AddCSLuaFile()

hook.Add("PlayerTick", "swcs.flashbang", function(ply, mv)
	ply:UpdateFlashBangEffect()
end)

-- PlayerTick isnt called when ply is in a vehicle
hook.Add("VehicleMove", "swcs.flashbang", function(ply, veh, mv)
	ply:UpdateFlashBangEffect()
end)

if CLIENT then
	local m_pFlashTexture
	local lastTimeGrabbed = 0.0
	local overlaycolor = Color(255, 255, 255)

	local DarkMode = CreateClientConVar("swcs_fx_flashbang_dark", "0", true, false, "Enable dark flashbangs")

	local function PerformFlashbangEffect()
		local localPlayer = LocalPlayer()

		local hFlashBangPlayer = NULL
		if localPlayer:GetObserverMode() == OBS_MODE_IN_EYE then
			local target = localPlayer:GetObserverTarget()

			if target:IsPlayer() then
				hFlashBangPlayer = target
			end
		else
			hFlashBangPlayer = localPlayer
		end

		if not hFlashBangPlayer:IsValid() then
			return
		end

		hFlashBangPlayer:UpdateFlashBangEffect()
		local flFlashOverlayAlpha = hFlashBangPlayer:GetNWFloat("FlashOverlayAlpha", 0.0)

		if flFlashOverlayAlpha <= 0.0 then
			return
		end

		local flAlphaScale = 1.0

		local bDarkMode = DarkMode:GetBool()

		local frac = (flFlashOverlayAlpha * flAlphaScale) / 255
		overlaycolor:SetUnpacked(255, 255, 255, 255)

		-- draw the screenshot overlay portion of the flashbang effect
		local pMaterial = Material("effects/flashbang")
		if pMaterial then
			-- This is for handling split screen where we could potentially enter this function more than once a frame.
			-- Since this bit of code grabs both the left and right viewports of the buffer, it only needs to be done once per frame per flash.
			if (CurTime() == lastTimeGrabbed) then
				hFlashBangPlayer.m_bFlashScreenshotHasBeenGrabbed = true
			end

			if (not hFlashBangPlayer.m_bFlashScreenshotHasBeenGrabbed) then
				local nScreenWidth, nScreenHeight = ScrW(), ScrH()

				-- update m_pFlashTexture
				lastTimeGrabbed = CurTime()

				m_pFlashTexture = GetRenderTarget("_rt_FullFrameFB0", nScreenWidth, nScreenHeight)
				render.CopyRenderTargetToTexture(m_pFlashTexture)

				pMaterial:SetTexture("$basetexture", m_pFlashTexture)

				hFlashBangPlayer.m_bFlashScreenshotHasBeenGrabbed = true
			end

			if m_pFlashTexture then
				pMaterial:SetVector("$color", overlaycolor:ToVector())
				pMaterial:SetFloat("$alpha", frac)

				render.SetMaterial(pMaterial)
				for pass = 1, 4 do
					render.DrawScreenQuadEx(0, 0, ScrW(), ScrH())
				end
			end
		end

		-- draw pure white overlay part of the flashbang effect.
		pMaterial = Material("vgui/white")
		if pMaterial then
			overlaycolor:SetUnpacked(
				bDarkMode and 0 or 255,
				bDarkMode and 0 or 255,
				bDarkMode and 0 or 255,
				255
			)
			pMaterial:SetFloat("$alpha", frac)
			pMaterial:SetVector("$color", overlaycolor:ToVector())
			render.SetMaterial(pMaterial)
			render.DrawScreenQuadEx(0, 0, ScrW(), ScrH())
			pMaterial:SetFloat("$alpha", 1)
			pMaterial:SetVector("$color", Vector(1, 1, 1))
		end
	end

	-- yea u can just remove these hooks and no more flashbangs
	-- but pls dont <3
	hook.Add("RenderScreenspaceEffects", "swcs.flashbang", PerformFlashbangEffect)
else
	hook.Add("DoPlayerDeath", "swcs.death", function(ply)
		ply:RemoveHelmet()
		ply:RemoveDefuser()

		local wep = ply:GetActiveWeapon()
		if wep.IsSWCSWeapon and wep.IsGrenade and wep:GetPinPulled() and not wep.m_bHasEmittedProjectile then
			wep:DropGrenade()
			wep:Remove()
		end
	end)

	local rethrow_last_class = ""
	local rethrow_last_pos = Vector()
	local rethrow_last_vel = Vector()
	local rethrow_last_owner = NULL
	local rethrow_last_weapon_factory
	local rethrow_last_dtvars = nil

	hook.Add("PlayerThrowSWCSGrenade", "swcs.sv_rethrow", function(ply, proj)
		rethrow_last_class = proj:GetClass()
		rethrow_last_pos = proj:GetPos()
		rethrow_last_vel = proj:GetInitialVelocity()
		rethrow_last_owner = ply
		rethrow_last_weapon_factory = proj.ItemAttributes
		rethrow_last_dtvars = proj:GetNetworkVars()

		ply.swcs_rethrow_last_class = rethrow_last_class
		ply.swcs_rethrow_last_pos = rethrow_last_pos
		ply.swcs_rethrow_last_vel = rethrow_last_vel
		ply.swcs_rethrow_last_weapon_factory = rethrow_last_weapon_factory
		ply.swcs_rethrow_last_dtvars = rethrow_last_dtvars
	end)

	-- i think it's cvars3 that breaks concommands respecting FCVAR_CHEAT
	-- so check sv_cheats manually
	local sv_cheats = GetConVar("sv_cheats")

	concommand.Add("sv_rethrow_last_swcs_grenade", function(ply)
		if not sv_cheats:GetBool() then return end

		local class, pos, vel, owner, attr, dtVars

		if ply:IsValid() then
			class = ply.swcs_rethrow_last_class
			pos = ply.swcs_rethrow_last_pos
			vel = ply.swcs_rethrow_last_vel
			owner = ply
			attr = ply.swcs_rethrow_last_weapon_factory
			dtVars = ply.swcs_rethrow_last_dtvars
		else
			class = rethrow_last_class
			pos = rethrow_last_pos
			vel = rethrow_last_vel
			owner = rethrow_last_owner
			attr = rethrow_last_weapon_factory
			dtVars = rethrow_last_dtvars
		end

		if not class then return end

		---@class Entity
		local hProjectile = ents.Create(class)

		if not hProjectile:IsValid() then
			return
		end

		hProjectile:RestoreNetworkVars(dtVars --[[@as table]])

		hProjectile.ItemAttributes = attr
		hProjectile:Create(pos, angle_zero, vel, Angle(600, math.Rand(-1200, 1200)), owner)
		hProjectile:Spawn()
	end, nil, "Emit the last grenade thrown on the server.", FCVAR_CHEAT --[[@as FCVAR]])
end

local function traceFilter(ent)
	-- csgo has a check for animations on models, and whether or not the animation has a specific flag
	-- gmod sadly cannot replicate this behavior :(

	-- CTraceFilterNoPlayers(AndFlashbangPassableAnims)
	-- Weapons don't block flashbangs
	local bWeapon = ent:IsWeapon()
	local bGrenade = ent.IsSWCSGrenade

	if bWeapon or bGrenade then
		return false
	end

	-- TraceFilterNoPlayers
	if ent:IsPlayer() then
		return false
	end

	return true
end

local FLASH_FRACTION = 0.167
local SIDE_OFFSET = 75.0

-- CTraceFilterNoPlayersAndFlashbangPassableAnims traceFilter( pevInflictor, COLLISION_GROUP_NONE )
local FLASH_MASK = bit.bor(MASK_OPAQUE_AND_NPCS, CONTENTS_DEBRIS)

-- According to comment in IsNoDrawBrush in cmodel.cpp, CONTENTS_OPAQUE is ONLY used for block light surfaces,
-- and we want flashbang traces to pass through those, since the block light surface is only used for blocking
-- lightmap light rays during map compilation.
FLASH_MASK = bit.band(FLASH_MASK, bit.bnot(CONTENTS_OPAQUE))

function swcs.PercentageOfFlashForPlayer(ply, flashPos, pevInflictor)
	local eyePos = ply:EyePos()
	local pos = Vector(eyePos)
	local vecRight, vecUp = Vector(), Vector()

	local tempAngle = (eyePos - flashPos):Angle()
	vecRight, vecUp = tempAngle:Right(), tempAngle:Up()

	vecRight:Normalize()
	vecUp:Normalize()

	-- Set up all the ray stuff.
	-- We don't want to let other players block the flash bang so we use this custom filter.
	local tr = util.TraceLine({
		start = flashPos,
		endpos = pos,
		mask = FLASH_MASK,
		filter = traceFilter
	})

	if ((tr.Fraction == 1.0) or (tr.Entity == ply)) then
		return 1.0
	end

	local retval = 0.0

	-- check the point straight up.
	pos:Set(flashPos)
	pos:Add(vecUp * 50)
	util.TraceLine({
		start = flashPos,
		endpos = pos,
		mask = FLASH_MASK,
		filter = traceFilter,
		output = tr,
	})

	-- Now shoot it to the player's eye.
	pos:Set(eyePos)
	util.TraceLine({
		start = tr.HitPos,
		endpos = pos,
		mask = FLASH_MASK,
		filter = traceFilter,
		output = tr,
	})

	if ((tr.Fraction == 1.0) or (tr.Entity == ply)) then
		retval = retval + FLASH_FRACTION
	end

	-- check the point up and right.
	pos:Set(flashPos)
	pos:Add(vecRight * SIDE_OFFSET)
	pos:Add(vecUp * 10.0)
	util.TraceLine({
		start = flashPos,
		endpos = pos,
		mask = FLASH_MASK,
		filter = traceFilter,
		output = tr,
	})

	-- Now shoot it to the player's eye.
	pos:Set(eyePos)
	util.TraceLine({
		start = tr.HitPos,
		endpos = pos,
		mask = FLASH_MASK,
		filter = traceFilter,
		output = tr,
	})

	if ((tr.Fraction == 1.0) or (tr.Entity == ply)) then
		retval = retval + FLASH_FRACTION
	end

	-- Check the point up and left.
	pos:Set(flashPos)
	pos:Sub(vecRight * SIDE_OFFSET)
	pos:Add(vecUp * 10.0)
	pos = flashPos - vecRight * SIDE_OFFSET + vecUp * 10.0
	util.TraceLine({
		start = flashPos,
		endpos = pos,
		mask = FLASH_MASK,
		filter = traceFilter,
		output = tr,
	})

	-- Now shoot it to the player's eye.
	pos:Set(eyePos)
	util.TraceLine({
		start = tr.HitPos,
		endpos = pos,
		mask = FLASH_MASK,
		filter = traceFilter,
		output = tr,
	})

	if ((tr.Fraction == 1.0) or (tr.Entity == ply)) then
		retval = retval + FLASH_FRACTION
	end

	return retval
end

function swcs.RadiusFlash(vecSrc, hInflictor, hAttacker, flDamage, iClassIgnore, bitsDamageType)
	vecSrc.z = vecSrc.z + 1 -- in case grenade is lying on the ground

	if not hAttacker:IsValid() then
		hAttacker = hInflictor
	end

	local flRadius = 3000
	local falloff = flDamage / flRadius

	local flAdjustedDamage = 0
	local flDot = 0
	local vecEyePos = Vector()
	local vecLOS = Vector()
	local vForward = Vector()

	local fadeTime, fadeHold = 0, 0

	for _, pEntity in ipairs(ents.FindInSphere(vecSrc, flRadius)) do
		if not pEntity:IsPlayer() then
			continue
		end

		vecEyePos:Set(pEntity:EyePos())

		local percentageOfFlash = swcs.PercentageOfFlashForPlayer(pEntity, vecSrc, hInflictor)
		if percentageOfFlash > 0 then
			flAdjustedDamage = flDamage - (vecSrc - pEntity:EyePos()):Length() * falloff

			if flAdjustedDamage > 0 then
				vForward:Set(pEntity:EyeAngles():Forward())
				vecLOS:Set(vecSrc)
				vecLOS:Sub(vecEyePos)

				local flDistance = vecLOS:Length()

				-- Normalize both vectors so the dotproduct is in the range -1.0 <= x <= 1.0
				vecLOS:Normalize()

				flDot = vecLOS:Dot(vForward)

				-- if target is facing the bomb, the effect lasts longer
				if (flDot >= 0.6) then
					-- looking at the flashbang
					fadeTime = flAdjustedDamage * 2.5
					fadeHold = flAdjustedDamage * 1.25
				elseif (flDot >= 0.3) then
					-- looking to the side
					fadeTime = flAdjustedDamage * 1.75
					fadeHold = flAdjustedDamage * 0.8
				elseif (flDot >= -0.2) then
					-- looking to the side
					fadeTime = flAdjustedDamage * 1.00
					fadeHold = flAdjustedDamage * 0.5
				else
					-- facing away
					fadeTime = flAdjustedDamage * 0.5
					fadeHold = flAdjustedDamage * 0.25
				end

				fadeTime = fadeTime * percentageOfFlash
				fadeHold = fadeHold * percentageOfFlash

				pEntity:SWCS_Blind(fadeHold, fadeTime, 255)
				pEntity:Deafen(flDistance)
			end
		end
	end
end
