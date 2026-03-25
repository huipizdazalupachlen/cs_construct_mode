SWEP.Base = "weapon_swcs_base"

SWEP.PrintName = "Knife"
SWEP.Spawnable = false
SWEP.HoldType = "knife"

SWEP.WorldModel = Model("models/weapons/csgo/w_knife_default_t.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_knife_default_t.mdl")

SWEP.Slot = 0
if swcs.InTTT then
	SWEP.Kind = WEAPON_MELEE
	--SWEP.InLoadoutFor  = {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE}
	SWEP.NoSights = true
	SWEP.IsSilent = true
	SWEP.Weight = 5
	SWEP.AutoSpawnable = false
	SWEP.AllowDelete = false
	SWEP.AllowDrop = false
end

SWEP.ItemDefAttributes = [=["attributes 08/03/2020" {
	"primary clip size" "-1"
	"is full auto" "1"
	"armor ratio"		"1.700000"
	"recoil seed" "0"
	"recoil angle variance" "0"
	"recoil magnitude" "0"
	"recoil magnitude variance" "0"
	"recoil angle variance alt" "0"
	"recoil magnitude alt" "0"
	"recoil magnitude variance alt" "0"
}]=]
SWEP.ItemDefVisuals = [=["visuals 08/03/2020" {
	"weapon_type" "knife"
}]=]

SWEP.IsKnife = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Automatic = true

DEFINE_BASECLASS(SWEP.Base)

sound.Add({
	name = "Weapon_Knife_CSGO.Deploy",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.1,
	sound = Sound(")weapons/csgo/knife/knife_deploy1.wav"),
})
sound.Add({
	name = "Weapon_Knife_CSGO.Hit",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.6,
	sound = {Sound(")weapons/csgo/knife/knife_hit1.wav"), Sound(")weapons/csgo/knife/knife_hit2.wav"), Sound(")weapons/csgo/knife/knife_hit3.wav"), Sound(")weapons/csgo/knife/knife_hit4.wav")},
})
sound.Add({
	name = "Weapon_Knife_CSGO.HitWall",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.6,
	sound = {Sound(")weapons/csgo/knife/knife_hit_01.wav"), Sound(")weapons/csgo/knife/knife_hit_02.wav"), Sound(")weapons/csgo/knife/knife_hit_03.wav"), Sound(")weapons/csgo/knife/knife_hit_04.wav"), Sound(")weapons/csgo/knife/knife_hit_05.wav")},
})
sound.Add({
	name = "Weapon_Knife_CSGO.Slash",
	channel = CHAN_WEAPON,
	level = 65,
	volume = 0.6,
	pitch = {97, 105},
	sound = {Sound(")weapons/csgo/knife/knife_slash1.wav"), Sound(")weapons/csgo/knife/knife_slash2.wav")},
})
sound.Add({
	name = "Weapon_Knife_CSGO.Stab",
	channel = CHAN_WEAPON,
	level = 65,
	volume = 0.6,
	pitch = {97, 105},
	sound = Sound(")weapons/csgo/knife/knife_stab.wav"),
})
sound.Add({
	name = "Player.WeaponSelectionClose_T",
	channel = CHAN_ITEM,
	volume = 0.2,
	level = SNDLVL_NORM,
	pitch = {98, 102},
	sound = {Sound(")player/csgo/footsteps/new/suit_t_01.wav"), Sound(")player/csgo/footsteps/new/suit_t_02.wav"), Sound(")player/csgo/footsteps/new/suit_t_03.wav"), Sound(")player/csgo/footsteps/new/suit_t_04.wav"), Sound(")player/csgo/footsteps/new/suit_t_05.wav"), Sound(")player/csgo/footsteps/new/suit_t_06.wav"), Sound(")player/csgo/footsteps/new/suit_t_07.wav"), Sound(")player/csgo/footsteps/new/suit_t_08.wav"), Sound(")player/csgo/footsteps/new/suit_t_09.wav"), Sound(")player/csgo/footsteps/new/suit_t_10.wav"), Sound(")player/csgo/footsteps/new/suit_t_11.wav"), Sound(")player/csgo/footsteps/new/suit_t_12.wav")},
})

if swcs.InTTT then
	function SWEP:OnDrop(...)
		BaseClass.OnDrop(self, ...)
		SafeRemoveEntity(self)
	end
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)
	self:NetworkVar("Bool", "SwingLeft")
end

