AddCSLuaFile()

ENT.Type = "anim"
ENT.Spawnable = false
ENT.Category = "#spawnmenu.category.swcs"
ENT.PrintName = "Shield"

ENT.IsSWCSShield = true
ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

-- NOTE: Ballistic Shield originally had 650 health, but do we care enough when its basically the same, just without the
--       face shield? I feel like that balances it enough as it is that the extra health it has is negligible.
--       Any custom ones can just cope or find a way around it :^)
local swcs_shield_hitpoints = CreateConVar("swcs_shield_hitpoints", "800", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "how many hit points the shield has when it spawns", 0)

sound.Add({
	name = "Shield.BulletImpact",
	pitch = {100, 101},
	volume = 0.8,
	soundlevel = 90,
	sound = {
		Sound(")physics/shield/bullet_hit_shield_01.wav"),
		Sound(")physics/shield/bullet_hit_shield_02.wav"),
		Sound(")physics/shield/bullet_hit_shield_03.wav"),
		Sound(")physics/shield/bullet_hit_shield_04.wav"),
		Sound(")physics/shield/bullet_hit_shield_05.wav"),
		Sound(")physics/shield/bullet_hit_shield_06.wav"),
		Sound(")physics/shield/bullet_hit_shield_07.wav"),
	},
})
sound.Add({
	name = "Breakable.Metal",
	channel = CHAN_STATIC,
	volume = 0.7,
	soundlevel = 85,
	sound = {
		Sound(")survival/container_death_01.wav"),
		Sound(")survival/container_death_02.wav"),
		Sound(")survival/container_death_03.wav"),
	},
})

function ENT:SetupDataTables()
	self:NetworkVar("Entity", "Weapon")
end

function ENT:Initialize()
	self:SetTransmitWithParent(true)

	if SERVER then
		self:SetMaxHealth(swcs_shield_hitpoints:GetInt())
		self:SetHealth(swcs_shield_hitpoints:GetInt())
	end

	if self:GetModel() == "models/error.mdl" then
		self:SetModel("models/weapons/csgo/w_eq_shield.mdl")
	end

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()
		if phys:IsValid() then
			phys:EnableMotion(true)
		end

		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	end
end

-- swcs.fx.ImpactEffect calls into ENT:ImpactTrace
local SENTINEL = false
function ENT:ImpactTrace(trace, dmgtype, strImpactEffect)
	if SERVER then return end -- crowbar, how
	if not IsFirstTimePredicted() then return end
	if SENTINEL then return end

	local data = EffectData()
	data:SetOrigin(trace.HitPos)
	data:SetStart(trace.StartPos)
	data:SetSurfaceProp(trace.SurfaceProps)
	data:SetDamageType(dmgtype)
	data:SetHitBox(trace.HitBox)
	data:SetEntity(trace.Entity)

	SENTINEL = true
	swcs.fx.ImpactEffect(data, nil, {"player"})
	SENTINEL = false

	-- not bullet damage
	if bit.band(dmgtype, DMG_BULLET) ~= DMG_BULLET then return true end

	local vecDir = trace.HitNormal
	local vecRight = trace.HitNormal:Cross(vector_up)
	local vecUp = vecRight:Cross(trace.HitNormal)

	local theta = g_ursRandom:RandomFloat(0, 2 * math.pi)
	local radius = g_ursRandom:RandomFloat()

	local xSpread = math.rad(180) * radius * math.cos(theta)
	local ySpread = math.rad(180) * radius * math.sin(theta)

	vecDir:Add(xSpread * vecRight)
	vecDir:Add(ySpread * vecUp)

	local tr = util.TraceLine({
		start = trace.HitPos,
		endpos = trace.HitPos + vecDir * 800,
		filter = {self, "player"},
	})

	util.ParticleTracerEx("impact_wallbang_heavy", tr.StartPos, tr.HitPos, false, self:EntIndex(), -1)

	return true
end

function ENT:OnTakeDamage(dmg)
	local wep = dmg:GetInflictor()
	local atk = dmg:GetAttacker()

	if atk == wep and atk.GetActiveWeapon then
		wep = atk:GetActiveWeapon()
	end

	if not wep:IsValid() then
		return
	end

	local flDamageToTake = dmg:GetDamage()

	if wep.IsSWCSWeapon then
		flDamageToTake = flDamageToTake * wep:GetPenetration()
	elseif not wep:IsScripted() and not dmg:IsDamageType(DMG_BUCKSHOT) then
		flDamageToTake = flDamageToTake * 4
	end

	local iCurHealth = self:Health() - flDamageToTake
	self:SetHealth(iCurHealth)

	if SERVER then
		local ourWep = self:GetWeapon()
		local owner = ourWep:IsValid() and ourWep:GetOwner() or NULL

		ourWep:SetHealth(iCurHealth)

		local bHoldingShield = owner:IsValid() and ourWep == owner:GetActiveWeapon()
		local punchAngle = Angle()

		if bHoldingShield then
			punchAngle:Set(ourWep:GetRawAimPunchAngle())
		else
			punchAngle:Set(owner:GetViewPunchAngles())
		end

		local seed = ourWep:GetRandomSeed()
		seed = seed + 1

		local rand = UniformRandomStream(seed)
		local add = Angle(rand:RandomInt(-2, 2), rand:RandomInt(-2, 2), rand:RandomInt(-2, 2))
		punchAngle:Add(add)

		if bHoldingShield then
			ourWep:SetRawAimPunchAngle(punchAngle)
		else
			owner:SetViewPunchAngles(punchAngle)
		end

		EmitSound("Shield.BulletImpact", dmg:GetDamagePosition())

		if iCurHealth <= 0 then
			self:GibBreakClient(Vector())
			self:EmitSound("Breakable.Metal")

			if ourWep:IsValid() then
				if self:GetOwner():GetActiveWeapon() == ourWep then
					ourWep:SwitchToPreviousWeapon()
				end
				ourWep:Remove()
			end
		end
	end
end
