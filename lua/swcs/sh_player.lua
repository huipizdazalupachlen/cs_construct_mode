AddCSLuaFile()
---@diagnostic disable: need-check-nil

local PLAYER = FindMetaTable("Player")

if CLIENT then
	local fov_desired = GetConVar("fov_desired")
	function PLAYER:GetDefaultFOV()
		return fov_desired:GetInt()
	end
else
	function PLAYER:GetDefaultFOV()
		return self:GetInternalVariable("m_iDefaultFOV")
	end
end

function PLAYER:Deafen(flDistance)
	-- Spectators don't get deafened
	if self:GetObserverMode() == OBS_MODE_NONE or self:GetObserverMode() == OBS_MODE_IN_EYE then
		-- dsp presets are defined in hl2/scripts/dsp_presets.txt

		local effect

		if (flDistance < 100) then
			effect = 35
		elseif (flDistance < 500) then
			effect = 36
		elseif (flDistance < 1000) then
			effect = 37
		else
			-- too far for us to get an effect
			return
		end

		self:SetDSP(effect, false)

		-- TODO: bots can't hear sound for a while?
	end
end

function PLAYER:SWCS_Blind(holdTime, fadeTime, startingAlpha)
	-- estimate when we can see again
	local oldBlindUntilTime = self:GetNWFloat("BlindUntilTime", 0)
	local oldBlindStartTime = self:GetNWFloat("BlindStartTime", 0)
	self:SetNWFloat("BlindUntilTime", math.max(self:GetNWFloat("BlindUntilTime", 0), CurTime() + holdTime + 0.5 * fadeTime))
	self:SetNWFloat("BlindStartTime", CurTime())

	fadeTime = fadeTime / 1.4

	if (CurTime() > oldBlindUntilTime) then
		-- The previous flashbang is wearing off, or completely gone
		self:SetNW2Float("FlashDuration", fadeTime)
		self:SetNWFloat("FlashMaxAlpha", startingAlpha)
	else
		-- The previous flashbang is still going strong - only extend the duration
		local remainingDuration = oldBlindStartTime + self:GetNW2Float("FlashDuration", 0) - CurTime()

		local flNewDuration = math.max(remainingDuration, fadeTime)

		-- The flashbang client effect runs off a network var change callback... Make sure the bits for duration get
		-- sent by changing it a tiny bit whenever these end up being equal.
		if (self:GetNW2Float("FlashDuration", 0) == flNewDuration) then
			flNewDuration = flNewDuration + 0.01
		end

		-- HACK: fix for gmod not networking the update
		self:SetNW2Float("FlashDuration", flNewDuration * 0.9)
		self:SetNW2Float("FlashDuration", flNewDuration)
		self:SetNWFloat("FlashMaxAlpha", math.max(self:GetNWFloat("FlashMaxAlpha", 0), startingAlpha))
	end
end

function PLAYER:SWCS_Unblind()
	self:SetNW2Float("FlashDuration", 0.0)
	self:SetNWFloat("FlashMaxAlpha", 0.0)
end

function PLAYER:ClearFlashbangScreenFade()
	if self:IsBlinded() then
		local clr = Color(0, 0, 0, 0)
		self:ScreenFade(bit.bor(SCREENFADE.OUT, SCREENFADE.PURGE), clr, 0.01, 0.0)

		self:SetNW2Float("FlashDuration", 0.0)
		self:SetNWFloat("FlashMaxAlpha", 255.0)
	end

	-- clear blind time (after screen fades are canceled )
	self:SetNWFloat("BlindUntilTime", 0.0)
	self:SetNWFloat("BlindStartTime", 0.0)
end

function PLAYER:GetLastWeapon()
	return self:GetInternalVariable("m_hLastWeapon")
end

function PLAYER:SWCS_IsFlashBangActive()
	return (self:GetNW2Float("FlashDuration", 0.0) > 0.0) and (CurTime() < self:GetNWFloat("FlashBangTime", 0.0))
end

function PLAYER:SWCS_IsFlashBangBuildUpActive()
	return self:GetNWBool("FlashBuildUp", false) and self:SWCS_IsFlashBangActive()
end

function PLAYER:SWCS_GetFlashStartTime()
	return self:GetNWFloat("FlashBangTime", 0.0) - self:GetNW2Float("FlashDuration", 0.0)
end

