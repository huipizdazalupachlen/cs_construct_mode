AddCSLuaFile()

local weapon_air_spread_scale = GetConVar"weapon_air_spread_scale"
local weapon_recoil_decay_coefficient = GetConVar"weapon_recoil_decay_coefficient"
local weapon_accuracy_nospread = GetConVar"weapon_accuracy_nospread"
local weapon_recoil_suppression_shots = CreateConVar("weapon_recoil_suppression_shots", "4")
local weapon_recoil_suppression_factor = CreateConVar("weapon_recoil_suppression_factor", "0.75")
local weapon_recoil_variance = CreateConVar("weapon_recoil_variance", "0.55")

function SWEP:GenerateRecoilTable(data)
	local iSuppressionShots = weapon_recoil_suppression_shots:GetInt()
	local fBaseSuppressionFactor = weapon_recoil_suppression_factor:GetFloat()
	local fRecoilVariance = weapon_recoil_variance:GetFloat()
	local recoilRandom = UniformRandomStream()

	if not data then return end

	local iSeed = 0
	local bHasAttrSeed = false
	local bFullAuto = false
	local bHasAttrFullAuto = false
	local flRecoilAngle = {}
	local bHasAttrRecoilAngle = {}
	local flRecoilAngleVariance = {}
	local bHasAttrRecoilAngleVariance = {}
	local flRecoilMagnitude = {}
	local bHasAttrRecoilMagnitude = {}
	local flRecoilMagnitudeVariance = {}
	local bHasAttrRecoilMagnitudeVariance = {}

	if self.ItemAttributes then
		iSeed = tonumber(self.ItemAttributes["recoil seed"]) or 0
		bFullAuto = tobool(self.ItemAttributes["is full auto"])
		for iMode = 0, 1 do
			local isAlt = iMode == 1 and " alt" or ""

			flRecoilAngle[iMode] = self.ItemAttributes["recoil angle" .. isAlt]
			bHasAttrRecoilAngle[iMode] = self.ItemAttributes["recoil angle" .. isAlt] ~= nil
			flRecoilAngleVariance[iMode] = self.ItemAttributes["recoil angle variance" .. isAlt] or 0
			bHasAttrRecoilAngleVariance[iMode] = true -- self.ItemAttributes["recoil angle variance" .. isAlt] ~= nil
			flRecoilMagnitude[iMode] = self.ItemAttributes["recoil magnitude" .. isAlt] or 0
			bHasAttrRecoilMagnitude[iMode] = true -- self.ItemAttributes["recoil magnitude" .. isAlt] ~= nil
			flRecoilMagnitudeVariance[iMode] = self.ItemAttributes["recoil magnitude variance" .. isAlt] or 0
			bHasAttrRecoilMagnitudeVariance[iMode] = true -- self.ItemAttributes["recoil magnitude variance" .. isAlt] ~= nil
		end

		bHasAttrSeed = iSeed ~= nil
		bHasAttrFullAuto = bFullAuto ~= nil
	end

	if bHasAttrSeed then
		for iMode = 0, 1 do
			data[iMode] = data[iMode] or {}
			--assert(bHasAttrSeed, "no recoil seed attribute")
			assert(bHasAttrFullAuto, "no full auto attribute")

			flRecoilAngle[iMode] = flRecoilAngle[iMode] or 0
			assert(bHasAttrRecoilAngleVariance[iMode], Format("no recoil angle variance attribute on iMode: %d", iMode))
			assert(bHasAttrRecoilMagnitude[iMode], Format("no recoil magnitude attribute on iMode: %d", iMode))
			assert(bHasAttrRecoilMagnitudeVariance[iMode], Format("no recoil magnitude variance attribute on iMode: %d", iMode))

			recoilRandom:SetSeed(iSeed)
			local fAngle = 0
			local fMagnitude = 0

			-- data->recoilTable[64] has 64 elements; [0-63]
			-- start it at 0 just for solidarity
			for j = 0, 63 do
				data[iMode][j] = data[iMode][j] or {}

				local fAngleNew = flRecoilAngle[iMode] + recoilRandom:RandomFloat(-flRecoilAngleVariance[iMode], flRecoilAngleVariance[iMode]);
				local fMagnitudeNew = flRecoilMagnitude[iMode] + recoilRandom:RandomFloat(-flRecoilMagnitudeVariance[iMode], flRecoilMagnitudeVariance[iMode]);

				if (bFullAuto and (j > 0)) then
					fAngle = Lerp(fRecoilVariance, fAngle, fAngleNew)
					fMagnitude = Lerp(fRecoilVariance, fMagnitude, fMagnitudeNew)
				else
					fAngle = fAngleNew
					fMagnitude = fMagnitudeNew
				end

				if (bFullAuto and (j < iSuppressionShots)) then
					local fSuppressionFactor = Lerp(j / iSuppressionShots, fBaseSuppressionFactor, 1.0);
					fMagnitude = fMagnitude * fSuppressionFactor;
				end

				data[iMode][j].fAngle = fAngle;
				data[iMode][j].fMagnitude = fMagnitude;
			end
		end
	end
