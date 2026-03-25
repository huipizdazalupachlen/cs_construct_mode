-- models/weapons/csgo/v_shield.mdl
-- models/weapons/csgo/w_eq_shield.mdl
-- models/weapons/csgo/w_eq_shield_back.mdl

SWEP.Base = "weapon_swcs_fists"
SWEP.Category = "#spawnmenu.category.swcs"

DEFINE_BASECLASS(SWEP.Base)

SWEP.Slot = 0

SWEP.PrintName = "Riot Shield"
SWEP.Spawnable = true
SWEP.HoldType = "melee2"
SWEP.NoCustomViewmodelPos = true
SWEP.IsShield = true

SWEP.ViewModel = Model("models/weapons/csgo/v_shield.mdl")
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_shield.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/shield.png", "smooth")
end

util.PrecacheModel("models/weapons/csgo/w_eq_shield.mdl")
for i = 1, 10 do
	util.PrecacheModel("models/weapons/csgo/shield_gibs/shield_gib" .. i .. ".mdl")
end

sound.Add({
	name = "Survival.ShieldPush",
	channel = CHAN_WEAPON,
	volume = 1,
	soundlevel = 75,
	sound = Sound(")survival/sheild_push_01.wav"),
})
sound.Add({
	name = "Survival.ShieldEquipStart",
	channel = CHAN_STATIC,
	volume = 1,
	soundlevel = 75,
	sound = Sound(")survival/shield_equip_04.wav"),
})
sound.Add({
	name = "Survival.ShieldEquipEnd",
	channel = CHAN_STATIC,
	volume = 1,
	soundlevel = 75,
	sound = Sound(")survival/shield_equip_05.wav"),
})

SWEP.ItemDefAttributes = [=["attributes 08/03/2020" {
	"primary clip size" "-1"
	"is full auto" "1"
	"in game price"		"1100"
	"max player speed"		"200"
	"max player speed alt"		"200"
	"weapon weight"		"0"
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
	"weapon_type"		"Shield"
}]=]

if swcs.InTTT then
	SWEP.AutoSpawnable = false
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Entity", "Impostor")
end

local swcs_weapon_disarm = GetConVar("swcs_weapon_disarm")
function SWEP:PowerfulSwing()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local vForward = owner:GetAimVector()
	local vecSrc = owner:GetShootPos()
	local vecEnd = vecSrc + vForward * 64

	local function trace_filter(ent)
		if ent == owner then return false end
		if ent:GetOwner() == owner then return false end

		return true
	end

	self:DoPlayerAttackAnimation(owner)

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

	self:EmitSound("Survival.ShieldPush")
	self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)

	local time = CurTime() + self:SequenceDuration()
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)

	local seed = self:GetRandomSeed()
	seed = seed + 1

	local rand = UniformRandomStream(seed)

	if tr.Fraction < 1 then
		local ent = tr.Entity

		self:SetViewPunchAngle(Angle(rand:RandomInt(5, 10), rand:RandomInt(5, 10), rand:RandomInt(5, 10)))

		local info = DamageInfo()
		info:SetInflictor(self)
		info:SetAttacker(owner)
		info:SetDamage(30)
		info:SetDamageType(DMG_CLUB)
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
			if (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then
				--self:EmitSound("Flesh.ImpactSoft")
			else
				--self:EmitSound("Flesh.ImpactSoftGloves")

				local surfaceData, soundname = util.GetSurfaceData(tr.SurfaceProps)
				if surfaceData then
					soundname = surfaceData.impactHardSound or surfaceData.impactSoftSound
				end

				local filter
				if SERVER then
					filter = RecipientFilter()
					filter:AddPVS(tr.HitPos)
					filter:RemovePlayer(owner --[[@as Player]])
				end

				if IsFirstTimePredicted() and soundname ~= nil then
					EmitSound(soundname, tr.HitPos, nil, nil, nil, nil, nil, nil, nil, filter)
				end
			end
		end
	else
		self:SetViewPunchAngle(Angle(rand:RandomInt(5, 7), rand:RandomInt(5, 7), rand:RandomInt(5, 7)))
	end
end
SWEP.Swing = SWEP.PowerfulSwing

hook.Add("DoAnimationEvent", "swcs.shield", function(ply, event, data)
	local wep = ply:GetActiveWeapon()
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY and wep:IsValid() and wep.IsSWCSWeapon and wep.IsShield then
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, ply:LookupSequence("flinch_shoulder_l"), 0, true)
		return ACT_INVALID
	end
end)
function SWEP:DoPlayerAttackAnimation(owner)
	if owner:IsPlayer() then
		owner:DoCustomAnimEvent(PLAYERANIMEVENT_ATTACK_PRIMARY, 0)
	else
		BaseClass.DoPlayerAttackAnimation(self, owner)
	end
end

function SWEP:SecondaryAttack()
	BaseClass.PrimaryAttack(self)
end