function PLAYER:SWCS_GetFlashTimeElapsed()
	return math.max(CurTime() - self:SWCS_GetFlashStartTime(), 0.0)
end

function PLAYER:IsBlinded()
	return (self:GetNWFloat("FlashBangTime", 0.0) - 1.0) > CurTime()
end

local certainBlindnessTimeThresh = 3.0 -- yes this is a magic number, necessary to match CS/CZ flashbang effectiveness cause the rendering system is completely different.

function PLAYER:UpdateFlashBangEffect()
	if self:GetNWFloat("FlashBangTime", 0.0) < CurTime() or self:GetNWFloat("FlashMaxAlpha", 0) <= 0.0 then
		-- FlashBang is inactive
		self:SetNW2Float("FlashDuration", 0.0)
		return
	end

	local FLASH_BUILD_UP_PER_FRAME = 45.0
	local FLASH_BUILD_UP_DURATION = (255.0 / FLASH_BUILD_UP_PER_FRAME) * (1.0 / 60.0)

	local flFlashTimeElapsed = self:SWCS_GetFlashTimeElapsed()

	--print("UPDATE")

	if self:GetNWBool("FlashBuildUp", false) then
		-- build up
		self:SetNWFloat("FlashScreenshotAlpha",
			math.Clamp(
				(flFlashTimeElapsed / FLASH_BUILD_UP_DURATION) * self:GetNWFloat("FlashMaxAlpha", 0),
				0.0,
				self:GetNWFloat("FlashMaxAlpha", 0)
			)
		)
		self:SetNWFloat("FlashOverlayAlpha", self:GetNWFloat("FlashScreenshotAlpha", 0.0))

		if flFlashTimeElapsed >= FLASH_BUILD_UP_DURATION then
			self:SetNWBool("FlashBuildUp", false)
		end
	else
		-- cool down
		local flFlashTimeLeft = self:GetNWFloat("FlashBangTime", 0.0) - CurTime()
		self:SetNWFloat("FlashScreenshotAlpha", (self:GetNWFloat("FlashMaxAlpha", 0) * flFlashTimeLeft) / self:GetNW2Float("FlashDuration", 0.0))
		self:SetNWFloat("FlashScreenshotAlpha",
			math.Clamp(
				(self:GetNWFloat("FlashMaxAlpha", 0) * flFlashTimeLeft) / self:GetNW2Float("FlashDuration", 0.0),
				0.0,
				self:GetNWFloat("FlashMaxAlpha", 0)
			)
		)

		local flAlphaPercentage = 1.0

		if (flFlashTimeLeft > certainBlindnessTimeThresh) then
			-- if we still have enough time of blindness left, make sure the player can't see anything yet.
			flAlphaPercentage = 1.0
		else
			-- blindness effects shorter than 'certainBlindness`TimeThresh' will start off at less than 255 alpha.
			flAlphaPercentage = flFlashTimeLeft / certainBlindnessTimeThresh

			-- reduce alpha level quicker with dx 8 support and higher to compensate
			-- for having the burn-in effect.
			flAlphaPercentage = flAlphaPercentage * flAlphaPercentage
		end

		flAlphaPercentage = flAlphaPercentage * self:GetNWFloat("FlashMaxAlpha", 0)
		self:SetNWFloat("FlashOverlayAlpha", flAlphaPercentage) -- scale a [0..1) value to a [0..MaxAlpha] value for the alpha.

		-- make sure the alpha is in the range of [0..MaxAlpha]
		self:SetNWFloat("FlashOverlayAlpha", math.Clamp(self:GetNWFloat("FlashOverlayAlpha", 0.0), 0.0, self:GetNWFloat("FlashMaxAlpha", 0)))
	end
end

function PLAYER:GetButtons()
	return self:GetInternalVariable("m_nButtons")
end

function PLAYER:SetButtons(buts)
	return self:SetInternalVariable("m_nButtons", buts)
end

function PLAYER:HasHelmet()
	return self:GetNWBool("SWCS.Helmet", false)
end

function PLAYER:GiveHelmet()
	self:SetNWBool("SWCS.Helmet", true)
end

function PLAYER:RemoveHelmet()
	self:SetNWBool("SWCS.Helmet", false)
end

function PLAYER:HasDefuser()
	return self:GetNWBool("SWCS.Defuser", false)
end

function PLAYER:GiveDefuser()
	self:SetNWBool("SWCS.Defuser", true)
end

