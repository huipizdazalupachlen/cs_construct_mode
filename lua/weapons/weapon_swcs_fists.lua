SWEP.Base = "weapon_swcs_base"
SWEP.Category = "#spawnmenu.category.swcs"

DEFINE_BASECLASS(SWEP.Base)

SWEP.Slot = 0

SWEP.PrintName = "Bare Hands"
SWEP.Spawnable = true
SWEP.HoldType = "fist"
SWEP.NoCrosshair = true

SWEP.ViewModel = Model("models/weapons/csgo/v_fists.mdl")
SWEP.WorldModel = ""
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/fists.png", "smooth")
end

SWEP.ItemDefAttributes = [=["attributes 08/03/2020" {
	"primary clip size" "-1"
	"is full auto" "1"
	"armor ratio"		"0.99"
	"recoil seed" "0"
	"recoil angle variance" "0"
	"recoil magnitude" "0"
	"recoil magnitude variance" "0"
	"recoil angle variance alt" "0"
	"recoil magnitude alt" "0"
	"recoil magnitude variance alt" "0"
}]=]
SWEP.ItemDefVisuals = [=["visuals 08/03/2020" {
}]=]

sound.Add({
	name = "Gloves.Swish",
	channel = CHAN_WEAPON,
	volume = {0.1, 0.3},
	level = 100,
	pitch = {98, 102},
	sound = {
		Sound(")physics/flesh/fist_swing_01.wav"),
		Sound(")physics/flesh/fist_swing_02.wav"),
		Sound(")physics/flesh/fist_swing_03.wav"),
		Sound(")physics/flesh/fist_swing_04.wav"),
		Sound(")physics/flesh/fist_swing_05.wav"),
		Sound(")physics/flesh/fist_swing_05.wav"),
	},
})

sound.Add({
	name = "Flesh.ImpactGloves",
	channel = CHAN_WEAPON,
	volume = {0.2, 0.5},
	level = 100,
	pitch = {98, 102},
	sound = {
		Sound("physics/flesh/fist_hit_01.wav"),
		Sound("physics/flesh/fist_hit_02.wav"),
		Sound("physics/flesh/fist_hit_03.wav"),
		Sound("physics/flesh/fist_hit_04.wav"),
		Sound("physics/flesh/fist_hit_05.wav"),
	},
})

sound.Add({
	name = "Flesh.ImpactSoftGloves",
	channel = CHAN_WEAPON,
	volume = 1.0,
	level = 100,
	pitch = {98, 103},
	sound = {
		Sound("physics/body/body_impact_fists_01.wav"),
		Sound("physics/body/body_impact_fists_02.wav"),
		Sound("physics/body/body_impact_fists_03.wav"),
		Sound("physics/body/body_impact_fists_04.wav"),
		Sound("physics/body/body_impact_fists_05.wav"),
	},
})


function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Float", "AttackDelay")
end

function SWEP:PrimaryAttack()
	local owner = self:GetPlayerOwner()
	if owner and owner:IsValid() then
		owner:LagCompensation(true)
	end

	self:Swing()

	if owner and owner:IsValid() then
		owner:LagCompensation(false)
	end
end

