AddCSLuaFile()

-- this entity only exists to network the ironsight controller to clients holding/spectating the weapon

ENT.Type = "anim" -- because point entities dont transmit to clients at all :)
ENT.Spawnable = false

ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "AttachedWeapon")

	--self:NetworkVar("Bool", 0, "IronSightAvailable")

	self:NetworkVar("Float", 0, "IronSightAmount")
	self:NetworkVar("Float", 1, "IronSightPullUpSpeed")
	self:NetworkVar("Float", 2, "IronSightPutDownSpeed")
	self:NetworkVar("Float", 3, "IronSightFOV")
	self:NetworkVar("Float", 4, "IronSightPivotForward")
	self:NetworkVar("Float", 5, "IronSightLooseness")
	self:NetworkVar("Float", 6, "IronSightAmountGained")
	self:NetworkVar("Float", 7, "IronSightAmountBiased")
	self:NetworkVar("Float", 8, "DotBlur")
	self:NetworkVar("Float", 9, "SpeedRatio")

	self:NetworkVar("Vector", 0, "ScopePos")

	self:NetworkVar("Angle", 0, "PivotAngle")

	self:SetIronSightAmount(0.0)
	self:SetIronSightPullUpSpeed(8.0)
	self:SetIronSightPutDownSpeed(4.0)
	self:SetIronSightFOV(80.0)
	self:SetIronSightPivotForward(10.0)
	self:SetIronSightLooseness(0.5)

	self:SetDotBlur(0)

	-- interpolate IronSightAmount
	do
		swcs.DefineInterpolatedVar(self, "m_flIronSightAmount", "IronSightAmount", true)
		swcs.DefineInterpolatedVar(self, "m_flIronSightAmountGained", "IronSightAmountGained", true)
		swcs.DefineInterpolatedVar(self, "m_flIronSightAmountBiased", "IronSightAmountBiased", true)
		self.m_flIronSightAmountLast = 0.0
		self.m_flIronSightAmountGainedLast = 0.0
		self.m_flIronSightAmountBiasedLast = 0.0
	end

	-- interpolate SpeedRatio
	do
		swcs.DefineInterpolatedVar(self, "m_flSpeedRatio", "SpeedRatio", true)
		self.m_flSpeedRatioLast = 0.0
	end
end

local Approach = swcs.Approach
local Gain = swcs.Gain
local Bias = swcs.Bias

AccessorFunc(ENT, "m_bIronSightAvailable", "IronSightAvailable", FORCE_BOOL)
ENT.m_bIronSightAvailable = false

function ENT:Draw() end

-- when entity is created
function ENT:Initialize()
	self:SetTransmitWithParent(true)

	if CLIENT then
		self:SetNoDraw(true)
	end
	self:DrawShadow(false)

	self:SetMoveType(MOVETYPE_NONE)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	self:SetSolid(SOLID_NONE)
end

hook.Add("PlayerTick", "swcs.ironsight", function(ply)
	local wep = ply:GetActiveWeapon()

	if wep:IsValid() and wep.IsSWCSWeapon then
		local iron = wep:GetIronSightController()
		if iron:IsValid() and iron.PredictedThink then
			iron:PredictedThink()
		end
	end
end)

function ENT:PredictedThink()
	self:UpdateIronSightAmount()

	local frametime = FrameTime()

	--dampen dot blur
	self:SetDotBlur(Approach(0, self:GetDotBlur(), frametime))

	local wep = self:GetAttachedWeapon()
	if wep:GetPlayerOwner() then
		local ply = wep:GetPlayerOwner()

		self:SetSpeedRatio(Approach(
			ply:GetVelocity():Length() / wep:GetMaxSpeed(),
			self:GetSpeedRatio(false),
			frametime * 10)
		)
	end
end

-- client only
ENT.m_angDeltaAverage = {}
ENT.m_angViewLast = Angle()
ENT.m_vecDotCoords = Vector()
--ENT.m_flDotBlur						= 0.0
--ENT.m_flSpeedRatio					= 0.0

local IRONSIGHT_ANGLE_AVERAGE_SIZE = 8
local IRONSIGHT_ANGLE_AVERAGE_DIVIDE = 1 / IRONSIGHT_ANGLE_AVERAGE_SIZE

local IronSight_should_approach_unsighted = 0
local IronSight_should_approach_sighted = 1
local IronSight_viewmodel_is_deploying = 2
local IronSight_weapon_is_dropped = 3

local IRONSIGHT_HIDE_CROSSHAIR_THRESHOLD = 0.5