function PLAYER:RemoveDefuser()
	self:SetNWBool("SWCS.Defuser", false)
end

local function setup_proxy(lp)
	lp:SetNW2VarProxy("FlashDuration", function(ply, _, old, flNewFlashDuration)
		ply:SetNWBool("FlashBuildUp", false)

		if flNewFlashDuration == 0.0 then
			-- Disable flashbang effect
			ply:SetNWFloat("FlashScreenshotAlpha", 0.0)
			ply:SetNWFloat("FlashOverlayAlpha", 0.0)
			ply:SetNWBool("FlashBuildUp", false)
			ply.m_bFlashScreenshotHasBeenGrabbed = false
			ply:SetNWFloat("FlashBangTime", 0.0)
			--ply:SetNWBool("FlashDspHasBeenCleared", false)
			return
		end

		if flNewFlashDuration > 0.0 and old == flNewFlashDuration then
			-- Ignore this update. This is a resend from the server
			return
		end

		-- If local player is spectating in mode other than first-person, reduce effect duration by half
		if ply:GetObserverMode() ~= OBS_MODE_NONE and ply:GetObserverMode() ~= OBS_MODE_IN_EYE then
			flNewFlashDuration = flNewFlashDuration * 0.5
		end

		if not ply:SWCS_IsFlashBangActive() and flNewFlashDuration > 0.0 then
			-- reset flash alpha to start of effect build-up
			ply:SetNWFloat("FlashScreenshotAlpha", 1.0)
			ply:SetNWFloat("FlashOverlayAlpha", 1.0)
			ply:SetNWBool("FlashBuildUp", true)
			ply.m_bFlashScreenshotHasBeenGrabbed = false
		end

		--ply:SetNWFloat("FlashDuration", flNewFlashDuration)
		ply:SetNWFloat("FlashBangTime", CurTime() + flNewFlashDuration)
		ply:SetNWBool("FlashDspHasBeenCleared", false)
	end)

	-- hack to call the proxy above, setting up our flashbang
	timer.Simple(0, function()
		if lp:IsValid() then
			lp:SetNW2Float("FlashDuration", lp:GetNW2Float("FlashDuration", 0.0))
		end
	end)
end

if CLIENT then
	if LocalPlayer():IsValid() then
		setup_proxy(LocalPlayer())
	else
		hook.Add("InitPostEntity", "swcs.nwvar_proxy", function()
			setup_proxy(LocalPlayer())
		end)
	end
elseif SERVER then
	hook.Add("PlayerInitialSpawn", "swcs.nwvar_proxy", function(ply)
		setup_proxy(ply)
	end)

	for _, ply in ipairs(player.GetAll()) do
		setup_proxy(ply)
	end
end

hook.Add("StartCommand", "swcs.cmd", function(ply, cmd)
	local cmd_num = cmd:CommandNumber()
	if cmd_num ~= 0 then
		ply.m_LastUserCommand = cmd
		ply.m_LastUserCommandNumber = cmd_num
	end

	if ply:GetNWBool("m_bIsDefusing", false) then
		cmd:RemoveKey(IN_ATTACK)
	end

	if SERVER and not cmd:IsForced() and not ply.swcs_net_init then
		ply.swcs_net_init = true

		timer.Simple(1, function()
			if ply:IsValid() then
				swcs.RequestCrosshairCode(ply)
			end
		end)
	end
end)

if CLIENT then
	hook.Add("PreventScreenClicks", "swcs.defusing", function()
		local lp = LocalPlayer()
		if lp:GetNWBool("m_bIsDefusing", false) then
			return true
		end
	end)
else
	-- EntityDroppedWeapon*; this is also called by NPCs from CBaseCombatCharacter::Weapon_Drop
	hook.Add("PlayerDroppedWeapon", "swcs.drop_wep", function(ent, wep)
		if not ent:IsValid() then return end
		if not wep.IsSWCSWeapon then return end

		if ent:IsPlayer() then
			if ent:GetFOV() ~= ent:GetDefaultFOV() then
				ent:SetFOV(0, 0.05)
			end
		else
			-- for some reasons NPCs will set clip1 to wep.Primary.DefaultClip when dropping SWEPs
			-- many of our weapons give reserve ammo upon equipping, so we need to clamp the value
			wep:SetClip1(math.min(wep:Clip1(), wep:GetMaxClip1()))
		end
	end)
end
