AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = math.huge
ENT.PrintName = "Breach Charge"

DEFINE_BASECLASS(ENT.Base)

local GRENADE_MODEL = "models/weapons/csgo/w_eq_charge.mdl"

AccessorFunc(ENT, "m_flExpireDelay", "ExpireDelay", FORCE_NUMBER)
AccessorFunc(ENT, "m_flDamage", "Damage", FORCE_NUMBER)
AccessorFunc(ENT, "m_DmgRadius", "Range", FORCE_NUMBER)
AccessorFunc(ENT, "m_hWeapon", "Weapon")

ENT.m_flExpireDelay = 1.0

local THINK_ARM = 1
local THINK_DETONATE = 2

ENT.ThinkFuncs = {
	[THINK_ARM] = function(self)
		if self:GetFinalVelocity():Length() > 0.2 then
			self:NextThink((engine.TickInterval() * engine.TickCount()) + 0.2)
			return true
		end

		if self.m_bMarkedToDetonate then
			self:SetThinkFuncIndex(THINK_DETONATE)
			self:CallThinkFunc(THINK_DETONATE)
		else
			self:SetThinkFuncIndex(0)
		end

		return true
	end,
	[THINK_DETONATE] = function(self)
		local curtime = engine.TickInterval() * engine.TickCount()
		if self:GetTimeToExpire() == 0 then
			if SERVER then
				self:EmitSound("Survival.BreachSoundWarningBeep")
			end

			self:SetTimeToExpire(curtime + self:GetExpireDelay())
		end

		if self:GetTimeToExpire() <= curtime then
			self:Detonate()

			self:SetThinkFuncIndex(0)
		end

		return true
	end,
}

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Int", 3, "ThinkFuncIndex")
	self:NetworkVar("Float", 1, "TimeToExpire")

	self:NetworkVar("Bool", "DestroyPhysics")
end

function ENT:Create(pos, angs, vel, angvel, owner)
	self:SetPos(pos)
	self:SetAngles(angs)

	self:SetVelocity(vel)
	self:SetInitialVelocity(vel)

	if IsValid(owner) then
		self:SetThrower(owner)
		self:SetOwner(owner)
	end

	self:SetTimer(2.0)
	self:SetTimeToDetonate(CurTime() + 9999)

	self:SetLocalAngularVelocity(angvel)
	self:SetFinalAngularVelocity(angvel)
	self:SetActualCollisionGroup(COLLISION_GROUP_PROJECTILE)

	self:SetDamage(self.ItemAttributes and self.ItemAttributes["damage"] or 500)
	self:SetRange(self.ItemAttributes and self.ItemAttributes["range"] or 350)

	return self
end

function ENT:SetTimer(flTimer)
	self:SetThinkFuncIndex(THINK_ARM)

	self:NextThink(CurTime() + flTimer)
end

function ENT:GetGrenadeGravity()
	return 1
end

function ENT:CleanupStickyProjectiles(parent, bRemoveSelf)
	parent = parent or self:GetParent()

	if parent:IsValid() then
		local children = parent.swcs_StickyProjectiles
		if not istable(children) or table.Count(children) == 0 then return end

		local child, prevchild = nil, nil
		child = next(children)
		while child ~= nil do
			if (bRemoveSelf and child == self) or not child:IsValid() then
				children[child] = nil
			else
				prevchild = child
			end

			child = next(children, prevchild)
		end
	end
end

function ENT:OnLostParent(parent)
	self:CleanupStickyProjectiles(parent, true)
end

function ENT:Initialize()
	self:SetModel(GRENADE_MODEL)

	BaseClass.Initialize(self)

	if SERVER then
		self:CallOnRemove("swcs_breachcharge", function(ent)
			ent:CleanupStickyProjectiles(nil, true)
		end)
	end

	self:SetDetonateTimerLength(self.m_flTimeToDetonate)
end

function ENT:Detonate()
	local tr = {}
	local vecSpot = self:GetPos() -- trace starts here!
	vecSpot.z = vecSpot.z + 8

	util.TraceLine({
		output = tr,

		start = vecSpot,
		endpos = vecSpot + Vector(0, 0, -32),
		mask = MASK_SHOT_HULL,
		filter = self,
		collisiongroup = COLLISION_GROUP_NONE,
	})

	if tr.StartSolid then
		-- Since we blindly moved the explosion origin vertically, we may have inadvertently moved the explosion into a solid,
		-- in which case nothing is going to be harmed by the grenade's explosion because all subsequent traces will startsolid.
		-- If this is the case, we do the downward trace again from the actual origin of the grenade. (sjb) 3/8/2007  (for ep2_outland_09)
		util.TraceLine({
			output = tr,

			start = self:GetPos(),
			endpos = self:GetPos() + Vector(0, 0, -32),
			mask = MASK_SHOT_HULL,
			filter = self,
			collisiongroup = COLLISION_GROUP_NONE,
		})
	end

	self:Explode(tr, DMG_BLAST)

	if SERVER then
		util.ScreenShake(self:GetPos(), 25, 150, 1, 750)

		self:CleanupStickyProjectiles(nil, true)
		self:Remove()
	end
