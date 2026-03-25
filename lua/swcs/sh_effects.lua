AddCSLuaFile()

game.AddParticles("particles/csgo/csgo_weapon_fx.pcf")
game.AddParticles("particles/csgo/csgo_impact_fx.pcf")
game.AddParticles("particles/csgo/csgo_blood_fx.pcf")
game.AddParticles("particles/csgo/explosions_fx.pcf")
if CLIENT then timer.Simple(0, function() game.AddParticles("particles/csgo/csgo_weapon_fx.pcf") end) end

PrecacheParticleSystem("weapon_shell_casing_candycorn")

PrecacheParticleSystem("explosion_basic")
PrecacheParticleSystem("explosion_basic_water")
PrecacheParticleSystem("explosion_hegrenade_dirt")
PrecacheParticleSystem("explosion_hegrenade_snow")
PrecacheParticleSystem("explosion_smokegrenade")
PrecacheParticleSystem("c4_train_ground_effect")
PrecacheParticleSystem("c4_timer_light")
PrecacheParticleSystem("c4_timer_light_trigger")

PrecacheParticleSystem("impact_wallbang_light")
PrecacheParticleSystem("impact_wallbang_heavy")

PrecacheParticleSystem("blood_impact_heavy")
PrecacheParticleSystem("blood_impact_medium")
PrecacheParticleSystem("blood_impact_light")
PrecacheParticleSystem("blood_impact_light_headshot")
PrecacheParticleSystem("impact_helmet_headshot")

PrecacheParticleSystem("impact_concrete_csgo")
PrecacheParticleSystem("impact_plaster_csgo")
PrecacheParticleSystem("impact_water_csgo")

PrecacheParticleSystem("weapon_snowball_trail")
PrecacheParticleSystem("weapon_snowball_impact")
PrecacheParticleSystem("weapon_snowball_impact_stuck_wall")
PrecacheParticleSystem("weapon_snowball_impact_splat")
PrecacheParticleSystem("snow_hit_player_screeneffect")
PrecacheParticleSystem("snowball_pile")

PrecacheParticleSystem("weapon_decoy_ground_effect")
PrecacheParticleSystem("weapon_decoy_ground_effect_shot")

local swcs_debug_impact = CreateConVar("swcs_debug_impact", "0", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Show debug info for impact effects")
local TAG = "swcs_fx"

local FX_IMPACT_GENERIC = 0
local FX_IMPACT_KNIFE = 1
local FX_PARTICLE = 2
local FX_DLIGHT = 3
local FX_SOUND = 4
local FX_BLOODSPRAY = 5

if SERVER then
	util.AddNetworkString(TAG)

	function swcs.SendParticle(particleName, vecPos, angles, bIsBlood, iBloodColor, entity, filter)
		if not filter then
			filter = RecipientFilter()
			filter:AddPVS(vecPos)
		end

		net.Start(TAG, true)
		net.WriteUInt(FX_PARTICLE, 3)

		net.WriteBool(bIsBlood)
		if bIsBlood then
			net.WriteInt(iBloodColor, 4)
		end

		net.WriteString(particleName)
		net.WriteVector(vecPos)
		net.WriteAngle(angles)
		net.WriteEntity(entity or NULL)
		net.Send(filter)
	end
	function swcs.SendMuzzleflashLight(ent)
		if not ent:IsValid() then return end

		local filter = RecipientFilter()
		filter:AddPVS(ent:GetPos())
		if ent:IsPlayer() then
			filter:RemovePlayer(ent)
		end

		net.Start(TAG)
		net.WriteUInt(FX_DLIGHT, 3)
		net.WriteEntity(ent)
		net.Send(filter)
	end
	function swcs.SendSound(soundName, vecPos, filter)
		if not filter then
			filter = RecipientFilter()
			filter:AddPVS(vecPos)
		end

		net.Start(TAG, true)
		net.WriteUInt(FX_SOUND, 3)
		net.WriteString(soundName)
		net.WriteVector(vecPos)
		net.Send(filter)
	end
else
	net.Receive(TAG, function()
		local type = net.ReadUInt(3)

		if type == FX_IMPACT_GENERIC or type == FX_IMPACT_KNIFE then
			local originEnt = net.ReadEntity()
			local vecOrigin = net.ReadVector()
			local vecStart = net.ReadVector()
			local iDamageType = net.ReadUInt(32)
			local iHitbox = net.ReadUInt(32)
			local pEntity = net.ReadEntity()
			local flags = net.ReadUInt(32)
			local nSurfaceProp = net.ReadUInt(8)

			local data = EffectData()
			data:SetOrigin(vecOrigin)
			data:SetStart(vecStart)
			data:SetDamageType(iDamageType)
			data:SetHitBox(iHitbox)
			data:SetEntity(pEntity)
			data:SetFlags(flags)
			data:SetSurfaceProp(nSurfaceProp)

			if type == FX_IMPACT_KNIFE then
				swcs.fx.KnifeSlashEffect(data, originEnt)
			else
				swcs.fx.ImpactEffect(data, originEnt)
			end
		elseif type == FX_PARTICLE then -- used to network confirmed bullet hits to weapon owner, and play particle effects
			local bIsBlood = net.ReadBool()
			if bIsBlood then
				local iBloodColor = net.ReadInt(4)

				if not swcs.fx.ShouldShowBlood(iBloodColor) then
					return
				end
			end

			local strEffectName = net.ReadString()
			local vecOrigin = net.ReadVector()
			local angles = net.ReadAngle()
			local ent = net.ReadEntity()

			angles:Normalize()

			local vForward, vRight, vUp = angles:Forward(), angles:Right(), angles:Up()
			vForward:Normalize()
			vRight:Normalize()
			vUp:Normalize()

			local pEffect
			if ent:IsValid() then
				---@diagnostic disable-next-line: missing-parameter
				pEffect = ent:CreateParticleEffect(strEffectName)
				--swcs.fx.SetImpactControlPoint(pEffect, 0, vecOrigin, vForward, ent)
			else
				pEffect = CreateParticleSystemNoEntity(strEffectName, vecOrigin, angles)
				--swcs.fx.SetImpactControlPoint(pEffect, 0, vecOrigin, vForward, ent)
			end

			if pEffect then
				pEffect:SetControlPoint(0, vecOrigin)
				pEffect:SetControlPointOrientation(0, vUp, vRight, vForward)
				pEffect:SetControlPointEntity(0, ent)
			end
		elseif type == FX_DLIGHT then -- only used for remote player muzzleflash, so hard code these values :)
			local ent = net.ReadEntity()
			if not ent:IsValid() then return end

			local light = DynamicLight(ent:EntIndex())
			if light then
				local origin = ent:EyePos()

				local vAngles = ent:EyeAngles()
				local vForward, vRight = vAngles:Forward(), vAngles:Right()

				--origin:Add(vRight * (cl_righthand:GetBool() and 4 or -4))
				origin:Add(vRight * 4)
				origin:Add(vForward * 31)
				origin.z = origin.z + 3.0

				light.pos = origin
				light.r = 255
				light.g = 186
				light.b = 64
				light.brightness = 5
				light.size = 70
				light.dietime = CurTime() + 0.05
				light.decay = 768
			end
		elseif type == FX_SOUND then
			local soundName = net.ReadString()
			local vecPos = net.ReadVector()

			local soundlevel = 75
			local volume = 1
			local pitch = 100

			local data = sound.GetProperties(soundName)
			if data then
				if data.soundlevel then
					soundlevel = data.soundlevel
				end
				if data.volume then
					volume = data.volume
				end
				if data.pitch then
					pitch = data.pitch
				end
			end

			sound.Play(soundName, vecPos, soundlevel, pitch, volume)
		elseif type == FX_BLOODSPRAY then
			local originEnt = net.ReadEntity()
			local vecOrigin = net.ReadVector()
			local vecDir = net.ReadVector()
			local flDamage = net.ReadFloat()
			local flRawDamage = net.ReadFloat()
			local pEntity = net.ReadEntity()

			local data = EffectData()
			data:SetOrigin(vecOrigin)
			data:SetNormal(vecDir)
			data:SetMagnitude(flDamage)
			data:SetRadius(flRawDamage)
			data:SetEntity(pEntity)

			swcs.fx.BloodSpray(data, originEnt)
		end
	end)