local classnames = {
	["weapon_crowbar"] = true,
	["weapon_stunstick"] = true,
}
local function IsMeleeWeapon(wep)
	local classname = wep:GetClass()
	if classnames[classname] then
		return true
	end

	if weapons.IsBasedOn(classname, "weapon_swcs_knife") then
		return true
	end
	if weapons.IsBasedOn(classname, "weapon_swcs_base_melee_throwable") then
		return true
	end

	return false
end
hook.Add("SWCSShouldDisarmPlayer", "swcs.shield", function(owner, wep, victim, victimWep)
	if wep.IsShield and IsMeleeWeapon(victimWep) then
		return false
	end
end)

local function CanProperty(self, ply, prop)
	return false
end

local ORIGIN = Vector()
local ANGLE_ZERO = Angle()

SWEP.ShieldOffset = Vector(4, -5.5, 5)
SWEP.ShieldOffsetBack = Vector(-12, -0.5, 0)
SWEP.ShieldAngle = {165, 0, 0}
SWEP.ShieldAngleBack = {-90, 0, -105}

function SWEP:ShieldToHands(ent)
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	ent:SetLocalPos(ORIGIN)
	ent:SetLocalAngles(ANGLE_ZERO)
	ent:SetParent(NULL, -1)
	ent:RemoveEffects(EF_FOLLOWBONE)

	ent:SetPos(ORIGIN)
	ent:SetAngles(ANGLE_ZERO)

	local iBoneIndex = owner:LookupBone("ValveBiped.Bip01_R_Hand")
	local ownerBonePos, ownerBoneAng = owner:GetBonePosition(iBoneIndex)
	local pos = LocalToWorld(self.ShieldOffset, ANGLE_ZERO, ownerBonePos, ownerBoneAng)

	ent:FollowBone(owner, iBoneIndex or 0)

	ent:SetPos(pos)
	ent:SetLocalPos(self.ShieldOffset)

	local ang = owner:GetAngles()
	local af, au, ar = unpack(self.ShieldAngle)
	ang:RotateAroundAxis(ang:Forward(), af)
	ang:RotateAroundAxis(ang:Up(), au)
	ang:RotateAroundAxis(ang:Right(), ar)
	ent:SetAngles(ang)
end

function SWEP:ShieldToBack(ent)
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	ent:SetLocalPos(ORIGIN)
	ent:SetLocalAngles(ANGLE_ZERO)
	ent:SetParent(NULL, -1)
	ent:RemoveEffects(EF_FOLLOWBONE)

	ent:SetPos(ORIGIN)
	ent:SetAngles(ANGLE_ZERO)

	local iBoneIndex = owner:LookupBone("ValveBiped.Bip01_Spine4")
	local ownerBonePos, ownerBoneAng = owner:GetBonePosition(iBoneIndex)
	local pos = LocalToWorld(self.ShieldOffsetBack, ANGLE_ZERO, ownerBonePos, ownerBoneAng)

	ent:FollowBone(owner, iBoneIndex or 0)

	ent:SetPos(pos)
	ent:SetLocalPos(self.ShieldOffsetBack)

	local ang = owner:GetAngles()
	local af, au, ar = unpack(self.ShieldAngleBack)
	ang:RotateAroundAxis(ang:Forward(), af)
	ang:RotateAroundAxis(ang:Up(), au)
	ang:RotateAroundAxis(ang:Right(), ar)
	ent:SetAngles(ang)
end

function SWEP:CreateImpostor(owner)
	---@class Entity
	local ent = ents.Create("swcs_shield")

	if ent:IsValid() then
		ent:SetOwner(owner)
		ent:SetWeapon(self)
		self:DeleteOnRemove(ent)
		self:SetImpostor(ent)
		ent.CanProperty = CanProperty

		ent:SetCollisionGroup(COLLISION_GROUP_WORLD)

		ent:SetModel(self.WorldModel)
		ent:Spawn()
		ent:Activate()

		local iHealth = self:Health()
		if iHealth > 0 then
			ent:SetHealth(iHealth)
		end

		hook.Run("PlayerSpawnedSENT", owner, ent)

		local phys = ent:GetPhysicsObject()
		if phys:IsValid() then
			phys:SetMass(1000)
		end
	end

	return ent
end

function SWEP:Equip(newOwner)
	BaseClass.Equip(self, newOwner)

	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	local ent = self:GetImpostor()
	if not ent:IsValid() then
		ent = self:CreateImpostor(owner)
	end
	self:ShieldToBack(ent)
end

function SWEP:Deploy()
	BaseClass.Deploy(self)

	if SERVER then
		local owner = self:GetOwner()
		local ent = self:GetImpostor()
		if not ent:IsValid() then
			ent = self:CreateImpostor(owner)
		end
		self:ShieldToHands(ent)
	end

	return true
end

function SWEP:Holster()
	BaseClass.Holster(self)

	if SERVER then
		local owner = self:GetOwner()
		local ent = self:GetImpostor()
		if not ent:IsValid() then
			ent = self:CreateImpostor(owner)
		end
		self:ShieldToBack(ent)
	end

	return true
