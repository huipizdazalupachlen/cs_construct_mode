AddCSLuaFile()

SWEP.Base = "weapon_base"
SWEP.IsSWCSWeapon = true

SWEP.AllowDrop = true
SWEP.SuppressSlidingViewModelTilt = true

SWEP.Slot = 1
SWEP.SlotPos = 2

local swcs_use_headbob = CLIENT and CreateClientConVar("swcs_use_headbob", "2")

SWEP.BobScale = (CLIENT and swcs_use_headbob and swcs_use_headbob:GetInt() == 0) and 1 or 0

SWEP.Secondary.Ammo = ""
SWEP.Secondary.ClipSize = -1

AccessorFunc(SWEP, "m_iUnsharedSeed", "UnsharedSeed", FORCE_NUMBER)

local IronSight_should_approach_unsighted = 0
local IronSight_should_approach_sighted = 1
local IronSight_viewmodel_is_deploying = 2
local IronSight_weapon_is_dropped = 3

local g_bSinglePlayer = game.SinglePlayer()

AddCSLuaFile"cl_crosshair.lua"

include"sh_penetration.lua"
include"sh_recoil.lua"
include"sh_econ.lua"
include"sh_effects.lua"
include"sh_spread.lua"

-- register ammo
hook.Add("Initialize", "swcs.ammo", function()
	--CreateConVar( "ammo_50AE_impulse", "2400", FCVAR_REPLICATED )
	--CreateConVar( "ammo_762mm_impulse", "2400", FCVAR_REPLICATED )
	--CreateConVar( "ammo_556mm_impulse", "2400", FCVAR_REPLICATED )
	--CreateConVar( "ammo_556mm_box_impulse", "2400", FCVAR_REPLICATED )
	--CreateConVar( "ammo_338mag_impulse", "2800", FCVAR_REPLICATED )
	--CreateConVar( "ammo_9mm_impulse", "2000", FCVAR_REPLICATED )
	--CreateConVar( "ammo_buckshot_impulse", "600", FCVAR_REPLICATED )
	--CreateConVar( "ammo_45acp_impulse", "2100", FCVAR_REPLICATED )
	--CreateConVar( "ammo_357sig_impulse", "2000", FCVAR_REPLICATED )
	--CreateConVar( "ammo_57mm_impulse", "2000", FCVAR_REPLICATED )

	game.AddAmmoType({
		name = "BULLET_PLAYER_50AE",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_762MM",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_556MM",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_556MM_SMALL",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_556MM_BOX",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2400,
		minsplash = 10,
		maxsplash = 14,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_338MAG",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2800,
		minsplash = 12,
		maxsplash = 16,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_9MM",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 5,
		maxsplash = 10,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_BUCKSHOT",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 600,
		minsplash = 3,
		maxsplash = 6,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_45ACP",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2100,
		minsplash = 6,
		maxsplash = 10,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_357SIG",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 4,
		maxsplash = 8,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_57MM",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 4,
		maxsplash = 8,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_357SIG_SMALL",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 4,
		maxsplash = 8,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_357SIG_MIN",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 4,
		maxsplash = 8,
	})
	game.AddAmmoType({
		name = "BULLET_PLAYER_357SIG_P250",
		dmgtype = DMG_BULLET,
		tracer = TRACER_LINE,
		force = 2000,
		minsplash = 4,
		maxsplash = 8,
	})

	game.AddAmmoType({name = "swcs_flashbang", maxcarry = 2})
	game.AddAmmoType({name = "swcs_hegrenade", maxcarry = 1})
	game.AddAmmoType({name = "swcs_smokegrenade", maxcarry = 1})
	game.AddAmmoType({name = "swcs_firegrenade", maxcarry = 1})
	game.AddAmmoType({name = "swcs_snowball", maxcarry = 3})
	game.AddAmmoType({name = "swcs_tagrenade", maxcarry = 1})
	game.AddAmmoType({name = "swcs_healthshot", maxcarry = 3})
	game.AddAmmoType({name = "swcs_decoygrenade", maxcarry = 1})
	game.AddAmmoType({name = "swcs_breachcharge", maxcarry = 3})
end)

local VectorMA

do
	local VECTOR = FindMetaTable("Vector")
	---@diagnostic disable: need-check-nil
	local VUnpack = VECTOR.Unpack
	local VSetUnpacked = VECTOR.SetUnpacked
	---@diagnostic enable: need-check-nil

	VectorMA = function(start, scale, dir, dest)
		local startX, startY, startZ = VUnpack(start)
		local dirX, dirY, dirZ = VUnpack(dir)

		VSetUnpacked(dest,
			startX + scale * dirX,
			startY + scale * dirY,
			startZ + scale * dirZ
		)
	end
end

SURFACE_PROP_DEFAULT = util.GetSurfaceIndex("default")

CS_MASK_SHOOT = bit.bor(MASK_SHOT, CONTENTS_DEBRIS)

Primary_Mode = 0
Secondary_Mode = 1

sound.Add({
	name = "Default.NearlyEmpty",
	channel = CHAN_ITEM,
	level = 65,
	volume = 1,
	sound = Sound("weapons/csgo/lowammo_01.wav"),
})
sound.Add({
	name = "Weapon.WeaponMove1",
	channel = CHAN_ITEM,
	level = 65,
	volume = {0.05, 0.1},
	pitch = {98, 101},
	sound = Sound("weapons/csgo/movement1.wav"),
})
sound.Add({
	name = "Weapon.WeaponMove2",
	channel = CHAN_ITEM,
	level = 65,
	volume = {0.05, 0.1},
	pitch = {98, 101},
	sound = Sound("weapons/csgo/movement2.wav"),
})
sound.Add({
	name = "Weapon.WeaponMove3",
	channel = CHAN_ITEM,
	level = 65,
	volume = {0.05, 0.1},
	pitch = {98, 101},
	sound = Sound("weapons/csgo/movement3.wav"),
})
sound.Add({
	name = "Weapon.AutoSemiAutoSwitch",
	channel = CHAN_STATIC,
	level = 65,
	volume = 1.0,
	pitch = {98, 101},
	sound = Sound("weapons/csgo/auto_semiauto_switch.wav"),
})

AccessorFunc(SWEP, "m_sWeaponType", "WeaponType", FORCE_STRING)
AccessorFunc(SWEP, "m_sZoomOutSound", "ZoomOutSound", FORCE_STRING)
AccessorFunc(SWEP, "m_sZoomInSound", "ZoomInSound", FORCE_STRING)
--AccessorFunc(SWEP, "m_flDeploySpeed", "DeploySpeed", FORCE_NUMBER)

SWEP.UseHands = true

local swcs_viewmodel_fov
local swcs_righthand
if CLIENT then
	swcs_viewmodel_fov = GetConVar("swcs_viewmodel_fov")
	swcs_righthand = GetConVar("swcs_righthand")
	SWEP.ViewModelFOV = swcs_viewmodel_fov:GetFloat()
	SWEP.ViewModelFlip = not swcs_righthand:GetBool()

	cvars.AddChangeCallback("swcs_righthand", function(_, _, new)
		local val = tonumber(new)
		if not val then return end

		local SWEP = weapons.GetStored("weapon_swcs_base")
		if not SWEP then return end

		local enabled = val ~= 0

		SWEP.ViewModelFlip = not enabled

		for _, v in ents.Iterator() do
			if v:IsValid() and v:IsWeapon() and weapons.IsBasedOn(v:GetClass(), "weapon_swcs_base") then
				if not v.NoViewModelFlip then
					v.ViewModelFlip = not enabled
				end
			end
		end
	end)
else
	SWEP.ViewModelFOV = 68
	SWEP.ViewModelFlip = false
end

local AE_CL_ATTACH_SILENCER_COMPLETE = 44
local AE_CL_DETACH_SILENCER_COMPLETE = 46
local AE_WPN_PRIMARYATTACK = 49
local AE_WPN_COMPLETE_RELOAD = 54
local AE_BEGIN_TAUNT_LOOP = 72
local AE_CL_SET_STATTRAK_GLOW = 5067
local AE_WPN_CZ_DUMP_CURRENT_MAG = 74
local AE_WPN_CZ_UPDATE_BODYGROUP = 75
local AE_MUZZLEFLASH = 5001
local AE_CLIENT_EJECT_BRASS = 5055
local AE_CL_BODYGROUP_SET_VALUE = 5056
local AE_CL_BODYGROUP_SET_TO_CLIP = 5057
local AE_CL_BODYGROUP_SET_TO_NEXTCLIP = 5058
local AE_CL_HIDE_SILENCER = 5059
local AE_CL_SHOW_SILENCER = 5060
local AE_WPN_NEXTCLIP_TO_POSEPARAM = 5061
local AE_WPN_CLIP_TO_POSEPARAM = 5063
local AE_WPN_HEALTHSHOT_INJECT = 76

local SILENCER_VISIBLE = 0
local SILENCER_HIDDEN = 1

function SWEP:GetShotgunReloadState() return 0 end -- only shotguns use this for multi-stage reloads

function SWEP:SetupDataTables()
	self:NetworkVar("Entity", 0, "IronSightController")

	self:NetworkVar("String", 1, "OriginalOwnerSteamID")

	self:NetworkVar("Bool", 0, "InReload")
	self:NetworkVar("Bool", 1, "IsLookingAtWeapon")
	self:NetworkVar("Bool", 2, "SilencerOn")
	self:NetworkVar("Bool", 3, "ResumeZoom")
	self:NetworkVar("Bool", 4, "BurstMode")
	self:NetworkVar("Bool", 5, "IsScoped")

	self:NetworkVar("Int", 0, "ShotsFired")
	self:NetworkVar("Int", 1, "ZoomLevel")
	self:NetworkVar("Int", 2, "WeaponMode")
	self:NetworkVar("Int", 3, "BurstShotsRemaining")
	self:NetworkVar("Int", 4, "SharedSeed")
	self:NetworkVar("Int", 5, "IronSightMode")
	self:NetworkVar("Int", 6, "ReserveAmmo")

	self:NetworkVar("Float", 0, "FinishReloadTime")
	self:NetworkVar("Float", 1, "WeaponIdleTime")
	self:NetworkVar("Float", 2, "AccuracyPenalty")
	self:NetworkVar("Float", 3, "RecoilIndex")
	self:NetworkVar("Float", 4, "DoneSwitchingSilencer")
	self:NetworkVar("Float", 5, "NextBurstShot")
	self:NetworkVar("Float", 6, "PostponeFireReadyTime")
	self:NetworkVar("Float", 7, "LookWeaponEndTime")

	-- done to prevent prediction errors due to network truncation on Angle netvars
	self:NetworkVar("Float", 8, "AimPunchVelP")
	self:NetworkVar("Float", 9, "AimPunchVelY")
	self:NetworkVar("Float", 10, "AimPunchP")
	self:NetworkVar("Float", 11, "AimPunchY")
	self:NetworkVar("Float", 12, "ViewPunchP")
	self:NetworkVar("Float", 13, "ViewPunchY")

	self:NetworkVar("Float", 14, "LastLookTime")
	self:NetworkVar("Float", 15, "LastShotTime")

	self:NetworkVar("Float", 16, "ViewPunchR")

	if CLIENT then
		self:NetworkVarNotify("ZoomLevel", self.OnZoomLevelChanged)
		self:NetworkVarNotify("ResumeZoom", self.OnResumeZoomChanged)
	end

	-- interpolate inaccuracy
	do
		swcs.DefineInterpolatedVar(self, "m_AccuracyPenalty", "AccuracyPenalty", true)
		self.m_AccuracyPenaltyLast = 0.0
		--
	end
end

function SWEP:OnZoomLevelChanged(name, old, new)
	if old == new then return end

	local selfTable = self:GetTable()

	if new == 0 then
		selfTable.SwayScale = 1

		if selfTable.OldBobScale then
			selfTable.BobScale = selfTable.OldBobScale
			selfTable.OldBobScale = nil
		end
	else
		if not selfTable.OldBobScale then
			selfTable.OldBobScale = selfTable.BobScale
		end
		selfTable.BobScale = 0

		selfTable.SwayScale = 0
	end
end

function SWEP:OnResumeZoomChanged(name, old, new)
	if old == new then return end

	local selfTable = self:GetTable()

	if new then
		selfTable.SwayScale = 1

		if selfTable.OldBobScale then
			selfTable.BobScale = selfTable.OldBobScale
			selfTable.OldBobScale = nil
		end
	else
		if not selfTable.OldBobScale then
			selfTable.OldBobScale = selfTable.BobScale
		end
		selfTable.BobScale = 0

		selfTable.SwayScale = 0
	end
end

function SWEP:GetAimPunchAngleVel()
	return Angle(self:GetAimPunchVelP(), self:GetAimPunchVelY(), 0)
end

-- View Punch definitions
do
	swcs.DefineInterpolatedVar(SWEP, "m_ViewPunchAngle", "ViewPunchAngle", true)
	SWEP.m_ViewPunchAngleLast = Angle()

	function SWEP:GetUninterpolatedViewPunchAngle()
		return Angle(self:GetViewPunchP(), self:GetViewPunchY(), self:GetViewPunchR())
	end

	-- viewpunch gets custom setter because we network the pitch and yaw seperately
	function SWEP:SetViewPunchAngle(ang)
		if IsFirstTimePredicted() then
			self:SetLastViewPunchAngle(self:GetUninterpolatedViewPunchAngle())
		end

		local p, y, r = ang:Unpack()
		self:SetViewPunchP(p)
		self:SetViewPunchY(y)
		self:SetViewPunchR(r)
	end
end

-- Aim Punch definitions
do
	swcs.DefineInterpolatedVar(SWEP, "m_RawAimPunchAngle", "RawAimPunchAngle", true)
	SWEP.m_RawAimPunchAngleLast = Angle()

	function SWEP:GetUninterpolatedRawAimPunchAngle()
		return Angle(self:GetAimPunchP(), self:GetAimPunchY(), 0)
	end

	-- aimpunch gets custom setter because we network the pitch and yaw seperately
	function SWEP:SetRawAimPunchAngle(ang)
		if IsFirstTimePredicted() then
			self:SetLastRawAimPunchAngle(self:GetUninterpolatedRawAimPunchAngle())
		end

		self:SetAimPunchP(ang.p)
		self:SetAimPunchY(ang.y)
	end
