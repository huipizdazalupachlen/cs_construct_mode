SWEP.Base = "weapon_swcs_base"

DEFINE_BASECLASS(SWEP.Base)

SWEP.Category = "#spawnmenu.category.swcs"
SWEP.HoldType = "slam"

SWEP.IsGrenade = true

SWEP.Slot = 4

if swcs.InTTT then
	SWEP.AutoSpawnable = false

	SWEP.Slot = 3

	SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy

	SWEP.IsSilent = false
	SWEP.Kind = WEAPON_NADE

	if CLIENT then
		SWEP.EquipMenuData = {
			type = "item_weapon",
			desc = "The Breach Charge is a remotely detonated explosive equipment which sticks to surfaces and objects.",
		}
	end

	SWEP.Primary.Ammo = "none"
	SWEP.Primary.ClipSize = 1
	SWEP.Primary.DefaultClip = 1
else
	SWEP.Primary.Ammo = "swcs_breachcharge"
	SWEP.Primary.ClipSize = -1
	SWEP.Primary.DefaultClip = 3
end

SWEP.PrintName = "Breach Charge"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_charge.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_breachcharge.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/breachcharge.png", "smooth")
end

sound.Add({
	name = "Survival.BreachChargeSetArmed",
	channel = CHAN_STATIC,
	volume = 1,
	soundlevel = 85,
	sound = Sound("survival/breach_land_01.wav"),
})
sound.Add({
	name = "Survival.BreachChargeClick",
	channel = CHAN_STATIC,
	volume = 0.6,
	soundlevel = 80,
	sound = Sound("common/null.wav"),
})
sound.Add({
	name = "Survival.BreachSoundWarningBeep",
	channel = CHAN_STATIC,
	volume = 0.5,
	soundlevel = 75,
	pitch = 100,
	sound = Sound("survival/breach_warning_beep_01.wav"),
})
sound.Add({
	name = "Survival.BreachSoundActivate",
	channel = CHAN_STATIC,
	volume = 1.0,
	soundlevel = 75,
	pitch = 100,
	sound = Sound("survival/breach_activate_01.wav"),
})
sound.Add({
	name = "Survival.BreachSoundActivateNoBombs",
	channel = CHAN_STATIC,
	volume = 1.0,
	soundlevel = 75,
	pitch = 100,
	sound = Sound("survival/breach_activate_nobombs_01.wav"),
})
sound.Add({
	name = "Survival.BreachDefused",
	channel = CHAN_STATIC,
	soundlevel = 75,
	volume = 0.7,
	sound = Sound("survival/breach_defuse_01.wav"),
})
sound.Add({
	name = "Survival.BreachUse",
	channel = CHAN_STATIC,
	volume = 1.0,
	soundlevel = 75,
	pitch = 100,
	sound = Sound("survival/breach_charge_pickup_01.wav"),
})
sound.Add({
	name = "Survival.BreachThrow",
	channel = CHAN_STATIC,
	volume = 0.8,
	pitch = 120,
	soundlevel = 65,
	sound = {Sound("survival/breach_throw_01.wav"), Sound("survival/breach_throw_02.wav"), Sound("survival/breach_throw_03.wav")},
})

