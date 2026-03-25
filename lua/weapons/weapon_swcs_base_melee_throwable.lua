SWEP.Base = "weapon_swcs_knife"

DEFINE_BASECLASS(SWEP.Base)

SWEP.PrintName = "melee_throwable"
SWEP.Spawnable = false
SWEP.HoldType = "slam"

SWEP.IsBaseWep = true

SWEP.SlashSound = "Weapon_Knife_CSGO.Stab"
SWEP.Swing1Damage = 24
SWEP.Swing2Damage = 20

SWEP.BackstabPrimaryDamage = 40

SWEP.m_bWasThrown = false
SWEP.m_hPhysicsAttacker = NULL

-- literally throwing the swep at people
function SWEP:Initialize(...)
	if self.m_iPhysCallback then
		self:RemoveCallback("PhysicsCollide", self.m_iPhysCallback)
	end

	if SERVER then
		self.m_iPhysCallback = self:AddCallback("PhysicsCollide", function(self, data)
			local other = data.HitEntity

			if not self.m_bWasThrown then return end

			local phys = data.PhysObject
			local bIsPlayer = other:IsPlayer()
			local bIsBreakable = swcs.IsBreakableEntity(other)

			if bIsPlayer or other:IsNPC() or other:IsNextBot() or bIsBreakable then
				if bIsPlayer then
					other:SetLastHitGroup(HITGROUP_GENERIC)
				end

				local dmginfo = DamageInfo()
				dmginfo:SetDamage(60)
				dmginfo:SetDamageType(DMG_CLUB)
				dmginfo:SetAttacker(self.m_hPhysicsAttacker)
				dmginfo:SetInflictor(self)
				dmginfo:SetDamagePosition(data.HitPos)
				dmginfo:SetDamageForce(phys:GetVelocity())
				other:TakeDamageInfo(dmginfo)

				if not bIsBreakable then
					phys:SetVelocity(Vector())
					phys:SetAngleVelocity(Vector())
				end
			end

			timer.Simple(0, function()
				if self:IsValid() then
					local owner = self:GetOwner()
					if owner:IsValid() and owner:GetWeapon(self:GetClass()) ~= self then
						self:SetOwner(NULL)
						self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
						self:AddSolidFlags(FSOLID_TRIGGER)
					end
				end
				if phys:IsValid() then
					phys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
				end

				-- moved into this timer because of cases where it touches the ground at the same time it kills an enemy
				-- (e.g. sloped surfaces) causing it to attribute the kill to the weapon
				self.m_hPhysicsAttacker = NULL
			end)

			self.m_iPhysCallback = nil
			self.m_bWasThrown = false
		end)
	end

	return BaseClass.Initialize(self, ...)
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", "InThrow")
end

function SWEP:PrimaryAttack()
	if self:GetInThrow() then self:SetInThrow(false) end

	BaseClass.PrimaryAttack(self)
end

function SWEP:SecondaryAttack()
	if not self.m_bProcessingActivities then return end

	local owner = self:GetPlayerOwner()
	if not owner then return end

	if not self:GetInThrow() then
		self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
		self:SetInThrow(true)
		self:SetWeaponAnim(ACT_VM_SWINGHARD)
	end
end

function SWEP:Think()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	if self:GetInThrow() and not owner:KeyDown(IN_ATTACK) and owner:KeyDownLast(IN_ATTACK2) and not owner:KeyDown(IN_ATTACK2) then
		self:SetWeaponAnim(ACT_VM_RELEASE)

		self:EmitProjectile()
	end

	BaseClass.Think(self)
end

function SWEP:Holster()
	self:SetInThrow(false)

	return BaseClass.Holster(self)
end

function SWEP:Deploy(...)
	self:SetInThrow(false)

	return BaseClass.Deploy(self, ...)
end

function SWEP:EmitProjectile()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	if SERVER then
		self:SwitchToPreviousWeapon()
		owner:DropWeapon(self)

		hook.Run("PlayerSpawnedSWEP", owner, self)

		local dir = owner:GetAimVector()
		local pos = owner:GetShootPos()
		pos:Add(dir:Cross(vector_up) * 4)

		--self:SetPos(pos)

		self.m_bWasThrown = true
		self.m_hPhysicsAttacker = owner
		self:RemoveSolidFlags(FSOLID_TRIGGER)
		self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
		self:SetOwner(owner)

		timer.Simple(0.5, function()
			if self:IsValid() then
				local owner = self:GetOwner()

				if owner:IsValid() and owner:GetWeapon(self:GetClass()) ~= self then
					self:SetOwner(NULL)
				end
			end
		end)

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetVelocityInstantaneous(dir * 800)
			phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
			phys:SetAngleVelocityInstantaneous(Vector(0, 360))
		end
	end
end

function SWEP:WeaponIdle()
	if self:GetInThrow() and self:GetWeaponIdleTime() <= CurTime() then
		self:EmitProjectile()

		self:SwitchToPreviousWeapon()

		if SERVER then
			self:GetOwner():StripWeapon(self:GetClass())
		end

		return
	end

	BaseClass.WeaponIdle(self)
end

hook.Add("PlayerCanPickupWeapon", "swcs.throwable", function(ply, wep)
	if wep.IsSWCSWeapon and wep.m_bWasThrown and wep:GetVelocity():Length() <= 10 then
		return false
	end
end)
