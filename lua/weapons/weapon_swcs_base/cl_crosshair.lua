SWEP.m_fAnimInset = 0
SWEP.m_fLineSpreadDistance = 1

local swcs_crosshair_sniper_show_normal_inaccuracy = CreateClientConVar("swcs_crosshair_sniper_show_normal_inaccuracy", "0", nil, nil, "Include standing inaccuracy when determining sniper crosshair blur")
local swcs_crosshair_sniper_width = GetConVar("swcs_crosshair_sniper_width")

local matBlur = Material("sprites/scope_line_blur")

SWEP.m_matArc = Material("sprites/scope_arc_csgo")
SWEP.m_matDust = Material("overlays/scope_lens_csgo")
function SWEP:DrawHUD()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local selfTable = self:GetTable()

	if selfTable.m_sWeaponType ~= "sniperrifle" then return end

	local kScopeMinFOV = 25.0 -- Clamp scope FOV to this value to prevent blur from getting too big when double-scoped
	local flTargetFOVForZoom = math.max(selfTable.GetZoomFOV(self, selfTable.GetZoomLevel(self)), kScopeMinFOV)

	if flTargetFOVForZoom ~= owner:GetDefaultFOV() and selfTable.IsZoomed(self) and not selfTable.GetResumeZoom(self) then
		local screenWide, screenTall = ScrW(), ScrH()

		local vm = owner:GetViewModel(0)
		if not vm:IsValid() then return end

		local fHalfFov = math.rad(flTargetFOVForZoom) * 0.5
		local fInaccuracyIn640x480Pixels = 320.0 / math.tan(fHalfFov) -- 640 = "reference screen width"

		-- Get the weapon's inaccuracy
		local fWeaponInaccuracy = selfTable.GetInaccuracy(self, true) + selfTable.GetSpread(self)

		-- Optional: Ignore "default" inaccuracy
		if not swcs_crosshair_sniper_show_normal_inaccuracy:GetBool() then
			fWeaponInaccuracy = fWeaponInaccuracy - selfTable.GetInaccuracyStand(self, Secondary_Mode) + selfTable.GetSpread(self)
		end

		fWeaponInaccuracy = math.max(fWeaponInaccuracy, 0)

		local fRawSpreadDistance = fWeaponInaccuracy * fInaccuracyIn640x480Pixels
		local fSpreadDistance = math.Clamp(fRawSpreadDistance, 0, 100)

		-- reduce the goal  (* 0.4 / 30.0f)
		-- then animate towards it at speed 19.0f
		-- (where did these numbers come from?)
		local flInsetGoal = fSpreadDistance * (0.4 / 30.0);
		selfTable.m_fAnimInset = swcs.Approach(flInsetGoal, selfTable.m_fAnimInset, math.abs((flInsetGoal - selfTable.m_fAnimInset) - FrameTime()) * 19)

		-- Approach speed chosen so we get 90% there in 3 frames if we are running at 192 fps vs a 64tick client/server.
		-- If our fps is lower we will reach the target faster, if higher it is slightly slower
		-- (since this is a framerate-dependent approach function).
		selfTable.m_fLineSpreadDistance = swcs.RemapClamped(FrameTime() * 140, 0, 1, selfTable.m_fLineSpreadDistance, fRawSpreadDistance)

		local offsetX = ((selfTable.m_bobState and selfTable.m_bobState:GetRawLateralBob() or 0) * (screenTall / 14))
		local offsetY = ((selfTable.m_bobState and selfTable.m_bobState:GetRawVerticalBob() or 0) * (screenTall / 14))

		local flInacDisplayBlur = selfTable.m_fAnimInset * 0.04
		if flInacDisplayBlur > 0.22 then
			flInacDisplayBlur = 0.22
		end

		local scrCenterX, scrCenterY = screenWide / 2, screenTall / 2
		local iCenterX, iCenterY = scrCenterX, scrCenterY

		if owner:IsWorldClicking() and not owner:IsWorldClickingDisabled() and vgui.CursorVisible() then
			iCenterX, iCenterY = input.GetCursorPos()
		end

		local centerOffsetX, centerOffsetY = iCenterX - scrCenterX, iCenterY - scrCenterY

		-- calculate the bounds in which we should draw the scope
		local inset = ((screenTall / 14) + (flInacDisplayBlur * (screenTall * 0.5)))
		local y1 = inset
		local x1 = ((screenWide - screenTall) / 2 + inset)
		local y2 = (screenTall - inset)
		local x2 = screenWide - x1

		y1 = y1 + offsetY + centerOffsetY
		y2 = y2 + offsetY + centerOffsetY
		x1 = x1 + offsetX + centerOffsetX
		x2 = x2 + offsetX + centerOffsetX

		local x = (iCenterX + offsetX)
		local y = (iCenterY + offsetY)

		local uv1 = 0.5 / 256
		local uv2 = 1 - uv1

		local vert = {{}, {}, {}, {}}

		local xMod = scrCenterX + offsetX + (flInacDisplayBlur * screenWide)
		local yMod = scrCenterY + offsetY + (flInacDisplayBlur * screenTall)

		local iMiddleX = (iCenterX + offsetX)
		local iMiddleY = (iCenterY + offsetY)

		surface.SetMaterial(selfTable.m_matDust)
		surface.SetDrawColor(255, 255, 255, 255)

		-- bottom right
		vert[1].x = scrCenterX + xMod
		vert[1].y = scrCenterY + yMod
		vert[1].u = uv2
		vert[1].v = uv1

		-- bottom left
		vert[2].x = scrCenterX - xMod + offsetX
		vert[2].y = scrCenterY + yMod + offsetY
		vert[2].u = uv1
		vert[2].v = uv1

		-- top left
		vert[3].x = scrCenterX - xMod + offsetX
		vert[3].y = scrCenterY - yMod + offsetY
		vert[3].u = uv1
		vert[3].v = uv2

		-- top right
		vert[4].x = scrCenterX + xMod
		vert[4].y = scrCenterY - yMod + offsetY
		vert[4].u = uv2
		vert[4].v = uv2
		surface.DrawPoly(vert)

		-- The math.pow here makes the blur not quite spread out quite as much as the actual inaccuracy;
		-- doing so is a bit too sudden and also leads to just a huge blur because the snipers are
		-- *extremely* inaccurate while scoped and moving.  This way we get a slightly smoother animation
		-- as well as not quite blowing up the blurred area by such a large amount.
		local fBlurWidth = math.pow(selfTable.m_fLineSpreadDistance, 0.75)
		if fBlurWidth ~= fBlurWidth then
			fBlurWidth = 0
		end
		local fScreenBlurWidth = fBlurWidth * screenTall / 640.0 -- scale from 'reference screen size' to actual screen

		local nSniperCrosshairThickness = swcs_crosshair_sniper_width:GetInt()
		if nSniperCrosshairThickness < 1 then
			nSniperCrosshairThickness = 1
		end

		local kMaxVarianceWithFullAlpha = 1.8 -- Tuned to look good
		local fBlurAlpha
		if fScreenBlurWidth <= nSniperCrosshairThickness + 0.5 then
			fBlurAlpha = (fBlurWidth < 1) and 1 or 1 / fBlurWidth
		else
			fBlurAlpha = (fBlurWidth < kMaxVarianceWithFullAlpha) and 1 or kMaxVarianceWithFullAlpha / fBlurWidth
		end

		-- This is a break from physical reality to make the look a bit better.  An actual Gaussian
		-- blur spreads the energy out over the entire blurred area, dropping the total opacity by the amount
		-- of the spread.  However, this leads to not being able to see the effect at all.  We solve this in
		-- 2 ways:
		--   (1) use sqrt on the alpha to bring it closer to 1, kind of like a gamma curve.
		--   (2) clamp the alpha at the lower end to 55% to make sure you can see *something* no matter
		--       how spread out it gets.
		fBlurAlpha = math.sqrt(fBlurAlpha)
		local iBlurAlpha = math.floor(math.Clamp(fBlurAlpha * 255, 140, 255))

		if fScreenBlurWidth <= math.Round(nSniperCrosshairThickness + 0.5) then
			surface.SetDrawColor(0, 0, 0, iBlurAlpha)

			-- Draw the reticle with primitives
			if nSniperCrosshairThickness <= 1 then
				surface.DrawLine(0, y, screenWide + offsetX, y)
				surface.DrawLine(x, 0, x, screenTall + offsetY)
			else
				local nStep = math.floor(nSniperCrosshairThickness / 2)
				surface.DrawRect(0, y - nStep, screenWide + offsetX, nSniperCrosshairThickness - nStep)
				surface.DrawRect(x - nStep, 0, nSniperCrosshairThickness - nStep, screenTall + offsetY)
			end
		else
			surface.SetDrawColor(0, 0, 0, iBlurAlpha)
			surface.SetMaterial(matBlur)

			-- vertical blurred line
			vert[1].x = iMiddleX - fScreenBlurWidth
			vert[1].y = offsetY
			vert[1].u = uv1
			vert[1].v = uv1

			vert[2].x = iMiddleX + fScreenBlurWidth
			vert[2].y = offsetY
			vert[2].u = uv2
			vert[2].v = uv1

			vert[3].x = iMiddleX + fScreenBlurWidth
			vert[3].y = screenTall + offsetY
			vert[3].u = uv2
			vert[3].v = uv2

			vert[4].x = iMiddleX - fScreenBlurWidth
			vert[4].y = screenTall + offsetY
			vert[4].u = uv1
			vert[4].v = uv2
			surface.DrawPoly(vert)

			-- horizontal blurred line
			vert[1].x = screenWide + offsetX
			vert[1].y = iMiddleY - fScreenBlurWidth
			vert[1].u = uv1
			vert[1].v = uv2

			vert[2].x = screenWide + offsetX
			vert[2].y = iMiddleY + fScreenBlurWidth
			vert[2].u = uv2
			vert[2].v = uv2

			vert[3].x = offsetX
			vert[3].y = iMiddleY + fScreenBlurWidth
			vert[3].u = uv2
			vert[3].v = uv1

			vert[4].x = offsetX
			vert[4].y = iMiddleY - fScreenBlurWidth
			vert[4].u = uv1
			vert[4].v = uv1
			surface.DrawPoly(vert)
		end

		surface.SetDrawColor(0, 0, 0, 255)
		surface.SetMaterial(selfTable.m_matArc)

		-- bottom right
		vert[1].x = x
		vert[1].y = y
		vert[1].u = uv1
		vert[1].v = uv1

		vert[2].x = x2
		vert[2].y = y
		vert[2].u = uv2
		vert[2].v = uv1

		vert[3].x = x2
		vert[3].y = y2
		vert[3].u = uv2
		vert[3].v = uv2

		vert[4].x = x
		vert[4].y = y2
		vert[4].u = uv1
		vert[4].v = uv2
		surface.DrawPoly(vert)

		-- top right
		vert[1].x = x - 1
		vert[1].y = y1
		vert[1].u = uv1
		vert[1].v = uv2

		vert[2].x = x2
		vert[2].y = y1
		vert[2].u = uv2
		vert[2].v = uv2

		vert[3].x = x2
		vert[3].y = y + 1
		vert[3].u = uv2
		vert[3].v = uv1

		vert[4].x = x - 1
		vert[4].y = y + 1
		vert[4].u = uv1
		vert[4].v = uv1
		surface.DrawPoly(vert)

		-- bottom left
		vert[1].x = x1
		vert[1].y = y
		vert[1].u = uv2
		vert[1].v = uv1

		vert[2].x = x
		vert[2].y = y
		vert[2].u = uv1
		vert[2].v = uv1

		vert[3].x = x
		vert[3].y = y2
		vert[3].u = uv1
		vert[3].v = uv2

		vert[4].x = x1
		vert[4].y = y2
		vert[4].u = uv2
		vert[4].v = uv2
		surface.DrawPoly(vert)

		-- top left
		vert[1].x = x1
		vert[1].y = y1
		vert[1].u = uv2
		vert[1].v = uv2

		vert[2].x = x
		vert[2].y = y1
		vert[2].u = uv1
		vert[2].v = uv2

		vert[3].x = x
		vert[3].y = y
		vert[3].u = uv1
		vert[3].v = uv1

		vert[4].x = x1
		vert[4].y = y
		vert[4].u = uv2
		vert[4].v = uv1
		surface.DrawPoly(vert)

		surface.DrawRect(0, 0, screenWide, y1 + 1) -- top
		surface.DrawRect(0, y2, screenWide, screenTall) -- bottom
		surface.DrawRect(0, y1, x1 + 1, screenTall) -- left
		surface.DrawRect(x2, y1, screenWide, screenTall) -- right
	end