local hardcoded_knife_deploy_time = 1.0
function SWEP:Deploy()
	-- NOTE (wills): Knives no longer use model bodygroups to change their appearance
	-- between CT and T versions. Team-specific knives now support team-specific
	-- viewmodel and world animations, so they are stored as unique models.
	-- If a knife needs to look aesthetically different between CT/T teams,
	-- add an asset_modifier block to the item definition to divert the whole model.

	-- Fix for different knife models having different deploy times.  If it's short,
	-- you just idle a bit before you attack.  If it's long, we animation-cancel the
	-- deploy animation and go straight into the swing/stab after a fixed amount of
	-- time.
	self:SetNextPrimaryFire(CurTime() + (hardcoded_knife_deploy_time * (1 / self:GetDeploySpeed())))
	self:SetNextSecondaryFire(CurTime() + (hardcoded_knife_deploy_time * (1 / self:GetDeploySpeed())))
	self:SetWeaponIdleTime(CurTime() + (self:SequenceDuration() * (1 / self:GetDeploySpeed())))

	local owner = self:GetPlayerOwner()
	if owner then
		local vm = owner:GetViewModel(self:ViewModelIndex())
		if vm:IsValid() then
			vm:SetPlaybackRate(self:GetDeploySpeed())
		end

		owner:SetSaveValue("m_flNextAttack", SERVER and 0 or CurTime())
	end

	self:SetHoldType(self.HoldType)

	return true
end

function SWEP:PrimaryAttack()
	if self:GetPlayerOwner() then
		self:GetPlayerOwner():LagCompensation(true)
	end

	self:SwingOrStab(Primary_Mode)

	if self:GetPlayerOwner() then
		self:GetPlayerOwner():LagCompensation(false)
	end
end

function SWEP:SecondaryAttack()
	if self:GetPlayerOwner() then
		self:GetPlayerOwner():LagCompensation(true)
	end

	self:SwingOrStab(Secondary_Mode)

	if self:GetPlayerOwner() then
		self:GetPlayerOwner():LagCompensation(false)
	end
end

local KNIFE_RANGE_LONG = 48
local KNIFE_RANGE_SHORT = 32

local head_hull_mins = Vector(-16, -16, -18)
local head_hull_maxs = Vector(16, 16, 18)

local CSGO_DUCK_HULL_MIN = Vector(-16, -16, 0)
local CSGO_DUCK_HULL_MAX = Vector(16, 16, 54)

local function FindHullIntersection(vecSrc, tr, mins, maxs, filter)
	local distance = 1e6
	local tmpTrace = {}
	local minmaxs = {mins, maxs}
	local vecHullEnd = Vector(tr.HitPos)
	local vecEnd = Vector()

	vecHullEnd = vecSrc + ((vecHullEnd - vecSrc) * 2)
	util.TraceLine({
		start = vecSrc,
		endpos = vecHullEnd,
		mask = MASK_SOLID,
		collisiongroup = COLLISION_GROUP_NONE,
		filter = filter,
		output = tmpTrace,
	})

	-- hit
	if tmpTrace.Fraction < 1 then
		table.CopyFromTo(tmpTrace, tr)
		return
	end

	for i = 1, 2 do
		for j = 1, 2 do
			for k = 1, 2 do
				vecEnd.x = vecHullEnd.x + minmaxs[i].x
				vecEnd.y = vecHullEnd.y + minmaxs[j].y
				vecEnd.z = vecHullEnd.z + minmaxs[k].z

				util.TraceLine({
					start = vecSrc,
					endpos = vecEnd,
					mask = MASK_SOLID,
					collisiongroup = COLLISION_GROUP_NONE,
					filter = filter,
					output = tmpTrace,
				})

				if tmpTrace.Fraction < 1 then
					local thisDistance = tmpTrace.HitPos:Distance(vecSrc)
					if thisDistance < distance then
						distance = thisDistance
						table.CopyFromTo(tmpTrace, tr)
					end
				end
			end
		end
	end
end

SWEP.SwingSound = "Weapon_Knife_CSGO.Slash"
SWEP.SlashSound = "Weapon_Knife_CSGO.Hit"
SWEP.HitSound = "Weapon_Knife_CSGO.HitWall"
SWEP.StabSound = "Weapon_Knife_CSGO.Stab"
SWEP.Swing1Damage = 40
SWEP.Swing2Damage = 25

SWEP.BackstabPrimaryDamage = 90