local IRONSIGHT_VIEWMODEL_BOB_MULT_X = 0.05
local IRONSIGHT_VIEWMODEL_BOB_PERIOD_X = 6
local IRONSIGHT_VIEWMODEL_BOB_MULT_Y = 0.1
local IRONSIGHT_VIEWMODEL_BOB_PERIOD_Y = 10

function ENT:IsApproachingSighted()
	local wep = self:GetAttachedWeapon()
	return wep:IsValid() and wep:GetIronSightMode() == IronSight_should_approach_sighted
end
function ENT:IsApproachingUnSighted()
	local wep = self:GetAttachedWeapon()
	return wep:IsValid() and wep:GetIronSightMode() == IronSight_should_approach_unsighted
end
function ENT:IsDeploying()
	local wep = self:GetAttachedWeapon()
	return wep:IsValid() and wep:GetIronSightMode() == IronSight_viewmodel_is_deploying
end
function ENT:IsDropped()
	local wep = self:GetAttachedWeapon()
	return wep:IsValid() and wep:GetIronSightMode() == IronSight_weapon_is_dropped
end

function ENT:UpdateIronSightAmount()
	if not self:GetAttachedWeapon():IsValid() or self:IsDropped() or self:IsDeploying() then
		-- ignore and discard any lingering ironsight amount.
		self:SetIronSightAmount(0)
		self:SetIronSightAmountGained(0)
		self:SetIronSightAmountBiased(0)
		return
	end

	-- first determine if we are going into or out of ironsights, and set m_flIronSightAmount accordingly
	local flIronSightAmountTarget = self:IsApproachingSighted() and 1.0 or 0.0
	local flIronSightUpdOrDownSpeed = self:IsApproachingSighted() and self:GetIronSightPullUpSpeed() or self:GetIronSightPutDownSpeed()

	-- LUA: magic scalar by 0.5 bc it feels off when at 100% frametime speed
	local val = Approach(flIronSightAmountTarget, self:GetIronSightAmount(false), FrameTime() * flIronSightUpdOrDownSpeed)

	self:SetIronSightAmount(val)
	self:SetIronSightAmountGained(Gain(val, 0.8))
	self:SetIronSightAmountBiased(Bias(val, 0.2))
end

function ENT:IsInIronSight()
	local wep = self:GetAttachedWeapon()
	if wep:IsValid() then
		if self:IsDeploying() or
			self:IsDropped() or
			wep:GetInReload() or
			wep:GetDoneSwitchingSilencer() >= CurTime() then
			return false
		end

		-- if looking at wep, return false

		if self:GetIronSightAmount() > 0 and (self:IsApproachingSighted() or self:IsApproachingUnSighted()) then
			return true
		end
	end

	return false
end

local function AngleDiff(destAngle, srcAngle)
	local delta = math.fmod(destAngle - srcAngle, 360)
	if destAngle > srcAngle then
		if delta >= 180 then
			delta = delta - 360
		end
	else
		if delta <= -180 then
			delta = delta + 360
		end
	end

	return delta
end

local function QAngleDiff(angTarget, angSrc)
	return Angle(
		AngleDiff(angTarget.x, angSrc.x),
		AngleDiff(angTarget.y, angSrc.y),
		AngleDiff(angTarget.z, angSrc.z)
	)
end

function ENT:AddToAngleAverage(newAngle)
	if self:GetIronSightAmount() < 1 then return end

	local newX, newY, newZ = newAngle:Unpack()
	newAngle:SetUnpacked(
		math.Clamp(newX, -2, 2),
		math.Clamp(newY, -2, 2),
		math.Clamp(newZ, -2, 2)
	)

	local angDeltaAverage = self.m_angDeltaAverage
	table.insert(angDeltaAverage, 1, newAngle)

	if #angDeltaAverage > IRONSIGHT_ANGLE_AVERAGE_SIZE then
		table.remove(angDeltaAverage)
	end
end

function ENT:GetAngleAverage()
	local temp = Angle()

	if self:GetIronSightAmount() < 1 then return temp end

	local deltaAvg = self.m_angDeltaAverage

	for i = 1, IRONSIGHT_ANGLE_AVERAGE_SIZE + 1 do
		local ang = deltaAvg[i]
		if not ang then break end

		temp:Add(ang)
	end

	temp:Mul(IRONSIGHT_ANGLE_AVERAGE_DIVIDE)
	return temp
end