function SWEP:Swing()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local vForward = owner:GetAimVector()
	local vecSrc = owner:GetShootPos()
	local vecEnd = vecSrc + vForward * 68

	local function trace_filter(ent)
		if ent == owner then return false end
		if ent:GetOwner() == owner then return false end

		return true
	end

	local tr = util.TraceLine({
		start = vecSrc,
		endpos = vecEnd,
		mask = MASK_SOLID,
		collisiongroup = COLLISION_GROUP_NONE,
		filter = trace_filter,
	})
	if not tr.Hit then
		util.TraceHull({
			start = vecSrc,
			endpos = vecEnd,
			mask = MASK_SOLID,
			collisiongroup = COLLISION_GROUP_NONE,
			filter = trace_filter,
			mins = vector_origin,
			maxs = vector_origin,
			output = tr,
		})
	end

	local bDidHit = tr.Fraction < 1

	self:SetWeaponAnim(ACT_VM_HITCENTER)
	self:EmitSound("Gloves.Swish")

	local time = CurTime() + 0.5
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)

	if bDidHit then
		local ent = tr.Entity

		local info = DamageInfo()
		info:SetInflictor(self)
		info:SetAttacker(owner)
		info:SetDamage(15)
		info:SetDamageType(DMG_GENERIC)
		info:SetDamagePosition(tr.HitPos)
		info:SetReportedPosition(tr.StartPos)

		local force = vForward:GetNormal() * GetConVar("phys_pushscale"):GetFloat()
		info:SetDamageForce(force)

		if SERVER and ent:IsPlayer() then
			ent:SetLastHitGroup(HITGROUP_GENERIC)
		end

		if SERVER then
			-- disable player pushback on bullet damage
			-- what the fuck
			if ent:IsPlayer() then
				owner:AddSolidFlags(FSOLID_TRIGGER)
			end

			ent:TakeDamageInfo(info)

			if ent:IsPlayer() then
				owner:RemoveSolidFlags(FSOLID_TRIGGER)
			end
		end

		if ent:IsValid() or ent == game.GetWorld() then
			local soundname

			if (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
				soundname = "Flesh.BulletImpact_CSGO"
			else
				local seed = self:GetRandomSeed()
				seed = seed + 1

				local rand = UniformRandomStream(seed)

				self:SetViewPunchAngle(Angle(rand:RandomInt(5, 10), rand:RandomInt(5, 10), rand:RandomInt(5, 10)))

				self:EmitSound("Flesh.ImpactGloves")

				local surfaceData = util.GetSurfaceData(tr.SurfaceProps)
				if surfaceData then
					soundname = surfaceData.impactSoftSound
				end
			end

			if soundname then
				local filter
				if SERVER then
					filter = RecipientFilter()
					filter:AddPVS(tr.HitPos)
					filter:RemovePlayer(owner --[[@as Player]])
				end

				if IsFirstTimePredicted() then
					EmitSound(soundname, tr.HitPos, nil, nil, nil, nil, nil, nil, nil, filter)
				end
			end
		end
	end

	owner:SetAnimation(PLAYER_ATTACK1)
end

local swcs_weapon_disarm = CreateConVar("swcs_weapon_disarm", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "whether certain weapons should disarm players when hit by them")
function SWEP:PowerfulSwing()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local vForward = owner:GetAimVector()
	local vecSrc = owner:GetShootPos()
	local vecEnd = vecSrc + vForward * 78

	local function trace_filter(ent)
		if ent == owner then return false end
		if ent:GetOwner() == owner then return false end

		return true
	end

	local tr = util.TraceLine({
		start = vecSrc,
		endpos = vecEnd,
		mask = MASK_SOLID,
		collisiongroup = COLLISION_GROUP_NONE,
		filter = trace_filter,
	})
	if not tr.Hit then
		util.TraceHull({
			start = vecSrc,
			endpos = vecEnd,
			mask = MASK_SOLID,
			collisiongroup = COLLISION_GROUP_NONE,
			filter = trace_filter,
			mins = vector_origin,
			maxs = vector_origin,
			output = tr,
		})
	end

	local bDidHit = tr.Fraction < 1

	self:EmitSound("Gloves.Swish")

	if bDidHit then
		local ent = tr.Entity

		local info = DamageInfo()
		info:SetInflictor(self)
		info:SetAttacker(owner)
		info:SetDamage(30)
		info:SetDamageType(DMG_GENERIC)
		info:SetDamagePosition(tr.HitPos)
		info:SetReportedPosition(tr.StartPos)

		local force = vForward * GetConVar("phys_pushscale"):GetFloat()
		info:SetDamageForce(force)

		if SERVER and ent:IsPlayer() then
			ent:SetLastHitGroup(HITGROUP_GENERIC)

			local victimWep = ent:GetActiveWeapon()
			if swcs_weapon_disarm:GetBool() and victimWep:IsValid() and hook.Run("SWCSShouldDisarmPlayer", owner, self, ent, victimWep) ~= false then
				local dir = Vector(vForward)
				dir.z = 0
				dir:Normalize()

				ent:DropWeapon(nil, ent:GetShootPos() + (dir * 128))
			end
		end

		if SERVER then
			-- disable player pushback on bullet damage
			-- what the fuck
			if ent:IsPlayer() then
				owner:AddSolidFlags(FSOLID_TRIGGER)
			end

			ent:TakeDamageInfo(info)

			if ent:IsPlayer() then
				owner:RemoveSolidFlags(FSOLID_TRIGGER)
			end
		end

		if ent:IsValid() or ent == game.GetWorld() then
			local soundname

			if (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
				soundname = "Flesh.BulletImpact_CSGO"
			else
				local seed = self:GetRandomSeed()
				seed = seed + 1

				local rand = UniformRandomStream(seed)

				self:SetViewPunchAngle(Angle(rand:RandomInt(5, 10), rand:RandomInt(5, 10), rand:RandomInt(5, 10)))

				self:EmitSound("Flesh.ImpactGloves")

				local surfaceData = util.GetSurfaceData(tr.SurfaceProps)
				if surfaceData then
					soundname = surfaceData.impactHardSound or surfaceData.impactSoftSound
				end
			end

			if soundname then
				local filter
				if SERVER then
					filter = RecipientFilter()
					filter:AddPVS(tr.HitPos)
					filter:RemovePlayer(owner --[[@as Player]])
				end

				if IsFirstTimePredicted() then
					EmitSound(soundname, tr.HitPos, nil, nil, nil, nil, nil, nil, nil, filter)
				end
			end
		end
	end
end

function SWEP:SecondaryAttack()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	self:SetWeaponSequence(self:LookupSequence("punch_hard"), 0.9)

	local time = self:GetWeaponIdleTime()
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)

	self:SetAttackDelay(CurTime() + 0.8)
end

function SWEP:Think()
	BaseClass.Think(self)

	local owner = self:GetPlayerOwner()
	if not owner or not owner:IsValid() then return end

	if self:GetAttackDelay() ~= 0 and self:GetAttackDelay() <= CurTime() then
		self:SetAttackDelay(0)

		owner:SetAnimation(PLAYER_ATTACK1)

		owner:LagCompensation(true)
		self:PowerfulSwing()
		owner:LagCompensation(false)
	end

	if CLIENT then
		local vm = owner:GetViewModel(self:ViewModelIndex())

		if vm:IsValid() and IsFirstTimePredicted() then
			local flMaxSpeed = self.GetMaxSpeed and self:GetMaxSpeed() or 250
			local mult = flMaxSpeed / 250
			if mult < 0 then
				mult = 1
			end

			flMaxSpeed = owner:GetWalkSpeed() * mult
			vm:SetPoseParameter("running", owner:GetVelocity():Length2D() / flMaxSpeed)
		end
	end
end

swcs.WeaponsDontDisarm = {
	["none"] = true,
	["weapon_fists"] = true,
	["weapon_swcs_fists"] = true,
	["weapon_swcs_shield"] = true,
	["gmod_tool"] = true,
	["weapon_physgun"] = true,

	["weapon_slap"] = true,
	["weapon_ttt_unarmed"] = true,
	["weapon_zm_carry"] = true,
}
hook.Add("SWCSShouldDisarmPlayer", "swcs.fists", function(owner, wep, victim, victimWep)
	local classname = victimWep:GetClass()
	if swcs.WeaponsDontDisarm[classname] then return false end

	if swcs.InTTT then
		if victimWep.IsKnife then return false end
	end
end)

function SWEP:OnDrop(...)
	BaseClass.OnDrop(self, ...)

	self:Remove() -- You can't drop fists
end

function SWEP:Holster(...)
	self:SetAttackDelay(0)

	return BaseClass.Holster(self, ...)
end

function SWEP:Deploy(...)
	self:SetAttackDelay(0)

	return BaseClass.Deploy(self, ...)
end