end

local ImpactStyle
if CLIENT then
	ImpactStyle = CreateClientConVar("swcs_fx_impact_style", "0", true, false, "what style of bullet impact effects to use (0 = hl2, 1 = csgo)", 0, 1)
end
local damage_impact_heavy = CreateConVar("swcs_fx_damage_impact_heavy", "40", nil, "Damage ABOVE this value is considered heavy damage")
local damage_impact_medium = CreateConVar("swcs_fx_damage_impact_medium", "20", nil, "Damage BELOW this value is considered light damage")

swcs.fx = {}

local rawDecalData = Format("\"temp\" {\n%s\n}", file.Read("scripts/decals_subrect.txt", "GAME"))
local decalData = util.KeyValuesToTable(rawDecalData, true, true)

-- fake material
local MAT_SHIELD = string.byte("u", 1, 1)

local engineDecalTranslation = {
	[MAT_SHIELD] = "Impact_CSGO.Shield",
}
local csgoDecalTranslation = {
	["C"] = "Impact_CSGO.Concrete",
	["D"] = "Impact_CSGO.Dirt",
	--["D"] = "Impact_CSGO.Cardboard",
	["F"] = "Impact_CSGO.Flesh",
	["J"] = "Impact_CSGO.Snow",
	["L"] = "Impact_CSGO.Plastic",
	["M"] = "Impact_CSGO.Metal",
	["N"] = "Impact_CSGO.Sand",
	["O"] = "Impact_CSGO.Leaves",
	["P"] = "Impact_CSGO.Computer",
	--["Q"] = "Impact_CSGO.Asphalt",
	--["R"] = "Impact_CSGO.Brick",
	["T"] = "Impact_CSGO.Tile",
	["U"] = "Impact_CSGO.Grass",
	["V"] = "Impact_CSGO.Vent",
	["W"] = "Impact_CSGO.Wood",
	["Y"] = "Impact.Glass", --"Impact_CSGO.Glass",
	["u"] = "Impact_CSGO.Shield",
}

-- decal registering
do
	-- we used to do game.AddDecal, but it would cause strangeness on the decal that was actually applied when joining servers after disconnecting from one
	swcs.fx.DecalMaterials = {
		["Impact_CSGO.Concrete"] = {
			"decals/csgo/concrete/concrete1_subrect",
			"decals/csgo/concrete/concrete2_subrect",
			"decals/csgo/concrete/concrete3_subrect",
			"decals/csgo/concrete/concrete4_subrect",
		},
		["Impact_CSGO.Dirt"] = {
			"decals/csgo/dirt/dirt1_subrect",
			"decals/csgo/dirt/dirt2_subrect",
			"decals/csgo/dirt/dirt3_subrect",
			"decals/csgo/dirt/dirt4_subrect",
		},
		["Impact_CSGO.Grass"] = {
			"decals/csgo/dirt/dirt1_subrect",
			"decals/csgo/dirt/dirt2_subrect",
			"decals/csgo/dirt/dirt3_subrect",
			"decals/csgo/dirt/dirt4_subrect",
		},
		["Impact_CSGO.Sand"] = {
			"decals/csgo/dirt/dirt1_subrect",
			"decals/csgo/dirt/dirt2_subrect",
			"decals/csgo/dirt/dirt3_subrect",
			"decals/csgo/dirt/dirt4_subrect",
		},
		["Impact_CSGO.Snow"] = {
			"decals/csgo/dirt/dirt1_subrect",
			"decals/csgo/dirt/dirt2_subrect",
			"decals/csgo/dirt/dirt3_subrect",
			"decals/csgo/dirt/dirt4_subrect",
		},
		["Impact_CSGO.Vent"] = {
			"decals/csgo/metal/metal01_subrect",
			"decals/csgo/metal/metal02_subrect",
			"decals/csgo/metal/metal03_subrect",
			"decals/csgo/metal/metal04_subrect",
		},
		["Impact_CSGO.Metal"] = {
			"decals/csgo/metal/metal01_subrect",
			"decals/csgo/metal/metal02_subrect",
			"decals/csgo/metal/metal03_subrect",
			"decals/csgo/metal/metal04_subrect",
		},
		["Impact_CSGO.Wood"] = {
			"decals/csgo/wood/wood1_subrect",
			"decals/csgo/wood/wood2_subrect",
			"decals/csgo/wood/wood3_subrect",
			"decals/csgo/wood/wood4_subrect",
		},
		["Impact_CSGO.Plastic"] = {
			"decals/csgo/computer/computer1_subrect",
			"decals/csgo/computer/computer2_subrect",
			"decals/csgo/computer/computer3_subrect",
			"decals/csgo/computer/computer4_subrect",
		},
		["Impact_CSGO.Computer"] = {
			"decals/csgo/computer/computer1_subrect",
			"decals/csgo/computer/computer2_subrect",
			"decals/csgo/computer/computer3_subrect",
			"decals/csgo/computer/computer4_subrect",
		},
		["Impact_CSGO.Tile"] = {
			"decals/csgo/tile/tile1_subrect",
			"decals/csgo/tile/tile2_subrect",
			"decals/csgo/tile/tile3_subrect",
			"decals/csgo/tile/tile4_subrect",
			"decals/csgo/tile/tile5_subrect",
			"decals/csgo/tile/tile6_subrect",
		},
		["Impact_CSGO.Flesh"] = {
			"decals/csgo/flesh/blood1_subrect",
			"decals/csgo/flesh/blood2_subrect",
			"decals/csgo/flesh/blood3_subrect",
			"decals/csgo/flesh/blood4_subrect",
			"decals/csgo/flesh/blood5_subrect",
			"decals/csgo/flesh/blood9_subrect",
		},
		["Impact_CSGO.Shield"] = {
			"decals/csgo/metal/steel01",
			"decals/csgo/metal/steel02",
			"decals/csgo/metal/steel03",
			"decals/csgo/metal/steel04",
		},
		["Impact_CSGO.Plaster"] = {
			"decals/csgo/plaster/plaster01_subrect",
			"decals/csgo/plaster/plaster02_subrect",
			"decals/csgo/plaster/plaster03_subrect",
			"decals/csgo/plaster/plaster04_subrect",
		},
		["Impact_CSGO.Cardboard"] = {
			"decals/csgo/cardboard/cardboard1_subrect",
			"decals/csgo/cardboard/cardboard2_subrect",
			"decals/csgo/cardboard/cardboard3_subrect",
			"decals/csgo/cardboard/cardboard4_subrect",
		},
		["Impact_CSGO.Rubber"] = {
			"decals/csgo/rubber/rubber1_subrect",
			"decals/csgo/rubber/rubber2_subrect",
			"decals/csgo/rubber/rubber3_subrect",
			"decals/csgo/rubber/rubber4_subrect",
		},
		["Impact_CSGO.Brick"] = {
			"decals/csgo/brick/brick1_subrect",
			"decals/csgo/brick/brick2_subrect",
			"decals/csgo/brick/brick3_subrect",
			"decals/csgo/brick/brick4_subrect",
		},
		["Impact_CSGO.Rock"] = {
			"decals/csgo/rock/rock01_subrect",
			"decals/csgo/rock/rock02_subrect",
			"decals/csgo/rock/rock03_subrect",
			"decals/csgo/rock/rock04_subrect",
		},
	}