end

local weapon_debug_spread_show = GetConVar"weapon_debug_spread_show"
local weapon_debug_spread_gap = CreateConVar("weapon_debug_spread_gap", "0.67", {FCVAR_REPLICATED})

local function DrawCrosshairRect(r, g, b, a, x0, y0, x1, y1, bAdditive, bOutline, flOutlineThickness)
	local w = math.max(x0, x1) - math.min(x0, x1)
	local h = math.max(y0, y1) - math.min(y0, y1)

	if bOutline then
		local flThick = flOutlineThickness * 2
		surface.SetDrawColor(0, 0, 0, a)
		surface.DrawRect(x0 - math.floor(flThick / 2), y0 - math.floor(flThick / 2), w + flThick, h + flThick)
	end

	surface.SetDrawColor(r, g, b, a)

	if bAdditive then
		surface.DrawTexturedRect(x0, y0, w, h)
	else
		surface.DrawRect(x0, y0, w, h)
	end
end

local SWITCH_CrosshairColor = {
	[0] = Color(250, 50, 50),
	Color(50, 250, 50),
	Color(250, 250, 50),
	Color(50, 50, 250),
	Color(50, 250, 250),
	function(settings)
		return Color(
			settings.red,
			settings.green,
			settings.blue
		)
	end,
}