end

-- csgo originally has this at 1.1
-- i have it at 1.25 because some servers have low tickrate, which causes erroneous decay
local WEAPON_RECOIL_DECAY_THRESHOLD = 1.25
local LOG_10 = math.log(10)
function SWEP:UpdateAccuracyPenalty()
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	local selfTable = self:GetTable()
	local fNewPenalty = 0

	if owner:GetMoveType() == MOVETYPE_LADDER then
		fNewPenalty = fNewPenalty + selfTable.GetInaccuracyLadder(self)
	elseif not owner:IsFlagSet(FL_ONGROUND) then
		fNewPenalty = fNewPenalty + selfTable.GetInaccuracyStand(self)
		fNewPenalty = fNewPenalty + selfTable.GetInaccuracyJump(self) * weapon_air_spread_scale:GetFloat()
	elseif owner:IsFlagSet(FL_DUCKING) then
		fNewPenalty = fNewPenalty + selfTable.GetInaccuracyCrouch(self)
	else
		fNewPenalty = fNewPenalty + selfTable.GetInaccuracyStand(self)
	end

	if selfTable.GetInReload(self) then
		fNewPenalty = fNewPenalty + selfTable.GetInaccuracyReload(self)
	end

	local accuracyPenalty = selfTable.GetAccuracyPenalty(self, false)
	if fNewPenalty > accuracyPenalty then
		selfTable.SetAccuracyPenalty(self, fNewPenalty)
	else
		local fDecayFactor = LOG_10 / math.max(selfTable.GetRecoveryTime(self), 0.001)
		selfTable.SetAccuracyPenalty(self, Lerp(math.exp(FrameTime() * -fDecayFactor), fNewPenalty, accuracyPenalty))
	end

	-- Decay the recoil index if a little more than cycle time has elapsed since the last shot. In other words,
	-- don't decay if we're firing full-auto.
	local curtime = CurTime()
	if SWCS_DEBUG_RECOIL_DECAY:GetBool() then
		print("should decay?",
			self, selfTable.GetRecoilIndex(self),
			self:GetLastShotTime() + (self:GetCycleTime() * WEAPON_RECOIL_DECAY_THRESHOLD) < curtime,
			self:GetCycleTime() * WEAPON_RECOIL_DECAY_THRESHOLD,
			curtime - self:GetLastShotTime())
	end
	if selfTable.GetLastShotTime(self) + (selfTable.GetCycleTime(self) * WEAPON_RECOIL_DECAY_THRESHOLD) < curtime then
		local fDecayFactor = LOG_10 * weapon_recoil_decay_coefficient:GetFloat()
		selfTable.SetRecoilIndex(self, math.exp(FrameTime() * -fDecayFactor) * selfTable.GetRecoilIndex(self))
	end
