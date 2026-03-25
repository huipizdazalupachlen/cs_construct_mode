AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = 1.5
ENT.IsSWCSGrenade = true
ENT.PrintName = "Decoy"

DEFINE_BASECLASS(ENT.Base)

local GRENADE_MODEL = "models/weapons/csgo/w_eq_decoy_thrown.mdl"

ENT.m_flDamage = 25
AccessorFunc(ENT, "m_flDamage", "Damage", FORCE_NUMBER)

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Int", 3, "ThinkFuncIndex")
	self:NetworkVar("Int", 4, "ShotsRemaining")
	self:NetworkVar("Float", 1, "ExpireTime")
end

local DecoyWeaponProfiles = {
	["pistol"] = {
		minShots = 1,
		maxShots = 3,
		extraDelay = 0.3,
		pauseMin = 0.5,
		pauseMax = 4.0,
	},
	["submachinegun"] = {
		minShots = 1,
		maxShots = 5,
		extraDelay = 0.0,
		pauseMin = 0.5,
		pauseMax = 4.0,
	},
	["rifle"] = {
		minShots = 1,
		maxShots = 3,
		extraDelay = 0.5,
		pauseMin = 0.5,
		pauseMax = 4.0,
	},
	["shotgun"] = {
		minShots = 1,
		maxShots = 3,
		extraDelay = 0.0,
		pauseMin = 0.5,
		pauseMax = 4.0,
	},
	["sniperrifle"] = {
		minShots = 1,
		maxShots = 3,
		extraDelay = 0.5,
		pauseMin = 0.5,
		pauseMax = 4.0,
	},
	["machinegun"] = {
		minShots = 6,
		maxShots = 20,
		extraDelay = 0.0,
		pauseMin = 0.5,
		pauseMax = 4.0,
	},
}
local EngineDecoyAttributes = {
	["weapon_pistol"] = {
		cycletime = 0.1
	},
	["weapon_357"] = {
		cycletime = 0.75
	},
	["weapon_smg1"] = {
		cycletime = 0.075
	},
	["weapon_ar2"] = {
		cycletime = 0.1
	},
	["weapon_shotgun"] = {
		cycletime = 1
	}
}
local EngineDecoyVisuals = {
		["weapon_pistol"] = {
			sound_single_shot = "Weapon_Pistol.Single"
		},
		["weapon_357"] = {
			sound_single_shot = "Weapon_357.Single"
		},
		["weapon_smg1"] = {
			sound_single_shot = "Weapon_SMG1.Single"
		},
		["weapon_ar2"] = {
			sound_single_shot = "Weapon_AR2.Single"
		},
		["weapon_shotgun"] = {
			sound_single_shot = "Weapon_Shotgun.Single"
		},
}
local EngineWeaponTypes = {
	["weapon_pistol"] = "pistol",
	["weapon_357"] = "pistol",
	["weapon_smg1"] = "submachinegun",
	["weapon_ar2"] = "submachinegun",
	["weapon_shotgun"] = "shotgun",
}

local THINK_DETONATE = 1
local THINK_GUNFIRE = 2
local THINK_REMOVE = 3