function SWEP:SwingOrStab(weaponMode)
	if game.SinglePlayer() then
		self:CallOnClient("SwingOrStab", weaponMode)
		weaponMode = tonumber(weaponMode)
	end

	local owner = self:GetPlayerOwner()
	if not owner then return end

	local fRange = (weaponMode == Primary_Mode) and KNIFE_RANGE_LONG or KNIFE_RANGE_SHORT
	fRange = fRange + 1

	local vForward = owner:GetAimVector()
	local vecSrc = owner:GetShootPos()
	local vecEnd = vecSrc + vForward * fRange

	local trace_filter = swcs.filter_IgnoreOwner(owner, {"swcs_shield"})

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
			mins = head_hull_mins,
			maxs = head_hull_maxs,
			output = tr,
		})

		if tr.Fraction < 1 then
			-- Calculate the point of intersection of the line (or hull) and the object we hit
			-- This is and approximation of the "best" intersection

			local pHit = tr.Entity
			if not pHit:IsValid() or swcs.IsBSPModel(pHit) then
				FindHullIntersection(vecSrc, tr, CSGO_DUCK_HULL_MIN, CSGO_DUCK_HULL_MAX, trace_filter)
			end

			--tr.HitPos =
		end
	end

	local bDidHit = tr.Fraction < 1

	local bFirstSwing = (self:GetNextPrimaryFire() + 0.4) < CurTime()
	if bFirstSwing then
		self:SetSwingLeft(true)
	end

	local fPrimDelay, fSecDelay

	if weaponMode == Secondary_Mode then
		fPrimDelay = bDidHit and 1.1 or 1
		fSecDelay = fPrimDelay
	else -- swing
		fPrimDelay = bDidHit and 0.5 or 0.4
		fSecDelay = 0.5
	end

	self:SetNextPrimaryFire(CurTime() + fPrimDelay)
	self:SetNextSecondaryFire(CurTime() + fSecDelay)

	local bBackStab = false

	if bDidHit then
		local ent = tr.Entity

		local fDamage = 0

		if ent:IsValid() and (ent:IsPlayer() or ent:IsNPC()) then
			local vTargetForward = ent:EyeAngles():Forward()

			local vecLOS = (ent:GetPos() - owner:GetPos())
			vecLOS.z = 0
			vecLOS:Normalize()

			vTargetForward.z = 0
			local flDot = vecLOS:Dot(vTargetForward)

			-- Triple the damage if we are stabbing them in the back.
			if flDot > .475 then
				bBackStab = true
			end
		end

		if weaponMode == Secondary_Mode then
			if bBackStab then
				fDamage = 180
			else
				fDamage = 65
			end
		else
			if bBackStab then
				fDamage = self.BackstabPrimaryDamage
			elseif bFirstSwing then
				-- first swing does full damage
				fDamage = self.Swing1Damage
			else
				-- subsequent swings do less
				fDamage = self.Swing2Damage
			end
		end

		if weaponMode == Secondary_Mode then
			local activity = ACT_VM_HITCENTER2
			local nSequence = self:SelectWeightedSequence(ACT_VM_SWINGHARD)

			if bBackStab and nSequence ~= ACT_INVALID and nSequence ~= nil then
				activity = ACT_VM_SWINGHARD
			end

			self:SetWeaponAnim(activity)
		else -- swing
			local activity = ACT_VM_HITCENTER
			local nSequence = self:SelectWeightedSequence(ACT_VM_SWINGHIT)

			if bBackStab and nSequence ~= ACT_INVALID and nSequence ~= nil then
				activity = ACT_VM_SWINGHIT
			end

			self:SetWeaponAnim(activity)
		end

		local info = DamageInfo()
		info:SetInflictor(self)
		info:SetAttacker(owner)
		info:SetDamage(fDamage)
		info:SetDamagePosition(tr.HitPos)
		info:SetReportedPosition(tr.StartPos)

		local force = vForward:GetNormal() * GetConVar("phys_pushscale"):GetFloat()
		info:SetDamageForce(force)

		if SERVER then
			if ent:IsPlayer() then
				info:SetDamageType(DMG_SLASH)

				ent:SetLastHitGroup(HITGROUP_GENERIC)

				-- disable player pushback on bullet damage
				-- what the fuck
				owner:AddSolidFlags(FSOLID_TRIGGER)
				swcs.fx.TraceAttack(tr.Entity, info, tr.Normal, tr)
				ent:TakeDamageInfo(info)
				owner:RemoveSolidFlags(FSOLID_TRIGGER)
			else
				info:SetDamageType(DMG_CLUB)

				ent:DispatchTraceAttack(info, tr)
			end

			SuppressHostEvents(owner --[[@as Player]])
		end

		if ent:IsValid() or ent:IsWorld() then
			if ent:IsPlayer() or ent:IsNPC() then
				self:EmitSound((weaponMode == Secondary_Mode) and self.StabSound or self.SlashSound)
			else
				self:EmitSound(self.HitSound)
			end
		end

		local data = EffectData()
		data:SetOrigin(tr.HitPos)
		data:SetStart(tr.StartPos)
		data:SetSurfaceProp(tr.SurfaceProps)
		data:SetDamageType(DMG_SLASH)
		data:SetHitBox(tr.HitBox)
		if CLIENT then
			data:SetEntity(tr.Entity)
		else
			data:SetEntIndex(tr.Entity:EntIndex())
		end

		data:SetAngles(owner:GetAngles())
		data:SetFlags(IMPACT_NODECAL)

		if SERVER or (CLIENT and IsFirstTimePredicted()) then
			swcs.fx.KnifeSlashEffect(data, owner)
		end
	else
		self:EmitSound(self.SwingSound)

		-- to hit breakable glass
		local null_info = DamageInfo()
		null_info:SetDamageType(DMG_CLUB)
		game.GetWorld():DispatchTraceAttack(null_info, tr)

		if weaponMode == Secondary_Mode then
			self:SetWeaponAnim(ACT_VM_MISSCENTER2)
		else
			self:SetWeaponAnim(ACT_VM_MISSCENTER)
		end
	end

	owner:SetAnimation(PLAYER_ATTACK1)
end