local function XRES(x)
	return x * (ScrW() / 640)
end
local function YRES(y)
	return y * (ScrH() / 480)
end

local cl_weapon_debug_print_accuracy = CreateClientConVar("cl_weapon_debug_print_accuracy", "0")
local cl_cam_driver_compensation_scale = CreateClientConVar("cl_cam_driver_compensation_scale", "0.75")
local view_recoil_tracking = GetConVar"view_recoil_tracking"
local weapon_recoil_scale = GetConVar"weapon_recoil_scale"

local VIEWPUNCH_COMPENSATE_MAGIC_SCALAR = 0.65

function SWEP:ShouldDrawCrosshair()
	local owner = self:GetOwner()
	if not owner then return false end

	local selfTable = self:GetTable()

	if selfTable.NoCrosshair then
		return false
	end

	local weapontype = selfTable.m_sWeaponType
	if (not swcs.InTTT and weapontype == "sniperrifle") or (swcs.InTTT and weapontype == "sniperrifle" and selfTable.IsZoomed(self) and not selfTable.GetResumeZoom(self)) then
		return false
	end

	local iron = selfTable.GetIronSightController(self)
	if not selfTable.CrosshairOnAimsight and iron:IsValid() and iron:ShouldHideCrossHair() then
		return false
	end

	return true
