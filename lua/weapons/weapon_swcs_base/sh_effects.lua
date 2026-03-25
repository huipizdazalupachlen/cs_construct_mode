AddCSLuaFile()

local SECONDS_FOR_COOL_DOWN = 1.0
local MIN_TIME_BETWEEN_SMOKES = 4.0
local MAX_SMOKE_ATTACHMENT_INDEX = 16

SWEP.m_gunHeat = 0.0
SWEP.m_lastSmokeTime = 0.0
SWEP.m_smokeAttachments = 0

local BarrelSmoke = CLIENT and CreateClientConVar("swcs_fx_weapon_barrel_smoke", "1", true, false, "show smoke emitting from barrel after sustained fire")

function SWEP:UpdateGunHeat(heat, iAttachmentIndex)
	if not BarrelSmoke or not BarrelSmoke:GetBool() then return end

	local owner = self:GetPlayerOwner()
	if not owner then return end

	local vm = owner:GetViewModel(self:ViewModelIndex())
	if not vm:IsValid() then return end

	local selfTable = self:GetTable()

	local currentShotTime = CurTime()
	local timeSinceLastShot = math.abs(currentShotTime - self:GetLastShotTime())

	-- Drain off any heat from prior shots.
	selfTable.m_gunHeat = selfTable.m_gunHeat - timeSinceLastShot * (1.0 / SECONDS_FOR_COOL_DOWN)
	if selfTable.m_gunHeat <= 0.0 then
		selfTable.m_gunHeat = 0.0
	end

	-- Add the new heat to the gun.
	selfTable.m_gunHeat = selfTable.m_gunHeat + heat
	if selfTable.m_gunHeat > 1.0 then
		-- Reset the heat so we have to build up to it again.
		selfTable.m_gunHeat = 0.0
		selfTable.m_smokeAttachments = bit.bor(selfTable.m_smokeAttachments, bit.lshift(1, iAttachmentIndex))
	end

	-- Logic for the gun smoke.
	-- We don't want to hammer the smoke effect too much, so prevent smoke from spawning too soon after the last smoke.
	if selfTable.m_smokeAttachments ~= 0 and currentShotTime - selfTable.m_lastSmokeTime > MIN_TIME_BETWEEN_SMOKES then
		local pszHeatEffect = self:GetHeatEffectName()

		if pszHeatEffect and #pszHeatEffect > 0 then
			local i = 1
			repeat
				local attachmentFlag = bit.lshift(1, i)

				if bit.band(attachmentFlag, selfTable.m_smokeAttachments) > 0 then
					-- Remove the attachment flag from the smoke attachments since we are firing it off.
					selfTable.m_smokeAttachments = bit.band(selfTable.m_smokeAttachments, bit.bnot(attachmentFlag))

					-- Dispatch this effect to the split screens that are rendering this first person view model.
					ParticleEffectAttach(pszHeatEffect, PATTACH_POINT_FOLLOW, vm, i)
					selfTable.m_lastSmokeTime = currentShotTime
					--break
				end

				i = i + 1
			until (i == MAX_SMOKE_ATTACHMENT_INDEX or selfTable.m_smokeAttachments == 0)
		end

		-- Reset the smoke attachments so that we can start doing a smoke effect for later shots.
		selfTable.m_smokeAttachments = 0
	end
end

function SWEP:GetMuzzleFlashEffect1stPerson()
	if not self.ItemVisuals then
		return ""
	end

	if self:GetHasSilencer() and self:GetSilencerOn() and not self:HasBuiltInSilencer() then
		return self.ItemVisuals.muzzle_flash_effect_1st_person_alt or ""
	else
		return self.ItemVisuals.muzzle_flash_effect_1st_person or ""
	end
end
function SWEP:GetMuzzleFlashEffect3rdPerson()
	if not self.ItemVisuals then
		return ""
	end

	if self:GetHasSilencer() and self:GetSilencerOn() and not self:HasBuiltInSilencer() then
		return self.ItemVisuals.muzzle_flash_effect_3rd_person_alt or ""
	else
		return self.ItemVisuals.muzzle_flash_effect_3rd_person or ""
	end
end

function SWEP:GetHeatEffectName()
	return self.ItemVisuals.heat_effect or ""
end

function SWEP:GetMuzzleAttachmentIndex_3rdPerson()
	if self:GetHasSilencer() and self:GetSilencerOn() and not self:HasBuiltInSilencer() then
		return self:LookupAttachment("muzzle_flash2")
	end

	return self:LookupAttachment("muzzle_flash")
