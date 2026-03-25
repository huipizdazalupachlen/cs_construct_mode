SWEP.Base = "weapon_swcs_base_grenade"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Slot = 4

SWEP.Primary.Ammo = swcs.InTTT and "none" or "swcs_tagrenade"
SWEP.AutoSpawnable = false

SWEP.PrintName = "Tactical Awareness Grenade"
SWEP.Spawnable = true
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_sensorgrenade.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_sonar_bomb.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/tagrenade.png", "smooth")
end

sound.Add({
	name = "Sensor.Activate",
	channel = CHAN_WEAPON,
	level = 65,
	volume = 0.5,
	pitch = 100,
	sound = Sound("weapons/csgo/sensorgrenade/sensor_arm.wav"),
})
sound.Add({
	name = "Sensor.Equip",
	channel = CHAN_WEAPON,
	level = 65,
	volume = 0.4,
	pitch = 100,
	sound = Sound("weapons/csgo/sensorgrenade/sensor_equip.wav"),
})
sound.Add({
	name = "Sensor.Land",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.7,
	pitch = 100,
	sound = Sound("weapons/csgo/sensorgrenade/sensor_land.wav"),
})
sound.Add({
	name = "Sensor.WarmupBeep",
	channel = CHAN_STATIC,
	level = 75,
	volume = 0.3,
	pitch = 100,
	sound = Sound("weapons/csgo/sensorgrenade/sensor_detect.wav"),
})
sound.Add({
	name = "Sensor.Detonate",
	channel = CHAN_STATIC,
	level = 140,
	volume = 1.0,
	pitch = 100,
	sound = Sound("weapons/csgo/sensorgrenade/sensor_explode.wav"),
})
--[[

	"Sensor.DetectPlayer_Hud"
	{
		"channel"		"CHAN_STATIC"
		"volume"		"0.5"
		"pitch"			"PITCH_NORM"
		"soundlevel"  		"SNDLVL_65dB"
		"wave"			"~weapons/sensorgrenade/sensor_detecthud.wav"
	}
]]

SWEP.ItemDefAttributes = [=["attributes 09/03/2020" {
	"max player speed"		"245"
	"in game price"		"200"
	"crosshair min distance"		"7"
	"penetration"		"1"
	"damage"		"50"
	"range"		"4096"
	"range modifier"		"0.990000"
	"throw velocity"		"750.000000"
	"primary default clip size"		"1"
	"secondary default clip size"		"1"
	"weapon weight"		"1"
	"itemflag exhaustible"		"1"
	"max player speed alt"		"245"
}]=]
SWEP.ItemDefVisuals = [=["visuals 09/03/2020" {
	"weapon_type"		"Grenade"
	"player_animation_extension"		"gren"
	"primary_ammo"		"AMMO_TYPE_FLASHBANG"
	"sound_single_shot"		"SmokeGrenade_CSGO.Throw"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]

function SWEP:EmitGrenade()
	if SERVER then
		return ents.Create("swcs_sensorgrenade_projectile")
	else
		return NULL
	end
end

local GRENADE_SECONDARY_DAMPENING = 0.3
local GRENADE_SECONDARY_LOWER = 12.0

function SWEP:ThrowGrenade()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	local angThrow = self:GetFinalAimAngle()
	if angThrow.p > 90 then
		angThrow.p = angThrow.p - 360
	elseif angThrow.p <= -90 then
		angThrow.p = angThrow.p + 360
	end

	assert(angThrow.p <= 90.0 and angThrow.p >= -90.0, "Grenade throw pitch angle must be between -90 and 90 for the adustments to work.")

	-- NB. a pitch of +90 is looking straight down, -90 is looking straight up

	-- add a 10 degrees upwards angle to the throw when looking horizontal, lerp the upwards boost to 0 at the pitch extremes
	angThrow.p = angThrow.p - (10.0 * (90.0 - math.abs(angThrow.p)) / 90.0)

	local kBaseVelocity = self:GetThrowVelocity()
	--const float kThrowVelocityClampRatio = 750.0f / 540.0f;	-- from original CSS values

	--float flVel = clamp((90 - angThrow.x) / 90, 0.0f, kThrowVelocityClampRatio) * kBaseVelocity;
	local flVel = math.Clamp(kBaseVelocity * 0.9, 15, 750)

	-- clamp the throw strength ranges just to be sure
	local flClampedThrowStrength = self:GetThrowStrength()
	flClampedThrowStrength = math.Clamp(flClampedThrowStrength, 0.0, 1.0)

	flVel = flVel * Lerp(flClampedThrowStrength, GRENADE_SECONDARY_DAMPENING, 1.0)
	local vForward = angThrow:Forward()

	local vecSrc = owner:GetShootPos()

	vecSrc:Add(Vector(0, 0, Lerp(flClampedThrowStrength, -GRENADE_SECONDARY_LOWER, 0.0)))

	-- We want to throw the grenade from 16 units out.  But that can cause problems if we're facing
	-- a thin wall.  Do a hull trace to be safe.
	-- Wills: Moved the trace length out to 22 inches, then subtract 6. This way we default to 16,
	-- but pull back 6 from wherever we hit, so we don't emit from EXACTLY inside the close surface, which can lead to
	-- the grenade penetrating the wall anyway.
	local trace = {}
	local mins = -Vector(2, 2, 2)
	util.TraceHull({
		start = vecSrc,
		endpos = vecSrc + vForward * 22,
		mins = mins,
		maxs = -mins,
		mask = bit.bor(MASK_SOLID, CONTENTS_GRENADECLIP),
		filter = owner,
		collisiongroup = COLLISION_GROUP_NONE,
		output = trace,
	})
	vecSrc = trace.HitPos - (vForward * 6)

	local vecThrow = vForward * flVel + (owner:GetVelocity() * 1.25)

	local iSeed = self:GetRandomSeed()
	iSeed = iSeed + 1

	local random = UniformRandomStream(iSeed)

	local hProjectile = self:EmitGrenade()
	if hProjectile:IsValid() then
		local angSpawn = Angle(angThrow)
		angSpawn:RotateAroundAxis(angSpawn:Right(), 90)

		hProjectile:Create(vecSrc, angSpawn, vecThrow, Angle(200, random:RandomInt(-360, 360)), owner)

		hook.Run("PlayerThrowSWCSGrenade", owner, hProjectile)

		if hProjectile:IsValid() then
			hProjectile:Spawn()
			hook.Run("PlayerSpawnedSENT", owner, hProjectile)
		end
	end

	-- Flag the grenade weapon as having emitted a projectile.
	-- The 'grenade' is now flying away from the player, so we don't want to drop *this* grenade on death
	-- (that'll make a duplicate)
	self.m_bHasEmittedProjectile = true
	self:SetRedraw(true)
	self:SetIsHeldByPlayer(false)
	self:SetThrowTime(0)
end