end

function ENT:Explode(tr, dmgtype)
	self:AddSolidFlags(FSOLID_NOT_SOLID)
	if SERVER then self:SetSaveValue("m_takedamage", 0) end

	-- Pull out of the wall a bit
	if tr.Fraction ~= 1.0 then
		self:Set_Pos(tr.HitPos + (tr.HitNormal * 0.6))
		self:SetPos(self:Get_Pos())
	end

	local vecReported = self:GetOwner():IsValid() and self:GetOwner():GetPos() or vector_origin

	if SERVER then
		self:EmitSound("HEGrenade.Explode")

		local info = DamageInfo()
		info:SetInflictor(self)
		info:SetAttacker(self:GetOwner():IsValid() and self:GetOwner() or self)
		--info:SetDamageForce(self:GetBlastForce())
		info:SetDamagePosition(self:GetPos())
		info:SetDamage(self:GetDamage())
		info:SetDamageType(dmgtype)
		info:SetReportedPosition(vecReported)

		--util.BlastDamageInfo(info, self:GetPos(), self:GetRange() / 2)
		swcs.RadiusDamage(info, self:GetPos(), self:GetRange() / 2, false)

		local data = EffectData()
		data:SetOrigin(self:GetPos())
		data:SetNormal(tr.HitNormal)
		data:SetScale(self:GetRange() * 0.3)
		data:SetRadius(self:GetRange())
		data:SetMagnitude(self:GetDamage())
		data:SetFlags(bit.bor(0x4))
		util.Effect("Explosion", data)

		if self:GetWeapon():IsValid() then
			self:GetWeapon():SignalBombDetonated(self)
		end
	end

	self:SetSolid(SOLID_NONE)
	self:AddEffects(EF_NODRAW)
end

function ENT:BounceSound()
	self:EmitSound("Survival.BreachChargeSetArmed")
end

local MaxAttachedProjectiles = CreateConVar("swcs_breachcharge_max_attached_projectiles", 10, FCVAR_REPLICATED, "The maximum number of projectiles that can be attached to a single entity")
function ENT:OnBounced(tr, other)
	if bit.band(other:GetSolidFlags(), bit.bor(FSOLID_TRIGGER, FSOLID_VOLUME_CONTENTS)) ~= 0 then
		return
	end

	if bit.band(tr.SurfaceFlags, SURF_SKY) ~= 0 then
		return
	end

	local children = other.swcs_StickyProjectiles
	local iMax = MaxAttachedProjectiles:GetInt()
	if iMax > -1 and istable(children) and table.Count(children) >= MaxAttachedProjectiles:GetInt() then
		return
	end

	-- don't hit the guy that launched this grenade
	if other == self:GetThrower() then
		return
	end

	local classname = other:GetClass()
	if classname == "func_breakable" then
		return
	end

	if classname == "func_breakable_surf" then
		return
	end

	-- don't detonate on ladders
	if classname == "func_ladder" then
		return
	end

	local bCombatCharacter = other:IsPlayer() or other:IsNPC() or other:IsNextBot()
	if bCombatCharacter or not tr.HitWorld then
		local iBoneIndex

		if tr.PhysicsBone then
			iBoneIndex = other:TranslatePhysBoneToBone(tr.PhysicsBone)
		else
			iBoneIndex = other:GetHitBoxBone(tr.HitBox, other:GetHitboxSet())
		end

		if bCombatCharacter then
			self:SetNotSolid(true)
		end

		if iBoneIndex and iBoneIndex ~= -1 then
			local boneMatrix = other:GetBoneMatrix(iBoneIndex)
			local bonePos = boneMatrix:GetTranslation()
			local boneAngles = boneMatrix:GetAngles()

			local localPos = WorldToLocal(tr.HitPos, Angle(), bonePos, boneAngles)

			self:FollowBone(other, iBoneIndex)
			self:SetLocalPos(localPos)
			self:SetLocalAngles(Angle())
		else
			self:SetParent(other)

			local pos = other:WorldToLocal(tr.HitPos)
			self:SetLocalPos(pos)
		end
	elseif other:IsValid() then
		self:SetParent(other)

		local pos = other:WorldToLocal(tr.HitPos)
		self:SetLocalPos(pos)
	elseif other:IsWorld() then
		self:SetDestroyPhysics(true)
	end

	if not other:IsWorld() then
		if not other.swcs_StickyProjectiles then
			other.swcs_StickyProjectiles = setmetatable({}, {__mode = "k"})

			other:CallOnRemove("swcs.sticky_proj", function(ent)
				if not istable(children) or #children == 0 then return end

				for _, child in next, children do
					if child:IsValid() then
						child:SetParent(NULL)

						local pos = child:GetPos()
						child:SetPos(pos)
						child:Set_Pos(pos)
					end
				end
			end)
		end

		other.swcs_StickyProjectiles[self] = true
	end

	-- stick the grenade onto the target surface using the closest rotational alignment to match the in-flight orientation,
	local vecSurfNormal = tr.HitNormal
	local vecProjectileZ = self:GetAngles():Forward()

	local vecC4Right = vecProjectileZ:Cross(vecSurfNormal)
	local vecC4Forward = vecC4Right:Cross(-vecSurfNormal)
	local angSurface = vecC4Forward:AngleEx(vecSurfNormal)

	self:SetAngles(angSurface)

	self:Set_Pos(tr.HitPos)
	self:SetFinalVelocity(vector_origin)

	if self:GetThinkFuncIndex() ~= THINK_DETONATE then self:SetThinkFuncIndex(THINK_ARM) end
	self:SetNWMoveType(MOVETYPE_NONE)
	self:SetMoveType(MOVETYPE_NONE)

	self:DrawShadow(false)

	local wep = self:GetWeapon()
	if SERVER and wep:IsValid() then
		wep:SendProjectiles(wep:GetOwner())
	end