end

function SWEP:SetAimPunchAngleVel(ang)
	self:SetAimPunchVelP(ang.p)
	self:SetAimPunchVelY(ang.y)
end

local md5 = util.MD5
function SWEP:GetRandomSeed()
	local owner = self:GetOwner()
	local iBase = SWCS_SPREAD_SHARE_SEED:GetBool() and 0 or self:GetUnsharedSeed()

	if owner:IsPlayer() then
		local commandNum = (owner.m_LastUserCommandNumber or (owner.m_LastUserCommand and owner.m_LastUserCommand:CommandNumber()) or 0)
		iBase = iBase + tonumber(string.sub(md5(commandNum --[[@as string]]), -2), 16) -- lol
	else
		iBase = iBase + engine.TickCount() + self:EntIndex()
	end

	return bit.band(iBase, SWCS_SPREAD_MAX_SEEDS:GetInt())
end

local weapon_recoil_scale = GetConVar"weapon_recoil_scale"
function SWEP:GetAimPunchAngle()
	local ret = self:GetRawAimPunchAngle()
	ret:Normalize()
	ret:Mul(weapon_recoil_scale:GetFloat())
	ret:Normalize()
	return ret
end

function SWEP:GetUninterpolatedAimPunchAngle()
	local ret = self:GetUninterpolatedRawAimPunchAngle()
	ret:Normalize()
	ret:Mul(weapon_recoil_scale:GetFloat())
	ret:Normalize()
	return ret
end

local deployoverride = SWCS_DEPLOY_OVERRIDE
local deployspeed = GetConVar"sv_defaultdeployspeed"
function SWEP:GetDeploySpeed()
	if deployoverride:GetFloat() ~= 0 then
		return deployoverride:GetFloat()
	end

	return swcs.InTTT and 1.4 or deployspeed:GetFloat()
end

function SWEP:UpdateDeploySpeed()
	local flDeploySpeed = 1

	local flDeployOverride = deployoverride:GetFloat()
	if flDeployOverride ~= 0 then
		flDeploySpeed = flDeployOverride
	elseif swcs.InTTT then
		flDeploySpeed = 1.4
	else
		flDeploySpeed = deployspeed:GetFloat()
	end

	self:SetDeploySpeed(flDeploySpeed)
end

SWEP.ItemDefAttributes = [=["attributes 04/22/2020" {
	"max player speed" "250"
}]=]
SWEP.ItemDefVisuals = [=["visuals 07/07/2020" {}]=]
SWEP.ItemDefPrefab = [=["prefab 08/11/2020" {}]=]
function SWEP:Initialize()
	local selfTable = self:GetTable()

	if selfTable.HoldType and #selfTable.HoldType > 0 then
		self:SetHoldType(selfTable.HoldType)
		selfTable.SetWeaponHoldType(self, selfTable.HoldType)
	end
	selfTable.UpdateDeploySpeed(self)

	selfTable.GenerateRecoilTable(self, selfTable.m_RecoilData)
	selfTable.GenerateSpreadTable(self, selfTable.m_SpreadData)

	selfTable.SetSilencerOn(self, selfTable.GetHasSilencer(self))
	selfTable.SetWeaponMode(self, (selfTable.GetHasSilencer(self) and not selfTable.HasBuiltinSilencer(self)) and Secondary_Mode or Primary_Mode)

	selfTable.UpdateIronSightController(self)

	-- csgo doesn't share the random seed, so we try to emulate that here
	-- servers and clients will never have the exact same address
	local iUnshared = tonumber(util.CRC(tostring({})))
	selfTable.SetUnsharedSeed(self, iUnshared)
	selfTable.SetSharedSeed(self, math.floor(CurTime() / engine.TickInterval()))
end

function SWEP:RemoveIfExhausted(bDoSwitch)
	if not self:GetExhaustible() then return false end

	local owner = self:GetPlayerOwner()
	if not owner then return false end

	if self:HasNoAmmo() then
		if bDoSwitch or bDoSwitch == nil then
			self:SwitchToPreviousWeapon()
		end

		if SERVER then
			owner:StripWeapon(self:GetClass())
		end

		return true
	end

	return false
end

function SWEP:SwitchToPreviousWeapon()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local prev = owner:GetPreviousWeapon()
	if prev ~= self then
		self:SwitchToWeapon(prev)
	end
end

function SWEP:SwitchToWeapon(wep)
	if not (isentity(wep) and wep:IsValid() and wep:IsWeapon()) then return end

	if SERVER then
		local owner = self:GetPlayerOwner()
		if owner then
			owner:SelectWeapon(wep:GetClass())
		end
	else
		input.SelectWeapon(wep)
	end
end

function SWEP:HasNoAmmo()
	local owner = self:GetPlayerOwner()
	local iAmmo = self:GetMaxClip1() == -1 and 0 or self:Clip1()
	iAmmo = iAmmo + (owner and owner:GetAmmoCount(self:GetPrimaryAmmoType()) or 0)
	return iAmmo <= 0
end

function SWEP:PlayReloadAnimation(selfTable)
	selfTable = selfTable or self:GetTable()
	local iAct = selfTable.GetReloadActivity(self)

	if iAct ~= -1 then
		selfTable.SetWeaponAnim(self, iAct)
	else
		local iSequence = selfTable.GetReloadSequence(self)

		if iSequence ~= -1 then
			selfTable.SetWeaponSequence(self, iSequence)
		else
			selfTable.SetWeaponAnim(self, ACT_VM_RELOAD)
		end
	end
end

function SWEP:Reload()
	local selfTable = self:GetTable()
	if not selfTable.m_bProcessingActivities then return end

	local ok = selfTable.CanReload(self)

	if ok then
		selfTable.SetInReload(self, true)
		selfTable.PlayReloadAnimation(self, selfTable)

		selfTable.SetShotsFired(self, 0)

		local time = CurTime() + self:SequenceDuration()
		selfTable.SetFinishReloadTime(self, time)
		self:SetNextPrimaryFire(time)
		self:SetNextSecondaryFire(time)

		self:GetOwner():DoReloadEvent()

		selfTable.OnStartReload(self)
	else
		selfTable.OnReloadFail(self)
	end
end

function SWEP:UpdateIronSightController()
	local iron = self:GetIronSightController()

	local Attributes = self.ItemAttributes

	if SERVER and Attributes and tobool(Attributes["aimsight capable"]) and not iron:IsValid() then
		iron = ents.Create("swcs_ironsightcontroller")
		self:DeleteOnRemove(iron)
		self:SetIronSightController(iron)
		iron:SetParent(self)
		iron:SetOwner(self:GetOwner())
		iron:Init(self)
		iron:SetLocalPos(vector_origin)
		iron:Spawn()
	elseif CLIENT then
		local owner = self:GetOwner()

		if not g_bSinglePlayer and owner == LocalPlayer() and iron:IsValid() and not iron:GetPredictable() then
			iron:SetPredictable(true)
		end
	end

	if iron:IsValid() and iron.Init then
		iron:Init(self)
	end
end

function SWEP:OwnerChanged()
	local owner = self:GetOwner()

	if SERVER and owner:IsValid() and owner:IsPlayer() and #self:GetOriginalOwnerSteamID() == 0 then
		self:SetOriginalOwnerSteamID(owner:SteamID())

		self:NetworkPlayerEconData(owner)
	end

	local iron = self:GetIronSightController()
	if iron:IsValid() then
		iron:SetOwner(owner)

		if CLIENT and not g_bSinglePlayer then
			if owner == LocalPlayer() and not iron:GetPredictable() then
				iron:SetPredictable(true)
			elseif iron:GetPredictable() then
				iron:SetPredictable(false)
			end
		end
	end
end

function SWEP:GetCycleTime()
	local flCycleTime = self:GetDefCycleTime()
	return flCycleTime ~= 0 and flCycleTime or .15 -- .15s cycle time = 400 rpm
end

-- called whenever the lua file is reloaded
function SWEP:OnReloaded()
	if self.swcs_cb_idx then
		local owner = self:GetOwner()
		if not owner:IsValid() then return end

		local vm = owner:GetViewModel()
		if vm:IsValid() then
			vm:RemoveCallback("BuildBonePositions", self.swcs_cb_idx)
			self.swcs_cb_idx = nil
		end
	end
end

function SWEP:GetHasZoom()
	return tonumber(self:GetZoomLevels()) and tonumber(self:GetZoomLevels()) ~= 0
end

function SWEP:SetWeaponSequence(idealSequence, flPlaybackRate)
	local owner = self:GetOwner()
	local vm = owner:IsPlayer() and owner:GetViewModel() or self

	if type(idealSequence) == "string" then
		idealSequence = vm:LookupSequence(idealSequence)
	end

	if idealSequence == -1 then return false end
	flPlaybackRate = isnumber(flPlaybackRate) and flPlaybackRate or 1

	self:SendViewModelMatchingSequence(idealSequence)
	self:SetSequence(idealSequence)

	if owner:IsValid() and owner:IsPlayer() and vm:IsValid() then
		vm:SendViewModelMatchingSequence(idealSequence)
		vm:SetPlaybackRate(flPlaybackRate)

		local bIsLookingAt = string.find(vm:GetSequenceName(idealSequence), "lookat")
		if not bIsLookingAt and CLIENT then
			-- Fade down stat trak glow if we're doing anything other than inspecting
			self:SetStatTrakGlowMultiplier(0)
		end
	end

	-- Set the next time the weapon will idle
	self:SetWeaponIdleTime(CurTime() + (vm:SequenceDuration(idealSequence) * (1 / flPlaybackRate)))
	return true
end

function SWEP:SetWeaponAnim(idealAct, flPlaybackRate)
	local owner = self:GetOwner()
	local vm = owner:IsPlayer() and owner:GetViewModel() or self

	if not vm:IsValid() then return false end

	local idealSequence = vm:SelectWeightedSequence(idealAct)
	if idealSequence == nil or idealSequence == ACT_INVALID then return false end
	flPlaybackRate = isnumber(flPlaybackRate) and flPlaybackRate or 1

	self:SendWeaponAnim(idealAct)
	self:SendViewModelMatchingSequence(idealSequence)

	if owner:IsValid() and owner:IsPlayer() then
		vm:SendViewModelMatchingSequence(idealSequence)
		vm:SetPlaybackRate(flPlaybackRate)

		local bIsLookingAt = idealAct ~= ACT_INVALID and string.find(vm:GetSequenceName(idealSequence), "lookat")
		if not bIsLookingAt and CLIENT then
			-- Fade down stat trak glow if we're doing anything other than inspecting
			self:SetStatTrakGlowMultiplier(0)
		end
	end

	-- Set the next time the weapon will idle
	self:SetWeaponIdleTime(CurTime() + (vm:SequenceDuration(idealSequence) * (1 / flPlaybackRate)))
	return true
end

function SWEP:WeaponIdle()
	if self:GetWeaponIdleTime() > CurTime() then return end

	--if self:Clip1() > 0 then
	if self:Clip1() ~= 0 then
		self:SetWeaponIdleTime(CurTime() + (self.GetIdleInterval and self:GetIdleInterval() or 0.1))

		-- silencers are bodygroups, so there is no longer a silencer-specific idle.
		self:SetWeaponAnim(ACT_VM_IDLE)
	end
end

function SWEP:IsUseable()
	local owner = self:GetPlayerOwner()
	if not owner then return false end

	if self:Clip1() <= 0 then
		if self:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 and self:GetMaxClip1() ~= -1 then
			-- clip is empty ( or nonexistant ) and the player has no more ammo of this type.
			return false
		end
	end

	return true
end

function SWEP:Think_RevolverResetHaulback(owner)
	if self.ItemAttributes and self:GetIsRevolver() then
		self:SetWeaponMode(Secondary_Mode)
		self:ResetPostponeFireReadyTime()

		if self:GetActivity() == ACT_VM_HAULBACK then
			self:SetWeaponAnim(ACT_VM_IDLE)
		end
	end
end

function SWEP:Think_ProcessIdleNoAction(owner)
	self:Think_RevolverResetHaulback(owner)

	self.m_bFireOnEmpty = false

	-- set the shots fired to 0 after the player releases a button
	self:SetShotsFired(0)

	if CurTime() > self:GetNextPrimaryFire() and self:Clip1() == 0 and self:IsUseable() and not self:GetInReload() then
		-- Reload if current clip is empty and weapon has waited as long as it has to after firing
		self:Reload()
		return
	end

	self:UpdateIronSightController()
	if self:GetIronSightMode() == IronSight_viewmodel_is_deploying and self:GetActivity() ~= ACT_VM_DEPLOY then
		self:SetIronSightMode(IronSight_should_approach_unsighted)
	end

	self:WeaponIdle()
end

function SWEP:Think_ProcessPrimaryAttack(owner)
	if self:Clip1() == 0 or (self:GetMaxClip1() == -1 and self:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0) then
		self.m_bFireOnEmpty = true
	end

	-- freeze period return

	if owner:GetNWBool("m_bIsDefusing", false) then
		return
	end

	-- don't repeat fire if this is not a full auto weapon or its clip is empty
	if self:GetShotsFired() > 0 and (not self.Primary.Automatic or self:Clip1() == 0) then
		return
	end

	if self:GetIsRevolver() then -- holding primary, will fire when time is elapsed
		-- don't allow a rapid fire shot instantly in the middle of a haul back hold, let the hammer return first
		self:SetNextSecondaryFire(CurTime() + 0.25)

		if self:GetActivity() ~= ACT_VM_HAULBACK then
			self:ResetPostponeFireReadyTime()
			self:SetWeaponAnim(ACT_VM_HAULBACK)
			return
		end

		self:SetWeaponMode(Primary_Mode)

		if self:GetPostponeFireReadyTime() >= CurTime() then
			return
		end

		if self.m_bFireOnEmpty then
			self:ResetPostponeFireReadyTime()
			self:SetNextPrimaryFire(CurTime() + 0.5)
			self:SetNextSecondaryFire(self:GetNextPrimaryFire())
		end

		-- we're going to fire after this point
	end

	self:PrimaryAttack()
	self:SetLastShotTime(CurTime())

	if self:GetIsRevolver() then
		-- we just fired.
		-- there's a bit of a cool-off before you can alt-fire at normal alt-fire rate
		self:SetNextSecondaryFire(CurTime() + (self:GetCycleTime() * 1.7))
	end
