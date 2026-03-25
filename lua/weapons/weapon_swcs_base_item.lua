SWEP.Base = "weapon_swcs_base"

DEFINE_BASECLASS(SWEP.Base)

SWEP.PrintName = "item"
SWEP.Spawnable = false
SWEP.HoldType = "slam"

SWEP.IsItem = true
SWEP.IsBaseWep = true


if swcs.InTTT then
	SWEP.Primary.Ammo = "none"
	SWEP.Primary.ClipSize = 1
	SWEP.Primary.DefaultClip = 1
else
	SWEP.Primary.ClipSize = -1
	SWEP.Primary.DefaultClip = 1
end

function SWEP:Initialize()
	BaseClass.Initialize(self, false)

	self.m_UseTimer = swcs.CountdownTimer()
	self.m_UseTimer:Invalidate()
end

function SWEP:Deploy(...)
	self:SetRedraw(false)
	self.m_UseTimer:Invalidate()
	self:RemoveIfExhausted()

	return BaseClass.Deploy(self, ...)
end

function SWEP:Holster(...)
	local owner = self:GetOwner()
	if self:GetVisuallyUsed() then
		-- emit event

		if not self:CompleteUse(owner) then
			owner:RemoveAmmo(1, self:GetPrimaryAmmoType())
		end

		self:SetVisuallyUsed(false)
	end

	self:SetRedraw(false)
	self.m_UseTimer:Invalidate()
	self:RemoveIfExhausted(false)

	return BaseClass.Holster(self, ...)
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", "Redraw")
	self:NetworkVar("Bool", "VisuallyUsed")

	self:SetRedraw(false)
end

function SWEP:CanUseOnSelf(ply)
	return true
end

function SWEP:PrimaryAttack()
	if not self.m_bProcessingActivities then return end
	local owner = self:GetPlayerOwner()
	if not owner then return end

	if self.m_UseTimer:HasStarted() then return end
	if self:GetRedraw() then return end

	if not self:CanUseOnSelf(owner) then return end

	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	--owner:DoAnimationEvent(PLAYERANIMEVENT_FIRE_GUN_PRIMARY)

	self:OnStartUse(owner)

	self:SetNextPrimaryFire(CurTime() + self:GetUseTimerDuration())
	self.m_UseTimer:Start(self:GetUseTimerDuration())
end

function SWEP:OnStartUse(ply) end

function SWEP:GetUseTimerDuration()
	return self:SequenceDuration()
end

function SWEP:Reload()
	if self:GetRedraw() and (self:GetNextPrimaryFire() <= CurTime()) and (self:GetNextSecondaryFire() <= CurTime()) then
		--Redraw the weapon
		self:SetWeaponAnim(ACT_VM_DRAW)

		--Update our times
		self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
		self:SetNextSecondaryFire(CurTime() + self:SequenceDuration())

		self:SetWeaponIdleTime(CurTime() + self:SequenceDuration())

		self:RemoveIfExhausted()

		--Mark this as done
		self:SetRedraw(false)
	end
end

function SWEP:Think()
	BaseClass.Think(self)

	local owner = self:GetPlayerOwner()
	if not owner then return end

	if self.m_UseTimer and self.m_UseTimer:HasStarted() and self.m_UseTimer:IsElapsed() then
		-- pills can only help you so much
		if owner and not owner:Alive() then
			self.m_UseTimer:Invalidate()
			return
		end

		self:SetRedraw(true)

		self.m_UseTimer:Invalidate()

		-- remove the ammo
		if not self:CompleteUse(owner) then
			owner:RemoveAmmo(1, self:GetPrimaryAmmoType())
		end

		self:SetVisuallyUsed(false)
	elseif self:GetRedraw() then
		self:Reload()
	end
end

function SWEP:OnVisualUse()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	self:SetVisuallyUsed(true)
end

function SWEP:CompleteUse(ply) end