SWEP.ItemDefAttributes = [=["attributes 04/16/2024" {
	"max player speed"		"245"
	"in game price"		"300"
	"armor ratio"		"1.200000"
	"penetration"		"1"
	"crosshair min distance"		"8"
	"damage"		"500"
	"range"		"350"
	"range modifier"		"0.990000"
	"throw velocity"		"750.000000"
	"primary clip size"		"-1"
	"primary default clip size"		"3"
	"weapon weight"		"2"
	"max player speed alt"		"245"
	"itemflag exhaustible"		"1"
}]=]
SWEP.ItemDefVisuals = [=["visuals 04/16/2024" {
	"weapon_type"		"Breach Charge"
	"player_animation_extension"		"gren"
	"grenade_smoke_color"		"0.0 0.8 0.0"
	"primary_ammo"		"AMMO_TYPE_BREACHCHARGE"
	"sound_single_shot"		"HEGrenade.Throw"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:Initialize()
	swcs.SetupItemDefGetter(self, "ThrowVelocity", "throw velocity")

	BaseClass.Initialize(self, false, self.Prefab == nil)
end

function SWEP:HasNoAmmo()
	return BaseClass.HasNoAmmo(self) and (SERVER and table.IsEmpty(self.Projectiles))
end

function SWEP:Think()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	if owner:KeyDown(IN_ATTACK) and self:GetNextPrimaryFire() < CurTime() then
		self:PrimaryAttack()
	elseif owner:KeyDown(IN_ATTACK2) and self:GetNextSecondaryFire() < CurTime() then
		self:SecondaryAttack()
	elseif not owner:KeyDown(IN_RELOAD) then
		self:WeaponIdle()
	end
end

SWEP.Projectiles = setmetatable({}, {__mode = "k"})
function SWEP:PrimaryAttack()
	local selfTable = self:GetTable()

	local iAmmo = self:GetAmmoCount(self:GetPrimaryAmmoType())
	if iAmmo <= 0 then return end

	self:SetNextPrimaryFire(CurTime() + 0.5)

	if iAmmo > 1 then
		self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
	else
		self:SetWeaponSequence("fire_to_empty")
	end

	if IsFirstTimePredicted() then
		self:EmitSound("Survival.BreachThrow")
	end

	local owner = self:GetOwner()
	if owner:IsValid() and owner:IsPlayer() then
		owner:DoCustomAnimEvent(PLAYERANIMEVENT_ATTACK_GRENADE, 1)
	end

	-- emit projectile
	if SERVER then
		local angThrow = self:GetFinalAimAngle()
		if angThrow.p > 90 then
			angThrow.p = angThrow.p - 360
		elseif angThrow.p <= -90 then
			angThrow.p = angThrow.p + 360
		end

		local flVel = 500

		local vForward = angThrow:Forward()

		local vecOrigin = owner:GetShootPos()
		vecOrigin.z = vecOrigin.z - 12

		-- We want to throw the grenade from 16 units out.  But that can cause problems if we're facing
		-- a thin wall.  Do a hull trace to be safe.
		-- Wills: Moved the trace length out to 22 inches, then subtract 6. This way we default to 16,
		-- but pull back 6 from wherever we hit, so we don't emit from EXACTLY inside the close surface, which can lead to
		-- the grenade penetrating the wall anyway.
		local maxs = Vector(2, 2, 2)
		local trace = util.TraceHull({
			start = vecOrigin,
			endpos = vecOrigin + vForward * 22,
			mins = -maxs,
			maxs = maxs,
			mask = bit.bor(MASK_SOLID, CONTENTS_GRENADECLIP),
			collisiongroup = COLLISION_GROUP_NONE,
			filter = owner,
		})
		vecOrigin = trace.HitPos - (vForward * 6)

		if not util.IsInWorld(vecOrigin) then return end

		local vecThrow = vForward * flVel + owner:GetVelocity()

		---@class Entity
		local proj = ents.Create("swcs_breachcharge_projectile")
		if proj:IsValid() then
			local projTable = proj:GetTable()
			projTable.ItemAttributes = selfTable.ItemAttributes
			projTable.ItemVisuals = selfTable.ItemVisuals

			--proj:SetOwner(owner)

			projTable.m_hWeapon = self
			angThrow.p = angThrow.p - 70
			proj:Create(vecOrigin, angThrow, vecThrow, Angle(100, g_ursRandom:RandomInt(-360, 360), 0), owner)
			proj:Spawn()

			hook.Run("PlayerSpawnedSENT", owner, proj)

			selfTable.Projectiles[proj] = true
		end
	else
		selfTable.Projectiles[NULL] = true
	end

	self:TakePrimaryAmmo(1)
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 2)

	if self:GetAmmoCount(self:GetPrimaryAmmoType()) >= 1 then
		self:SetWeaponAnim(ACT_VM_HITRIGHT)
	else
		self:SetWeaponSequence("detonate_empty")
	end

	if table.IsEmpty(self.Projectiles) then
		if IsFirstTimePredicted() then
			self:EmitSound("Survival.BreachSoundActivateNoBombs")
		end
	else
		if IsFirstTimePredicted() then
			self:EmitSound("Survival.BreachSoundActivate")
		end

		if SERVER then
			self:SendDetonateSignal()
		end
	end
end

function SWEP:SignalBombDetonated(proj)
	local selfTable = self:GetTable()
	if selfTable.Projectiles[proj] then
		selfTable.Projectiles[proj] = nil
	end

	local owner = self:GetPlayerOwner()
	if owner and owner:IsValid() then
		self:SendProjectiles(owner)

		if owner:GetActiveWeapon() ~= self then
			self:RemoveIfExhausted(false)
		end
	end
end

function SWEP:WeaponIdle()
	if self:GetWeaponIdleTime() > CurTime() then return end

	if self:RemoveIfExhausted() then return end

	self:SetWeaponIdleTime(CurTime() + 0.1)

	if self:GetAmmoCount(self:GetPrimaryAmmoType()) >= 1 then
		self:SetWeaponAnim(ACT_VM_IDLE)
	else
		self:SetWeaponSequence("idle_empty")
	end
end

function SWEP:Deploy()
	local ret = BaseClass.Deploy(self)

	if SERVER then
		self:SendProjectiles(self:GetPlayerOwner())
	end

	if self:GetAmmoCount(self:GetPrimaryAmmoType()) >= 1 then
		self:SetWeaponAnim(ACT_VM_DEPLOY)
	else
		self:SetWeaponSequence("deploy_empty")
	end

	return ret
end

function SWEP:GetPinPulled()
	return false
end

function SWEP:DrawWorldModel(flags)
	local owner = self:GetOwner()

	if not owner:IsValid() then
		local iClip = self:Clip1()
		iClip = (iClip == -1) and 3 or iClip -- gmod doesnt network this atm :)

		self:SetBodygroup(0, iClip + 1)
	else
		self:SetBodygroup(0, 5)
		self:SetBodygroup(1, 1)
	end

	self:DrawModel(flags)
end

if SERVER then
	function SWEP:SendProjectiles(ply)
		if not IsValid(ply) or not ply:IsPlayer() then return end
		local projectiles = self.Projectiles

		local v, last = next(projectiles, nil), nil
		while v do
			if not v:IsValid() then
				projectiles[v] = nil
				v = next(projectiles, last)
				continue
			end

			last = v
			v = next(projectiles, v)
		end

		-- players would stack up projectiles into a giant pile & detonate them,
		-- the subsequent flood of networking the projectiles would kick the weapon owner from the game with an overflow
		-- this timer is to help prevent that
		timer.Create(string.format("swcs_breachcharge_sendproj_%s", ply:UserID()), engine.TickInterval() * 2, 1, function()
			net.Start("weapon_swcs_breachcharge")
			net.WriteEntity(self)

			local iLen = math.min(table.Count(projectiles), 255)
			net.WriteUInt(iLen, 8)

			if iLen > 0 then
				local iWritten = 0
				for proj in pairs(projectiles) do
					if iWritten >= 255 then break end

					if proj:IsValid() then
						net.WriteEntity(proj)
						iWritten = iWritten + 1
					end
				end
			end
			net.Send(ply)
		end)
	end

	function SWEP:SendDetonateSignal()
		local projectiles = self.Projectiles
		local current = next(projectiles, nil)
		while current do
			if IsValid(current) then
				current:SignalDetonate()
			end

			current = next(projectiles, current)
		end
	end
else
	net.Receive("weapon_swcs_breachcharge", function(msglen)
		local wep = net.ReadEntity()
		if not wep:IsValid() or wep:GetClass() ~= "weapon_swcs_breachcharge" then return end
		local wepTable = wep:GetTable()

		local iLen = net.ReadUInt(8)

		table.Empty(wepTable.Projectiles)

		if iLen > 0 then
			for i = 1, iLen do
				local proj = net.ReadEntity()
				if proj:IsValid() and proj:GetClass() == "swcs_breachcharge_projectile" then
					wepTable.Projectiles[proj] = true
				end
			end
		end
	end)

	local mat = Material("models/weapons/v_models/csgo/breachcharge/breachcharge_icon")
	function SWEP:DrawHUD()
		local selfTable = self:GetTable()

		local eyePos = EyePos()
		surface.SetMaterial(mat)
		surface.SetDrawColor(255, 255, 255, 255)

		for proj in next, selfTable.Projectiles do
			if proj:IsValid() then
				if proj:GetThinkFuncIndex() == 1 then continue end

				local pos = proj:GetPos()
				local flDist = pos:Distance(eyePos)

				local size = proj:GetTimeToExpire() > 0 and 32 or math.Clamp(math.Remap(flDist, 256, 512, 32, 0), 0, 32)
				if size <= 0 then continue end

				size = math.Clamp(size + ((math.sin(CurTime() * 24) - 1) * size / 10), 0, 32)

				pos.z = pos.z + 3
				local spos = pos:ToScreen()

				surface.DrawTexturedRect(spos.x - (size / 2), spos.y - (size / 2), size, size)
			end
		end
	end
end

local NoAmmo = CreateConVar("swcs_breachcharge_noammopickup", "0", {FCVAR_ARCHIVE}, "whether or not to allow picking up ammo from dropped Breach Charges")
function SWEP:EquipAmmo(ply)
	if NoAmmo:GetBool() then
		ply:RemoveAmmo(self.Primary.DefaultClip, self.Primary.Ammo)
	end
end