end

function SWEP:Think_ProcessZoomAction(owner)
	if self:GetHasZoom() then
		self:CallSecondaryAttack()
		return true
	end

	return false
end

-- Common code put here to support separate zoom from silencer/burst
function SWEP:CallSecondaryAttack()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	if self:Clip2() ~= -1 and self:GetAmmoCount(self:GetSecondaryAmmoType()) ~= 0 then
		self.m_bFireOnEmpty = true
	end

	self:SecondaryAttack()
end

function SWEP:Think_ProcessSecondaryAttack(owner)
	if self:GetIsRevolver() then
		-- freeze period return

		if owner:GetNWBool("m_bIsDefusing", false) then
			return
		end

		if (self:Clip1() == 0 or (self:GetMaxClip1() == -1 and self:GetAmmoCount(self:GetPrimaryAmmoType()) == 0)) then
			self.m_bFireOnEmpty = true
		end

		self:SetWeaponMode(Secondary_Mode)

		if not self.m_bFireOnEmpty then
			self:ResetPostponeFireReadyTime()

			if self:GetActivity() == ACT_VM_HAULBACK then
				self:SetWeaponAnim(ACT_VM_IDLE)
				return false
			end

			if self:GetPostponeFireReadyTime() < CurTime() then
				return false
			end
		end

		if self:GetShotsFired() > 0 then -- revolver secondary isn't full-auto even though primary is
			return false -- shots fired is zeroed when the buttons release
		end

		if self.m_bFireOnEmpty then
			if self:GetActivity() ~= ACT_VM_HAULBACK then
				self:ResetPostponeFireReadyTime()
				self:SetWeaponAnim(ACT_VM_HAULBACK)
			end

			if self:GetPostponeFireReadyTime() >= CurTime() then
				return false
			end
		end
	end

	self:CallSecondaryAttack()
	return true
end

function SWEP:Think_ProcessReloadAction(owner)
	-- reload when reload is pressed, or if no buttons are down and weapon is empty.

	self:Think_RevolverResetHaulback()

	self:Reload()
end

function SWEP:OnFinishReload() end

function SWEP:InReloadThink() end

function SWEP:OnReloadFail()
	--self:StopLookingAtWeapon()
end

function SWEP:CanReload()
	if self:GetInReload() then return false end
	if self:Clip1() >= self:GetMaxClip1() then return false end
	if self:GetNextPrimaryFire() > CurTime() then return false end

	local owner = self:GetPlayerOwner()
	if not owner then return false end
	if self:GetAmmoCount(self:GetPrimaryAmmoType()) < 1 then return false end

	return true
end

function SWEP:Think()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local selfTable = self:GetTable()

	if selfTable.GetInReload(self) then
		if selfTable.GetFinishReloadTime(self) > CurTime() then
			selfTable.InReloadThink(self)
		else
			-- the AE_WPN_COMPLETE_RELOAD event should handle the stocking the clip, but in case it's missing, we can do it here as well
			local j = math.min(self:GetMaxClip1() - self:Clip1(), self:GetAmmoCount(self:GetPrimaryAmmoType()))

			-- Add them to the clip
			self:SetClip1(self:Clip1() + j)

			if SWCS_INDIVIDUAL_AMMO:GetBool() then
				selfTable.SetReserveAmmo(self, selfTable.GetReserveAmmo(self) - j)
			else
				owner:RemoveAmmo(j, self:GetPrimaryAmmoType())
			end

			selfTable.SetInReload(self, false)
			selfTable.OnFinishReload(self)
		end
	elseif selfTable.GetHasSilencer(self) then
		local flDoneSwitchTime = selfTable.GetDoneSwitchingSilencer(self)
		if flDoneSwitchTime > 0 and flDoneSwitchTime <= CurTime() then
			selfTable.SetDoneSwitchingSilencer(self, 0)

			if not selfTable.m_bFiredSilencerAnimEvent then
				if selfTable.GetSilencerOn(self) then
					selfTable.SetWeaponMode(self, Secondary_Mode)
					selfTable.SetSilencerOn(self, true)
					selfTable.SetWMBodyGroup(self, "silencer", SILENCER_VISIBLE)
				else
					selfTable.SetWeaponMode(self, Primary_Mode)
					selfTable.SetSilencerOn(self, false)
					selfTable.SetWMBodyGroup(self, "silencer", SILENCER_HIDDEN)
				end
			end
		end
	end

	--selfTable.ProcessActivities(self)
	selfTable.m_bProcessActivities = true

	selfTable.UpdateIronSightController(self)
	if selfTable.GetIronSightMode(self) == IronSight_viewmodel_is_deploying and self:GetActivity() ~= ACT_VM_DEPLOY then
		selfTable.SetIronSightMode(self, IronSight_should_approach_unsighted)
	end

	if CLIENT then
		selfTable.UpdateStatTrakGlow(self, selfTable)
	end

	selfTable.PostThink(self, selfTable)
end

SWEP.m_bProcessActivities = false
hook.Add("PlayerTick", "swcs.ProcessActivities", function(ply)
	if not IsValid(ply) then return end
	local wep = ply:GetActiveWeapon()

	local tbl = wep:GetTable()
	if not IsValid(wep) or not weapons.IsBasedOn(tbl.ClassName, "weapon_swcs_base") then return end

	if tbl.m_bProcessActivities then
		tbl.ProcessActivities(wep, tbl)
		tbl.m_bProcessActivities = false
	end
end)

function SWEP:ProcessActivities(tbl)
	local selfTable = tbl or self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	local cmd
	if g_bSinglePlayer then
		cmd = owner.m_LastUserCommand
	elseif owner == GetPredictionPlayer() then
		cmd = owner:GetCurrentCommand()

		owner.m_LastUserCommand = cmd
		owner.m_LastUserCommandNumber = cmd:CommandNumber()
	else
		cmd = owner.m_LastUserCommand
	end

	local buts = g_bSinglePlayer and owner:GetButtons() or (cmd and cmd:GetButtons() or owner:GetButtons())

	selfTable.m_bProcessingActivities = true

	local bInReload = selfTable.GetInReload(self)

	local bAllowZoom = owner:GetInfoNum("swcs_enable_zoom", 0) == 1
	local bContextualZoom = owner:GetInfoNum("swcs_contextual_zoom", 1) == 1
	local activity_buts = bit.bor(IN_ATTACK, IN_ATTACK2, IN_RELOAD)

	if bAllowZoom and bit.band(buts, IN_ZOOM) ~= 0 then
		buts = bit.band(buts, bit.bnot(IN_ATTACK))
		if not selfTable.GetHasZoom(self) then
			buts = bit.band(buts, bit.bnot(IN_ATTACK2))
		end
	end

	if not bInReload and bit.band(buts, IN_ATTACK) ~= 0 and self:GetNextPrimaryFire() <= CurTime() then
		selfTable.Think_ProcessPrimaryAttack(self, owner)
	elseif not bInReload and bit.band(buts, IN_ZOOM) ~= 0 and bContextualZoom and self:GetNextSecondaryFire() <= CurTime() and selfTable.Think_ProcessZoomAction(self, owner) then
		buts = bit.band(buts, bit.bnot(IN_ZOOM))
	elseif not bInReload and bit.band(buts, IN_ATTACK2) ~= 0 and self:GetNextSecondaryFire() <= CurTime() and selfTable.GetShotgunReloadState(self) == 0 then
		if selfTable.Think_ProcessSecondaryAttack(self, owner) then
			buts = bit.band(buts, bit.bnot(IN_ATTACK2))
		end
	elseif bit.band(buts, IN_RELOAD) ~= 0 and self:GetMaxClip1() ~= -1 and self:GetNextPrimaryFire() < CurTime() and selfTable.GetShotgunReloadState(self) == 0 then
		selfTable.Think_ProcessReloadAction(self, owner)
	elseif bit.band(buts, activity_buts) == 0 then
		selfTable.Think_ProcessIdleNoAction(self, owner)
	elseif bInReload then
		selfTable.Think_ProcessIdleNoAction(self, owner)
	end

	if selfTable.GetIsLookingAtWeapon(self) and selfTable.GetLookWeaponEndTime(self) <= CurTime() then
		selfTable.StopLookingAtWeapon(self)
	end

	if bit.band(owner:GetButtons(), activity_buts) ~= 0 then
		buts = bit.band(buts, bit.bnot(IN_ATTACK3))
		selfTable.StopLookingAtWeapon(self)
	end

	if bit.band(buts, IN_ATTACK3) ~= 0 then
		selfTable.m_bIsHoldingLookAtWeapon = true
		selfTable.TertiaryAttack(self)
	else
		selfTable.m_bIsHoldingLookAtWeapon = false
	end

	-- GOOSEMAN : Return zoom level back to previous zoom level before we fired a shot. This is used only for the AWP.
	if selfTable.GetResumeZoom(self) and self:GetNextPrimaryFire() <= CurTime()
		and selfTable.GetZoomLevel(self) > 0 then -- only need to re-zoom the zoom when there's a zoom to re-zoom to. who knew?
		if self:Clip1() ~= 0 then
			selfTable.SetWeaponMode(self, Secondary_Mode)
			owner:SetFOV(selfTable.GetZoomFOV(self, selfTable.GetZoomLevel(self)), 0.1)
		else
			selfTable.SetZoomLevel(self, 0)
			selfTable.SetWeaponMode(self, Primary_Mode)
		end

		selfTable.SetIsScoped(self, true)
		selfTable.SetResumeZoom(self, false)
	end

	if selfTable.GetHasBurstMode(self) and selfTable.GetBurstShotsRemaining(self) > 0 and selfTable.GetNextBurstShot(self) <= CurTime() then
		selfTable.BurstFireRemaining(self)
	end

	if selfTable.GetIsRevolver(self) and not bit.band(buts, bit.bor(IN_ATTACK, IN_ATTACK2, IN_ATTACK3, IN_RELOAD)) then -- not holding any weapon buttons
		selfTable.SetWeaponMode(self, Secondary_Mode)
		selfTable.ResetPostponeFireReadyTime(self)
		if self:GetActivity() == ACT_VM_HAULBACK then
			selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
		end
	end

	selfTable.m_bProcessingActivities = false
end

function SWEP:PostThink(selfTable)
	selfTable = selfTable or self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if owner and g_bSinglePlayer then
		local fov = owner:GetFOV()

		local iron = selfTable.GetIronSightController(self)
		if iron:IsValid() and iron.IsInitializedAndAvailable and iron:IsInitializedAndAvailable() then
			fov = iron:GetIronSightFOVValue(fov, false)
		end

		-- some weird math; to make sure viewmodels are where they're supposed to be regardless of FOV
		-- done using ironsight amount, because that's all where it's needed most
		local fDefaultFov = owner:GetDefaultFOV()
		local flFOVOffset = fDefaultFov - fov

		local fTargetFov = SERVER and 68 or swcs_viewmodel_fov:GetFloat()
		selfTable.ViewModelFOV = fTargetFov + flFOVOffset - ((fTargetFov - 10) * ((iron:IsValid() and iron.GetIronSightAmount and iron:GetIronSightAmount()) or 0))
	end
end

function SWEP:GetPlayerOwner()
	local owner = self:GetOwner()
	if not (owner:IsValid() and owner:IsPlayer()) then return false end

	return owner
end

local CS_COMMAND_MAX_RATE = 0.3
function SWEP:TertiaryAttack()
	if CurTime() - self:GetLastLookTime() < CS_COMMAND_MAX_RATE then
		return false
	end

	self:SetLastLookTime(CurTime())
	self:LookAtHeldWeapon()
end

function SWEP:StopLookingAtWeapon()
	self:SetIsLookingAtWeapon(false)
end

function SWEP:LookAtHeldWeapon()
	if self:GetIsLookingAtWeapon() then return end

	local nSequence = ACT_INVALID

	-- Can't taunt while zoomed, reloading, or switching silencer
	if self:IsZoomed() or self:GetInReload() or self:GetDoneSwitchingSilencer() >= CurTime() then return end

	-- don't let me inspect a shotgun that's reloading
	if self:GetWeaponType() == "shotgun" and self:GetShotgunReloadState() ~= 0 then return end

	if self:GetIronSightController():IsValid() and self:GetIronSightController():IsApproachingSighted() then return end

	local vm = self:GetOwner():GetViewModel()
	if vm:IsValid() then
		nSequence = vm:SelectWeightedSequence(ACT_VM_IDLE_LOWERED)

		if nSequence == nil or nSequence == ACT_INVALID then
			nSequence = vm:LookupSequence("lookat01")
		end

		if self:GetHasSilencer() then
			self:SetVMBodyGroup("silencer", self:GetSilencerOn() and 0 or 1)
		end

		if nSequence ~= nil and nSequence ~= ACT_INVALID then
			self:SetIsLookingAtWeapon(true)
			self:SetLookWeaponEndTime(CurTime() + vm:SequenceDuration(nSequence))

			self:SetWeaponSequence(nSequence)
		end
	end
end

function SWEP:BurstFireRemaining()
	local owner = self:GetPlayerOwner()
	if not owner or self:Clip1() <= 0 then
		self:SetClip1(0)
		self:SetBurstShotsRemaining(0)
		self:SetNextBurstShot(0)
		return
	end

	self:FX_FireBullets()
	self:DoFireEffects()

	self:SetWeaponAnim(self:PrimaryAttackAct())

	owner:SetAnimation(PLAYER_ATTACK1)

	self:SetBurstShotsRemaining(self:GetBurstShotsRemaining() - 1)

	if self:GetBurstShotsRemaining() > 0 then
		self:SetNextBurstShot(CurTime() + self:GetTimeBetweenBurstShots())
	else
		self:SetNextBurstShot(0)
	end

	self:OnPrimaryAttack()

	self:SetAccuracyPenalty(self:GetAccuracyPenalty(false) + self:GetInaccuracyFire())

	self:Recoil(self:GetWeaponMode())

	self:SetShotsFired(self:GetShotsFired() + 1)
	self:SetRecoilIndex(self:GetRecoilIndex() + 1)
	self:TakePrimaryAmmo(1)
end

function SWEP:AdjustMouseSensitivity()
	local owner = self:GetOwner()
	if not owner:IsValid() then return 1 end

	return math.tan(math.rad(owner:GetFOV()) / 2) / math.tan(math.rad(owner:GetDefaultFOV()) / 2)