local ironsight_catchupspeed = 60
function ENT:ApplyIronSightPositioning(vecPosition, angAngle)
	--self:UpdateIronSightAmount()

	if self:GetIronSightAmount() == 0 then return end

	local wep = self:GetAttachedWeapon()

	-- if we're more than 10% ironsighted, apply looseness.
	if self:GetIronSightAmount() > 0.1 then
		-- get the difference between current angles and last angles
		local angDelta = QAngleDiff(self.m_angViewLast, angAngle)

		-- dampen the delta to simulate 'looseness', but the faster we move, the more looseness approaches ironsight_running_looseness.GetFloat(), which is as waggly as possible
		if game.SinglePlayer() or IsFirstTimePredicted() then
			self:AddToAngleAverage(angDelta * Lerp(self:GetSpeedRatio(), self:GetIronSightLooseness(), .3))
		end

		-- m_angViewLast tries to catch up to angAngle
		self.m_angViewLast:Sub(angDelta * math.Clamp(FrameTime() * ironsight_catchupspeed, 0, 1))
	else
		self.m_angViewLast:Set(angAngle)
	end

	-- now the fun part - move the viewmodel to look down the sights

	-- create a working matrix at the current eye position and angles
	local matIronSightMatrix = Matrix()
	matIronSightMatrix:Translate(vecPosition)
	matIronSightMatrix:SetAngles(angAngle)

	local amountGained = self:GetIronSightAmountGained()
	-- offset the matrix by the ironsight eye position
	matIronSightMatrix:Translate((-self:GetScopePos()) * amountGained)

	-- additionally offset by the ironsight origin of rotation, the weapon will pivot around this offset from the eye
	matIronSightMatrix:Translate(Vector(self:GetIronSightPivotForward(), 0, 0))

	local angDeltaAverage = self:GetAngleAverage()

	-- apply ironsight eye rotation
	local bViewmodelFlip = wep.ViewModelFlip or false

	if bViewmodelFlip then
		angDeltaAverage.y = 0 + angDeltaAverage.y
	end

	-- use schema defined angles
	local temp = Angle()
	local pivot = self:GetPivotAngle()
	pivot:Normalize()
	temp:RotateAroundAxis(Vector(1, 0, 0), (angDeltaAverage.z + pivot.z) * amountGained)
	temp:RotateAroundAxis(Vector(0, 1, 0), (angDeltaAverage.x + pivot.x) * amountGained)
	temp:RotateAroundAxis(Vector(0, 0, 1), ((angDeltaAverage.y * (bViewmodelFlip and -1 or 1)) + pivot.y) * amountGained)
	matIronSightMatrix:Rotate(temp)

	-- move the weapon back to the ironsight eye position
	matIronSightMatrix:Translate(Vector(-self:GetIronSightPivotForward(), 0, 0))

	-- if the player is moving, pull down and re-bob the weapon
	if wep:GetPlayerOwner() then
		local vecIronSightBob = Vector(
			1,
			IRONSIGHT_VIEWMODEL_BOB_MULT_X * math.sin(CurTime() * IRONSIGHT_VIEWMODEL_BOB_PERIOD_X),
			IRONSIGHT_VIEWMODEL_BOB_MULT_Y * math.sin(CurTime() * IRONSIGHT_VIEWMODEL_BOB_PERIOD_Y) - IRONSIGHT_VIEWMODEL_BOB_MULT_Y
		)

		local dotCoords = self.m_vecDotCoords

		dotCoords.x = -vecIronSightBob.y
		dotCoords.y = -vecIronSightBob.z
		dotCoords:Mul(0.1)
		dotCoords.x = dotCoords.x * 0.6
		dotCoords.x = dotCoords.x - angDeltaAverage.y * 0.03

		dotCoords.y = dotCoords.y * 0.2
		dotCoords.y = dotCoords.y + angDeltaAverage.x * 0.03
		dotCoords:Mul(self:GetSpeedRatio())

		if bViewmodelFlip then
			vecIronSightBob.y = -vecIronSightBob.y
		end

		matIronSightMatrix:Translate(vecIronSightBob * self:GetSpeedRatio())
	end

	-- extract the final position and angles and apply them as differences from the passed in values
	vecPosition:Sub(vecPosition - matIronSightMatrix:GetTranslation())

	local angIronSightAngles = matIronSightMatrix:GetAngles()
	angIronSightAngles:Normalize()
	angAngle:Sub(QAngleDiff(angAngle, angIronSightAngles))
end

function ENT:SetState(newState)
	if newState == IronSight_viewmodel_is_deploying or newState == IronSight_weapon_is_dropped then
		self:SetIronSightAmount(0)
	end

	local wep = self:GetAttachedWeapon()
	if wep:IsValid() and wep.IsSWCSWeapon then
		wep:SetIronSightMode(newState)
	end
end

function ENT:IsInitializedAndAvailable()
	return self:GetIronSightAvailable()