end

function SWEP:GetRecoveryTime()
	local owner = self:GetOwner()
	if not owner:IsValid() then return -1 end

	if owner:GetMoveType() == MOVETYPE_LADDER then
		return self:GetRecoveryTimeStand()
	elseif not owner:IsFlagSet(FL_ONGROUND) then -- in air
		return self:GetRecoveryTimeCrouch()
	elseif owner:IsFlagSet(FL_DUCKING) then
		local flRecoveryTime = self:GetRecoveryTimeCrouch()
		local flRecoveryTimeFinal = self:GetRecoveryTimeCrouchFinal()

		if flRecoveryTimeFinal ~= -1 then
			local nRecoilIndex = math.floor(self:GetRecoilIndex())

			flRecoveryTime = swcs.RemapClamped(nRecoilIndex, self:GetRecoveryTransitionStartBullet() or 0, self:GetRecoveryTransitionEndBullet() or 0, flRecoveryTime, flRecoveryTimeFinal)
		end

		return flRecoveryTime
	else
		local flRecoveryTime = self:GetRecoveryTimeStand()
		local flRecoveryTimeFinal = self:GetRecoveryTimeStandFinal()

		if flRecoveryTimeFinal ~= -1 then
			local nRecoilIndex = math.floor(self:GetRecoilIndex())

			flRecoveryTime = swcs.RemapClamped(nRecoilIndex, self:GetRecoveryTransitionStartBullet() or 0, self:GetRecoveryTransitionEndBullet() or 0, flRecoveryTime, flRecoveryTimeFinal)
		end

		return flRecoveryTime
	end
end