end

-- calcview shit
do
	local viewmodel_offset_x = GetConVar"viewmodel_offset_x"
	local viewmodel_offset_y = GetConVar"viewmodel_offset_y"
	local viewmodel_offset_z = GetConVar"viewmodel_offset_z"

	local function SmoothCurve(x)
		return 1 - math.cos(x * math.pi) * 0.5
	end

	local swcs_gunlowerangle = CLIENT and CreateClientConVar("swcs_gunlowerangle", "2")
	local swcs_gunlowerspeed = CLIENT and CreateClientConVar("swcs_gunlowerspeed", "0.1")

	SWEP.m_vLoweredWeaponOffset = Vector()
	function SWEP:ApplyViewModelPitchAndDip(vecNewOrigin, vecNewAngles)
		local owner = self:GetPlayerOwner()
		if not owner then return end

		-- Check for lowering the weapon
		local bJumping = not owner:IsFlagSet(FL_ONGROUND)
		local bLowered = bJumping --pPlayer->IsWeaponLowered()

		local loweredAmount = swcs.Approach(bLowered and swcs_gunlowerangle and swcs_gunlowerangle:GetFloat() or 0, self.m_vLoweredWeaponOffset.x, swcs_gunlowerspeed and swcs_gunlowerspeed:GetFloat() or 0.1)
		self.m_vLoweredWeaponOffset.x = loweredAmount
		vecNewAngles.p = vecNewAngles.p - (loweredAmount * 0.2)
		vecNewOrigin.z = vecNewOrigin.z - (loweredAmount * 0.4) -- translation offset looks more natural than rotation
	end

	SWEP.m_angCamDriverLastAng = Angle()
	SWEP.m_vecCamDriverLastPos = Vector()
	SWEP.m_flCamDriverAppliedTime = 0
	function SWEP:PostBuildTransformations(vm)
		local iCamDriverBone = vm:LookupBone("cam_driver")
		if iCamDriverBone and iCamDriverBone ~= -1 then
			local mat = vm:GetBoneMatrix(iCamDriverBone)
			local bPos, bAng

			if mat then
				bPos = mat:GetTranslation()
				bAng = mat:GetAngles()
			else
				bPos = Vector()
				bAng = vm:GetLocalAngles()
			end

			bAng:Sub(vm:GetLocalAngles())
			bAng:Normalize()

			local selfTable = self:GetTable()
			selfTable.m_flCamDriverAppliedTime = CurTime()
			selfTable.m_vecCamDriverLastPos = bPos
			selfTable.m_angCamDriverLastAng = bAng
		end
	end

	local viewmodel_recoil = GetConVar"viewmodel_recoil"
	local view_recoil_tracking = GetConVar"view_recoil_tracking"
	function SWEP:CalcViewModelView(vm, _, _, pos, ang)
		if not IsValid(vm) then return end -- ????
		---@class Player
		local owner = vm:GetOwner()

		-- how
		if not owner:IsPlayer() then return pos, ang end

		local ret_pos, ret_ang = self:CalcView(owner, pos, ang, owner:GetFOV())
		local vForward, vUp, vRight = ret_ang:Forward(), ret_ang:Up(), ret_ang:Right()

		local iron = self:GetIronSightController()
		local pa = self:GetRawAimPunchAngle()
		pa:Mul(weapon_recoil_scale:GetFloat() * (1 - view_recoil_tracking:GetFloat()))

		if iron:IsValid() and iron.IsInIronSight and iron:IsInIronSight() then
			local flInvIronSightAmount = (1.0 - iron:GetIronSightAmount())

			vForward = vForward * flInvIronSightAmount
			vUp = vUp * flInvIronSightAmount
			vRight = vRight * flInvIronSightAmount

			pa:Normalize()
			pa:Mul(math.min(flInvIronSightAmount, view_recoil_tracking:GetFloat()))
		end

		-- custom viewmodel offset for players
		if CLIENT and not self.NoCustomViewmodelPos then
			ret_pos:Add(vForward * viewmodel_offset_y:GetFloat() + vUp * viewmodel_offset_z:GetFloat() + vRight * viewmodel_offset_x:GetFloat())
		end

		if CLIENT and (not iron:IsValid() or (iron:IsValid() and iron.IsInIronSight and not iron:IsInIronSight())) then
			self:AddViewModelBob(vm, ret_pos, ret_ang)
			self:ApplyViewModelPitchAndDip(ret_pos, ret_ang)
		end

		-- add aimpunch, viewpunch angles
		if CLIENT then
			pa:Mul(viewmodel_recoil:GetFloat())
		end

		if self.ViewModelFlip then
			pa.y = -pa.y
		end
		ret_ang:Add(pa)

		if iron:IsValid() and iron.ApplyIronSightPositioning then
			iron:ApplyIronSightPositioning(ret_pos, ret_ang)

			if iron:IsInIronSight() then
				vm:SetLocalPos(LerpVector(iron:GetIronSightAmountGained(), vm:GetLocalPos(), ret_pos))
				vm:SetLocalAngles(LerpAngle(iron:GetIronSightAmountGained(), vm:GetLocalAngles(), ret_ang))
			end
		end

		return ret_pos, ret_ang
	end

	-- Purpose: Allow the viewmodel to layer in artist-authored additive camera animation (to make some first-person anims 'punchier')
	local CAM_DRIVER_RETURN_TO_NORMAL = 0.25
	local CAM_DRIVER_RETURN_TO_NORMAL_GAIN = 0.8
	local cl_cam_driver_compensation_scale = GetConVar("cl_cam_driver_compensation_scale")

	SWEP.m_flCamDriverWeight = 0
	function SWEP:CalcAddViewmodelCameraAnimation(eyeOrigin, eyeAngles)
		if self.ViewModelFlip then return end

		local owner = self:GetPlayerOwner()
		if not owner then return end

		local vm = owner:GetViewModel(self:ViewModelIndex())
		if not vm:IsValid() then return end

		local flTimeDelta = math.Clamp(CurTime() - self.m_flCamDriverAppliedTime, 0, CAM_DRIVER_RETURN_TO_NORMAL)

		if flTimeDelta < CAM_DRIVER_RETURN_TO_NORMAL then
			self.m_flCamDriverWeight = math.Clamp(swcs.Gain(swcs.RemapClamped(flTimeDelta, 0, CAM_DRIVER_RETURN_TO_NORMAL, 1, 0), CAM_DRIVER_RETURN_TO_NORMAL_GAIN), 0, 1)

			--eyeOrigin:Add(self.m_vecCamDriverLastPos * self.m_flCamDriverWeight)
			eyeAngles:Add(self.m_angCamDriverLastAng * self.m_flCamDriverWeight * math.Clamp(cl_cam_driver_compensation_scale:GetFloat(), -10, 10))
		else
			self.m_flCamDriverWeight = 0
		end
	end

	-- hermite basis function for smooth interpolation
	-- Similar to Gain() above, but very cheap to call
	-- value should be between 0 & 1 inclusive
	local function SimpleSpline(value)
		local valueSquared = value * value

		-- Nice little ease-in, ease-out spline-like curve
		return 3 * valueSquared - 2 * valueSquared * value
	end

	local swcs_view_dip_anim = CLIENT and GetConVar("swcs_view_dip_anim")
	function SWEP:CalcViewBob(pos)
		if not CLIENT or not swcs_use_headbob or swcs_use_headbob:GetInt() < 2 then
			return
		end

		local owner = self:GetPlayerOwner()
		if not owner then return end

		local ownerTable = owner:GetTable()

		local baseEyePos = Vector(pos)

		if CLIENT and g_bSinglePlayer then
			ownerTable.m_flFallVelocity = -owner:GetVelocity().z
			ownerTable.m_flOldFallVelocity = ownerTable.m_flOldFallVelocity or 0

			if not ownerTable.m_bInLanding and swcs_view_dip_anim and swcs_view_dip_anim:GetBool() and
				owner:OnGround() and ownerTable.m_flFallVelocity <= 0.1 and
				ownerTable.m_flOldFallVelocity > 10.0 and ownerTable.m_flOldFallVelocity <= swcs.PLAYER_FATAL_FALL_SPEED
			then
				ownerTable.m_bInLanding = true
				ownerTable.m_flLandingTime = UnPredictedCurTime()
				ownerTable.m_flFallDipVelocity = ownerTable.m_flOldFallVelocity
			end
		end

		-- if we just landed, dip the player's view
		if ownerTable.m_bInLanding then
			local landseconds = math.max(UnPredictedCurTime() - ownerTable.m_flLandingTime, 0.0)
			local landFraction = math.Clamp(SimpleSpline(landseconds / 0.25), 0.0, 1.0)

			local flDipAmount = (1 / ownerTable.m_flFallDipVelocity) * 0.1

			local dipHighOffset = 64
			local dipLowOffset = math.floor(dipHighOffset - 4 --[[cl_headbob_land_dip_amt.GetInt()]])

			local temp = owner:GetViewOffset()
			temp.z = ((dipLowOffset - flDipAmount) * landFraction) + (dipHighOffset * (1 - landFraction))

			if temp.z > dipHighOffset then
				temp.z = dipHighOffset
				ownerTable.m_bInLanding = false
			end

			if ownerTable.m_bInLanding and landFraction <= 0 and landseconds > 0.5 then
				ownerTable.m_bInLanding = false
			end

			pos.z = pos.z - (dipHighOffset - temp.z)
		end

		-- stop when our eyes get back to default
		if ownerTable.m_bInLanding and --[[pos.z - baseEyePos.z < 0.001]] (pos.z - 0.001) >= baseEyePos.z then
			ownerTable.m_bInLanding = false
		end

		if not ownerTable.m_bInLanding then
			-- Set the old velocity to the new velocity, we check next frame to see if we hit the ground
			ownerTable.m_flOldFallVelocity = ownerTable.m_flFallVelocity
		end
	end

	function SWEP:CalcView(ply, pos, ang, fov)
		if CLIENT and ply:ShouldDrawLocalPlayer() then
			return pos, ang, fov
		end

		local vpang = self:GetViewPunchAngle()
		local apang = self:GetAimPunchAngle()

		self:CalcViewBob(pos)

		-- currently only used by the r8 revolver
		self:CalcAddViewmodelCameraAnimation(pos, ang)

		apang:Mul(view_recoil_tracking:GetFloat())
		ang:Add(apang)
		ang:Add(vpang)

		ang:Normalize()

		-- some weird math; to make sure viewmodels are where they're supposed to be regardless of FOV
		-- done using ironsight amount, because that's all where it's needed most

		local iron = self:GetIronSightController()
		if iron:IsValid() and iron.IsInitializedAndAvailable and iron:IsInitializedAndAvailable() then
			fov = iron:GetIronSightFOVValue(fov, false)
		end

		-- some weird math; to make sure viewmodels are where they're supposed to be regardless of FOV
		-- done using ironsight amount, because that's all where it's needed most
		local fDefaultFov = ply:GetDefaultFOV()
		local flIronsightAmount = iron:IsValid() and iron.GetIronSightAmount and iron:GetIronSightAmount() or 0
		local flFOVOffset = (fDefaultFov - fov) * flIronsightAmount

		local fTargetFov = SERVER and 68 or swcs_viewmodel_fov:GetFloat()
		self.ViewModelFOV = fTargetFov + flFOVOffset - ((fTargetFov - 10) * flIronsightAmount)

		return pos, ang, fov
	end

	local cl_bob_lower_amt = GetConVar"cl_bob_lower_amt"
	local cl_bobcycle = CLIENT and CreateConVar("cl_bobcycle", "0.98", FCVAR_ARCHIVE, "the frequency at which the viewmodel bobs.", 0.1, 2.0)
	local cl_viewmodel_shift_left_amt = CLIENT and CreateConVar("cl_viewmodel_shift_left_amt", "1.5", FCVAR_ARCHIVE, "The amount the viewmodel shifts to the left when shooting accuracy increases.", 0.5, 2.0)
	local cl_viewmodel_shift_right_amt = CLIENT and CreateConVar("cl_viewmodel_shift_right_amt", "0.75", FCVAR_ARCHIVE, "The amount the viewmodel shifts to the right when shooting accuracy increases.", 0.5, 2.0)
	local cl_bobup = CLIENT and CreateConVar("cl_bobup", "0.5")
	local cl_bobamt_vert = CLIENT and CreateConVar("cl_bobamt_vert", "0.25", FCVAR_ARCHIVE, "The amount the viewmodel moves up and down when running", 0.1, 2.0)
	local cl_bobamt_lat = CLIENT and CreateConVar("cl_bobamt_lat", "0.4", FCVAR_ARCHIVE, "The amount the viewmodel moves side to side when running", 0.1, 2.0)

	local g_lateralBob = 0
	local g_verticalBob = 0

	if CLIENT then
		cvars.AddChangeCallback("swcs_use_headbob", function(_, _, new)
			local val = tonumber(new)
			if not val then return end

			local SWEP = weapons.GetStored("weapon_swcs_base")
			if not SWEP then return end

			local newVal = (val == 0) and 1 or 0

			SWEP.BobScale = newVal

			for _, wep in ents.Iterator() do
				if wep:IsValid() and wep:IsWeapon() and weapons.IsBasedOn(wep:GetClass(), "weapon_swcs_base") then
					local wepTable = wep:GetTable()
					if wepTable.OldBobScale then
						wepTable.OldBobScale = newVal
					else
						wepTable.BobScale = newVal
					end
				end
			end
		end)
	end

	SWEP.m_flGunAccuracyPosition = 0
	local function CalcViewModelBobHelper(ply, wep, vm)
		if --[[FrameTime() <= 0 or]] not ply:IsValid() then return end

		local bPredicted = IsFirstTimePredicted() or g_bSinglePlayer

		local bobState = wep.m_bobState
		local cycle

		local speed = ply:GetAbsVelocity():Length2D()
		local curtime = CurTime()

		local flSpeedFactor = 0
		local flRunAddAmt = 0.0
		local flmaxSpeedDelta = math.max(0, (curtime - bobState.m_flLastBobTime) * 640.0)

		local flLastSpeed = bobState:GetLastSpeed()
		speed = math.Clamp(speed, flLastSpeed - flmaxSpeedDelta, flLastSpeed + flmaxSpeedDelta)
		speed = math.Clamp(speed, -320.0, 320.0)

		if bPredicted then
			bobState:SetLastSpeed(ply:GetAbsVelocity():Length2D())
		end

		local bShouldIgnoreOffsetAndAccuracy = false --(vm:IsValid() and vm.m_bShouldIgnoreOffsetAndAccuracy)

		if CLIENT and not wep:IsZoomed() then
			flSpeedFactor = speed * 0.006
			flSpeedFactor = math.Clamp(flSpeedFactor, 0.0, 0.5)

			local flLowerAmt = cl_bob_lower_amt:GetFloat() * 0.2

			if bShouldIgnoreOffsetAndAccuracy then
				flLowerAmt = flLowerAmt * 0.1
			end

			flRunAddAmt = (flLowerAmt * flSpeedFactor)
		end

		local bob_offset = swcs.RemapClamped(math.Clamp(speed, 0, 320), 0.0, 320.0, 0.0, 1.0)

		if bPredicted then
			bobState.m_flBobTime = bobState.m_flBobTime + ((curtime - bobState.m_flLastBobTime) * bob_offset)
			bobState.m_flLastBobTime = curtime
		end

		local flBobCycle = 0.5
		local flAccuracyDiff = 0
		local flGunAccPos = 0

		if ply:IsValid() and wep:IsValid() and wep.ItemAttributes then
			local flMaxSpeed = wep:GetMaxSpeed() or 250
			flBobCycle = (((1000 - flMaxSpeed) / 3.5) * 0.001) * (cl_bobcycle and cl_bobcycle:GetFloat() or 0.98)

			local flAccuracy = 0.0

			if not wep:GetInReload() and not wep.IsElites then
				local flCrouchAccuracy = wep:GetInaccuracyCrouch()
				local flBaseAccuracy = wep:GetInaccuracyStand()
				if ply:IsFlagSet(FL_DUCKING) then
					flAccuracy = flCrouchAccuracy
				else
					flAccuracy = wep:GetInaccuracy(false)
				end

				local bIsSniper = wep:GetWeaponType() == "sniperrifle"

				local flMultiplier = 1
				if (flAccuracy < flBaseAccuracy) then
					if (not bIsSniper) then
						flMultiplier = 18
					else
						flMultiplier = 0.15
					end

					flMultiplier = flMultiplier * (cl_viewmodel_shift_left_amt and cl_viewmodel_shift_left_amt:GetFloat() or 1.5)
				else
					flAccuracy = math.min(flAccuracy, 0.082)
					flMultiplier = flMultiplier * (cl_viewmodel_shift_right_amt and cl_viewmodel_shift_right_amt:GetFloat() or 0.75)
				end

				flAccuracyDiff = math.max((flAccuracy - flBaseAccuracy) * flMultiplier, -0.1)
			end

			wep.m_flGunAccuracyPosition = swcs.Approach(flAccuracyDiff * 80, wep.m_flGunAccuracyPosition, math.abs(((flAccuracyDiff * 80) - wep.m_flGunAccuracyPosition) * FrameTime()) * 4)

			if not wep:IsZoomed() then
				flGunAccPos = wep.m_flGunAccuracyPosition
			end
		else
			flBobCycle = (((1000.0 - 150) / 3.5) * 0.001) * (cl_bobcycle and cl_bobcycle:GetFloat() or 0.98)
		end

		cycle = bobState.m_flBobTime - math.floor(bobState.m_flBobTime / flBobCycle) * flBobCycle
		cycle = cycle / flBobCycle

		local bobup = cl_bobup:GetFloat()
		if (cycle < bobup) then
			cycle = math.pi * cycle / bobup
		else
			cycle = math.pi + math.pi * (cycle - bobup) / (1.0 - bobup)
		end

		local flBobMultiplier = 0.00625

		if not ply:IsFlagSet(FL_ONGROUND) then
			flBobMultiplier = 0.00125
		end

		if bPredicted then
			local flBobVert = bShouldIgnoreOffsetAndAccuracy and 0.3 or (cl_bobamt_vert and cl_bobamt_vert:GetFloat() or 0.25)
			bobState.m_flVerticalBob = speed * (flBobMultiplier * flBobVert)
			bobState.m_flVerticalBob = (bobState.m_flVerticalBob * 0.3 + bobState.m_flVerticalBob * 0.7 * math.sin(cycle))
			bobState:SetRawVerticalBob(bobState.m_flVerticalBob)

			bobState:SetVerticalBob(math.Clamp(bobState.m_flVerticalBob - (flRunAddAmt - (flGunAccPos * 0.2)), -7.0, 4.0))
		end

		cycle = bobState.m_flBobTime - math.floor(bobState.m_flBobTime / flBobCycle * 2) * flBobCycle * 2
		cycle = cycle / (flBobCycle * 2)

		if (cycle < bobup) then
			cycle = math.pi * cycle / bobup
		else
			cycle = math.pi + math.pi * (cycle - bobup) / (1.0 - bobup)
		end

		local flBobLat = bShouldIgnoreOffsetAndAccuracy and 0.5 or (cl_bobamt_lat and cl_bobamt_lat:GetFloat() or 0.4)
		if bPredicted and ply:IsValid() and wep:IsValid() then
			bobState.m_flLateralBob = speed * (flBobMultiplier * flBobLat)
			bobState.m_flLateralBob = bobState.m_flLateralBob * 0.3 + bobState.m_flLateralBob * 0.7 * math.sin(cycle)
			bobState:SetRawLateralBob(bobState.m_flLateralBob)

			bobState:SetLateralBob(math.Clamp(bobState.m_flLateralBob + flGunAccPos * 0.25, -8.0, 8.0))
		end
	end

	local function AddViewModelBobHelper(pos, ang, bobState)
		local vForward, vRight, vUp = ang:Forward(), ang:Right(), ang:Up()

		-- Apply bob, but scaled down to 40%
		VectorMA(pos, bobState:GetVerticalBob() * .4, vForward, pos)

		-- Z bob a bit more
		VectorMA(pos, bobState:GetVerticalBob() * .1, vUp, pos)

		-- bob the angles
		ang.r = ang.r + bobState:GetVerticalBob() * .5
		ang.p = ang.p - bobState:GetVerticalBob() * .4
		ang.y = ang.y - bobState:GetLateralBob() * .3

		VectorMA(pos, bobState:GetLateralBob() * 0.2, vRight, pos)
	end

	local bobtime = 0
	local lastbobtime = 0
	local lastspeed = 0
	local function CalcViewModelBob(self, vm)
		local owner = self:GetPlayerOwner()
		if not owner then return end

		CalcViewModelBobHelper(owner, self, vm)

		local iHeadbob = swcs_use_headbob and swcs_use_headbob:GetInt() or 2
		if iHeadbob == 2 or iHeadbob == 0 then return end

		if not owner or
			(cl_bobcycle and cl_bobcycle:GetFloat() or 0.98) <= 0.0 or
			cl_bobup:GetFloat() <= 0.0 or
			cl_bobup:GetFloat() >= 1.0
		then
			return
		end

		local cycle

		-- Find the speed of the player
		local speed = owner:GetAbsVelocity():Length2D()
		local flmaxSpeedDelta = math.max(0, (CurTime() - lastbobtime) * 320.0)

		-- don't allow too big speed changes
		speed = math.Clamp(speed, lastspeed - flmaxSpeedDelta, lastspeed + flmaxSpeedDelta)
		speed = math.Clamp(speed, -320, 320)

		lastspeed = speed

		local bob_offset = math.Remap(speed, 0, 320, 0.0, 1.0);

		bobtime = bobtime + ((CurTime() - lastbobtime) * bob_offset)
		lastbobtime = CurTime()

		local bobcycle = cl_bobcycle and cl_bobcycle:GetFloat() or 0.98

		-- Calculate the vertical bob
		cycle = bobtime - math.floor(bobtime / bobcycle) * bobcycle
		cycle = cycle / bobcycle

		local bobup = cl_bobup:GetFloat()
		if (cycle < bobup) then
			cycle = math.pi * cycle / bobup
		else
			cycle = math.pi + math.pi * (cycle - bobup) / (1.0 - bobup)
		end

		g_verticalBob = speed * 0.005
		g_verticalBob = g_verticalBob * 0.3 + g_verticalBob * 0.7 * math.sin(cycle)

		g_verticalBob = math.Clamp(g_verticalBob, -7.0, 4.0)

		-- Calculate the lateral bob
		cycle = bobtime - math.floor(bobtime / bobcycle * 2) * bobcycle * 2
		cycle = cycle / (bobcycle * 2)

		if (cycle < bobup) then
			cycle = math.pi * cycle / bobup
		else
			cycle = math.pi + math.pi * (cycle - bobup) / (1.0 - bobup)
		end

		g_lateralBob = speed * 0.005
		g_lateralBob = g_lateralBob * 0.3 + g_lateralBob * 0.7 * math.sin(cycle)
		g_lateralBob = math.Clamp(g_lateralBob, -7.0, 4.0)
	end

	function SWEP:AddViewModelBob(vm, pos, ang)
		local bobState = self.m_bobState
		if not bobState then
			bobState = {
				m_flBobTime = 0,
				m_flLastBobTime = 0,
				m_flLastSpeed = 0,
				m_flVerticalBob = 0,
				m_flLateralBob = 0,
				m_flRawVerticalBob = 0,
				m_flRawLateralBob = 0,
			}
			self.m_bobState = bobState

			swcs.DefineInterpolatedVar(bobState, "m_flLastSpeed", "LastSpeed", 0, false)
			swcs.DefineInterpolatedVar(bobState, "m_flVerticalBob", "VerticalBob", 0, false)
			swcs.DefineInterpolatedVar(bobState, "m_flLateralBob", "LateralBob", 0, false)
			swcs.DefineInterpolatedVar(bobState, "m_flRawVerticalBob", "RawVerticalBob", 0, false)
			swcs.DefineInterpolatedVar(bobState, "m_flRawLateralBob", "RawLateralBob", 0, false)
		end

		CalcViewModelBob(self, vm)

		local iHeadbob = swcs_use_headbob and swcs_use_headbob:GetInt() or 2
		if iHeadbob == 2 then
			AddViewModelBobHelper(pos, ang, bobState)
			return
		elseif iHeadbob == 0 then
			return
		end

		local forward = ang:Forward()

		-- Apply bob, but scaled down to 40%
		VectorMA(pos, g_verticalBob * 0.4, forward, pos)

		-- Z bob a bit more
		pos[2] = pos[2] + g_verticalBob * 0.1

		-- bob the angles
		ang.r = ang.r + g_verticalBob * 0.5
		ang.p = ang.p - g_verticalBob * 0.4
		ang.y = ang.y - g_lateralBob * 0.3
	end