end

function SWEP:DrawWorldModel(flags)
	if not self:GetOwner():IsValid() then
		self:DrawModel()
	else
		local ent = self:GetImpostor()
		if ent:IsValid() and ent:GetNoDraw() then -- set to nodraw on owner client
			ent:DrawModel()
		end
	end
end

function SWEP:OnDrop()
	local imp = self:GetImpostor()
	if imp:IsValid() then
		imp:Remove()
	end
end

if CLIENT then
	local icon = Material("hud/swcs/shield_alert.png", "smooth")
	local icon_additive = CreateMaterial("swcs_shield_alert_additive", icon:GetShader(), icon:GetKeyValues())

	-- panorama screen scales from 1080 instead of the old 480
	local function ScreenScaleP(n)
		return math.ceil(n * (ScrH() / 1080))
	end

	function SWEP:DrawHUD()
		-- https://github.com/Facepunch/garrysmod-issues/issues/1531#issuecomment-719965167
		if not icon_additive:GetString("$basetexture") then
			icon_additive:SetTexture("$basetexture", icon:GetTexture("$basetexture"))

			-- flags get reset when setting new base texture?
			icon_additive:SetInt("$flags", 176) -- alpha + $additive
			icon_additive:Recompute()
		end

		local shield = self:GetImpostor()
		if not shield:IsValid() then return end

		local health = (shield:Health() / shield:GetMaxHealth())

		if shield:Health() <= 0 or health > 0.9 then return end

		-- #HudBottomCenter height: 43%
		local bcy = math.ceil(ScrH() * 0.43)

		-- .ShieldDamageAlert width and height: 110px
		local w, h = ScreenScaleP(110), ScreenScaleP(110)

		local x = math.ceil(ScrW() / 2) - math.ceil(w / 2)
		local y = ScrH() - math.ceil(bcy / 2) - math.ceil(h / 2)

		-- .ShieldDamageAlertBackdrop
		surface.SetDrawColor(0, 0, 0, 128)
		surface.SetMaterial(icon)
		surface.DrawTexturedRect(x, y, w, h)

		-- .ShieldDamageAlertOverlay
		surface.SetDrawColor(255, 225, 0, 179)
		surface.SetMaterial(icon_additive)
		surface.DrawTexturedRect(x, y, w, h)

		-- .ShieldDamageAlertProgress
		-- height: 10%
		local ph = math.ceil(h * 0.1)
		local py = (y + h) - ph

		surface.DrawOutlinedRect(x, py, w, ph)

		local pw = (w - 1) * health
		local bw = (w - 1) * (1 - health)

		surface.DrawRect((x + 1) + bw, py + 1, pw, ph - 2)

		surface.SetDrawColor(0, 0, 0, 179)
		surface.DrawRect((x + 1), py + 1, bw, ph - 2)
	end

	local shield = NULL
	hook.Add("PreRender", "swcs.shield", function()
		local lply = LocalPlayer()
		if not IsValid(lply) then return end

		if lply:GetObserverMode() == OBS_MODE_CHASE or lply:GetObserverMode() == OBS_MODE_IN_EYE then
			---@diagnostic disable-next-line: cast-local-type
			lply = lply:GetObserverTarget()
		end

		if IsValid(shield) and shield:GetOwner() ~= lply then shield = NULL end

		if not IsValid(shield) and lply:IsPlayer() then
			for _, w in ipairs(lply:GetWeapons()) do
				if w.IsSWCSWeapon and w.IsShield then
					shield = w
					break
				end
			end
		end

		if not IsValid(shield) then return end

		local ent = shield:GetImpostor()
		if not IsValid(ent) then return end

		if lply:IsPlayer() and lply:ShouldDrawLocalPlayer() then
			ent:SetNoDraw(false)
		else
			ent:SetNoDraw(true)
		end
	end)
elseif SERVER then
	hook.Add("PlayerGiveSWEP", "swcs.shield", function(ply, class)
		local has_shield = false
		for _, w in ipairs(ply:GetWeapons()) do
			if w and w.IsSWCSWeapon and w.IsShield then
				has_shield = true
				break
			end
		end

		local wep = weapons.Get(class)

		if has_shield and wep and wep.IsSWCSWeapon and wep.IsShield then
			ply:PrintMessage(HUD_PRINTTALK, "#swcs.shield_onlyone")
			return false
		end
	end)
	hook.Add("PlayerCanPickupWeapon", "swcs.shield", function(ply, wep)
		local has_shield = false
		local shield_class = ""
		for _, w in ipairs(ply:GetWeapons()) do
			if w and w.IsSWCSWeapon and w.IsShield then
				has_shield = true
				shield_class = w:GetClass()
				break
			end
		end

		if has_shield and IsValid(wep) and wep.IsSWCSWeapon and wep.IsShield and wep:GetClass() ~= shield_class then
			return false
		end
	end)
end