end

for charMat, matDecalName in next, decalData.TranslationData do
	engineDecalTranslation[string.byte(charMat, 1, 1)] = matDecalName
end

local keys = table.GetKeys(csgoDecalTranslation)
for _, charMat in ipairs(keys) do
	csgoDecalTranslation[string.byte(charMat, 1, 1)] = csgoDecalTranslation[charMat]
end

IMPACT_NODECAL = 0x1

function swcs.fx.ParseImpactData(data, vecOrigin, vecStart, vecShotDir, trace_filter)
	local nSurfaceProp, iMaterial, iDamageType, iHitbox

	local pEntity = data:GetEntity()
	if SERVER and not pEntity:IsValid() then
		pEntity = Entity(data:GetEntIndex())
	end

	vecOrigin:Set(data:GetOrigin())
	vecStart:Set(data:GetStart())
	vecShotDir:Set(vecOrigin)
	vecShotDir:Sub(vecStart)
	vecShotDir:Normalize()

	local tr = util.TraceLine({
		start = vecStart,
		endpos = vecOrigin + vecShotDir,
		mask = MASK_SHOT,
		filter = trace_filter,
	})

	if not tr then return end

	vecOrigin:Set(tr.HitPos)
	nSurfaceProp = tr.SurfaceProps

	iDamageType = data:GetDamageType()
	iHitbox = data:GetHitBox()

	local tSurfaceData = util.GetSurfaceData(nSurfaceProp)

	iMaterial = tSurfaceData and tSurfaceData.material or MAT_CONCRETE

	return pEntity, nSurfaceProp, iMaterial, iDamageType, iHitbox, tr
end

function swcs.fx.GetImpactDecal(iMaterial, iSurfaceProp, iDamageType)
	if iDamageType == DMG_SLASH then
		return "ManhackCut", true
	end

	-- hl2
	if ImpactStyle:GetInt() == 0 then
		return engineDecalTranslation[iMaterial] or "Impact.Concrete", engineDecalTranslation[iMaterial] ~= nil
	else
		local sinfo = swcs.GetSurfaceInfo(iSurfaceProp)
		local decal = (sinfo and sinfo.decal) or csgoDecalTranslation[iMaterial] or "Impact.Concrete"

		return decal, true
	end

	--local translation = engineDecalTranslation
	--if ImpactStyle:GetInt() == 1 then
	--	translation = csgoDecalTranslation
	--end
	--
	--return translation[iMaterial] or "Impact.Concrete", translation[iMaterial] ~= nil
end

local mat_cache = {}
function swcs.fx.GetImpactMaterial(iMaterial, iSurfaceProp, iDamageType)
	if SERVER then return end

	local decal, ok = swcs.fx.GetImpactDecal(iMaterial, iSurfaceProp, iDamageType)
	local path -- = util.DecalMaterial(decal)

	if iMaterial == MAT_SHIELD then
		path = table.Random(swcs.fx.DecalMaterials["Impact_CSGO.Shield"])
	elseif ImpactStyle:GetInt() == 1 and swcs.fx.DecalMaterials[decal] then
		path = table.Random(swcs.fx.DecalMaterials[decal])
	else
		path = util.DecalMaterial(decal)
	end

	if not path then
		if swcs_debug_impact:GetBool() then
			print("missing texture for impact decal", decal)
		end

		return nil, false
	end

	local mat = mat_cache[path]
	if not mat then
		mat_cache[path] = Material(path)
		mat = mat_cache[path]
	end

	if swcs_debug_impact:GetBool() then
		local tex = mat:GetTexture("$basetexture")

		if not ok then
			print("missing decal for mat index", iMaterial)
		elseif mat:IsError() then
			print("material error for decal mat", path)
		elseif tex:IsErrorTexture() then
			print("texture error for decal mat", path, mat:GetString("$basetexture"))
		end
	end

	return mat, ok
end