end

function SWEP:GetReloadActivity()
	return self.m_iReloadActivityIndex or ACT_VM_RELOAD
end

function SWEP:GetReloadSequence()
	return -1
end

SWEP.VM_BodyGroups = {}
SWEP.WM_BodyGroups = {}
function SWEP:SetVMBodyGroup(bodygroup, p_value)
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local vm = owner:GetViewModel(self:ViewModelIndex())
	if not vm:IsValid() then return end

	local index, value = nil, tonumber(p_value)
	if string.find(bodygroup, " ") then
		value = bodygroup:match("%s(%d+)$")
		bodygroup = bodygroup:match("%b\"\""):sub(2, -2)
	end

	if not index then
		index = vm:FindBodygroupByName(bodygroup)
	end
	value = tonumber(value)

	if not (isnumber(index) and isnumber(value)) then return end

	self.VM_BodyGroups[index] = value
	if SERVER then
		--self:CallOnClient("SetVMBodyGroup", Format("\"%s\" %s", bodygroup, value))
		net.Start("swcs_CallOnClients")
		net.WriteEntity(self)
		net.WriteString("SetVMBodyGroup")
		net.WriteString(Format("\"%s\" %s", bodygroup, value))
		net.Broadcast()
	end
end

function SWEP:SetWMBodyGroup(bodygroup, p_value)
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local index, value = nil, tonumber(p_value)
	if string.find(bodygroup, " ") then
		value = bodygroup:match("%s(%d+)$")
		bodygroup = bodygroup:match("%b\"\""):sub(2, -2)
	end

	if not index then
		index = self:FindBodygroupByName(bodygroup)
	end
	value = tonumber(value)

	if not (isnumber(index) and isnumber(value)) then return end

	self.WM_BodyGroups[index] = value
	if SERVER then
		--self:CallOnClient("SetWMBodyGroup", Format("\"%s\" %s", bodygroup, p_value))
		net.Start("swcs_CallOnClients")
		net.WriteEntity(self)
		net.WriteString("SetWMBodyGroup")
		net.WriteString(Format("\"%s\" %s", bodygroup, value))
		net.Broadcast()
	end
end

local function ApplyIronSightScopeEffect(wep, x, y, w, h, bPreparationStage)
	local ply = wep:GetPlayerOwner()
	if not ply then return end

	local iron = wep:GetIronSightController()
	if not iron:IsValid() then return end

	if bPreparationStage then
		return iron:PrepareScopeEffect(x, y, w, h)
	else
		iron:RenderScopeEffect(x, y, w, h)
	end
end

if CLIENT then
	SWEP.m_viewmodelScopeStencilMask = NULL
end

local FLT_EPSILON = 1.19209290e-07