end
function SWEP:GetMuzzleAttachmentIndex_1stPerson(vm)
	if IsValid(vm) then
		if self:GetHasSilencer() and self:GetSilencerOn() and not self:HasBuiltInSilencer() then
			return vm:LookupAttachment("muzzle_flash2")
		end

		return vm:LookupAttachment("1")
	end

	return 0
end

local halloween_lover = GetConVar("swcs_halloween_casings")
function SWEP:GetEjectBrassEffectName()
	if not self.ItemVisuals then
		return ""
	end

	local effectName = self.ItemVisuals.eject_brass_effect or ""

	if #effectName > 0 and (swcs.IsHalloween() and (not halloween_lover or halloween_lover:GetBool())) then
		return "weapon_shell_casing_candycorn"
	end

	return effectName
end
function SWEP:GetEjectBrassAttachmentIndex_1stPerson(vm)
	if IsValid(vm) and isentity(vm) then
		return vm:LookupAttachment("2")
	end

	return 0
end
function SWEP:GetEjectBrassAttachmentIndex_3rdPerson()
	return self:LookupAttachment("shell_eject")
end

local TRACER_ORIGIN_FRAME_NUMBER = 0
local TRACER_ORIGIN_CACHE = Vector()
local TRACER_ORIGIN_CACHE_ANG = Angle()
function SWEP:GetTracerOrigin()
	local owner = self:GetOwner()
	if not owner:IsValid() then
		return Vector()
	end

	local bIsPlayer = owner:IsPlayer()
	local bDrawPlayer = not bIsPlayer

	if CLIENT then
		local observerTarget = LocalPlayer():GetObserverTarget()
		if ((self:IsCarriedByLocalPlayer() and owner:ShouldDrawLocalPlayer()) or
				(not self:IsCarriedByLocalPlayer() and (owner ~= observerTarget or owner == observerTarget and LocalPlayer():GetObserverMode() ~= OBS_MODE_IN_EYE))) then
			bDrawPlayer = true
		end
	end

	local vm = bIsPlayer and owner:GetViewModel()
	local iAttachmentIndex = not bDrawPlayer and self:GetMuzzleAttachmentIndex_1stPerson(vm) or self:GetMuzzleAttachmentIndex_3rdPerson()

	local vecPos = owner:EyePos()

	local tAttachment

	if bDrawPlayer then
		tAttachment = self:GetAttachment(iAttachmentIndex)
	elseif vm and vm:IsValid() then
		if CLIENT then
			local pos = vm:GetPos()

			-- why is my viewmodel at origin gmod
			if pos:IsZero() then
				if TRACER_ORIGIN_FRAME_NUMBER ~= FrameNumber() then
					local ang = owner:EyeAngles()
					pos, ang = self:CalcViewModelView(vm, vecPos * 1, ang * 1, vecPos * 1, ang * 1)
					vm:SetPos(pos)
					vm:SetAngles(ang)

					-- wiki has no return type guh
					---@diagnostic disable-next-line: cast-local-type
					TRACER_ORIGIN_FRAME_NUMBER = FrameNumber()
					TRACER_ORIGIN_CACHE:Set(pos)
					TRACER_ORIGIN_CACHE_ANG:Set(ang)
				else
					vm:SetPos(TRACER_ORIGIN_CACHE)
					vm:SetAngles(TRACER_ORIGIN_CACHE_ANG)
				end
			end
		end

		tAttachment = vm:GetAttachment(iAttachmentIndex)
	end

	if tAttachment then
		vecPos:Set(tAttachment.Pos)
	end

	return vecPos
end

local swcs_drawtracers_movetonotintersect = CLIENT and CreateClientConVar("swcs_drawtracers_movetonotintersect", "1", true, false, "Move tracers to not intersect with world")
local swcs_drawtracers_firstperson = CLIENT and CreateClientConVar("swcs_drawtracers_firstperson", "1", true, false, "Toggle visibility of first person weapon tracers")