FX_WATER_IN_SLIME = 0x1
function swcs.fx.Impact(vecOrigin, vecStart, iMaterial, iDamageType, iHitbox, pEntity, tr, nFlags, trace_filter)
	-- Setup our shot information
	local shotDir = vecOrigin - vecStart
	local flLength = shotDir:Length()
	shotDir:Normalize()

	local traceExt = vecStart + (shotDir * (flLength + 8))

	util.TraceLine({
		start = vecStart,
		endpos = traceExt,
		mask = MASK_SHOT,
		output = tr,
		filter = trace_filter,
	})

	-- traces not available at this point, bail
	if not tr.HitPos then return end

	-- fired into water
	if bit.band(util.PointContents(tr.HitPos), bit.bor(CONTENTS_WATER, CONTENTS_SLIME)) ~= 0 then
		local waterTrace = util.TraceLine({
			start = tr.StartPos,
			endpos = tr.HitPos,
			mask = bit.bor(CONTENTS_WATER, CONTENTS_SLIME),
			filter = {swcs.fx.CurrentPlayer},
			collisiongroup = COLLISION_GROUP_NONE,
		})

		if not waterTrace.AllSolid then
			local data = EffectData()
			data:SetOrigin(waterTrace.HitPos)
			data:SetNormal(waterTrace.HitNormal)
			data:SetScale(g_ursRandom:RandomFloat(8, 12))

			if bit.band(waterTrace.Contents, CONTENTS_SLIME) ~= 0 then
				data:SetFlags(bit.bor(data:GetFlags(), FX_WATER_IN_SLIME))
			else
				data:SetFlags(bit.bnot(FX_WATER_IN_SLIME))
			end

			if ImpactStyle:GetInt() == 0 then
				util.Effect("gunshotsplash", data, not game.SinglePlayer())
			else
				ParticleEffect("impact_water_csgo", waterTrace.HitPos, angle_zero, nil)
				sound.Play("Water.BulletImpact", waterTrace.HitPos)
			end

			return false
		end
	end

	if tr.Fraction == 1 then
		return false
	end

	if ImpactStyle:GetInt() == 1 and bit.band(nFlags, IMPACT_NODECAL) == 0 then
		if pEntity and pEntity.IsSWCSShield then
			iMaterial = MAT_SHIELD
		end

		local decalMat, exists = swcs.fx.GetImpactMaterial(iMaterial, tr.SurfaceProps, iDamageType)

		if not exists then
			return false
		end

		if decalMat then
			util.DecalEx(decalMat, pEntity, tr.HitPos, tr.HitNormal, color_white, 1, 1)
		end
	end

	return true
end

-- register sounds
do
	sound.Add({
		name = "FX_RicochetSound_CSGO.Ricochet",
		channel = CHAN_STATIC,
		level = 87,
		volume = 0.7,
		sound = {Sound("weapons/csgo/fx/rics/ric3.wav"), Sound("weapons/csgo/fx/rics/ric4.wav"), Sound("weapons/csgo/fx/rics/ric5.wav")},
	})
	sound.Add({
		name = "FX_RicochetSound_CSGO.Ricochet_Legacy",
		channel = CHAN_STATIC,
		level = 87,
		volume = 0.3,
		sound = {Sound("weapons/csgo/fx/rics/legacy_ric_conc-1.wav"), Sound("weapons/csgo/fx/rics/legacy_ric_conc-2.wav")},
	})

	sound.Add({
		name = "SWCS.DamageHeadShot",
		channel = CHAN_STATIC,
		level = 64,
		volume = 1,
		sound = {Sound("player/csgo/headshot1.wav"), Sound("player/csgo/headshot2.wav")},
	})
	sound.Add({
		name = "SWCS.DamageHeadShotFeedback",
		channel = CHAN_STATIC,
		level = 0,
		volume = 0.7,
		sound = {Sound("player/csgo/headshot1.wav"), Sound("player/csgo/headshot2.wav")},
	})

	sound.Add({
		name = "SWCS.DamageHelmet",
		channel = CHAN_STATIC,
		level = 64,
		volume = 1,
		sound = Sound("player/csgo/bhit_helmet-1.wav"),
	})
	sound.Add({
		name = "SWCS.DamageHelmetFeedback",
		channel = CHAN_STATIC,
		level = 0,
		volume = 0.7,
		sound = Sound("player/csgo/bhit_helmet-1.wav"),
	})

	sound.Add({
		name = "SWCS.DamageKevlar",
		channel = CHAN_STATIC,
		level = 75,
		volume = 1,
		sound = {
			Sound("player/csgo/kevlar1.wav"), Sound("player/csgo/kevlar2.wav"), Sound("player/csgo/kevlar3.wav"),
			Sound("player/csgo/kevlar4.wav"), Sound("player/csgo/kevlar5.wav"),
		},
	})

	sound.Add({
		name = "SWCS.Player_DeathTaser",
		channel = CHAN_STATIC,
		volume = 1,
		pitch = 100,
		sound = Sound("hostage/hpain/hpain1.wav"),
	})

	sound.Add({
		name = "Shield_CSGO.BulletImpact",
		channel = CHAN_AUTO,
		level = 90,
		pitch = {100, 101},
		volume = 0.8,
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
		name = "Flesh.BulletImpact_CSGO",
		channel = CHAN_STATIC,
		volume = 0.7,
		level = 64,
		pitch = 100,
		sound = {
			Sound("physics/flesh/csgo/flesh_impact_bullet1.wav"),
			Sound("physics/flesh/csgo/flesh_impact_bullet2.wav"),
			Sound("physics/flesh/csgo/flesh_impact_bullet3.wav"),
			Sound("physics/flesh/csgo/flesh_impact_bullet4.wav"),
			Sound("physics/flesh/csgo/flesh_impact_bullet5.wav"),
		},
	})
end

function swcs.fx.RicochetSound(pos)
	local strSoundName = "FX_RicochetSound_CSGO.Ricochet"
	if g_ursRandom:RandomFloat() < 0.01 then -- 1% chance of playing legacy cs 1.6 ric sound.
		strSoundName = "FX_RicochetSound_CSGO.Ricochet_Legacy"
	end

	sound.Play(strSoundName, pos)
end

local SWITCH_RICO_CHANCE = {
	[MAT_METAL] = 5,
	[MAT_CONCRETE] = 5,
	[MAT_COMPUTER] = 5,
	[MAT_TILE] = 5,

	[MAT_GRATE] = 3,
	[MAT_VENT] = 3,
	[MAT_WOOD] = 3,

	[MAT_DIRT] = 1,
	[MAT_PLASTIC] = 1,
}
function swcs.fx.PlayImpactSound(pEntity, tr, vecServerOrigin, nServerSurfaceProp, bDoRico)
	if not pEntity then return end

	if bDoRico == nil then
		bDoRico = true
	end
	local vecOrigin = Vector()

	if pEntity:IsDormant() then return end

	-- If the client-side trace hit a different entity than the server, or
	-- the server didn't specify a surfaceprop, then use the client-side trace
	-- material if it's valid.

	if tr.Hit and (pEntity ~= tr.Entity or nServerSurfaceProp == 0) then
		nServerSurfaceProp = tr.SurfaceProps
	end

	if nServerSurfaceProp == -1 then
		if swcs_debug_impact:GetBool() then
			print("missing surface data for surface prop", nServerSurfaceProp, "defaulting to concrete")
			print(Format("HIT: %s (%s)", tr.Entity:GetClass(), tr.Entity:GetModel()))
		end

		nServerSurfaceProp = util.GetSurfaceIndex("concrete")
	end

	local pdata = util.GetSurfaceData(nServerSurfaceProp)

	if tr.Fraction < 1 then
		vecOrigin:Set(tr.HitPos)
	else
		vecOrigin:Set(vecServerOrigin)
	end

	-- Now play the sound
	if pEntity.IsSWCSShield then
		sound.Play("Shield_CSGO.BulletImpact", vecOrigin)
	elseif pdata.material == MAT_FLESH and (pEntity:IsPlayer() or pEntity:IsNPC() or pEntity:IsNextBot()) then
		sound.Play("Flesh.BulletImpact_CSGO", vecOrigin)
	elseif pdata.bulletImpactSound then
		sound.Play(pdata.bulletImpactSound, vecOrigin)

		-- play a ricochet based on the material
		local flRicoChance = SWITCH_RICO_CHANCE[pdata.material] or 0
		if bDoRico and g_ursRandom:RandomFloat(0, 10) <= flRicoChance then
			swcs.fx.RicochetSound(vecOrigin)
		end
	end