local BarrelHeat = CLIENT and CreateClientConVar("swcs_fx_weapon_barrel_heat", "0", true, false, "show barrel glowing red hot after sustained fire")
function SWEP:PreDrawViewModel(vm, _, owner)
	for id, val in next, self.VM_BodyGroups do
		vm:SetBodygroup(id, val)
	end

	local szHeatDriver = self.ItemVisuals and self.ItemVisuals.heat_param
	if isstring(szHeatDriver) and szHeatDriver ~= "" then
		if not self.m_viewmodelIMaterialHandle then
			self.m_viewmodelIMaterialHandle = Material(self:GetMaterials()[1])
		end

		local pMaterial = self.m_viewmodelIMaterialHandle
		if pMaterial:GetFloat(szHeatDriver) then
			local iMaxClip = self:GetMaxClip1()
			self.m_viewmodelHeat = Lerp(swcs.FrameTime(), self:GetRecoilIndex(), self.m_viewmodelHeat or 0)
			local flBlendFactor = (BarrelHeat and BarrelHeat:GetBool() or false) and math.Clamp(math.Remap(self.m_viewmodelHeat, iMaxClip * 0.33, iMaxClip * 0.95, 0, 1), FLT_EPSILON, 1) or 0
			pMaterial:SetFloat(szHeatDriver, flBlendFactor)
		end
	end

	self:ApplyWeaponSkin(vm, owner)

	-- try to render the scope lens mask stencil shape
	-- first create and bonemerge a new scope lens mask stencil shape if we don't have one
	local strMaskModel, pScopeStencilMask = (self.ItemAttributes and self:GetScopeLensMaskModel()), nil
	if not self.m_viewmodelScopeStencilMask:IsValid() and strMaskModel and strMaskModel ~= "" then
		pScopeStencilMask = ClientsideModel(strMaskModel)
		if pScopeStencilMask and pScopeStencilMask:IsValid() then
			self.m_viewmodelScopeStencilMask = pScopeStencilMask
			pScopeStencilMask:SetParent(vm)
			pScopeStencilMask:AddEffects(EF_BONEMERGE)
			pScopeStencilMask:AddEffects(EF_BONEMERGE_FASTCULL)
			pScopeStencilMask:AddEffects(EF_NODRAW)
			pScopeStencilMask:SetLocalPos(vector_origin)
		end
	elseif self.m_viewmodelScopeStencilMask:IsValid() then
		pScopeStencilMask = self.m_viewmodelScopeStencilMask

		-- fix missing stencils when grabbing props with +use
		if pScopeStencilMask:GetParent() ~= vm then
			pScopeStencilMask:SetParent(vm)
		end
	end

	return not self:ShouldDrawViewModel()
end

function SWEP:PostDrawViewModel(vm, _, owner)
	self:RemoveWeaponSkin(vm, owner)

	if ApplyIronSightScopeEffect(self, 0, 0, ScrW(), ScrH(), true) then
		-- now render the scope lens mask stencil shape if we have one
		if IsValid(self.m_viewmodelScopeStencilMask) then
			render.SetBlend(0)
			render.OverrideColorWriteEnable(false, true)
			render.OverrideDepthEnable(false, true)

			render.MaterialOverride(Material("dev/scope_mask"))

			local bViewmodelFlip = self.ViewModelFlip
			if bViewmodelFlip then
				render.CullMode(MATERIAL_CULLMODE_CW)
			end

			self.m_viewmodelScopeStencilMask:DrawModel()

			if bViewmodelFlip then
				render.CullMode(MATERIAL_CULLMODE_CCW)
			end

			render.MaterialOverride()
			render.SetBlend(1)
		end

		ApplyIronSightScopeEffect(self, 0, 0, ScrW(), ScrH(), false)
	end
end

function SWEP:DrawWorldModel(flags)
	for id, val in next, self.WM_BodyGroups do
		self:SetBodygroup(id, val)
	end

	self:DrawModel(flags)
end

SWEP.m_bFiredSilencerAnimEvent = false
local SWITCH_ANIMEVENT = {
	[AE_BEGIN_TAUNT_LOOP] = function(self, _, _, options)
		local owner = self:GetPlayerOwner()
		if not owner then return end

		local vm = owner:GetViewModel(self:ViewModelIndex())
		if not vm:IsValid() then return end

		options = tonumber(options)

		-- FIXME: when gmod lets me :SetCycle() on VMs, i will finish this
		-- homonovus, 08/12/2020

		-- pViewModel->ForceCycle( 0 );
		-- pViewModel->ResetSequence( nSequence );

		--[[print(self, "cycle", vm, options, vm:GetCycle(), self:GetLookWeaponEndTime())
		if self:GetIsLookingAtWeapon() and self.m_bIsHoldingLookAtWeapon then
			local seq = vm:GetSequence()
			local flSequenceDuration = vm:SequenceDuration(seq)

			local flPrevCycle = vm:GetCycle()
			self:SetWeaponAnim(ACT_VM_IDLE)
			--vm:SetCycle(options)
			--vm:ResetSequence(seq)
			--self:SendViewModelMatchingSequence(seq)
			--vm:SendViewModelMatchingSequence(seq)
			--self:SetWeaponSequence(seq)
			vm:SetCycle(options)
			local diff = (flPrevCycle - options) * flSequenceDuration

			self:SetLookWeaponEndTime(self:GetLookWeaponEndTime() + diff)
			self:SetWeaponIdleTime(self:GetLookWeaponEndTime())
		end
		print(self, "cycle", vm, options, vm:GetCycle(), self:GetLookWeaponEndTime())--]]
	end,
	[AE_CL_BODYGROUP_SET_VALUE] = function(self, _, _, options)
		options = options:Split" "
		local bodygroup = options[1]
		local value = tonumber(options[2])

		if not IsValid(self) then return end
		local owner = self:GetPlayerOwner()
		if not owner then return end

		self:SetVMBodyGroup(bodygroup, value)
	end,
	[AE_WPN_PRIMARYATTACK] = function(self, _, _, options)
		local time = tonumber(options)
		if time then
			self:SetPostponeFireReadyTime(CurTime() + time)

			-- send everyone else the "click" back noise
			-- except in eye observers
			self:EmitSound("Weapon_Revolver_CSGO.Prepare")
		end
	end,
	[AE_WPN_CZ_DUMP_CURRENT_MAG] = function(self)
		-- csgo used to empty the mag when you reloaded the cz??!?!
		-- self:SetClip1(0)
		self:SetVMBodyGroup("front_mag", 1)
		self:SetWMBodyGroup("front_mag", 1)

		local vm = self:GetOwner():GetViewModel(self:ViewModelIndex())
		-- if the front mag is removed, all subsequent anims use the non-front mag reload
		self.m_iReloadActivityIndex = vm:GetSequenceActivity(vm:LookupSequence("reload2"))

		-- lua: cz is the only thing that uses this, so i'm just gonna...
		-- as opposed to checking inside :Deploy() whether it has ammo or not
		self.m_bAlreadyReloaded = true
	end,
	[AE_CL_BODYGROUP_SET_TO_CLIP] = function(self)
		local owner = self:GetPlayerOwner()
		if not owner then return end

		local vm = owner:GetViewModel(self:ViewModelIndex())
		if not vm:IsValid() then return end

		for i = 0, vm:GetNumBodyGroups() - 1 do
			self:SetVMBodyGroup(vm:GetBodygroupName(i), (self:Clip1() < i) and 1 or 0)
		end
	end,
	[AE_CL_BODYGROUP_SET_TO_NEXTCLIP] = function(self)
		local owner = self:GetPlayerOwner()
		local vm = owner:GetViewModel(self:ViewModelIndex())

		local iNextClip = math.min(self:GetMaxClip1(), self:Clip1() + self:GetAmmoCount(self:GetPrimaryAmmoType()))
		for i = 0, vm:GetNumBodyGroups() - 1 do
			self:SetVMBodyGroup(vm:GetBodygroupName(i), (iNextClip >= i) and 0 or 1)
		end
	end,
	[AE_CL_HIDE_SILENCER] = function(self)
		self:SetVMBodyGroup("silencer", SILENCER_HIDDEN)
	end,
	[AE_CL_SHOW_SILENCER] = function(self)
		self:SetVMBodyGroup("silencer", SILENCER_VISIBLE)
	end,
	[AE_WPN_COMPLETE_RELOAD] = function(self)
		local owner = self:GetPlayerOwner()
		if not owner then return end

		self.m_bReloadVisuallyComplete = true
		local j = math.min(self:GetMaxClip1() - self:Clip1(), self:GetAmmoCount(self:GetPrimaryAmmoType()))

		self:SetClip1(self:Clip1() + j)

		if SWCS_INDIVIDUAL_AMMO:GetBool() then
			self:SetReserveAmmo(self:GetReserveAmmo() - j)
		else
			owner:RemoveAmmo(j, self:GetPrimaryAmmoType())
		end

		self:SetRecoilIndex(0)
	end,
	[AE_CL_DETACH_SILENCER_COMPLETE] = function(self)
		self.m_bFiredSilencerAnimEvent = true
		self:SetWeaponMode(Primary_Mode)
		self:SetSilencerOn(false)
		self:SetWMBodyGroup("silencer", SILENCER_HIDDEN)
	end,
	[AE_CL_ATTACH_SILENCER_COMPLETE] = function(self)
		self.m_bFiredSilencerAnimEvent = true
		self:SetWeaponMode(Secondary_Mode)
		self:SetSilencerOn(true)
		self:SetWMBodyGroup("silencer", SILENCER_VISIBLE)
	end,
	[AE_MUZZLEFLASH] = function(self, _, _, options)
		local selfTable = self:GetTable()
		local pPlayer = selfTable.GetPlayerOwner(self)

		if not pPlayer then
			return true
		end

		local vm = pPlayer:GetViewModel(self:ViewModelIndex())

		if selfTable.GetZoomLevels(self) > 1 and vm:GetCycle() > 0.1 and not selfTable.GetDoesUnzoomAfterShoot(self) then
			return true
		end

		-- return if scoped with sniper
		if pPlayer:GetFOV() ~= pPlayer:GetDefaultFOV() and selfTable.GetIsScoped(self) and selfTable.GetDoesHideViewModelWhenZoomed(self) then
			return true
		end

		local bLocalThirdPerson = ((pPlayer == LocalPlayer()) and pPlayer:ShouldDrawLocalPlayer());

		local origin = Vector()
		local iAttachmentIndex = selfTable.GetMuzzleAttachmentIndex_1stPerson(self, vm)
		local pszEffect = selfTable.GetMuzzleFlashEffect1stPerson(self)

		if pszEffect and #pszEffect > 0 and iAttachmentIndex >= 0 then
			if not bLocalThirdPerson then
				ParticleEffectAttach(pszEffect, PATTACH_POINT_FOLLOW, vm, iAttachmentIndex)
			end

			local shouldEmitLight = not selfTable.GetHasSilencer(self) or (selfTable.InvertMuzzleEffects and selfTable.GetSilencerOn(self) or false)
			if shouldEmitLight then
				origin:Set(pPlayer:EyePos())

				local vAngles = EyeAngles()
				local vForward, vRight = vAngles:Forward(), vAngles:Right()

				origin:Add(vRight * (selfTable.ViewModelFlip and -4 or 4))
				origin:Add(vForward * 31)
				origin.z = origin.z + 3.0

				local light = DynamicLight(vm:EntIndex())
				light.pos = origin
				light.r = 255
				light.g = 186
				light.b = 64
				light.brightness = 5
				light.size = 70
				light.dietime = CurTime() + 0.05
				light.decay = 768
			end

			selfTable.UpdateGunHeat(self, selfTable.GetHeatPerShot(self), iAttachmentIndex)
		end

		return true
	end,
	[AE_CLIENT_EJECT_BRASS] = function(self, _, _, options)
		local pPlayer = self:GetPlayerOwner()
		if not pPlayer then
			return
		end

		--if( pPlayer && pPlayer->GetFOV() != pPlayer->GetDefaultFOV() && pPlayer->m_bIsScoped && DoesHideViewModelWhenZoomed() )
		--  return true;

		local pszEffect = self:GetEjectBrassEffectName()
		local iAttachmentIndex = -1

		local vm = pPlayer:GetViewModel(self:ViewModelIndex())

		if self:GetZoomLevels() > 1 and vm:GetCycle() > 0.1 and not self:GetDoesUnzoomAfterShoot() then
			return true
		end

		-- If options is non-zero in length, treat as an attachment name to use for this particle effect.
		if options and #options > 0 then
			iAttachmentIndex = vm:LookupAttachment(tonumber(options))
		else
			iAttachmentIndex = self:GetEjectBrassAttachmentIndex_1stPerson(vm)
		end

		if pszEffect and #pszEffect > 0 and iAttachmentIndex >= 0 then
			local bLocalThirdPerson = pPlayer == LocalPlayer() and pPlayer:ShouldDrawLocalPlayer()

			-- The view model fixes up the split screen visibility of any effects spawned off of it.
			if not bLocalThirdPerson then
				ParticleEffectAttach(pszEffect, PATTACH_POINT_FOLLOW, vm, iAttachmentIndex)
			end
		end

		return true
	end,
	[AE_CL_SET_STATTRAK_GLOW] = function(self, _, _, options)
		self:SetStatTrakGlowMultiplier(tonumber(options))
	end,
	[AE_WPN_CLIP_TO_POSEPARAM] = function(self, _, _, param)
		local owner = self:GetPlayerOwner()
		if not owner then return end

		local vm = owner:GetViewModel()
		if not vm:IsValid() then return end

		vm:SetPoseParameter(param, 1 - (self:Clip1() / self:GetMaxClip1()))
	end,
	[AE_WPN_NEXTCLIP_TO_POSEPARAM] = function(self, _, _, param)
		local owner = self:GetPlayerOwner()
		if not owner then return end

		local vm = owner:GetViewModel(self:ViewModelIndex())
		if not vm:IsValid() then return end

		local iNextClip = math.min(self:GetMaxClip1(), self:Clip1() + self:GetAmmoCount(self:GetPrimaryAmmoType()))
		vm:SetPoseParameter(param, 1 - (iNextClip / self:GetMaxClip1()))
	end,
	[AE_WPN_HEALTHSHOT_INJECT] = function(self, _, __, param)
		self:OnVisualUse()
	end,
}

function SWEP:FireAnimationEvent(pos, ang, event, options, src_ent)
	if SWCS_DEBUG_AE:GetBool() then
		print("csgo AE", self, event, options, src_ent, IsFirstTimePredicted())
	end

	if SWITCH_ANIMEVENT[event] then
		local fn = SWITCH_ANIMEVENT[event]
		---@diagnostic disable-next-line: redundant-parameter
		local ret = fn(self, pos, ang, options, src_ent)

		if ret ~= nil then
			return ret
		end
	end
end

