SWEP.Base = "weapon_swcs_base"
SWEP.Category = "#spawnmenu.category.swcs"

DEFINE_BASECLASS(SWEP.Base)

SWEP.Slot = 1
SWEP.AutoSpawnable = false

SWEP.PrintName = "Taser"
SWEP.Spawnable = true
SWEP.HoldType = "pistol"
SWEP.WorldModel = Model("models/weapons/csgo/w_eq_taser.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_eq_taser.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/taser.png", "smooth")
end

sound.Add({
	name = "Weapon_Taser_CSGO.Single",
	channel = CHAN_WEAPON,
	level = 79,
	volume = 0.35,
	pitch = 100,
	sound = Sound(")weapons/csgo/taser/taser_shoot.wav"),
})
sound.Add({
	name = "Weapon_PartyHorn_CSGO.Taser",
	channel = CHAN_WEAPON,
	level = 79,
	volume = 0.7,
	pitch = 100,
	sound = Sound(")weapons/csgo/taser/taser_shoot_birthday.wav"),
})
sound.Add({
	name = "Weapon_Taser_CSGO.Hit",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.6,
	pitch = 100,
	sound = Sound(")weapons/csgo/taser/taser_hit.wav"),
})
sound.Add({
	name = "Weapon_Taser_CSGO.Draw",
	channel = CHAN_STATIC,
	level = 65,
	volume = 0.3,
	pitch = 100,
	sound = Sound(")weapons/csgo/taser/taser_draw.wav"),
})
sound.Add({
	name = "Weapon_PartyHorn_CSGO.Single",
	channel = CHAN_STATIC,
	level = 79,
	volume = 1.0,
	pitch = 100,
	sound = Sound(")weapons/csgo/party_horn_01.wav"),
})

local TASER_BIRTHDAY_PARTICLES = "weapon_confetti"
local TASER_BIRTHDAY_SOUND = Sound("Weapon_PartyHorn_CSGO.Single")

local kTaserDropDelay = 0.5

SWEP.m_fFireTime = 0
function SWEP:PrimaryAttack()
	if not self:CSBaseGunFire(self:GetCycleTime(), Primary_Mode) then
		return
	end

	self.m_fFireTime = CurTime()

	if swcs.IsParty() then
		self:EmitSound(TASER_BIRTHDAY_SOUND)
	end
end

function SWEP:Think()
	BaseClass.Think(self)

	if self:Clip1() == 0 and CurTime() >= self.m_fFireTime + kTaserDropDelay then
		local owner = self:GetPlayerOwner()

		if SERVER and owner then
			self:SwitchToPreviousWeapon()
			owner:StripWeapon(self:GetClass())

			self:Remove()
		end
	end
end

function SWEP:Holster(nextWep)
	if self:Clip1() == 0 then
		local owner = self:GetPlayerOwner()

		if SERVER and owner then
			owner:StripWeapon(self:GetClass())
			return true
		end
	end

	return BaseClass.Holster(self, nextWep)
end

function SWEP:Initialize(...)
	BaseClass.Initialize(self, ...)

	PrecacheParticleSystem(TASER_BIRTHDAY_PARTICLES)
end

function SWEP:GetMuzzleFlashEffect1stPerson()
	if swcs.IsParty() then
		return TASER_BIRTHDAY_PARTICLES
	else
		return BaseClass.GetMuzzleFlashEffect1stPerson(self)
	end
end

function SWEP:GetMuzzleFlashEffect3rdPerson()
	if swcs.IsParty() then
		return TASER_BIRTHDAY_PARTICLES
	else
		return BaseClass.GetMuzzleFlashEffect3rdPerson(self)
	end
end

function SWEP:CustomAmmoDisplay() end

if SERVER then
	hook.Add("PlayerDeath", "swcs.taser", function(victim, inflictor, attacker)
		if inflictor:IsWeapon() and inflictor:GetClass() == "weapon_swcs_taser" then
			-- never used, never unset
			--victim.swcs_TaserDeath = true
			victim:EmitSound("SWCS.Player_DeathTaser")
		end
	end)
end

SWEP.ItemDefAttributes = [=["attributes 02/04/2023"
{
	"inaccuracy jump initial"		"96.620003"
	"inaccuracy jump"		"92.959999"
	"inaccuracy jump alt"		"92.959999"
	"heat per shot"		"0.000000"
	"tracer frequency"		"1"
	"max player speed"		"220"
	"in game price"		"200"
	"kill award"		"0"
	"armor ratio"		"2"
	"crosshair min distance"		"8"
	"penetration"		"0"
	"damage"		"500"
	"range"		"190"
	"range modifier"		"0.004900"
	"flinch velocity modifier large"		"0.500000"
	"flinch velocity modifier small"		"0.650000"
	"spread"		"2.000000"
	"inaccuracy crouch"		"1.000000"
	"inaccuracy stand"		"1.000000"
	"inaccuracy land"		"0.175000"
	"inaccuracy ladder"		"119.500000"
	"inaccuracy fire"		"22.120001"
	"inaccuracy move"		"1.000000"
	"recovery time crouch"		"0.287823"
	"recovery time stand"		"0.345388"
	"recoil seed"		"687"
	"primary clip size"		"1"
	"primary default clip size"		"1"
	"secondary default clip size"		"1"
	"weapon weight"		"5"
	"itemflag exhaustible"		"1"
	"rumble effect"		"1"
	"inaccuracy crouch alt"		"1.000000"
	"inaccuracy fire alt"		"22.120001"
	"inaccuracy ladder alt"		"119.500000"
	"inaccuracy land alt"		"0.175000"
	"inaccuracy move alt"		"1.000000"
	"inaccuracy stand alt"		"1.000000"
	"max player speed alt"		"220"
	"recovery time crouch final"		"0.287823"
	"recovery time stand final"		"0.345388"
	"spread alt"		"2.000000"
}]=]
SWEP.ItemDefVisuals = [=["visuals 02/04/2023"
{
	"muzzle_flash_effect_1st_person"		"weapon_muzzle_flash_taser"
	"muzzle_flash_effect_3rd_person"		"weapon_muzzle_flash_taser"
	"eject_brass_effect"		"weapon_shell_casing_9mm"
	"tracer_effect"		"weapon_tracers_taser"
	"weapon_type"		"Knife"
	"player_animation_extension"		"pistol"
	"primary_ammo"		"AMMO_TYPE_TASERCHARGE"
	"sound_single_shot"		"Weapon_Taser_CSGO.Single"
	"sound_nearlyempty"		"Default.nearlyempty"
}]=]