end

swcs.fx.CurrentPlayer = NULL
function swcs.fx.SetImpactControlPoint(pEffect, nPoint, vecImpactPoint, vecForward, pEntity)
	-- this is how you should do this, but gmod makes particles appear weird when doing it like this
	--[[
		local vecImpactY = vecForward:Cross(vector_up)
		local vecImpactZ = vecForward:Cross(-vecImpactY)
	]]
	local vecImpactY, vecImpactZ = Vector(), Vector()
	swcs.VectorVectors(vecForward, vecImpactY, vecImpactZ)

	pEffect:SetControlPoint(nPoint, vecImpactPoint)
	--pEffect:SetControlPointOrientation(nPoint, vecForward, vecImpactY, vecImpactZ)
	pEffect:SetControlPointOrientation(nPoint, vecImpactZ, vecImpactY, vecForward)
	if pEntity:IsValid() or pEntity:IsWorld() then
		pEffect:SetControlPointEntity(nPoint, pEntity)
	end
end

--local r_drawflecks = GetConVar("r_drawflecks")
local noEffectsFlags = bit.bor(SURF_SKY, SURF_NODRAW, SURF_HINT, SURF_SKIP)

---@param tr TraceResult
function swcs.fx.PerformCustomEffects(vecOrigin, tr, shotDir, iMaterial, iScale, nFlags)
	if bit.band(tr.SurfaceFlags, noEffectsFlags) ~= 0 then return end

	if not nFlags then
		nFlags = 0
	end

	--local bNoFlecks = not r_drawflecks:GetBool()
	--if not bNoFlecks then
	--    bNoFlecks = bit.band(nFlags, 0x1) ~= 0
	--end

	-- Compute the impact effect name
	local tSurfaceInfo = swcs.SurfaceInfo[swcs.SurfaceProps[tr.SurfaceProps]]
	local strImpactName

	if tSurfaceInfo then
		strImpactName = tSurfaceInfo.impact
	end

	if not strImpactName then
		if swcs_debug_impact:GetBool() then
			print("missing impact particle for surface prop", swcs.SurfaceProps[tr.SurfaceProps])
		end
		return
	end

	--print("impact", strImpactName)
	--[[
		const ImpactEffect_t &effect = pEffectList[ iMaterial - nOffset ];

		const char *pImpactName = effect.m_pName;
		int nEffectIndex = pEffectIndex[0];
		if ( bNoFlecks && effect.m_pNameNoFlecks )
		{
			pImpactName = effect.m_pNameNoFlecks;
			nEffectIndex = pEffectIndex[1];
		}
		if ( !pImpactName )
			return;
	]]

	local flDot = shotDir:Dot(tr.HitNormal)
	local vecReflect = shotDir + (tr.HitNormal * (-2.0 * flDot))

	local vecShotBackward = -shotDir
	local vecImpactPoint = tr.Fraction ~= 1 and tr.HitPos or vecOrigin

	local pEffect = CreateParticleSystemNoEntity(strImpactName, vecImpactPoint, --[[tr.HitNormal:Angle()]] Angle())
	if not (pEffect and pEffect:IsValid()) then return end

	swcs.fx.SetImpactControlPoint(pEffect, 0, vecImpactPoint, tr.HitNormal, tr.Entity)
	swcs.fx.SetImpactControlPoint(pEffect, 1, vecImpactPoint, vecReflect, tr.Entity)
	swcs.fx.SetImpactControlPoint(pEffect, 2, vecImpactPoint, vecShotBackward, tr.Entity)
	pEffect:SetControlPoint(3, Vector(iScale, iScale, iScale))

	local baseColor = render.GetSurfaceColor(tr.HitPos - tr.Normal * 1.1, tr.HitPos + tr.Normal)
	pEffect:SetControlPoint(4, baseColor)

	-- NOTE: fix for gmod not orienting properly when particle's orientation mode is set to 2
	--       with an orientation control point set
	do
		local up, right = Vector(), Vector()
		swcs.VectorVectors(-tr.HitNormal, right, up)

		pEffect:SetControlPointOrientation(3, up, right, -tr.HitNormal)
	end

	--print(tr.HitNormal, vecReflect, vecShotBackward)
	--debugoverlay.Line(vecImpactPoint, vecImpactPoint + tr.HitNormal * 10, 5, Color(255,0,0), true)
	--debugoverlay.Line(vecImpactPoint, vecImpactPoint + vecReflect * 10, 5, Color(0,255,0), true)
	--debugoverlay.Line(vecImpactPoint, vecImpactPoint + vecShotBackward * 10, 5, Color(0,0,255), true)

	--baseColor = baseColor:ToColor()
	--debugoverlay.Line(tr.StartPos, tr.HitPos, 5, baseColor, true)
end

