SWEP.Base = "weapon_swcs_base"

DEFINE_BASECLASS(SWEP.Base)

SWEP.PrintName = "grenade"
SWEP.Spawnable = false
SWEP.HoldType = "grenade"

SWEP.IsGrenade = true
SWEP.IsBaseWep = true

SWEP.Primary.DefaultClip = 1
SWEP.Primary.ClipSize = -1

SWEP.ItemDefAttributes = [=["attributes 04/22/2020" {}]=]
SWEP.ItemDefVisuals = [=["visuals 07/07/2020" {}]=]
SWEP.ItemDefPrefab = [=["prefab 08/11/2020" {}]=]

local GRENADE_SECONDARY_DAMPENING = 0.3
local GRENADE_SECONDARY_LOWER = 12.0
local GRENADE_SECONDARY_TRANSITION = 1.3
local GRENADE_SECONDARY_INTERP = 2.0
local GRENADE_UNDERHAND_THRESHOLD = 0.33

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", "Redraw")
	self:NetworkVar("Bool", "IsHeldByPlayer")
	self:NetworkVar("Bool", "PinPulled")
	self:NetworkVar("Bool", "LoopingSoundPlaying")
	self:NetworkVar("Float", "ThrowTime")
	self:NetworkVar("Float", "ThrowStrength")

	self:SetRedraw(false)
	self:SetIsHeldByPlayer(false)
	self:SetPinPulled(false)
	self:SetThrowTime(0)
	self:SetLoopingSoundPlaying(false)
	self:SetThrowStrength(0)
end

function SWEP:HasNoAmmo()
	if swcs.InTTT then
		return self.m_bHasEmittedProjectile and self:GetRedraw() --self:Clip1() <= 0
	else
		return BaseClass.HasNoAmmo(self)
	end
end

function SWEP:Deploy()
	self:SetRedraw(false)
	self:SetIsHeldByPlayer(true)
	self:SetPinPulled(false)

	self:SetThrowStrength(1.0)
	self:SetThrowStrengthClientSmooth(1)
	self:SetThrowTime(0)

	-- if we're officially out of grenades, ditch this weapon
	self:RemoveIfExhausted()

	return BaseClass.Deploy(self)
end

function SWEP:Initialize()
	swcs.SetupItemDefGetter(self, "ThrowVelocity", "throw velocity")

	self:SetPinPulled(false)
	BaseClass.Initialize(self, false, self.Prefab == nil)

	self.GetHasSilencer = function() return false end
	self.GetZoomLevels = function() return 0 end
end

function SWEP:Reload()
	if self:GetPinPulled() then
		return false
	end

	if self:GetRedraw() and (self:GetNextPrimaryFire() <= CurTime()) and (self:GetNextSecondaryFire() <= CurTime()) then
		--Redraw the weapon
		self:SetWeaponAnim(ACT_VM_DRAW)

		--Update our times
		self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
		self:SetNextSecondaryFire(CurTime() + self:SequenceDuration())

		self:SetWeaponIdleTime(CurTime() + self:SequenceDuration())

		self.m_bHasEmittedProjectile = false

		--Mark this as done
		self:SetRedraw(false)
		self:SetIsHeldByPlayer(true)
		-- m_bRedraw = false
	end
end

function SWEP:Holster(new_wep)
	-- clear out viewmodel pose parameters
	local owner = self:GetPlayerOwner()
	if owner then
		local vm = owner:GetViewModel(self:ViewModelIndex())

		if vm:IsValid() then
			vm:SetPoseParameter("throwcharge", 0.0)
		end

		self:RemoveIfExhausted(false)
	end

	if self:GetThrowTime() > CurTime() then
		return false
	else
		self:SetRedraw(false)
		self:SetPinPulled(false)
		self:SetThrowStrength(1.0)
		self:SetThrowStrengthClientSmooth(1)
		self:SetThrowTime(0)
	end

	return true
end

SWEP.m_flThrowStrengthClientSmooth = 0
swcs.DefineInterpolatedVar(SWEP, "m_flThrowStrengthClientSmooth", "ThrowStrengthClientSmooth", 0, false)
function SWEP:ApproachThrownStrength()
	local val = swcs.Approach(
		self:GetThrowStrengthClientSmooth(),
		self:GetThrowStrength(),
		FrameTime() * GRENADE_SECONDARY_INTERP
	)

	self:SetThrowStrengthClientSmooth(val)
	return val
end

function SWEP:PrimaryAttack()
	if not self:GetPinPulled() then
		self:SetThrowStrength(1)
		self:SetThrowStrengthClientSmooth(1)
	end

	self:BeginThrow()
end

function SWEP:SecondaryAttack()
	if not self:GetPinPulled() then
		self:SetThrowStrength(0)
		self:SetThrowStrengthClientSmooth(0)
	end

	self:BeginThrow()
end

local attempted_cvar = false
local ttt_no_nade_throw_during_prep = GetConVar("ttt_no_nade_throw_during_prep")
local ttt_nade_throw_during_prep = GetConVar("ttt_nade_throw_during_prep")