end

SWEP.m_flCrosshairDistance = 0
SWEP.m_iAmmoLastCheck = 0
function SWEP:DrawCrosshair(settings)
	local owner = self:GetPlayerOwner()
	if not owner then return end

	assert(owner == LocalPlayer() or LocalPlayer():GetObserverMode() == OBS_MODE_IN_EYE)

	-- no crosshair for sniper rifles

	-- localplayer must be owner if not in Spec mode

	local r, g, b = 50, 250, 50
	local alpha = math.Clamp(settings.alpha, 0, 255)

	local selfTable = self:GetTable()

	if not selfTable.m_iCrosshairTextureID then
		selfTable.m_iCrosshairTextureID = surface.GetTextureID("vgui/white_additive")
	end

	local bAdditive = not settings.alphaEnabled
	if bAdditive then
		surface.SetTexture(selfTable.m_iCrosshairTextureID)
		alpha = 200
	end

	local iron = selfTable.GetIronSightController(self)
	if not selfTable.CrosshairOnAimsight and iron:IsValid() and iron:ShouldHideCrossHair() then
		alpha = 0
	end

	local fHalfFov = math.rad(owner:GetFOV()) * 0.5
	local flInaccuracy = selfTable.GetInaccuracy(self, true)
	local flSpread = selfTable.GetSpread(self)

	local fSpreadDistance = ((flInaccuracy + flSpread) * 320 / math.tan(fHalfFov))
	local flCappedSpreadDistance = fSpreadDistance
	local flMaxCrossDistance = settings.splitDistance
	if fSpreadDistance > flMaxCrossDistance then
		flCappedSpreadDistance = flMaxCrossDistance
	end

	local iSpreadDistance = settings.style < 4 and math.floor(YRES(fSpreadDistance)) or 2
	local iCappedSpreadDistance = settings.style < 4 and math.floor(YRES(flCappedSpreadDistance)) or 2

	if cl_weapon_debug_print_accuracy:GetInt() == 1 then
		local flVel = owner:GetVelocity():Length()
		if flVel > 0 then
			Msg(Format("Inaccuracy =\t%f\tSpread =\t%f\tSpreadDistance =\t%f\tPlayer Velocity =\t%f\n", flInaccuracy, flSpread, fSpreadDistance, flVel))
		end
	end

	local view = render.GetViewSetup()

	local iCenterX = math.ceil(view.width / 2) + 1
	local iCenterY = math.ceil(view.height / 2) + 1

	local iDeltaDistance = selfTable.GetCrosshairDeltaDistance(self) -- amount by which the crosshair expands when shooting (per frame)
	local fCrosshairDistanceGoal = settings.deployedWeaponGapEnabled and selfTable.GetCrosshairMinDistance(self) or 4 -- The minimum distance the crosshair can achieve...

	-- 0 = default
	-- 1 = default static
	-- 2 = classic standard
	-- 3 = classic dynamic
	-- 4 = classic static
	-- if ( cl_dynamiccrosshair.GetBool() )
	if settings.style ~= 4 and (settings.style == 2 or settings.style == 3) then
		if not owner:IsOnGround() then
			fCrosshairDistanceGoal = fCrosshairDistanceGoal * 2
		elseif owner:Crouching() then
			fCrosshairDistanceGoal = fCrosshairDistanceGoal * 0.5
		elseif owner:GetVelocity():Length() > 100 then
			fCrosshairDistanceGoal = fCrosshairDistanceGoal * 1.5
		end
	end

	-- [jpaquin] changed to only bump up the crosshair size if the player is still shooting or is spectating someone else
	if selfTable.GetShotsFired(self) > selfTable.m_iAmmoLastCheck and (owner:KeyDown(IN_ATTACK) or owner:KeyDown(IN_ATTACK2)) and self:Clip1() >= 0 then
		if settings.style == 5 then
			selfTable.m_flCrosshairDistance = selfTable.m_flCrosshairDistance + (selfTable.GetRecoilMagnitude(self, selfTable.GetWeaponMode(self)) / 3.5)
		elseif settings.style ~= 4 then
			fCrosshairDistanceGoal = fCrosshairDistanceGoal + iDeltaDistance
		end
	end

	selfTable.m_iAmmoLastCheck = selfTable.GetShotsFired(self)

	if selfTable.m_flCrosshairDistance > fCrosshairDistanceGoal then
		if settings.style == 5 then
			selfTable.m_flCrosshairDistance = selfTable.m_flCrosshairDistance - 42 * FrameTime()
		else
			selfTable.m_flCrosshairDistance = Lerp(FrameTime() / 0.025, fCrosshairDistanceGoal, selfTable.m_flCrosshairDistance)
		end
	end

	-- clamp max crosshair expansion
	selfTable.m_flCrosshairDistance = math.Clamp(selfTable.m_flCrosshairDistance, fCrosshairDistanceGoal, 25.0)

	local iCrosshairDistance, iBarSize, iBarThickness
	local iCappedCrosshairDistance = 0

	iCrosshairDistance = math.floor((selfTable.m_flCrosshairDistance * ScrH() / 1200.0) + settings.gap)
	iBarSize = math.floor(YRES(settings.length))
	iBarThickness = math.max(1, math.floor(YRES(settings.thickness)))

	-- 0 = default
	-- 1 = default static
	-- 2 = classic standard
	-- 3 = classic dynamic
	-- 4 = classic static
	-- if weapon_debug_spread_show:GetInt() == 2
	if iSpreadDistance > 0 and settings.style == 2 or settings.style == 3 then
		iCrosshairDistance = iSpreadDistance + settings.gap

		if settings.style == 2 then
			iCappedCrosshairDistance = iCappedSpreadDistance + settings.gap
		end
	elseif settings.style == 4 or (iSpreadDistance == 0 and (settings.style == 2 or settings.style == 3)) then
		iCrosshairDistance = fCrosshairDistanceGoal + settings.gap
		iCappedCrosshairDistance = 4 + settings.gap
	end

	-- subtract a ratio of cam driver motion from crosshair according to cl_cam_driver_compensation_scale
	local angViewOffset = Angle()
	if cl_cam_driver_compensation_scale:GetFloat() ~= 0 and owner then
		local vm = owner:GetViewModel(self:ViewModelIndex())

		if vm:IsValid() and selfTable.m_flCamDriverWeight > 0 then
			local angCamDriver = selfTable.m_flCamDriverWeight * selfTable.m_angCamDriverLastAng * math.Clamp(cl_cam_driver_compensation_scale:GetFloat(), -10, 10)
			angCamDriver:Normalize()

			if not angCamDriver:IsZero() then
				angViewOffset:Sub(angCamDriver)
			end
		end
	end

	if settings.followRecoil then
		local ang = selfTable.GetRawAimPunchAngle(self)
		ang:Mul((1 - view_recoil_tracking:GetFloat()) * weapon_recoil_scale:GetFloat())
		ang:Sub(selfTable.GetViewPunchAngle(self))

		--[[
			// Optionally subtract out viewangle since it doesn't affect shooting.
			if ( cl_flinch_compensate_crosshair.GetBool() )
			{
				QAngle viewPunch = pPlayer->GetViewPunchAngle();

				if ( viewPunch.x != 0 || viewPunch.y != 0 )
				{
					if ( flAngleToScreenPixel == 0 )
						flAngleToScreenPixel = VIEWPUNCH_COMPENSATE_MAGIC_SCALAR * 2 * ( ScreenHeight() / ( 2.0f * tanf(DEG2RAD( pPlayer->GetFOV() ) / 2.0f) ) );

					iCenterY -= flAngleToScreenPixel * sinf( DEG2RAD( viewPunch.x ) );
					iCenterX += flAngleToScreenPixel * sinf( DEG2RAD( viewPunch.y ) );
				}
			}
		--]]

		angViewOffset:Add(ang)
	end

	if not angViewOffset:IsZero() then
		iCenterX, iCenterY = swcs.AngleToScreenPixel(angViewOffset)
	end

	if weapon_debug_spread_show:GetInt() == 1 then
		r, g, b = 250, 250, 50

		local iInnerLeft = iCenterX - iSpreadDistance
		local iInnerRight = iCenterX + iSpreadDistance
		local iOuterLeft = iInnerLeft - iBarThickness
		local iOuterRight = iInnerRight + iBarThickness
		local iInnerTop = iCenterY - iSpreadDistance
		local iInnerBottom = iCenterY + iSpreadDistance
		local iOuterTop = iInnerTop - iBarThickness
		local iOuterBottom = iInnerBottom + iBarThickness

		local iGap = math.floor(weapon_debug_spread_gap:GetFloat() * iSpreadDistance)

		-- draw horizontal lines
		DrawCrosshairRect(r, g, b, alpha, iOuterLeft, iOuterTop, iCenterX - iGap, iInnerTop, bAdditive, settings.outlineEnabled, settings.outline)
		DrawCrosshairRect(r, g, b, alpha, iCenterX + iGap, iOuterTop, iOuterRight, iInnerTop, bAdditive, settings.outlineEnabled, settings.outline)
		DrawCrosshairRect(r, g, b, alpha, iOuterLeft, iInnerBottom, iCenterX - iGap, iOuterBottom, bAdditive, settings.outlineEnabled, settings.outline)
		DrawCrosshairRect(r, g, b, alpha, iCenterX + iGap, iInnerBottom, iOuterRight, iOuterBottom, bAdditive, settings.outlineEnabled, settings.outline)

		-- draw vertical lines
		DrawCrosshairRect(r, g, b, alpha, iOuterLeft, iOuterTop, iInnerLeft, iCenterY - iGap, bAdditive, settings.outlineEnabled, settings.outline)
		DrawCrosshairRect(r, g, b, alpha, iOuterLeft, iCenterY + iGap, iInnerLeft, iOuterBottom, bAdditive, settings.outlineEnabled, settings.outline)
		DrawCrosshairRect(r, g, b, alpha, iInnerRight, iOuterTop, iOuterRight, iCenterY - iGap, bAdditive, settings.outlineEnabled, settings.outline)
		DrawCrosshairRect(r, g, b, alpha, iInnerRight, iCenterY + iGap, iOuterRight, iOuterBottom, bAdditive, settings.outlineEnabled, settings.outline)
	end

	if selfTable.NoCrosshair then
		return true
	end

	local weaponType = selfTable.m_sWeaponType
	if weaponType == "sniperrifle" then
		local bWantsCrosshair = selfTable.SniperAllowCrosshair or swcs.InTTT
		if not bWantsCrosshair or (bWantsCrosshair and selfTable.IsZoomed(self) and not selfTable.GetResumeZoom(self)) then
			return true
		end
	end

	if SWITCH_CrosshairColor[settings.color] then
		local col = SWITCH_CrosshairColor[settings.color]

		if isfunction(col) then
			col = col(settings)
		end

		r, g, b = col:Unpack()
	end

	-- 0 = default
	-- 1 = default static
	-- 2 = classic standard
	-- 3 = classic dynamic
	-- 4 = classic static

	local flAlphaSplitInner = settings.innerSplitAlpha
	local flAlphaSplitOuter = settings.outerSplitAlpha
	local flSplitRatio = settings.splitSizeRatio
	local iInnerCrossDist = iCrosshairDistance
	local flLineAlphaInner = alpha
	local flLineAlphaOuter = alpha
	local iBarSizeInner = iBarSize
	local iBarSizeOuter = iBarSize

	-- draw the crosshair that splits off from the main xhair
	if settings.style == 2 and fSpreadDistance > flMaxCrossDistance then
		iInnerCrossDist = iCappedCrosshairDistance
		flLineAlphaInner = alpha * flAlphaSplitInner
		flLineAlphaOuter = alpha * flAlphaSplitOuter
		iBarSizeInner = math.ceil(iBarSize * (1.0 - flSplitRatio))
		iBarSizeOuter = math.floor(iBarSize * flSplitRatio)

		-- draw horizontal crosshair lines
		local iInnerLeft = (iCenterX - iCrosshairDistance - iBarThickness / 2) - iBarSizeInner
		local iInnerRight = iInnerLeft + 2 * (iCrosshairDistance + iBarSizeInner) + iBarThickness
		local iOuterLeft = iInnerLeft - iBarSizeOuter
		local iOuterRight = iInnerRight + iBarSizeOuter
		local y0 = iCenterY - iBarThickness / 2
		local y1 = y0 + iBarThickness
		DrawCrosshairRect(r, g, b, flLineAlphaOuter, iOuterLeft, y0, iInnerLeft, y1, bAdditive, settings.outlineEnabled, settings.outline)
		DrawCrosshairRect(r, g, b, flLineAlphaOuter, iInnerRight, y0, iOuterRight, y1, bAdditive, settings.outlineEnabled, settings.outline)

		-- draw vertical crosshair lines
		local iInnerTop = (iCenterY - iCrosshairDistance - iBarThickness / 2) - iBarSizeInner
		local iInnerBottom = iInnerTop + 2 * (iCrosshairDistance + iBarSizeInner) + iBarThickness
		local iOuterTop = iInnerTop - iBarSizeOuter
		local iOuterBottom = iInnerBottom + iBarSizeOuter
		local x0 = iCenterX - iBarThickness / 2
		local x1 = x0 + iBarThickness
		if not settings.tStyleEnabled then DrawCrosshairRect(r, g, b, flLineAlphaOuter, x0, iOuterTop, x1, iInnerTop, bAdditive, settings.outlineEnabled, settings.outline) end
		DrawCrosshairRect(r, g, b, flLineAlphaOuter, x0, iInnerBottom, x1, iOuterBottom, bAdditive, settings.outlineEnabled, settings.outline)
	end

	-- draw horizontal crosshair lines
	local iInnerLeft = iCenterX - iInnerCrossDist - (iBarThickness / 2)
	local iInnerRight = iInnerLeft + (2 * iInnerCrossDist) + iBarThickness
	local iOuterLeft = iInnerLeft - iBarSizeInner
	local iOuterRight = iInnerRight + iBarSizeInner
	local y0 = iCenterY - (iBarThickness / 2)
	local y1 = y0 + iBarThickness
	DrawCrosshairRect(r, g, b, flLineAlphaInner, iOuterLeft, y0, iInnerLeft, y1, bAdditive, settings.outlineEnabled, settings.outline)
	DrawCrosshairRect(r, g, b, flLineAlphaInner, iInnerRight, y0, iOuterRight, y1, bAdditive, settings.outlineEnabled, settings.outline)

	-- draw vertical crosshair lines
	local iInnerTop = iCenterY - iInnerCrossDist - (iBarThickness / 2)
	local iInnerBottom = iInnerTop + (2 * iInnerCrossDist) + iBarThickness
	local iOuterTop = iInnerTop - iBarSizeInner
	local iOuterBottom = iInnerBottom + iBarSizeInner
	local x0 = iCenterX - (iBarThickness / 2)
	local x1 = x0 + iBarThickness
	if not settings.tStyleEnabled then DrawCrosshairRect(r, g, b, flLineAlphaInner, x0, iOuterTop, x1, iInnerTop, bAdditive, settings.outlineEnabled, settings.outline) end
	DrawCrosshairRect(r, g, b, flLineAlphaInner, x0, iInnerBottom, x1, iOuterBottom, bAdditive, settings.outlineEnabled, settings.outline)

	-- draw dot
	if settings.centerDotEnabled then
		local x0 = iCenterX - iBarThickness / 2
		local x1 = x0 + iBarThickness
		local y0 = iCenterY - iBarThickness / 2
		local y1 = y0 + iBarThickness
		DrawCrosshairRect(r, g, b, alpha, x0, y0, x1, y1, bAdditive, settings.outlineEnabled, settings.outline)
	end

	return true