-- ImpactCallback
function swcs.fx.ImpactEffect(data, ply, trace_filter)
	local tr = {}
	local vecOrigin, vecStart, vecShotDir = Vector(), Vector(), Vector()

	swcs.fx.CurrentPlayer = ply or NULL

	trace_filter = trace_filter or swcs.filter_IgnoreOwner(swcs.fx.CurrentPlayer, {})

	local pEntity, nSurfaceProp, iMaterial, iDamageType, iHitbox, _tr = swcs.fx.ParseImpactData(data, vecOrigin, vecStart, vecShotDir, trace_filter)

	if not pEntity or not isentity(pEntity) or (not pEntity:IsValid() and not pEntity:IsWorld()) then return end

	local flags = 0
	if bit.band(iDamageType or 0, DMG_SHOCK) ~= 0 then -- no decals for shock damage
		flags = IMPACT_NODECAL
	end

	data:SetFlags(flags)

	-- network to clients in PVS of impact point
	if SERVER then
		sound.EmitHint(SOUND_BULLET_IMPACT, vecOrigin, 400, 0.2, ply)
		local filter = RecipientFilter()
		filter:AddPAS(vecOrigin)
		if not game.SinglePlayer() and swcs.fx.CurrentPlayer:IsValid() then
			filter:RemovePlayer(swcs.fx.CurrentPlayer)
		end

		net.Start(TAG, true)
		net.WriteUInt(FX_IMPACT_GENERIC, 3)
		net.WriteEntity(swcs.fx.CurrentPlayer)
		net.WriteVector(vecOrigin)
		net.WriteVector(vecStart)
		net.WriteUInt(iDamageType --[[@as number]], 32)
		net.WriteUInt(iHitbox --[[@as number]], 32)
		net.WriteEntity(pEntity)
		net.WriteUInt(flags, 32)
		net.WriteUInt(nSurfaceProp --[[@as number]], 8)
		net.Send(filter)

		return
	end

	if pEntity.ImpactTrace and pEntity:ImpactTrace(_tr, iDamageType, "") == true then
		return
	end

	if swcs.fx.Impact(vecOrigin, vecStart, iMaterial, iDamageType, iHitbox, pEntity, tr, flags, trace_filter) then
		if tr.Fraction == 1 then
			return false
		end

		if ImpactStyle:GetInt() == 0 then
			if pEntity and pEntity.IsSWCSShield then
				local decalMat, exists = swcs.fx.GetImpactMaterial(MAT_SHIELD, nSurfaceProp, iDamageType)

				if exists and decalMat then
					data:SetFlags(IMPACT_NODECAL)
					util.DecalEx(decalMat, pEntity, tr.HitPos, tr.HitNormal, color_white, 1, 1)
				end

				swcs.fx.PlayImpactSound(pEntity, tr, vecOrigin, nSurfaceProp)
			end

			util.Effect("Impact_GMOD", data, not game.SinglePlayer())
			return
		end

		swcs.fx.PerformCustomEffects(vecOrigin, tr, vecShotDir, iMaterial, 1)
	end

	swcs.fx.PlayImpactSound(pEntity, tr, vecOrigin, nSurfaceProp)

	local clTr = util.TraceLine({
		start = vecStart,
		endpos = vecOrigin,
		mask = CS_MASK_SHOOT,
		filter = trace_filter,
		hitclientonly = true,
	})

	if clTr.Hit and clTr.Entity:EntIndex() == -1 then
		local hitEnt = clTr.Entity

		swcs.fx.PerformCustomEffects(clTr.HitPos, clTr, clTr.Normal, clTr.MatType, 1)
		swcs.fx.PlayImpactSound(hitEnt, clTr, clTr.HitPos, clTr.SurfaceProps)

		local phys = hitEnt:GetPhysicsObjectNum(clTr.PhysicsBone)
		if phys and phys:IsValid() then
			phys:Wake()
			phys:ApplyForceOffset(vecShotDir * 1200 * 2 --[[dmg:GetDamageForce() * 2, clTr.HitPos]], clTr.HitPos)

			if hitEnt:GetPhysicsObjectCount() > 1 and not hitEnt.m_bAlreadyShotThisFrame then -- if it's a ragdoll
				hitEnt.m_bAlreadyShotThisFrame = true

				timer.Simple(0, function()
					if hitEnt:IsValid() then
						hitEnt.m_bAlreadyShotThisFrame = false
					end
				end)
				local root = hitEnt:GetPhysicsObjectNum(0)

				if root:IsAsleep() then
					root:Wake()
					root:SetPos(root:GetPos() + Vector(0, 0, 1.5))
				end
			else
				local decalMat, exists = swcs.fx.GetImpactMaterial(clTr.MatType, clTr.SurfaceProps, iDamageType)
				if exists and decalMat then
					util.DecalEx(decalMat, hitEnt, clTr.HitPos, clTr.HitNormal, color_white, 1, 1)
				end

				if hitEnt:Health() ~= 0 then -- if it's a breakable
					local health = hitEnt:Health() - 30

					if health <= 0 then
						hitEnt:GibBreakClient(vector_origin)
						hitEnt:Remove()
					else
						hitEnt:SetHealth(health)
					end
				end
			end
		end
	end
end

-- KnifeSlash
function swcs.fx.KnifeSlashEffect(data, ply, trace_filter)
	local tr = {}
	local vecOrigin, vecStart, vecShotDir = Vector(), Vector(), Vector()
	local iMaterial, iDamageType, iHitbox = 0, 0, 0
	local nSurfaceProp = 0

	swcs.fx.CurrentPlayer = ply or NULL

	trace_filter = trace_filter or swcs.filter_IgnoreOwner(swcs.fx.CurrentPlayer, {})

	local pEntity
	---@diagnostic disable-next-line: cast-local-type
	pEntity, nSurfaceProp, iMaterial, iDamageType, iHitbox = swcs.fx.ParseImpactData(data, vecOrigin, vecStart, vecShotDir, trace_filter)

	if not pEntity or not isentity(pEntity) or (not pEntity:IsValid() and not pEntity:IsWorld()) then return end

	-- network to clients in PVS of impact point
	if SERVER then
		sound.EmitHint(SOUND_BULLET_IMPACT, vecOrigin, 400, 0.2, ply)
		local recv = RecipientFilter()
		recv:AddPAS(vecOrigin)
		if not game.SinglePlayer() then
			recv:RemovePlayer(swcs.fx.CurrentPlayer)
		end

		net.Start(TAG, true)
		net.WriteUInt(FX_IMPACT_KNIFE, 3)
		net.WriteEntity(swcs.fx.CurrentPlayer)
		net.WriteVector(vecOrigin)
		net.WriteVector(vecStart)
		net.WriteUInt(iDamageType --[[@as number]], 32)
		net.WriteUInt(iHitbox --[[@as number]], 32)
		net.WriteEntity(pEntity)
		net.WriteUInt(data:GetFlags(), 32)
		net.WriteUInt(nSurfaceProp --[[@as number]], 8)
		net.Send(recv)

		return
	end

	local mat = swcs.fx.GetImpactMaterial(iMaterial, nSurfaceProp, iDamageType)
	if not mat then return end

	if pEntity.ImpactTrace and pEntity:ImpactTrace(tr, iDamageType, "") == true then return end

	if swcs.fx.Impact(vecOrigin, vecStart, iMaterial, iDamageType, iHitbox, pEntity, tr, data:GetFlags(), trace_filter) then
		-- if ent is world or not a combat character, apply a decal
		if pEntity:IsWorld() or (pEntity:IsValid() and not (pEntity:IsPlayer() or pEntity:IsNPC() or pEntity:IsNextBot())) then
			local shotDir = vecOrigin - vecStart
			local flLength = shotDir:Length()
			shotDir:Normalize()

			local traceExt = vecStart + (shotDir * (flLength + 8))

			util.TraceLine({
				start = vecStart,
				endpos = traceExt,
				mask = MASK_SHOT,
				output = tr,
				filter = trace_filter,
			})

			local normal = Vector(tr.Normal)

			if tr.HitNormal.z == 0 then
				normal.z = 0
				normal:Normalize()
			end

			local planeRight = normal:Cross(-vector_up)
			local planeForward = planeRight:Cross(vector_up)

			local decalAngle = planeForward:AngleEx(vector_up)
			local decalNormal = decalAngle:Forward()

			if tr.HitNormal.z ~= 0 then
				decalNormal:Set(planeRight)
			end

			util.DecalEx(mat, pEntity, tr.HitPos, decalNormal, color_white, 1, 1)
		end

		if ImpactStyle:GetInt() == 0 then
			if data:GetEntity():IsPlayer() then
				data:SetDamageType(DMG_GENERIC)
			end

			data:SetFlags(IMPACT_NODECAL)
			util.Effect("Impact_GMOD", data, not game.SinglePlayer())

			--

			return
		end

		swcs.fx.PerformCustomEffects(vecOrigin, tr, vecShotDir, iMaterial, 1)
	end

	swcs.fx.PlayImpactSound(pEntity, tr, vecOrigin, nSurfaceProp, false)