function SWEP:TakePrimaryAmmo(num)
	--if not SWCS_INDIVIDUAL_AMMO:GetBool() then
	--	return BaseClass.TakePrimaryAmmo(self, num)
	--end

	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	if self:Clip1() <= 0 then
		if self:GetAmmoCount(self:GetPrimaryAmmoType()) <= 0 then return end

		if SWCS_INDIVIDUAL_AMMO:GetBool() then
			self:SetReserveAmmo(math.max(self:GetReserveAmmo() - num, 0))
		else
			owner:RemoveAmmo(num, self:GetPrimaryAmmoType())
		end

		return
	end

	self:SetClip1(self:Clip1() - num)
end

function SWEP:CustomAmmoDisplay()
	local iClip1 = self:Clip1()
	if iClip1 < 0 then return end

	local iReserveAmmo = -1

	if SWCS_INDIVIDUAL_AMMO:GetBool() then
		if self:GetReserveAmmo() ~= -1 then
			iReserveAmmo = self:GetReserveAmmo()
		end
	else
		return
		--local owner = self:GetPlayerOwner()
		--if owner then
		--	iReserveAmmo = owner:GetAmmoCount(self:GetPrimaryAmmoType())
		--end
	end

	return {
		Draw = true,
		PrimaryClip = iClip1,
		PrimaryAmmo = iReserveAmmo,
	}
end

function SWEP:GetAmmoCount(type)
	if SWCS_INDIVIDUAL_AMMO:GetBool() then
		return self:GetReserveAmmo()
	end

	local owner = self:GetPlayerOwner()
	if not owner then return 0 end

	return owner:GetAmmoCount(type)
end

-- sandbox lets ppl deploy weps at 4x speed
-- sometimes servers will lower this
local swcs_crosshairstyle = GetConVar"swcs_crosshairstyle"
function SWEP:Deploy()
	local selfTable = self:GetTable()

	local owner = selfTable.GetPlayerOwner(self)
	if not owner then return end

	self:SetHoldType(selfTable.HoldType)
	selfTable.UpdateDeploySpeed(self)
	selfTable.NetworkPlayerEconData(self, owner)

	selfTable.SetIronSightMode(self, IronSight_viewmodel_is_deploying)

	local iron = selfTable.GetIronSightController(self)
	if iron:IsValid() then
		iron:SetState(IronSight_viewmodel_is_deploying)
	end

	local crosshairStyle = CLIENT and swcs_crosshairstyle:GetInt() or 0
	if CLIENT and (crosshairStyle == 4 or crosshairStyle == 5) then
		selfTable.m_flCrosshairDistance = 1
	end

	owner:SetSaveValue("m_flNextAttack", SERVER and 0 or CurTime())

	selfTable.SetShotsFired(self, 0)
	selfTable.SetRecoilIndex(self, 0)
	selfTable.SetAccuracyPenalty(self, 0)

	if selfTable.GetHasZoom(self) then
		selfTable.SetIsScoped(self, false)
		selfTable.SetZoomLevel(self, 0)
		selfTable.SetWeaponMode(self, Primary_Mode)
	end

	if owner:GetFOV() ~= owner:GetDefaultFOV() then
		owner:SetFOV(0, 0.01)
	end

	if selfTable.GetSilencerOn(self) then
		selfTable.SetWeaponAnim(self, ACT_VM_DRAW_SILENCED, self:GetDeploySpeed())
	elseif selfTable.m_bAlreadyReloaded then -- cz alt draw anim; i do it like this instead of checking if they have any reserve ammo
		local seq = self:LookupSequence("draw2")
		local act

		if seq then
			act = self:GetSequenceActivity(seq)
			selfTable.SetWeaponAnim(self, act, self:GetDeploySpeed())
		end

		selfTable.SetVMBodyGroup(self, "front_mag", 1)
	end

	local vm = owner:GetViewModel(self:ViewModelIndex())
	if vm:IsValid() then
		vm:SetPlaybackRate(self:GetDeploySpeed())
		selfTable.SetWeaponIdleTime(self, CurTime() + (self:SequenceDuration() * (1 / self:GetDeploySpeed())))

		local oPrim = self:GetNextPrimaryFire()
		local oSec = self:GetNextSecondaryFire()
		self:SetNextPrimaryFire(oPrim < self:GetWeaponIdleTime() and self:GetWeaponIdleTime() or oPrim)
		self:SetNextSecondaryFire(oSec < self:GetWeaponIdleTime() and self:GetWeaponIdleTime() or oSec)
	end

	if selfTable.GetIsRevolver(self) then
		selfTable.SetWeaponMode(self, Secondary_Mode)
	end

	return true
end

function SWEP:CalculateNextAttackTime(fCycleTime)
	local fCurAttack = self:GetNextPrimaryFire()
	local curtime = CurTime()
	local fDeltaAttack = curtime - fCurAttack
	if fDeltaAttack < 0 or fDeltaAttack > engine.TickInterval() then
		fCurAttack = curtime
	end
	self:SetNextPrimaryFire(fCurAttack + fCycleTime)
	self:SetNextSecondaryFire(fCurAttack + fCycleTime)

	return fCurAttack
end

function SWEP:IsPistol()
	return self:GetWeaponType() == "pistol"
end

function SWEP:PlayEmptySound()
	if self:IsPistol() then
		self:EmitSound("Default.ClipEmpty_Pistol")
	else
		self:EmitSound("Default.ClipEmpty_Rifle")
	end
end

function SWEP:PrimaryAttackAct()
	return ACT_VM_PRIMARYATTACK
end

function SWEP:GetFinalAimAngle()
	local owner = self:GetOwner()
	if not owner:IsValid() then return Angle(0, 0, 0) end

	local angShooting = owner:GetAimVector():Angle() + self:GetUninterpolatedAimPunchAngle()
	angShooting:Normalize()

	return angShooting
end

local UnlimitedRange = GetConVar("swcs_weapon_unlimited_range")
function SWEP:GetRange()
	if UnlimitedRange:GetBool() then
		return 0x7ffe
	end

	return self:GetAttributeRange()
end

local MaxPitchShiftInaccuracy = 0.05
local weapon_near_empty_sound = GetConVar"weapon_near_empty_sound"

function SWEP:FX_FireBullets()
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	local bIsPlayer = owner:IsPlayer()

	local fInaccuracy = self:GetInaccuracy(false)
	local soundToPlay = self:GetHasSilencer() and self:GetSilencerOn() and self.SND_SPECIAL1 or self.SND_SINGLE

	local flPitchShift = self:GetInaccuracyPitchShift() * (fInaccuracy < MaxPitchShiftInaccuracy and fInaccuracy or MaxPitchShiftInaccuracy)
	if soundToPlay == self.SND_SINGLE and self:GetInaccuracyAltSoundThreshold() > 0 and fInaccuracy < self:GetInaccuracyAltSoundThreshold() then
		soundToPlay = self.SND_SINGLE_ACCURATE
		flPitchShift = 0
	end

	if SERVER and g_bSinglePlayer and bIsPlayer then
		self:CallOnClient("FX_FireBullets", "")
	end

	if IsFirstTimePredicted() then
		self:EmitSound(soundToPlay, nil, 100 + math.floor(flPitchShift))
	end

	-- If the gun's nearly empty, also play a subtle "nearly-empty" sound, since the weapon
	-- is lighter and acoustically different when weighed down by fewer bullets.
	-- But really it's so you get a fun low ammo warning from an audio cue.
	if weapon_near_empty_sound:GetBool() and
		self:GetMaxClip1() > 1 and -- not a single-shot weapon
		(self:Clip1() / self:GetMaxClip1()) <= 0.2 -- 20% or fewer bullets remaining
	then
		self:EmitSound(self.SND_NEARLY_EMPTY or "Default.nearlyempty")
	end

	local angShooting = self:GetFinalAimAngle()
	local vecDirShooting = angShooting:Forward()

	-- fire bullets individually to avoid getting shotguns clipped to bbox
	if bIsPlayer then
		owner:LagCompensation(true)
	end

	swcs.FireBullets(self, {
		Src = owner.m_vSavedShootPos or owner:GetShootPos(), -- done to fix gmod's shoot pos being behind 1 tick on client
		Dir = vecDirShooting,
		Num = self:GetBullets(),
		AmmoType = self.Primary.Ammo,
		Tracer = self:GetTracerFrequency(),
		--TracerName = isstring(self.ItemVisuals.tracer_effect) and #self.ItemVisuals.tracer_effect > 0 and self.ItemVisuals.tracer_effect,
		Attacker = owner,
		Distance = self:GetRange(),
		Spread = vector_origin,
		Damage = self:GetDamage(),
	})

	if bIsPlayer then
		owner:LagCompensation(false)
	end
end

-- head = 4x; chest & arms = 1x; stomach = 1.25x; legs = .75x
local SWCS_HITGROUP_HEAD = CreateConVar("swcs_damage_scale_hitgroup_head", "4", FCVAR_REPLICATED, "damage to scale damage to head hitgroup by (before swcs_damage_scale)", 1)
local SWCS_HITGROUP_STOMACH = CreateConVar("swcs_damage_scale_hitgroup_stomach", "1.25", FCVAR_REPLICATED, "damage to scale damage to stomach hitgroup by (before swcs_damage_scale)", 1)
local SWCS_HITGROUP_BODY = CreateConVar("swcs_damage_scale_hitgroup_body", "1", FCVAR_REPLICATED, "damage to scale damage to body hitgroups by (before swcs_damage_scale)", 1)
local SWCS_HITGROUP_LEGS = CreateConVar("swcs_damage_scale_hitgroup_legs", "1", FCVAR_REPLICATED, "damage to scale damage to leg hitgroups by (before swcs_damage_scale)", 1)
local HITGROUP_DAMAGE_SCALE = {
	[HITGROUP_HEAD] = SWCS_HITGROUP_HEAD,
	[HITGROUP_STOMACH] = SWCS_HITGROUP_STOMACH,
	[HITGROUP_CHEST] = SWCS_HITGROUP_BODY,
	[HITGROUP_LEFTARM] = SWCS_HITGROUP_BODY,
	[HITGROUP_RIGHTARM] = SWCS_HITGROUP_BODY,
	[HITGROUP_LEFTLEG] = SWCS_HITGROUP_LEGS,
	[HITGROUP_RIGHTLEG] = SWCS_HITGROUP_LEGS,
}
local DAMAGE_SCALE = GetConVar("swcs_damage_scale")
local DAMAGE_SCALE_HEAD = GetConVar("swcs_damage_scale_head")
function SWEP:ApplyDamageScale(dmgInfo, iHitGroup, flBaseDamage)
	dmgInfo:SetDamage(flBaseDamage)

	-- adjust damage values so that when gamemode scales the damage, it calculates to the correct value
	if swcs.InSandbox then
		if iHitGroup == HITGROUP_HEAD then
			dmgInfo:ScaleDamage(0.5)
		elseif iHitGroup == HITGROUP_LEFTARM or iHitGroup == HITGROUP_RIGHTARM or iHitGroup == HITGROUP_LEFTLEG or iHitGroup == HITGROUP_RIGHTLEG then
			dmgInfo:ScaleDamage(4)
		end
	end

	-- rescale damage bc gmod has its own scalar
	-- we are trying to recreate csgo weps and how ppl expect them to be :)
	if HITGROUP_DAMAGE_SCALE[iHitGroup] then
		local scaled = iHitGroup == HITGROUP_HEAD and DAMAGE_SCALE_HEAD:GetFloat() or DAMAGE_SCALE:GetFloat()
		dmgInfo:ScaleDamage(HITGROUP_DAMAGE_SCALE[iHitGroup]:GetFloat() * scaled)
	end
end

local ironsight_rand = UniformRandomStream()

function SWEP:CSBaseGunFire(flCycleTime, weaponMode)
	local owner = self:GetOwner()
	if not owner:IsValid() then
		return false
	end

	if self:Clip1() <= 0 then
		self:PlayEmptySound()
		self:SetNextPrimaryFire(CurTime() + .2)

		if self:GetIsRevolver() then
			self:SetNextPrimaryFire(CurTime() + self:GetCycleTime())
			self:SetNextSecondaryFire(self:GetNextPrimaryFire())
			self:SetWeaponAnim(ACT_VM_DRYFIRE)
		end

		return false
	end

	if (self:GetWeaponType() ~= "sniperrifle" and self:IsZoomed()) or (self:GetIsRevolver() and weaponMode == Secondary_Mode) then
		self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)
	else
		self:SetWeaponAnim(self:PrimaryAttackAct())
	end

	self:DoPlayerAttackAnimation(owner)

	self:FX_FireBullets()
	self:DoFireEffects()

	if --[[IsFirstTimePredicted() and]] self:GetIronSightController():IsValid() then
		ironsight_rand:SetSeed(self:GetSharedSeed())
		self:GetIronSightController():IncreaseDotBlur(ironsight_rand:RandomFloat(.22, .28))
	end

	self:SetWeaponIdleTime(CurTime() + self:GetTimeToIdleAfterFire())

	self:OnPrimaryAttack()

	self:SetAccuracyPenalty(self:GetAccuracyPenalty(false) + self:GetInaccuracyFire())

	self:Recoil(self:GetWeaponMode())

	self:SetShotsFired(self:GetShotsFired() + 1)
	self:SetRecoilIndex(self:GetRecoilIndex() + 1)
	self:TakePrimaryAmmo(1)

	self:CalculateNextAttackTime(flCycleTime)

	return true
end

function SWEP:DoPlayerAttackAnimation(owner)
	owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:OnPrimaryAttack() end

function SWEP:ResetPostponeFireReadyTime()
	self:SetPostponeFireReadyTime(math.huge)
end