ENT.ThinkFuncs = {
	[THINK_DETONATE] = function(self)
		if self:GetFinalVelocity():Length() > 0.1 then
			-- Still moving. Don't detonate yet.
			return true
		end

		-- hook, SWCSDecoyStart

		self:SetShotsRemaining(0)
		self:SetExpireTime(CurTime() + 14)

		self:SetThinkFuncIndex(THINK_GUNFIRE)
		--self:SetGrenadeRadius(115)
		self:CallThinkFunc(THINK_GUNFIRE) -- This will handling the 'Detonate'

		return true
	end,
	[THINK_GUNFIRE] = function(self)
		if not self.m_tProfile then return true end

		local profile = self.m_tProfile

		if self:GetShotsRemaining() <= 0 then
			-- pick a new burst activity
			self:SetShotsRemaining(g_ursRandom:RandomInt(profile.minShots, profile.maxShots))
		end

		local shootSound = ""

		local flCycleTime = 0.1
		if self.m_decoyAttributes then
			local iHasSilencer = tonumber(self.m_decoyAttributes["has silencer"])
			if iHasSilencer == 1 then
				-- silenced
				if self.m_decoyWeaponMode == Primary_Mode then
					shootSound = self.m_decoyVisuals["sound_single_shot"]
				else
					shootSound = self.m_decoyVisuals["sound_special1"]
				end
			else
				shootSound = self.m_decoyVisuals["sound_single_shot"]
			end

			flCycleTime = tonumber(self.m_decoyAttributes["cycletime"]) or flCycleTime
		else
			-- uhhhhh idk man
			assert(false, "Decoy grenade has no attributes")
		end

		self:EmitSound(shootSound)
		if SERVER then
			sound.EmitHint(bit.bor(SOUND_COMBAT, SOUND_CONTEXT_GUNFIRE), self:GetPos(), 1024, 3)
			ParticleEffect("weapon_decoy_ground_effect_shot", self:GetPos(), self:GetAngles(), self)
		end

		-- fire hook decoy firing

		self:SetShotsRemaining(self:GetShotsRemaining() - 1)
		if self:GetShotsRemaining() > 0 then
			self:NextThink(CurTime() + flCycleTime + g_ursRandom:RandomFloat(0.0, profile.extraDelay))
			return true
		end

		if CurTime() < self:GetExpireTime() then
			self:NextThink(CurTime() + flCycleTime + g_ursRandom:RandomFloat(profile.pauseMin, profile.pauseMax))
		else
			self:Explode()

			SafeRemoveEntity(self)
		end

		return true
	end,
	[THINK_REMOVE] = function(self)
		--if SERVER then self:Remove() end
		return true
	end,
}

function ENT:Explode()
	local vecSpot = self:GetPos() + Vector(0, 0, 8) -- trace starts here!

	--SetThink( NULL );

	local tr = util.TraceLine({
		start = vecSpot,
		endpos = vecSpot - Vector(0, 0, 32),
		mask = MASK_SHOT_HULL,
		filter = self,
		collisiongroup = COLLISION_GROUP_NONE,
	})

	if tr.StartSolid then
		-- Since we blindly moved the explosion origin vertically, we may have inadvertently moved the explosion into a solid,
		-- in which case nothing is going to be harmed by the grenade's explosion because all subsequent traces will startsolid.
		-- If this is the case, we do the downward trace again from the actual origin of the grenade. (sjb) 3/8/2007  (for ep2_outland_09)
		util.TraceLine({
			start = self:GetPos(),
			endpos = self:GetPos() - Vector(0, 0, 32),
			mask = MASK_SHOT_HULL,
			filter = self,
			collisiongroup = COLLISION_GROUP_NONE,
			output = tr,
		})
	end

	-- boom
	local attacker = self:GetThrower()
	if not attacker:IsValid() then
		attacker = self
	end
	util.BlastDamage(self, attacker, tr.HitPos, 115, 50)

	util.Decal("Scorch", tr.StartPos, tr.HitPos - Vector(0, 0, 1), self)

	--self:EmitSound("HEGrenade.Explode")

	sound.EmitHint(bit.bor(SOUND_COMBAT, SOUND_CONTEXT_EXPLOSION), self:GetPos(), 1024, 3)

	local data = EffectData()
	data:SetOrigin(self:GetPos())
	data:SetScale(115 * 0.3)
	data:SetRadius(115)
	data:SetMagnitude(50)
	data:SetNormal(tr.HitNormal)
	util.Effect("Explosion", data, false, not game.SinglePlayer())

	util.ScreenShake(self:GetPos(), 0, 150, 1, 750, true)
end

function ENT:AdditionalThink(selfTable)
	selfTable = selfTable or self:GetTable()
	if CLIENT and selfTable.GetFinalVelocity(self):Length() < 0.1 then
		if not IsValid(selfTable.m_decoyParticleEffect) then
			selfTable.m_decoyParticleEffect = CreateParticleSystem(self, "weapon_decoy_ground_effect", PATTACH_POINT_FOLLOW, self:LookupAttachment("Wick"))
		elseif selfTable.m_decoyParticleEffect:IsValid() then
			selfTable.m_decoyParticleEffect:SetSortOrigin(self:GetPos())
		end
	end

	return self:CallThinkFunc(self:GetThinkFuncIndex())
end

function ENT:CallThinkFunc(iThinkFunc)
	if iThinkFunc ~= 0 then
		local fnThink = self.ThinkFuncs[iThinkFunc]
		if isfunction(fnThink) then
			return fnThink(self)
		end
	end
end