end

-- BloodSprayCallback "csblood"
local blood_style = CLIENT and CreateClientConVar("swcs_fx_blood_style", "1", true, false, "Blood style to use for impacts. 0 = HL2/GMod, 1 = CS:GO", -1, 1)
function swcs.fx.BloodSpray(data, owner)
	local origin = data:GetOrigin()
	local normal = data:GetNormal()
	local flDamage = data:GetMagnitude()
	local flRawDamage = data:GetRadius()

	swcs.fx.CurrentPlayer = owner or NULL

	-- Use the new particle system
	local dir = Vector(normal) -- * RandomVector( -0.05f, 0.05f )
	local offset = origin + normal

	local vecAngles = dir:Angle()

	local pEffectName
	if flDamage > damage_impact_heavy:GetInt() then
		pEffectName = "blood_impact_heavy"
	elseif flDamage >= damage_impact_medium:GetInt() then
		pEffectName = "blood_impact_medium"
	elseif flDamage > 1 then
		pEffectName = "blood_impact_light"
	else
		pEffectName = "blood_impact_light_headshot"
	end

	-- network to clients in PVS of impact point
	if SERVER then
		local filter = RecipientFilter()
		filter:AddPAS(origin)

		net.Start(TAG, true)
		net.WriteUInt(FX_BLOODSPRAY, 3)
		net.WriteEntity(swcs.fx.CurrentPlayer)
		net.WriteVector(origin)
		net.WriteVector(normal)
		net.WriteFloat(flDamage)
		net.WriteFloat(data:GetRadius())
		net.WriteEntity(data:GetEntity())
		net.Send(filter)

		return
	end

	swcs.fx.TraceBleed(flRawDamage, dir * -1, {Entity = data:GetEntity(), HitPos = origin}, DMG_BULLET)

	local bUseCSBlood = blood_style and blood_style:GetBool()
	if bUseCSBlood and swcs.fx.ShouldShowBlood(BLOOD_COLOR_RED) then
		ParticleEffect(pEffectName, offset, vecAngles)
	elseif not bUseCSBlood and swcs.fx.ShouldShowBlood(BLOOD_COLOR_RED) then
		util.Effect("BloodImpact", data)
	end
end

local swcs_damage_viewpunch = CreateConVar("swcs_damage_viewpunch", "1", {FCVAR_REPLICATED}, "Whether or not to punch the view when getting hit.")
local mp_flinch_punch_scale = CreateConVar("swcs_flinch_punch_scale", "3", {FCVAR_REPLICATED, FCVAR_CHEAT}, "Scalar for first person view punch when getting hit.")