local CS_PLAYER_SPEED_DUCK_MODIFIER = .34
local MOVEMENT_CURVE01_EXPONENT = .25
local weapon_accuracy_forcespread = GetConVar"weapon_accuracy_forcespread"
function SWEP:GetInaccuracy(bInterpolate)
	local owner = self:GetOwner()
	if not owner:IsValid() then return 0 end
	if weapon_accuracy_nospread:GetBool() then return 0 end
	if weapon_accuracy_forcespread:GetFloat() > 0 then return weapon_accuracy_forcespread:GetFloat() end

	local selfTable = self:GetTable()
	local bIsPlayer = owner:IsPlayer()

	local fMaxSpeed = selfTable.GetMaxSpeed(self)
	local fAccuracy = selfTable.GetAccuracyPenalty(self, bInterpolate)

	local velocity = (owner:IsNPC() and not owner:IsNextBot()) and owner:GetMoveVelocity() or owner:GetVelocity()

	local flVerticalSpeed = math.abs(velocity.z)

	-- Adding movement penalty here results in an instaneous penalty that doesn't persist.
	local flMovementInaccuracyScale = swcs.RemapClamped(velocity:Length2D(),
		fMaxSpeed * CS_PLAYER_SPEED_DUCK_MODIFIER,
		fMaxSpeed * .95, -- max out at 95% of run speed to avoid jitter near max speed
		0, 1)

	if flMovementInaccuracyScale > 0 then
		-- power curve only applies at speeds greater than walk
		if bIsPlayer and not owner:KeyDown(IN_WALK) then
			flMovementInaccuracyScale = math.pow(flMovementInaccuracyScale, MOVEMENT_CURVE01_EXPONENT)
		end

		fAccuracy = fAccuracy + (flMovementInaccuracyScale * selfTable.GetInaccuracyMove(self))
	end

	-- If we are in the air/on ladder, add inaccuracy based on vertical speed (maximum accuracy at apex of jump)
	if bIsPlayer and not owner:IsFlagSet(FL_ONGROUND) then
		local flInaccuracyJumpInitial = selfTable.GetInaccuracyJumpInitial(self) * weapon_air_spread_scale:GetFloat()
		local flInaccuracyJumpApex = selfTable.GetInaccuracyJumpApex(self) * weapon_air_spread_scale:GetFloat()

		-- Use sqrt here to make the curve more "sudden" around the accurate point at the apex of the jump
		local fSqrtMaxJumpSpeed = math.sqrt(owner:GetJumpPower()) -- sv_jump_impulse:GetFloat()
		local fSqrtVerticalSpeed = math.sqrt(flVerticalSpeed)

		local flAirSpeedInaccuracy = math.Remap(fSqrtVerticalSpeed,
			fSqrtMaxJumpSpeed * 0.25, -- Anything less than 6.25% of maximum speed has no additional accuracy penalty for z-motion (6.25% = .25 * .25)
			fSqrtMaxJumpSpeed, -- Penalty at max jump speed
			flInaccuracyJumpApex, -- Movement-penalty when close to stopped
			flInaccuracyJumpInitial -- Movement-penalty at start of jump
		)

		-- static const float kMaxFallingPenalty = 2.0f; // Accuracy is never worse than 2x starting penalty
		-- Clamp to min/max values.  (Don't use RemapValClamped because it makes clamping to > kJumpMovePenalty hard)
		if flAirSpeedInaccuracy < 0 then
			flAirSpeedInaccuracy = 0
		elseif flAirSpeedInaccuracy > flInaccuracyJumpInitial * 2 then
			flAirSpeedInaccuracy = flInaccuracyJumpInitial * 2
		end

		-- Apply air velocity inaccuracy penalty
		-- (There is an additional penalty for being in the air at all applied in UpdateAccuracyPenalty())
		fAccuracy = fAccuracy + flAirSpeedInaccuracy
	end

	return math.min(fAccuracy, 1)
end

function SWEP:GetRecoilOffset(iMode, iIndex)
	local data = self.m_RecoilData
	if not data or table.IsEmpty(data) then
		ErrorNoHalt("[SWCS] Generating recoil table too late")

		data = {}
		self.m_RecoilData = data
		self:GenerateRecoilTable(data)
	end

	iIndex = iIndex % 63

	local elem = data[iMode][iIndex]
	if elem then
		return elem.fAngle, elem.fMagnitude
	else
		return 0, 0
	end
end

local weapon_recoil_view_punch_extra = GetConVar"weapon_recoil_view_punch_extra"
function SWEP:Recoil(iMode)
	local owner = self:GetPlayerOwner()
	if not owner then return end

	if SWCS_DEBUG_RECOIL:GetBool() then
		print(Format("recoiling on %s index: %f", self, self:GetRecoilIndex()))
	end

	local iIndex = math.floor(self:GetRecoilIndex())
	local fAngle, fMagnitude = self:GetRecoilOffset(iMode, iIndex)

	local angleVel = Angle()
	angleVel.y = -math.sin(math.rad(fAngle)) * fMagnitude
	angleVel.p = -math.cos(math.rad(fAngle)) * fMagnitude
	angleVel = angleVel + self:GetAimPunchAngleVel()
	self:SetAimPunchAngleVel(angleVel)

	-- this bit gives additional punch to the view (screen shake) to make the kick back a bit more visceral
	local viewPunch = self:GetUninterpolatedViewPunchAngle()
	local fViewPunchMagnitude = fMagnitude * weapon_recoil_view_punch_extra:GetFloat()
	viewPunch.y = viewPunch.y - math.sin(math.rad(fAngle)) * fViewPunchMagnitude
	viewPunch.p = viewPunch.p - math.cos(math.rad(fAngle)) * fViewPunchMagnitude
	viewPunch:Normalize()

	self:SetViewPunchAngle(viewPunch)
end

-- decay angles in PlayerMove()
local weapon_recoil_scale = GetConVar("weapon_recoil_scale")
function SWEP:OnMove(ply, move, cmd, selfTable)
	selfTable = selfTable or self:GetTable()

	selfTable.DecayViewPunchAngle(self)
	selfTable.DecayAimPunchAngle(self)

	-- we have this set on a NWFloat so that gmod can network it to other players without doing any dumb lua net messages
	self:SetNW2Float("m_flThirdpersonRecoil", selfTable.GetAimPunchP(self) * weapon_recoil_scale:GetFloat())

	selfTable.UpdateAccuracyPenalty(self)
end

local sqrt = math.sqrt
local ANGLE = FindMetaTable("Angle")
---@diagnostic disable: need-check-nil
local AMul = ANGLE.Mul
local AZero = ANGLE.Zero
local AUnpack = ANGLE.Unpack
---@diagnostic enable: need-check-nil

local function DecayAngles(v, fExp, fLin, dT)
	fExp = fExp * dT
	fLin = fLin * dT

	AMul(v, math.exp(-fExp))

	local x, y, z = AUnpack(v)
	local fMag = sqrt(x * x + y * y + z * z) --v:Length()
	if fMag > 0.1 and fMag > fLin then
		AMul(v, 1 - fLin / fMag)
	else
		AZero(v)
	end
end

local view_punch_decay = CreateConVar("view_punch_decay", "18", nil, "Decay factor exponent for view punch")
function SWEP:DecayViewPunchAngle()
	local punchAng = self:GetUninterpolatedViewPunchAngle()
	punchAng:Normalize()

	DecayAngles(punchAng, view_punch_decay:GetFloat(), 0, FrameTime())
	punchAng:Normalize()

	self:SetViewPunchAngle(punchAng)
end

local weapon_recoil_decay2_exp = CreateConVar("weapon_recoil_decay2_exp", "8", nil, "Decay factor exponent for weapon recoil")
local weapon_recoil_decay2_lin = CreateConVar("weapon_recoil_decay2_lin", "18", nil, "Decay factor (linear term) for weapon recoil")
local weapon_recoil_vel_decay = CreateConVar("weapon_recoil_vel_decay", "4.5", nil, "Decay factor for weapon recoil velocity")
function SWEP:DecayAimPunchAngle()
	local punchAng = self:GetUninterpolatedRawAimPunchAngle()
	local punchAngVel = self:GetAimPunchAngleVel()
	punchAng:Normalize()
	punchAngVel:Normalize()

	DecayAngles(punchAng, weapon_recoil_decay2_exp:GetFloat(), weapon_recoil_decay2_lin:GetFloat(), FrameTime())
	punchAng:Normalize()

	punchAng:Add(punchAngVel * FrameTime() * .5)

	punchAngVel:Mul(math.exp(FrameTime() * -weapon_recoil_vel_decay:GetFloat()))

	punchAng:Add(punchAngVel * FrameTime() * .5)

	punchAng:Normalize()
	punchAngVel:Normalize()

	self:SetRawAimPunchAngle(punchAng)
	self:SetAimPunchAngleVel(punchAngVel)
end

function SWEP:OnLand(fVelocity)
	local fPenalty = self:GetInaccuracyLand() * fVelocity
	self:SetAccuracyPenalty(self:GetAccuracyPenalty(false) + fPenalty)
	fPenalty = math.Clamp(fPenalty, -1, 1)

	local owner = self:GetPlayerOwner()
	if not owner then return end

	-- NOTE: do NOT call GetAimPunchAngle() here because it may be adjusted by some recoil scalar.
	-- We just want to update the raw punch angle.
	local angle = self:GetUninterpolatedRawAimPunchAngle()
	local fVKick = math.deg(math.asin(fPenalty)) * 0.2
	local fHKick = util.SharedRandom("LandPunchAngleYaw", -1.0, 1.0) * fVKick * 0.1

	angle.x = angle.x + fVKick -- pitch
	angle.y = angle.y + fHKick -- yaw

	self:SetRawAimPunchAngle(angle)
end