function SWEP:PrimaryAttack()
	local owner = self:GetOwner()

	if not owner:IsValid() then return end

	local selfTable = self:GetTable()

	if owner:IsPlayer() and not selfTable.m_bProcessingActivities then return end

	-- cant shoot underwater thing

	local flCycleTime = selfTable.GetCycleTime(self)

	if owner:IsNPC() then
		if self:Clip1() == 0 and self:GetMaxClip1() ~= -1 then
			owner:SetCondition(COND.NO_PRIMARY_AMMO)
		end
		if selfTable.GetWeaponType(self) == "sniperrifle" then
			flCycleTime = flCycleTime * 2
		end
	end

	-- change a few things if we're in burst mode
	local cycleTimeInMode = 0
	if selfTable.GetBurstMode(self) then
		cycleTimeInMode = selfTable.GetCycleTimeInBurstMode(self)
		if cycleTimeInMode > 0 then
			flCycleTime = cycleTimeInMode
		end

		selfTable.SetBurstShotsRemaining(selfTable, 2)
		selfTable.SetNextBurstShot(selfTable, CurTime() + selfTable.GetTimeBetweenBurstShots(selfTable))
	elseif selfTable.IsZoomed(self) then
		cycleTimeInMode = selfTable.GetCycleTimeInZoom(self)
		if cycleTimeInMode > 0 then
			flCycleTime = cycleTimeInMode
		end
	end

	if not selfTable.CSBaseGunFire(self, flCycleTime, selfTable.GetWeaponMode(self)) then
		return
	end

	if selfTable.GetSilencerOn(self) then
		selfTable.SetWeaponAnim(self, ACT_VM_SECONDARYATTACK)
	end

	if selfTable.IsZoomed(self) and selfTable.GetDoesUnzoomAfterShoot(self) then
		selfTable.SetIsScoped(self, false)
		selfTable.SetResumeZoom(self, true)
		owner:SetFOV(0, 0.05)
		selfTable.SetWeaponMode(self, Primary_Mode)
	end
end

function SWEP:IsZoomed()
	return self:GetZoomLevel() > 0
end

function SWEP:GetZoomFOV(iZoomLevel)
	if iZoomLevel == 0 then
		return 0 -- not used, always return default FOV
	elseif iZoomLevel == 1 then
		return self:GetZoomFOV1()
	elseif iZoomLevel == 2 then
		return self:GetZoomFOV2()
	else
		return 0
	end
end

function SWEP:GetZoomTime(iZoomLevel)
	if iZoomLevel == 0 then
		return self:GetZoomTime0()
	elseif iZoomLevel == 1 then
		return self:GetZoomTime1()
	elseif iZoomLevel == 2 then
		return self:GetZoomTime2()
	else
		return 0
	end
end

function SWEP:SecondaryAttack()
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	local selfTable = self:GetTable()
	if owner:IsPlayer() and not selfTable.m_bProcessingActivities then return end

	if self:GetNextPrimaryFire() >= CurTime() then return end
	if self:GetNextSecondaryFire() >= CurTime() then return end

	if selfTable.GetHasZoom(self) then
		local iZoomLevel = selfTable.GetZoomLevel(self) + 1
		if iZoomLevel > selfTable.GetZoomLevels(self) then
			iZoomLevel = 0
		elseif iZoomLevel == 1 and SERVER and owner:IsPlayer() and owner:GetFOV() ~= owner:GetDefaultFOV() then
			owner:StopZooming()
		end
		selfTable.SetZoomLevel(self, iZoomLevel)

		local iron = selfTable.GetIronSightController(self)

		if selfTable.IsZoomed(self) then
			self:EmitSound(selfTable.GetZoomInSound(self))

			selfTable.SetIsScoped(self, true)
			selfTable.SetWeaponMode(self, Secondary_Mode)
			selfTable.SetAccuracyPenalty(self, selfTable.GetAccuracyPenalty(self, false) + selfTable.GetInaccuracyAltSwitch(self))

			selfTable.UpdateIronSightController(self)
			if iron:IsValid() and iron:IsInitializedAndAvailable() then
				owner:SetFOV(iron:GetIronSightFOV(), iron:GetIronSightPullUpDuration())
				iron:SetState(IronSight_should_approach_sighted)

				selfTable.StopLookingAtWeapon(self)

				-- force idle
				selfTable.SetWeaponAnim(self, ACT_VM_IDLE)
			else
				owner:SetFOV(selfTable.GetZoomFOV(self, iZoomLevel), selfTable.GetZoomTime(self, iZoomLevel))
			end
		else
			self:EmitSound(selfTable.GetZoomOutSound(self))

			selfTable.SetIsScoped(self, false)
			selfTable.SetWeaponMode(self, Primary_Mode)
			owner:SetFOV(0, selfTable.GetZoomTime(self, 0))
			selfTable.SetWeaponAnim(self, ACT_VM_FIDGET)

			if iron:IsValid() then
				iron:SetState(IronSight_should_approach_unsighted)
			end
		end
	elseif selfTable.GetHasSilencer(self) and not selfTable.HasBuiltInSilencer(self) and selfTable.GetDoneSwitchingSilencer(self) <= CurTime() then
		owner:DoCustomAnimEvent(PLAYERANIMEVENT_ATTACK_SECONDARY, 0)

		if selfTable.GetSilencerOn(self) then
			selfTable.SetWeaponAnim(self, ACT_VM_DETACH_SILENCER)
		else
			selfTable.SetWeaponAnim(self, ACT_VM_ATTACH_SILENCER)
		end

		local nextAttackTime = CurTime() + self:SequenceDuration()
		selfTable.m_bFiredSilencerAnimEvent = false
		selfTable.SetDoneSwitchingSilencer(self, nextAttackTime)
		self:SetNextPrimaryFire(nextAttackTime)
		self:SetNextSecondaryFire(nextAttackTime)
	elseif selfTable.GetHasBurstMode(self) then
		if selfTable.GetBurstMode(self) then
			owner:PrintMessage(HUD_PRINTCENTER, "#swcs.switched_to_auto")
			selfTable.SetBurstMode(self, false)
			selfTable.SetWeaponMode(self, Primary_Mode)
		else
			owner:PrintMessage(HUD_PRINTCENTER, "#swcs.switched_to_burst")
			selfTable.SetBurstMode(self, true)
			selfTable.SetWeaponMode(self, Secondary_Mode)
		end

		self:EmitSound("Weapon.AutoSemiAutoSwitch")
	elseif selfTable.GetIsRevolver(self) and self:GetNextSecondaryFire() < CurTime() then
		local flCycletimeAlt = selfTable.GetCycleTime(self)
		selfTable.SetWeaponMode(self, Secondary_Mode)
		selfTable.UpdateAccuracyPenalty(self)

		selfTable.CSBaseGunFire(self, flCycletimeAlt, Secondary_Mode)
		self:SetNextSecondaryFire(CurTime() + flCycletimeAlt)
		return
	end

	self:SetNextSecondaryFire(CurTime() + 0.3)
end

hook.Add("DoAnimationEvent", "swcs.silencer", function(ply, event, data)
	local wep = ply:GetActiveWeapon()

	if event == PLAYERANIMEVENT_ATTACK_SECONDARY and wep:IsValid() and wep.IsSWCSWeapon then
		ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD, ply:LookupSequence("gesture_item_place"), 0, true)
		return ACT_INVALID
	end
end)

function SWEP:OnStartReload()
	local owner = self:GetPlayerOwner()
	if not owner or not owner:IsValid() then return end

	if self:GetZoomLevel() > 0 and self:GetIsScoped() then
		owner:SetFOV(0, self:GetZoomTime(0))
		self:SetIsScoped(false)
	end

	if self:GetHasZoom() then
		self:SetZoomLevel(0)
		self:SetResumeZoom(false)
		self:SetWeaponMode(Primary_Mode)
	end

	self.m_bReloadVisuallyComplete = false
	self:SetIronSightMode(IronSight_should_approach_unsighted)

	self:SetShotsFired(0)
	self:SetRecoilIndex(self:GetRecoilIndex() + 1)
end

function SWEP:Holster(nextWep)
	local selfTable = self:GetTable()
	local owner = selfTable.GetPlayerOwner(self)

	-- silencer stuff here
	if (self:GetActivity() == ACT_VM_ATTACH_SILENCER and not selfTable.GetSilencerOn(self)) or
		(self:GetActivity() == ACT_VM_DETACH_SILENCER and selfTable.GetSilencerOn(self))
	then
		selfTable.SetDoneSwitchingSilencer(self, 0)
		self:SetNextPrimaryFire(CurTime())
		self:SetNextSecondaryFire(CurTime())
	end

	if selfTable.GetHasZoom(self) then
		selfTable.SetIsScoped(self, false)
		selfTable.SetZoomLevel(self, 0)
		selfTable.SetWeaponMode(self, Primary_Mode)
		if owner and owner:GetFOV() ~= owner:GetDefaultFOV() then
			owner:SetFOV(0, 0.01)
		end
	end

	-- animation cancel for unfinished reload
	if selfTable.GetInReload(self) and not selfTable.m_bReloadVisuallyComplete then
		self:SetNextPrimaryFire(CurTime())
		self:SetNextSecondaryFire(CurTime())
	end

	-- lua: reset bodygroups bc gmod doesnt
	-- :Holster() is only called when owner is valid
	if owner then
		local vm = owner:GetViewModel()
		if vm:IsValid() then
			for i = 0, vm:GetNumBodyGroups() - 1 do
				vm:SetBodygroup(i, 0)
			end

			for i = 0, vm:GetNumPoseParameters() - 1 do
				vm:SetPoseParameter(i, SERVER and 0 or math.Remap(0, 0, 1, vm:GetPoseParameterRange(i)))
			end

			if CLIENT then
				selfTable.RemoveWeaponSkin(self, vm, owner)
			end
		end
	end

	local iron = selfTable.GetIronSightController(self)
	if iron:IsValid() then
		iron:SetState(IronSight_viewmodel_is_deploying)
	end

	selfTable.SetInReload(self, false)
	selfTable.SetFinishReloadTime(self, 0)
	selfTable.SetShotsFired(self, 0)

	if IsValid(nextWep) then
		if nextWep.IsSWCSWeapon then
			nextWep:SetAimPunchVelP(selfTable.GetAimPunchVelP(self))
			nextWep:SetAimPunchVelY(selfTable.GetAimPunchVelY(self))
			nextWep:SetAimPunchP(selfTable.GetAimPunchP(self))
			nextWep:SetAimPunchY(selfTable.GetAimPunchY(self))
			nextWep:SetViewPunchP(selfTable.GetViewPunchP(self))
			nextWep:SetViewPunchY(selfTable.GetViewPunchY(self))
			nextWep:SetLastViewPunchAngle(selfTable.GetViewPunchAngle(self, false))
		elseif owner then
			local aimpunch = Angle(selfTable.GetAimPunchP(self), selfTable.GetAimPunchY(self))
			local viewpunch = Angle(selfTable.GetViewPunchP(self), selfTable.GetViewPunchY(self))
			local angvel = Angle(selfTable.GetAimPunchVelP(self), selfTable.GetAimPunchVelY(self))

			local angFinal = aimpunch + viewpunch
			owner:SetViewPunchAngles(angFinal)
			--owner:SetViewPunchVelocity(angvel)
		end
	end

	selfTable.SetAimPunchVelP(self, 0)
	selfTable.SetAimPunchVelY(self, 0)
	selfTable.SetAimPunchP(self, 0)
	selfTable.SetAimPunchY(self, 0)
	selfTable.SetViewPunchP(self, 0)
	selfTable.SetViewPunchY(self, 0)

	return true
end

---@diagnostic disable: inject-field
function SWEP:ViewModelDrawn(vm)
	--local owner = vm:GetOwner()

	if not vm.swcs_cb_idx then
		vm.swcs_cb_idx = vm:AddCallback("BuildBonePositions", function(_vm, numBones)
			local owner = _vm:GetOwner()
			if not owner or not owner:IsValid() then return end

			local wep = owner:GetActiveWeapon()
			if wep:IsValid() and wep.PostBuildTransformations then
				wep:PostBuildTransformations(_vm)
			end
		end)
	else
		local callbacks = vm:GetCallbacks("BuildBonePositions")
		if table.IsEmpty(callbacks) then
			vm.swcs_cb_idx = nil
		end
	end

	local selfTable = self:GetTable()
	local item = selfTable.m_econItem --plyInventory[self:GetClass()]
	if item then
		selfTable.CreateViewmodelAttachments(self, vm, item)
		selfTable.RenderViewmodelAttachments(self, vm, item)
	end
end

---@diagnostic enable: inject-field

function SWEP:ShouldDrawViewModel()
	local owner = self:GetPlayerOwner()
	if owner and owner:GetFOV() ~= owner:GetDefaultFOV() and self:IsZoomed() and (self:GetDoesHideViewModelWhenZoomed() and not self:GetResumeZoom()) then
		return false
	end

	return true
end

function SWEP:IsEquipment()
	return false
end

-- https://github.com/Facepunch/garrysmod/blob/master/garrysmod/gamemodes/terrortown/entities/weapons/weapon_tttbase.lua
function SWEP:DampenDrop()
	-- For some reason gmod drops guns on death at a speed of 400 units, which
	-- catapults them away from the body. Here we want people to actually be able
	-- to find a given corpse's weapon, so we override the velocity here and call
	-- this when dropping guns on death.
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetVelocityInstantaneous(Vector(0, 0, -75) + phys:GetVelocity() * 0.001)
		phys:AddAngleVelocity(phys:GetAngleVelocity() * -0.99)
	end
end

function SWEP:Ammo1()
	return self:GetAmmoCount(self:GetPrimaryAmmoType())
end

function SWEP:PostHitCallback(...)
	--
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
	return 1
end

function SWEP:HasBuiltInSilencer()
	return (tonumber(self.ItemAttributes and self.ItemAttributes["has silencer"]) or 0) == 2
end

-- fix for https://steamcommunity.com/sharedfiles/filedetails/?id=1146104662
function SWEP:GetIronSights()
	local iron = self:GetIronSightController()

	if iron:IsValid() then
		return iron.IsApproachingSighted and iron:IsApproachingSighted()
	end

	if self.NoCustomViewmodelPos then
		return true
	end
end

if SERVER then
	SWEP.NPCBurstMin = 2
	SWEP.NPCBurstMax = 4
	SWEP.NPCBurstDelay = 1

	SWEP.NPCRestMin = 0.3
	SWEP.NPCRestMax = 0.66

	function SWEP:GetNPCBulletSpread(prof)
		self:UpdateAccuracyPenalty()
		return 5
	end

	function SWEP:GetNPCBurstSettings()
		local flCycleTime = self:GetCycleTime()
		local weaponType = self:GetWeaponType()

		local iBurstMin = self.NPCBurstMin
		local iBurstMax = self.NPCBurstMax

		if weaponType == "sniperrifle" then
			flCycleTime = flCycleTime * 1.75
			iBurstMin = 1
			iBurstMax = 1
		end

		return iBurstMin, iBurstMax, flCycleTime
	end

	function SWEP:GetNPCRestTimes()
		return self.NPCRestMin, self.NPCRestMax
	end
end