function ENT:AssignRandomWeapon()
	local iRandom = g_ursRandom:RandomInt(0, 8)
	self.m_decoyWeaponMode = Primary_Mode

	self.m_tProfile = DecoyWeaponProfiles["pistol"]

	if iRandom == 0 then
		self.m_decoyWeapon = "weapon_swcs_glock"
	elseif iRandom == 1 then
		self.m_decoyWeapon = "weapon_swcs_hkp2000"
	elseif iRandom == 2 or iRandom == 3 then
		self.m_decoyWeapon = "weapon_swcs_usp_silencer"

		if iRandom == 3 then
			self.m_decoyWeaponMode = Secondary_Mode
		end
	elseif iRandom >= 4 and iRandom <= 8 then -- hl2 weps
		if iRandom == 4 then -- pistol
			self.m_decoyWeapon = "weapon_pistol"
		elseif iRandom == 5 then -- 357
			self.m_decoyWeapon = "weapon_357"
		elseif iRandom == 6 then -- smg1
			self.m_decoyWeapon = "weapon_smg1"
		elseif iRandom == 7 then -- ar2
			self.m_decoyWeapon = "weapon_ar2"
		elseif iRandom == 8 then -- shotgun
			self.m_decoyWeapon = "weapon_shotgun"
		end

		self.m_decoyAttributes = EngineDecoyAttributes[self.m_decoyWeapon]
		self.m_decoyVisuals = EngineDecoyVisuals[self.m_decoyWeapon]
		self.m_tProfile = DecoyWeaponProfiles[EngineWeaponTypes[self.m_decoyWeapon]]
	end
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

	self:SetLocalAngularVelocity(angvel)
	self:SetFinalAngularVelocity(angvel)
	self:SetActualCollisionGroup(COLLISION_GROUP_PROJECTILE)

	-- primary first
	-- then secondary
	-- then default val (T/CT starter pistol)
	if IsValid(owner) then
		local prevWeapon = owner:GetLastWeapon()
		if prevWeapon:IsValid() then
			local classname = prevWeapon:GetClass()

			if prevWeapon.IsSWCSWeapon and not (prevWeapon.IsGrenade or prevWeapon.IsKnife) then
				self.m_decoyWeapon = classname
				self.m_decoyWeaponMode = prevWeapon:GetWeaponMode()
				self.m_decoyAttributes = prevWeapon.ItemAttributes
				self.m_decoyVisuals = prevWeapon.ItemVisuals

				self.m_tProfile = DecoyWeaponProfiles[prevWeapon:GetWeaponType()]
			elseif EngineDecoyAttributes[classname] then
				self.m_decoyWeapon = classname
				self.m_decoyWeaponMode = Primary_Mode
				self.m_decoyAttributes = EngineDecoyAttributes[classname]
				self.m_decoyVisuals = EngineDecoyVisuals[classname]
				self.m_tProfile = DecoyWeaponProfiles[EngineWeaponTypes[classname]]
			end
		end
	end

	if not self.m_tProfile then
		self:AssignRandomWeapon()
	end

	if not self.m_decoyAttributes and self.m_decoyWeapon then
		local swepTable = weapons.Get(self.m_decoyWeapon)

		if swepTable then
			if swepTable.ItemAttributes then
				self.m_decoyAttributes = swepTable.ItemAttributes
			end
			if swepTable.ItemVisuals then
				self.m_decoyVisuals = swepTable.ItemVisuals
			end
		end
	end

	return self
end

function ENT:Initialize()
	self:SetModel(GRENADE_MODEL)

	self:SetDetonateTimerLength(self.m_flTimeToDetonate)

	BaseClass.Initialize(self)
end

-- Implement this so we never call the base class,
-- but this should never be called either.
function ENT:Detonate()
	assert(false, "Decoy grenade handles its own detonation\n")
end

function ENT:BounceSound()
	self:EmitSound("Flashbang.Bounce")
end

function ENT:SetTimer(flTimer)
	self:SetThinkFuncIndex(THINK_DETONATE)
	self:NextThink((engine.TickInterval() * engine.TickCount()) + flTimer)

	--self:SetGrenadeRadius(0)
end

function ENT:AcceptInput(strInput, actor, caller, data)
	if string.lower(strInput) == "settimer" then
		self.m_flTimeToDetonate = tonumber(data)
		self:SetDetonateTimerLength(self.m_flTimeToDetonate)
	end
end