function SWEP:DoTracer(pszTracerEffectName, vecSrc, vecEnd, iTracerFreq)
	if iTracerFreq == 0 then return end

	local owner = self:GetOwner()
	if not owner:IsValid() then
		return
	end

	if SERVER and game.SinglePlayer() and owner:IsPlayer() then return end

	local viewmodel = owner:IsPlayer() and owner:GetViewModel(self:ViewModelIndex()) or NULL
	if CLIENT and viewmodel:IsValid() and swcs_drawtracers_firstperson and not swcs_drawtracers_firstperson:GetBool() then
		return
	end

	if not (isstring(pszTracerEffectName) and #pszTracerEffectName > 0) then
		return --[[print("bad tracer effect", self, pszTracerEffectName)]]
	end

	local nBulletNumber = self:GetMaxClip1() - self:Clip1()

	if nBulletNumber % iTracerFreq ~= 0 then
		return
	end

	vecSrc = self:GetTracerOrigin()

	-- if the tracer visually hits anything that it should not, we move the tracer to almost match the bullet trace itself
	if CLIENT and swcs_drawtracers_movetonotintersect and swcs_drawtracers_movetonotintersect:GetBool() then
		local tr = util.TraceLine({
			start = vecSrc,
			endpos = vecEnd,
			mask = MASK_SHOT,
			filter = {self, owner},
			collisiongroup = COLLISION_GROUP_PROJECTILE,
		})

		if tr.Fraction ~= 1.0 then
			vecSrc = owner:EyePos()

			local vangles = owner:EyeAngles()
			local vforward, vright = vangles:Forward(), vangles:Right()

			vright:Mul(self.ViewModelFlip and -2.5 or 2.5)
			vforward:Mul(10)
			vecSrc:Add(vright)
			vecSrc:Add(vforward)
			vecSrc.z = vecSrc.z - 2.5

			util.ParticleTracerEx(pszTracerEffectName, vecSrc, vecEnd, true, -1, -1)
			return
		end
	end

	local iAttachment = -1
	if SERVER then
		iAttachment = self:GetMuzzleAttachmentIndex_3rdPerson()
	end

	local iEntIndex = owner:IsPlayer() and self:EntIndex() or owner:EntIndex()
	util.ParticleTracerEx(pszTracerEffectName, vecSrc, vecEnd, true, iEntIndex, iAttachment)
end

function SWEP:DoFireEffects()
	if SERVER and game.SinglePlayer() then
		self:CallOnClient("DoFireEffects")
		return
	end

	local selfTable = self:GetTable()
	local shouldEmitLight = not selfTable.GetHasSilencer(self) or (selfTable.InvertMuzzleEffects and selfTable.GetSilencerOn(self) or false)

	local owner = self:GetOwner()
	if not owner:IsValid() then return end
	if owner:IsDormant() then return end

	if CLIENT then
		if self:IsCarriedByLocalPlayer() and not owner:ShouldDrawLocalPlayer() then return end
		if owner == LocalPlayer():GetObserverTarget() and LocalPlayer():GetObserverMode() == OBS_MODE_IN_EYE then return end
	end

	-- Muzzle Flash Effect.
	local iAttachmentIndex = selfTable.GetMuzzleAttachmentIndex_3rdPerson(self)
	local pszEffect = selfTable.GetMuzzleFlashEffect3rdPerson(self)
	if pszEffect and #pszEffect > 0 and iAttachmentIndex > 0 and not self:GetNoDraw() then
		ParticleEffectAttach(pszEffect, PATTACH_POINT_FOLLOW, self, iAttachmentIndex)
	end

	if SERVER and owner:IsPlayer() then
		swcs.SendMuzzleflashLight(owner)

		local filter = RecipientFilter()
		filter:AddPVS(self:GetPos())
		filter:RemovePlayer(owner --[[@as Player]])

		net.Start("swcs_CallOnClients", true)
		net.WriteEntity(self)
		net.WriteString("DoFireEffects")
		net.WriteString("")
		net.Send(filter)
	elseif CLIENT and self:IsCarriedByLocalPlayer() and owner:ShouldDrawLocalPlayer() then
		if shouldEmitLight then
			local vecPos = owner:EyePos()

			local tAttachment = self:GetAttachment(iAttachmentIndex)
			if tAttachment then
				vecPos:Set(tAttachment.Pos)
			end

			--local vAngles = EyeAngles()
			--local vForward, vRight = vAngles:Forward(), vAngles:Right()

			--origin:Add(vRight * (cl_righthand:GetBool() and 4 or -4))
			--origin:Add(vRight * 4)
			--origin:Add(vForward * 31)
			--origin.z = origin.z + 3.0

			local light = DynamicLight(self:EntIndex())
			light.pos = vecPos
			light.r = 255
			light.g = 186
			light.b = 64
			light.brightness = 5
			light.size = 70
			light.dietime = CurTime() + 0.05
			light.decay = 768
		end
	end

	-- Brass Eject Effect.
	iAttachmentIndex = selfTable.GetEjectBrassAttachmentIndex_3rdPerson(self)
	pszEffect = selfTable.GetEjectBrassEffectName(self)
	if pszEffect and #pszEffect > 0 and iAttachmentIndex > 0 and not self:GetNoDraw() and not selfTable.GetIsRevolver(self) then
		ParticleEffectAttach(pszEffect, PATTACH_POINT_FOLLOW, self, iAttachmentIndex)
	end
end