local function ThrowDuringPrep()
	if ttt_nade_throw_during_prep then
		return ttt_nade_throw_during_prep:GetBool()
	elseif ttt_no_nade_throw_during_prep then
		return not ttt_no_nade_throw_during_prep:GetBool()
	else
		return true
	end
end

function SWEP:BeginThrow()
	-- doesnt load at startup properly aaaaaaaaa
	if swcs.InTTT and not attempted_cvar then
		if not ttt_no_nade_throw_during_prep then
			ttt_no_nade_throw_during_prep = GetConVar("ttt_no_nade_throw_during_prep")
		end
		if not ttt_nade_throw_during_prep then
			ttt_nade_throw_during_prep = GetConVar("ttt_nade_throw_during_prep")
		end
		attempted_cvar = true
	end

	if self:GetNextPrimaryFire() > CurTime() then
		return
	end
	if --[[not self:GetIsHeldByPlayer() or]] self:GetPinPulled() or self:GetThrowTime() > 0 then return end
	if swcs.InTTT and not ThrowDuringPrep() and GetRoundState() == ROUND_PREP then return end

	local owner = self:GetPlayerOwner()
	if not owner then return end

	self:SetWeaponAnim(ACT_VM_PULLPIN)
	self:SetPinPulled(true)

	self:SetWeaponIdleTime(CurTime() + self:SequenceDuration())

	self:SetNextPrimaryFire(self:GetWeaponIdleTime())
end

function SWEP:CalcViewModelView(vm, oldPos, oldAng, pos, ang)
	if self:GetPinPulled() then
		vm:SetPoseParameter("throwcharge", math.Clamp(self:ApproachThrownStrength(), 0, 1))
	else
		vm:SetPoseParameter("throwcharge", 0)
	end

	return BaseClass.CalcViewModelView(self, vm, oldPos, oldAng, pos, ang)
end


hook.Add("DoAnimationEvent", "swcs.grenade", function(ply, event, data)
	local wep = ply:GetActiveWeapon()
	if event == PLAYERANIMEVENT_ATTACK_GRENADE and wep:IsValid() and wep.IsSWCSWeapon and wep.IsGrenade then
		if data == 1 then
			ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_SLAM, true)
			return ACT_INVALID
		else
			ply:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_HL2MP_GESTURE_RANGE_ATTACK_GRENADE, true)
			return ACT_INVALID
		end
	end
end)
function SWEP:Think()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local vm = owner:GetViewModel(self:ViewModelIndex())
	if not vm:IsValid() then return end

	local bPrimaryHeld = (owner:KeyDown(IN_ATTACK))
	local bSecondaryHeld = (owner:KeyDown(IN_ATTACK2))

	if self:GetPinPulled() and (bPrimaryHeld or bSecondaryHeld) then
		local flIdealThrowStrength = 0.5

		if bPrimaryHeld then
			flIdealThrowStrength = flIdealThrowStrength + 0.5
		end

		if bSecondaryHeld then
			flIdealThrowStrength = flIdealThrowStrength - 0.5
		end

		self:SetThrowStrength(swcs.Approach(flIdealThrowStrength, self:GetThrowStrength(), FrameTime() * GRENADE_SECONDARY_TRANSITION))

		if self:IsThrownUnderhand() then
			self:SetHoldType("slam")
		else
			self:SetHoldType("grenade")
		end
	end

	-- If they let go of the fire buttons, they want to throw the grenade.
	if self:GetPinPulled() and not (bPrimaryHeld or bSecondaryHeld) and not (game.SinglePlayer() and CLIENT) then
		self:StartGrenadeThrow()

		self:SetPinPulled(false)

		if self:IsThrownUnderhand() then
			self:SetWeaponAnim(ACT_VM_RELEASE)
		else
			self:SetWeaponAnim(ACT_VM_THROW)
		end

		owner:DoCustomAnimEvent(PLAYERANIMEVENT_ATTACK_GRENADE, self:IsThrownUnderhand() and 1 or 0)

		self:SetWeaponIdleTime(CurTime() + self:SequenceDuration())
		self:SetNextPrimaryFire(self:GetWeaponIdleTime())
	elseif self:GetThrowTime() > 0 and self:GetThrowTime() < CurTime() then
		self:TakePrimaryAmmo(1)
		self:ThrowGrenade()
	elseif not self:GetIsHeldByPlayer() then
		if self:GetWeaponIdleTime() < CurTime() then
			if self:HasNoAmmo() then
				self:RemoveIfExhausted()
			elseif self:GetRedraw() then
				self:Reload()
			end
		end
	elseif not self:GetRedraw() then
		BaseClass.Think(self)
	end
end

function SWEP:CustomAmmoDisplay() end

function SWEP:IsThrownUnderhand()
	return self:GetThrowStrength() <= GRENADE_UNDERHAND_THRESHOLD
end

function SWEP:StartGrenadeThrow()
	self:SetThrowTime(CurTime() + .1)

	self:EmitSound(self.SND_SINGLE or "weapons/hegrenade/he_draw.wav")