end

function ENT:Init(wep)
	if self:IsInitializedAndAvailable() then return true end

	if wep:IsValid() and wep:IsWeapon() and wep.IsSWCSWeapon then
		local attributes = wep.ItemAttributes

		if attributes and tobool(attributes["aimsight capable"]) then
			self:SetIronSightAvailable(true)
			self:SetAttachedWeapon(wep)

			self:SetIronSightLooseness(tonumber(attributes["aimsight looseness"]) or self:GetIronSightLooseness())
			self:SetIronSightPullUpSpeed(tonumber(attributes["aimsight speed up"]) or self:GetIronSightPullUpSpeed())
			self:SetIronSightPutDownSpeed(tonumber(attributes["aimsight speed down"]) or self:GetIronSightPutDownSpeed())
			self:SetIronSightFOV(tonumber(attributes["aimsight fov"]) or 45)
			self:SetIronSightPivotForward(tonumber(attributes["aimsight pivot forward"]) or self:GetIronSightPivotForward())
			self:SetScopePos(Vector(attributes["aimsight eye pos"]))
			self:SetPivotAngle(Angle(attributes["aimsight pivot angle"]))

			return true
		end
	end

	return false
end

function ENT:ShouldHideCrossHair()
	return (self:IsApproachingSighted() or self:IsApproachingUnSighted()) and self:GetIronSightAmount() > IRONSIGHT_HIDE_CROSSHAIR_THRESHOLD
end

function ENT:GetDotMaterial()
	local wep = self:GetAttachedWeapon()

	if wep:IsValid() and wep.IsSWCSWeapon then
		local attributes = wep.ItemAttributes

		if attributes["aimsight material"] == "" then
			return "null"
		else
			return attributes["aimsight material"] or "models/weapons/shared/scope/scope_dot_green"
		end
	end
end
function ENT:IncreaseDotBlur(flAmount)
	if self:IsInIronSight() --[[and IsFirstTimePredicted()]] then
		self:SetDotBlur(math.Clamp(self:GetDotBlur() + flAmount, 0, 1))
	end
end
function ENT:GetDotBlurValue()
	return Bias(1 - math.max(self:GetDotBlur(), self:GetSpeedRatio() * 0.5), 0.2)
end
function ENT:GetDotWidth()
	return 32 + (256 * math.max(self:GetDotBlur(), self:GetSpeedRatio() * 0.3))
end

function ENT:GetIronSightFOVValue(flDefaultFOV, bUseBiasedValue)
	-- sets biased value between the current FOV and the ideal IronSight FOV based on how 'ironsighted' the weapon currently is
	if not self:IsInIronSight() then
		return flDefaultFOV
	end

	local flIronSightFOVAmount = bUseBiasedValue and self:GetIronSightAmountBiased() or self:GetIronSightAmount()

	return Lerp(flIronSightFOVAmount, flDefaultFOV, self:GetIronSightFOV())
end