function swcs.fx.TraceAttack(pEnt, dmg, vecDir, tr)
	if not (pEnt:IsPlayer() or pEnt:IsNPC() or pEnt:IsNextBot()) then return end

	local iBloodColor = pEnt:GetBloodColor()

	local bShouldBleed = swcs.fx.ShouldShowBlood(iBloodColor)
	local bShouldSpark = false

	if SERVER and pEnt:GetInternalVariable("m_takedamage") ~= 2 then
		return
	end

	local flDamage = dmg:GetDamage()

	local punchAngle = Angle()
	local flAng

	local hitByGrenadeProjectile = false

	local flBodyDamageScale = 1 --(GetTeamNumber() == TEAM_CT) ? mp_damage_scale_ct_body.Getlocal() : mp_damage_scale_t_body.GetFloat();
	local flHeadDamageScale = 1 --(GetTeamNumber() == TEAM_CT) ? mp_damage_scale_ct_head.GetFloat() : mp_damage_scale_t_head.GetFloat();

	local flFlinchPunchScale = mp_flinch_punch_scale:GetFloat()
	local bShouldFlinch = swcs_damage_viewpunch:GetBool() and not dmg:IsDamageType(DMG_SLASH)

	if bit.band(dmg:GetDamageType(), DMG_SHOCK) ~= 0 then
		bShouldBleed = false
	elseif bit.band(dmg:GetDamageType(), DMG_BLAST) ~= 0 then
		if pEnt:IsPlayer() and pEnt:Armor() > 0 then
			bShouldBleed = false
		end

		-- punch view if we have no armor
		if SERVER and bShouldBleed and pEnt:IsPlayer() and bShouldFlinch then
			local wep = pEnt:GetActiveWeapon()
			if wep:IsValid() and wep.IsSWCSWeapon then
				punchAngle:Set(wep:GetRawAimPunchAngle())
			else
				punchAngle:Set(pEnt:GetViewPunchAngles())
			end

			punchAngle.x = flFlinchPunchScale * flDamage * -0.1

			if punchAngle.x < flFlinchPunchScale * -4 then
				punchAngle.x = flFlinchPunchScale * -4
			end

			if wep:IsValid() and wep.IsSWCSWeapon then
				wep:SetRawAimPunchAngle(punchAngle)
			elseif pEnt:IsPlayer() then
				pEnt:SetViewPunchAngles(punchAngle)
			end
		end
	elseif SERVER then
		local hVictimWep = NULL
		if pEnt:IsPlayer() then
			hVictimWep = pEnt:GetActiveWeapon()

			if hVictimWep:IsValid() and hVictimWep.IsSWCSWeapon then
				punchAngle:Set(hVictimWep:GetRawAimPunchAngle())
			else
				punchAngle:Set(pEnt:GetViewPunchAngles())
			end
		end

		if tr.HitGroup == HITGROUP_HEAD then
			if pEnt:IsPlayer() and pEnt:HasHelmet() and not hitByGrenadeProjectile then
				bShouldSpark = true
			end

			flDamage = flDamage * 4
			flDamage = flDamage * flHeadDamageScale

			if pEnt:IsPlayer() and not pEnt:HasHelmet() and bShouldFlinch then
				punchAngle.x = punchAngle.x + flFlinchPunchScale * flDamage * -0.5

				if punchAngle.x < flFlinchPunchScale * -12 then
					punchAngle.x = flFlinchPunchScale * -12
				end

				punchAngle.z = flFlinchPunchScale * flDamage * g_ursRandom:RandomFloat(-1, 1)

				if punchAngle.z < flFlinchPunchScale * -9 then
					punchAngle.z = flFlinchPunchScale * -9
				elseif punchAngle.z > flFlinchPunchScale * 9 then
					punchAngle.z = flFlinchPunchScale * 9
				end
			end
		elseif tr.HitGroup == HITGROUP_CHEST then
			flDamage = flDamage * 1.0
			flDamage = flDamage * flBodyDamageScale

			if bShouldFlinch then
				if pEnt:IsPlayer() and pEnt:Armor() <= 0 then
					flAng = -0.1
				else
					flAng = -0.005
				end

				punchAngle.x = punchAngle.x + flFlinchPunchScale * flDamage * flAng

				if punchAngle.x < flFlinchPunchScale * -4 then
					punchAngle.x = flFlinchPunchScale * -4
				end
			end
		elseif tr.HitGroup == HITGROUP_STOMACH then
			flDamage = flDamage * 1.25
			flDamage = flDamage * flBodyDamageScale

			if bShouldFlinch then
				if pEnt:IsPlayer() and pEnt:Armor() <= 0 then
					flAng = -0.1
				else
					flAng = -0.005
				end

				punchAngle.x = punchAngle.x + flFlinchPunchScale * flDamage * flAng

				if punchAngle.x < flFlinchPunchScale * -4 then
					punchAngle.x = flFlinchPunchScale * -4
				end
			end
		end

		if hVictimWep:IsValid() and hVictimWep.IsSWCSWeapon then
			hVictimWep:SetRawAimPunchAngle(punchAngle)
		elseif pEnt:IsPlayer() then
			pEnt:SetViewPunchAngles(punchAngle)
		end
	end

	if SERVER then
		if bShouldBleed and iBloodColor == BLOOD_COLOR_RED then
			local data = EffectData()
			data:SetOrigin(tr.HitPos)
			data:SetNormal(vecDir * -1)
			if SERVER then
				data:SetEntIndex(tr.Entity:IsValid() and tr.Entity:EntIndex() or 0)
			else
				data:SetEntity(tr.Entity)
			end
			data:SetMagnitude(flDamage)
			data:SetRadius(flDamage) -- store original damage for blood decals

			-- reduce blood effect if target has armor
			if pEnt:IsPlayer() and pEnt:Armor() > 0 then
				data:SetMagnitude(flDamage * 0.5)
			end

			-- reduce blood effect if target is hit in the helmet
			if tr.HitGroup == HITGROUP_HEAD and bShouldSpark then
				data:SetMagnitude(1)
			end

			swcs.fx.BloodSpray(data, dmg:GetAttacker())
		end

		local atk = dmg:GetAttacker()

		local filter = RecipientFilter()
		filter:AddPVS(tr.HitPos)

		if atk:IsPlayer() then
			filter:RemovePlayer(atk)
		end

		local bDamageTypeAppliesToArmor = (dmg:GetDamageType() == DMG_GENERIC) or
				(bit.band(dmg:GetDamageType(), bit.bor(DMG_BULLET, DMG_BLAST, DMG_CLUB, DMG_SLASH)) ~= 0)

		local bIsBullet = dmg:IsDamageType(DMG_BULLET)

		-- they hit a helmet
		if bIsBullet and tr.HitGroup == HITGROUP_HEAD then
			if bShouldSpark then
				-- show metal spark effect
				local angle = tr.HitNormal:Angle()

				swcs.SendSound("SWCS.DamageHelmet", tr.HitPos, filter)

				if atk:IsPlayer() then
					swcs.SendParticle("impact_helmet_headshot", tr.HitPos, angle, false, nil, nil, atk)
					swcs.SendSound("SWCS.DamageHelmetFeedback", tr.HitPos, atk)
				end

				ParticleEffect("impact_helmet_headshot", tr.HitPos, angle)
			else
				swcs.SendSound("SWCS.DamageHeadShot", tr.HitPos, filter)

				if atk:IsPlayer() then
					swcs.SendSound("SWCS.DamageHeadShotFeedback", tr.HitPos, atk)
				end
			end
		else
			if bDamageTypeAppliesToArmor and pEnt:IsPlayer() then
				if atk:IsPlayer() then
					filter:AddPlayer(atk)
				end

				if pEnt:Armor() > 0 then
					swcs.SendSound("SWCS.DamageKevlar", tr.HitPos, filter)
				else
					swcs.SendSound("Flesh.BulletImpact_CSGO", tr.HitPos, filter)
				end
			end
			--
		end
	end
end

function swcs.fx.TraceBleed(flDamage, vecDir, tr, bitsDamageType)
	local ent = tr.Entity
	if not ent:IsValid() then return end

	if ent:GetBloodColor() == DONT_BLEED or ent:GetBloodColor() == BLOOD_COLOR_MECH then return end

	if flDamage == 0 then return end

	if bit.band(bitsDamageType, bit.bor(DMG_CRUSH, DMG_BULLET, DMG_SLASH, DMG_BLAST, DMG_CLUB, DMG_AIRBOAT)) == 0 then
		return
	end

	-- make blood decal on the wall!
	local bloodTr = {}
	local vecTraceDir
	local flNoise = 0
	local cCount = 0

	if flDamage < 10 then
		flNoise = 0.1
		cCount = 1
	elseif flDamage < 25 then
		flNoise = 0.2
		cCount = 2
	else
		flNoise = 0.3
		cCount = 4
	end

	local flTraceDist = bit.band(bitsDamageType, DMG_AIRBOAT) ~= 0 and 384 or 172

	for i = 0, cCount do
		vecTraceDir = vecDir * -1 -- trace in the opposite direction the shot came from (the direction the shot is going)

		vecTraceDir.x = vecTraceDir.x + g_ursRandom:RandomFloat(-flNoise, flNoise)
		vecTraceDir.y = vecTraceDir.y + g_ursRandom:RandomFloat(-flNoise, flNoise)
		vecTraceDir.z = vecTraceDir.z + g_ursRandom:RandomFloat(-flNoise, flNoise)

		-- Don't bleed on grates.
		util.TraceLine({
			start = tr.HitPos,
			endpos = tr.HitPos + vecTraceDir * -flTraceDist,
			mask = bit.band(MASK_SOLID_BRUSHONLY, bit.bnot(CONTENTS_GRATE)),
			collisiongroup = COLLISION_GROUP_NONE,
			filter = {ent},
			output = bloodTr,
		})

		if bloodTr.Hit then
			swcs.fx.BloodDecalTrace(bloodTr, ent:GetBloodColor(), ent)
		end
	end
end

function swcs.fx.BloodDecalTrace(tr, bloodColor, srcEnt)
	if swcs.fx.ShouldShowBlood(bloodColor) then
		if bloodColor == BLOOD_COLOR_RED then
			util.Decal("Blood", tr.StartPos, tr.HitPos + tr.Normal, srcEnt)
		else
			util.Decal("YellowBlood", tr.StartPos, tr.HitPos + tr.Normal, srcEnt)
		end
	end
end

local violence_hblood = GetConVar("violence_hblood")
local violence_ablood = GetConVar("violence_ablood")
function swcs.fx.ShouldShowBlood(color)
	if color ~= DONT_BLEED then
		if color == BLOOD_COLOR_RED then
			return violence_hblood:GetBool()
		else
			return violence_ablood:GetBool()
		end
	end

	return false
end