end

CONTENTS_GRENADECLIP = 0x80000
function SWEP:ThrowGrenade()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local angThrow = self:GetFinalAimAngle()
	if angThrow.p > 90 then
		angThrow.p = angThrow.p - 360
	elseif angThrow.p <= -90 then
		angThrow.p = angThrow.p + 360
	end

	assert(angThrow.p <= 90.0 and angThrow.p >= -90.0, "Grenade throw pitch angle must be between -90 and 90 for the adustments to work.")

	-- NB. a pitch of +90 is looking straight down, -90 is looking straight up

	-- add a 10 degrees upwards angle to the throw when looking horizontal, lerp the upwards boost to 0 at the pitch extremes
	angThrow.p = angThrow.p - (10.0 * (90.0 - math.abs(angThrow.p)) / 90.0)

	local kBaseVelocity = self:GetThrowVelocity()
	--const float kThrowVelocityClampRatio = 750.0f / 540.0f;	-- from original CSS values

	--float flVel = clamp((90 - angThrow.x) / 90, 0.0f, kThrowVelocityClampRatio) * kBaseVelocity;
	local flVel = math.Clamp(kBaseVelocity * 0.9, 15, 750)

	-- clamp the throw strength ranges just to be sure
	local flClampedThrowStrength = self:GetThrowStrength()
	flClampedThrowStrength = math.Clamp(flClampedThrowStrength, 0.0, 1.0)

	flVel = flVel * Lerp(flClampedThrowStrength, GRENADE_SECONDARY_DAMPENING, 1.0)
	local vForward = angThrow:Forward()

	local vecSrc = owner:GetShootPos()

	vecSrc:Add(Vector(0, 0, Lerp(flClampedThrowStrength, -GRENADE_SECONDARY_LOWER, 0.0)))

	-- We want to throw the grenade from 16 units out.  But that can cause problems if we're facing
	-- a thin wall.  Do a hull trace to be safe.
	-- Wills: Moved the trace length out to 22 inches, then subtract 6. This way we default to 16,
	-- but pull back 6 from wherever we hit, so we don't emit from EXACTLY inside the close surface, which can lead to
	-- the grenade penetrating the wall anyway.
	local trace = {}
	local mins = -Vector(2, 2, 2)
	util.TraceHull({
		start = vecSrc,
		endpos = vecSrc + vForward * 22,
		mins = mins,
		maxs = -mins,
		mask = bit.bor(MASK_SOLID, CONTENTS_GRENADECLIP),
		filter = owner,
		collisiongroup = COLLISION_GROUP_NONE,
		output = trace,
	})
	vecSrc = trace.HitPos - (vForward * 6)

	local vecThrow = vForward * flVel + (owner:GetVelocity() * 1.25)

	local iSeed = self:GetRandomSeed()
	iSeed = iSeed + 1

	local random = UniformRandomStream(iSeed)

	local hProjectile = self:EmitGrenade()
	if hProjectile:IsValid() then
		hProjectile:Create(vecSrc, angle_zero, vecThrow, Angle(600, random:RandomInt(-1200, 1200)), owner)

		hook.Run("PlayerThrowSWCSGrenade", owner, hProjectile)

		if hProjectile:IsValid() then
			hProjectile:Spawn()
			hook.Run("PlayerSpawnedSENT", owner, hProjectile)
		end
	end

	self.m_bHasEmittedProjectile = true -- Flag the grenade weapon as having emitted a projectile. The 'grenade' is now flying away from the player, so we don't want to drop *this* grenade on death (that'll make a duplicate)
	self:SetRedraw(true)
	self:SetIsHeldByPlayer(false)
	self:SetThrowTime(0)
end

function SWEP:DropGrenade()
	local owner = self:GetPlayerOwner()
	if not owner then
		return
	end

	local vForward = owner:GetAimVector()
	local vecSrc = owner:GetShootPos() + vForward * 16

	local vecVel = owner:GetVelocity()

	local iSeed = self:GetRandomSeed()
	iSeed = iSeed + 1

	local random = UniformRandomStream(iSeed)

	local hProjectile = self:EmitGrenade()
	if hProjectile:IsValid() then
		hProjectile:Create(vecSrc, angle_zero, vecVel, Angle(600, random:RandomInt(-1200, 1200)), owner)
		hProjectile:Spawn()
	end

	self:SetRedraw(true)
	self:SetIsHeldByPlayer(false)
	self:SetThrowTime(0)
end

function SWEP:EmitGrenade(vecSrc, angles, vecVel, vecAngImpulse, owner)
	return assert(NULL, "swcs_base_grenade:EmitGrenade() should not be called. Make sure to implement this in your subclass!\n")
end

function SWEP:DrawWorldModel(flags)
	for id, val in next, self.WM_BodyGroups do
		self:SetBodygroup(id, val)
	end

	if self:GetIsHeldByPlayer() or not self:GetOwner():IsValid() then
		self:DrawModel(flags)
	end
end