if CLIENT then
	local s_RatioToAspectModes = {
		{0, 4.0 / 3.0},
		{1, 16.0 / 9.0},
		{2, 16.0 / 10.0},
		{2, 1.0},
	}
	local function GetScreenAspectRatio(width, height)
		local aspectRatio = width / height

		-- just find the closest ratio
		local closestAspectRatioDist = 99999.0
		local closestAnamorphic = 0
		for i = 1, #s_RatioToAspectModes do
			local dist = math.abs(s_RatioToAspectModes[i][2] - aspectRatio)
			if (dist < closestAspectRatioDist) then
				closestAspectRatioDist = dist
				closestAnamorphic = s_RatioToAspectModes[i][1]
			end
		end

		return closestAnamorphic
	end

	local rtFullFrame = render.GetScreenEffectTexture()
	local rt_vm = GetRenderTarget("swcs_rt_vm", ScrW(), ScrH())

	local DoBlur = CreateClientConVar("swcs_scope_blur", "1", true, false, "Enable scope blur effect")

	function ENT:PrepareScopeEffect(x, y, w, h)
		if not self:IsInIronSight() then return false end

		-- fixes cross edge bleeding
		render.CopyTexture(rt_vm, rtFullFrame)

		-- blur viewmodel rendertarget
		if DoBlur:GetBool() then
			render.PushRenderTarget(rtFullFrame)
			-- destroys fps on shitty PCs
			render.BlurRenderTarget(rtFullFrame, 2, 2, 1)
			render.PopRenderTarget()
		end

		render.ClearStencil()

		-- Prepare to render the scope lens mask shape into the stencil buffer.
		-- The weapon itself will take care of using the correct blend mode and override material.
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(0xFF)
		render.SetStencilTestMask(0xFF)
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilZFailOperation(STENCIL_REPLACE)

		return true
	end

	local VIEWPUNCH_COMPENSATE_MAGIC_SCALAR = 0.58
	local view_recoil_tracking = GetConVar"view_recoil_tracking"
	local weapon_recoil_scale = GetConVar"weapon_recoil_scale"

	function ENT:RenderScopeEffect(x, y, w, h)
		if not self:IsInIronSight() then return end

		-- apply the blur effect to the screen while masking out the scope lens
		-- stencilState_skip_scope_lens_pixels
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		-- RENDER _rt_SmallFB0 to screen
		local pBlurOverlayMaterial = Material("dev/scope_bluroverlay")

		-- set alpha to the amount of ironsightedness
		local flAlphaVar = pBlurOverlayMaterial:GetFloat("$alpha")
		if flAlphaVar then
			pBlurOverlayMaterial:SetFloat("$alpha", Bias(self:GetIronSightAmount(), 0.2))
		end

		local view = render.GetViewSetup()

		local wep = self:GetAttachedWeapon()
		local settings = wep.m_tCurrentCrosshairSettings

		local ang = wep:GetRawAimPunchAngle()
		ang:Mul((1 - view_recoil_tracking:GetFloat()) * weapon_recoil_scale:GetFloat())
		ang:Sub(wep:GetViewPunchAngle())

		local recoilX, recoilY
		if settings and settings.followRecoil and not ang:IsZero() then
			recoilX, recoilY = swcs.AngleToScreenPixel(ang)
		end

		local owner = wep:GetOwner()

		-- render background blur & scope dot
		cam.Start2D()
		render.OverrideDepthEnable(true, false)

		render.SetLightingMode(2)
		render.SetMaterial(pBlurOverlayMaterial)
		render.DrawScreenQuad()

		-- now draw the laser dot, masked to ONLY render on the lens
		local dotCoords = self.m_vecDotCoords
		dotCoords.x = dotCoords.x * GetScreenAspectRatio(w, h)

		-- stencilState_use_only_scope_lens_pixels
		render.SetStencilReferenceValue(1)
		render.SetStencilCompareFunction(STENCIL_EQUAL)
		render.SetStencilPassOperation(STENCIL_KEEP)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_REPLACE)

		local iWidth = self:GetDotWidth()

		local pMatDot = Material(self:GetDotMaterial())

		dotCoords.x = (dotCoords.x * 2) + 0.5
		dotCoords.y = (dotCoords.y * 3) + 0.5

		local iDrawX = (w * dotCoords.x)
		local iDrawY = (h * dotCoords.y)

		if settings and settings.followRecoil and recoilX then
			local ratio = (math.tan(math.rad(view.fov_unscaled) / 2) / math.tan(math.rad(owner:GetDefaultFOV()) / 2)) * VIEWPUNCH_COMPENSATE_MAGIC_SCALAR
			local diffX, diffY = (iDrawX - recoilX) * ratio, (iDrawY - recoilY) * ratio

			iDrawX, iDrawY = iDrawX - diffX, iDrawY - diffY
			--[[else
			local alphaVar2 = pMatDot:GetFloat("$alpha")
			local flDotBlur = self:GetDotBlurValue()
			flDotBlur = flDotBlur == flDotBlur and flDotBlur or 0

			if alphaVar2 then
				pMatDot:SetFloat("$alpha", flDotBlur)
			end

			render.SetBlend(flDotBlur)--]]
		end

		--print("what", pMatDot, pMatDot:GetInt("$alpha"))
		--pMatDot:SetFloat("$alpha", 1.0)

		render.SetMaterial(pMatDot)
		render.DrawScreenQuadEx(
			iDrawX - (iWidth / 2),
			iDrawY - (iWidth / 2),
			iWidth,
			iWidth
		)

		render.SetLightingMode(0)
		cam.End2D()

		render.OverrideDepthEnable(false, true)

		-- restore a disabled stencil state
		render.SetStencilEnable(false)

		--clean up stencil buffer once we're done so render elements like the glow pass draw correctly
		render.ClearStencil()
	end
end

-- pull up duration is how long the pull up would take in seconds, not the speed
function ENT:GetIronSightPullUpDuration()
	return self:GetIronSightPullUpSpeed() > 0 and (1 / self:GetIronSightPullUpSpeed()) or 0
end
function ENT:GetIronSightPutDownDuration()
	return self:GetIronSightPutDownSpeed() > 0 and (1 / self:GetIronSightPutDownSpeed()) or 0
end