end

function ENT:AdditionalThink(selfTable)
	selfTable = selfTable or self:GetTable()
	if SERVER and not selfTable.GetWeapon(self):IsValid() then
		selfTable:SignalDetonate()
	end

	if selfTable.GetDestroyPhysics(self) then
		selfTable.SetDestroyPhysics(self, false)

		self:PhysicsDestroy()
	end

	return selfTable.CallThinkFunc(self, selfTable.GetThinkFuncIndex(self))
end

ENT.m_bMarkedToDetonate = false
-- this function does not use the entity reference, so we can call it using the entity's table :)
function ENT:SignalDetonate(delay)
	if not delay then
		delay = 1.0
	else
		delay = math.max(delay, 1.0)
	end

	self:SetExpireDelay(delay)

	if self:GetThinkFuncIndex() == THINK_ARM then
		self.m_bMarkedToDetonate = true
	else
		self:SetThinkFuncIndex(THINK_DETONATE)
	end
end

function ENT:CallThinkFunc(iThinkFunc)
	if iThinkFunc ~= 0 then
		local fnThink = self.ThinkFuncs[iThinkFunc]
		if isfunction(fnThink) then
			return fnThink(self)
		end
	end
end

function ENT:OnTakeDamage(dmg)
	if dmg:IsDamageType(DMG_BLAST) then
		self:SignalDetonate()
	end
end

if CLIENT then
	local ENTITY = FindMetaTable("Entity")
	---@diagnostic disable-next-line: need-check-nil
	local GetParent = ENTITY.GetParent
	---@diagnostic disable-next-line: need-check-nil
	local DrawModel = ENTITY.DrawModel

	function ENT:Draw(flags)
		if GetParent(self) == LocalPlayer() then return end

		DrawModel(self, flags)
	end
end

function ENT:Use(actor, caller, usetype, val)
	if not caller:IsPlayer() or caller:KeyDownLast(IN_USE) then return end
	if self:GetParent():IsPlayer() then return end

	local wep = caller:GetWeapon("weapon_swcs_breachcharge")
	if wep:IsValid() and wep == self.m_hWeapon then
		self:StopSound("Survival.BreachSoundWarningBeep")
		self:EmitSound("Survival.BreachUse")

		self:SetMoveType(MOVETYPE_NONE)
		self:SetNWMoveType(MOVETYPE_NONE)

		local owner = wep:GetOwner()

		owner:GiveAmmo(1, "swcs_breachcharge", true)
		wep.Projectiles[self] = nil

		self:CleanupStickyProjectiles(nil, true)
		self:Remove()

		wep:SendProjectiles(owner)
	end
end