end

local swcs_crosshair = GetConVar("swcs_crosshair")
local swcs_crosshair_use_spectator = GetConVar("swcs_crosshair_use_spectator")
SWEP.m_strCurrentCrosshairCode = ""
SWEP.m_tCurrentCrosshairSettings = {}
function SWEP:DoDrawCrosshair()
	local owner = self:GetOwner()

	local code = ""

	if self:IsCarriedByLocalPlayer() or not swcs_crosshair_use_spectator:GetBool() then
		code = owner.swcs_CrosshairCode
		if not code then
			code = swcs.EncodeCrosshairCode()
			owner.swcs_CrosshairCode = code
		end
	elseif owner:IsValid() and owner:IsPlayer() then
		code = owner:GetNWString("swcs.crosshair_code", "")
	end

	local selfTable = self:GetTable()
	if code ~= "" then
		if code ~= selfTable.m_strCurrentCrosshairCode then
			selfTable.m_strCurrentCrosshairCode = code
			selfTable.m_tCurrentCrosshairSettings = nil
		end

		if not selfTable.m_tCurrentCrosshairSettings then
			selfTable.m_tCurrentCrosshairSettings = swcs.DecodeCrosshairCode(code)
		end
	end

	if swcs_crosshair:GetBool() then
		if selfTable.m_tCurrentCrosshairSettings then
			selfTable.DrawCrosshair(self, selfTable.m_tCurrentCrosshairSettings)
		end

		return true
	else
		return not selfTable.ShouldDrawCrosshair(self)
	end
end
