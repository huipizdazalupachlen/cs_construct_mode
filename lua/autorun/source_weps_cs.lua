local swcs = swcs or {}
_G.swcs = swcs

AddCSLuaFile("swcs/cl_rendertarget.lua")
AddCSLuaFile("swcs/cl_tab.lua")
AddCSLuaFile("swcs/cl_killicon.lua")
AddCSLuaFile("swcs/cl_matproxy.lua")
AddCSLuaFile("swcs/cl_hud.lua")

include("swcs/sh_cvars.lua")
include("swcs/sh_surfaces.lua")
include("swcs/sh_util.lua")

include("swcs/sh_crosshaircode.lua")

include("swcs/classes/sh_timer.lua")
include("swcs/classes/sh_random.lua")

include("swcs/sh_player.lua")
include("swcs/sh_knives.lua")
include("swcs/sh_grenades.lua")
include("swcs/sh_effects.lua")
include("swcs/sh_damage.lua")
include("swcs/sh_econ.lua")

-- NOTE: https://wiki.facepunch.com/gmod/Global.DeriveGamemode
local function GM_IsBasedOn(name, base)
	local GM1 = gamemode.Get(name)
	if not GM1 then return false end
	if GM1.DerivedFrom == name then return false end

	if GM1.DerivedFrom == base then return true end
	return GM_IsBasedOn(GM1.DerivedFrom, base)
end

local strActiveGamemode = engine.ActiveGamemode()
if strActiveGamemode == "terrortown" then
	include("swcs/sh_ttt.lua")
elseif strActiveGamemode == "sandbox" or GM_IsBasedOn(strActiveGamemode, "sandbox") then
	swcs.InSandbox = true
end

if CLIENT then
	include("swcs/cl_rendertarget.lua")
	include("swcs/cl_tab.lua")
	include("swcs/cl_killicon.lua")
	include("swcs/cl_matproxy.lua")
	include("swcs/cl_hud.lua")
end

if CLIENT then
	swcs.HandsMap = {
		[0] = {
			name = "GMod Hands",
		},
		{
			name = "Bare Hands",
			model = Model("models/weapons/v_models/csgo/arms/bare/v_bare_hands.mdl"),
		},
		{
			name = "Anarchist Gloves",
			model = Model("models/weapons/v_models/csgo/arms/anarchist/v_glove_anarchist.mdl"),
		},
		{
			name = "Ghost Hands",
			model = Model("models/weapons/v_models/csgo/arms/ghost/v_ghost_hands.mdl"),
		},
		{
			name = "Bloodhound Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_bloodhound/v_glove_bloodhound.mdl"),
		},
		{
			name = "Bloodhound Gloves (Broken Fang)",
			model = Model("models/weapons/v_models/csgo/arms/glove_bloodhound/v_glove_bloodhound_brokenfang.mdl"),
		},
		{
			name = "Bloodhound Gloves (Hydra)",
			model = Model("models/weapons/v_models/csgo/arms/glove_bloodhound/v_glove_bloodhound_hydra.mdl"),
		},
		{
			name = "Fingerless Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_fingerless/v_glove_fingerless.mdl"),
		},
		{
			name = "Full-Finger Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_fullfinger/v_glove_fullfinger.mdl"),
		},
		{
			name = "Leather Hand-Wrap Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_handwrap_leathery/v_glove_handwrap_leathery.mdl"),
		},
		{
			name = "Hard-Knuckle Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_hardknuckle/v_glove_hardknuckle.mdl"),
		},
		{
			name = "Hard-Knuckle Gloves (Black)",
			model = Model("models/weapons/v_models/csgo/arms/glove_hardknuckle/v_glove_hardknuckle_black.mdl"),
		},
		{
			name = "Hard-Knuckle Gloves (Blue)",
			model = Model("models/weapons/v_models/csgo/arms/glove_hardknuckle/v_glove_hardknuckle_blue.mdl"),
		},
		{
			name = "Motorcycle Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_motorcycle/v_glove_motorcycle.mdl"),
		},
		{
			name = "Slick Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_slick/v_glove_slick.mdl"),
		},
		{
			name = "Specialist Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_specialist/v_glove_specialist.mdl"),
		},
		{
			name = "Sporty Gloves",
			model = Model("models/weapons/v_models/csgo/arms/glove_sporty/v_glove_sporty.mdl"),
		},
		{
			name = "[Old] CT Default (Seal Team 6)",
			model = Model("models/weapons/v_models/csgo/arms/ct_arms.mdl"),
		},
		{
			name = "[Old] FBI",
			model = Model("models/weapons/v_models/csgo/arms/ct_arms_fbi.mdl"),
		},
		{
			name = "[Old] GIGN",
			model = Model("models/weapons/v_models/csgo/arms/ct_arms_gign.mdl"),
		},
		{
			name = "[Old] GSG9",
			model = Model("models/weapons/v_models/csgo/arms/ct_arms_gsg9.mdl"),
		},
		{
			name = "[Old] IDF",
			model = Model("models/weapons/v_models/csgo/arms/ct_arms_idf.mdl"),
		},
		{
			name = "[Old] SAS",
			model = Model("models/weapons/v_models/csgo/arms/ct_arms_sas.mdl"),
		},
		{
			name = "[Old] Seal Team 6",
			model = Model("models/weapons/v_models/csgo/arms/ct_arms_st6.mdl"),
		},
		{
			name = "[Old] SWAT",
			model = Model("models/weapons/v_models/csgo/arms/ct_arms_swat.mdl"),
		},
		{
			name = "[Old] T Default (Leet)",
			model = Model("models/weapons/v_models/csgo/arms/t_arms.mdl"),
		},
		{
			name = "[Old] Anarchist",
			model = Model("models/weapons/v_models/csgo/arms/t_arms_anarchist.mdl"),
		},
		{
			name = "[Old] Balkan",
			model = Model("models/weapons/v_models/csgo/arms/t_arms_balkan.mdl"),
		},
		{
			name = "[Old] Leet",
			model = Model("models/weapons/v_models/csgo/arms/t_arms_leet.mdl"),
		},
		{
			name = "[Old] Phoenix",
			model = Model("models/weapons/v_models/csgo/arms/t_arms_phoenix.mdl"),
		},
		{
			name = "[Old] Pirate",
			model = Model("models/weapons/v_models/csgo/arms/t_arms_pirate.mdl"),
		},
		{
			name = "[Old] Professional",
			model = Model("models/weapons/v_models/csgo/arms/t_arms_professional.mdl"),
		},
		{
			name = "[Old] Separatist",
			model = Model("models/weapons/v_models/csgo/arms/t_arms_separatist.mdl"),
		},
	}
	swcs.SleevesMap = {
		[0] = {
			name = "No Sleeves",
		},
		{
			name = "Anarchist",
			model = Model("models/weapons/v_models/csgo/arms/anarchist/v_sleeve_anarchist.mdl"),
		},

		-- Balkan
		{
			name = "Old Balkan",
			model = Model("models/weapons/v_models/csgo/arms/balkan/v_sleeve_balkan.mdl"), -- old balkan
		},
		{
			name = "Sabre Dragomir (Brown)",
			model = Model("models/weapons/v_models/csgo/arms/balkan/v_sleeve_balkan_v2_variantf.mdl"), -- new balkan (variant 1)
		},
		{
			name = "Sabre Rezen (Maroon)",
			model = Model("models/weapons/v_models/csgo/arms/balkan/v_sleeve_balkan_v2_variantg.mdl"), -- new balkan (variant 2)
		},
		{
			name = "Sabre Romanov",
			model = Model("models/weapons/v_models/csgo/arms/balkan/v_sleeve_balkan_v2_varianth.mdl"), -- new balkan (variant 3)
		},
		{
			name = "Sabre Blackwolf",
			model = Model("models/weapons/v_models/csgo/arms/balkan/v_sleeve_balkan_v2_variantj.mdl"), -- new balkan (variant 4)
		},

		-- Heavies
		{
			name = "Heavy CT",
			model = Model("models/weapons/v_models/csgo/arms/ctm_heavy/v_sleeve_ctm_heavy.mdl"),
		},
		{
			name = "Heavy T",
			model = Model("models/weapons/v_models/csgo/arms/phoenix_heavy/v_sleeve_phoenix_heavy.mdl"),
		},

		-- FBI
		{
			name = "FBI Agent",
			model = Model("models/weapons/v_models/csgo/arms/fbi/v_sleeve_fbi.mdl"), -- FBI, FBI Variant A, C, D, E
		},
		{
			name = "FBI Ava",
			model = Model("models/weapons/v_models/csgo/arms/fbi/v_sleeve_fbi_dark.mdl"), -- FBI Variant B
		},
		{
			name = "FBI Markus",
			model = Model("models/weapons/v_models/csgo/arms/fbi/v_sleeve_fbi_green.mdl"), -- FBI variant G
		},
		{
			name = "FBI Operator",
			model = Model("models/weapons/v_models/csgo/arms/fbi/v_sleeve_fbi_light_green.mdl"), -- FBI variant F
		},

		-- hello ct
		{
			name = "GIGN",
			model = Model("models/weapons/v_models/csgo/arms/gign/v_sleeve_gign.mdl"),
		},
		{
			name = "GSG9",
			model = Model("models/weapons/v_models/csgo/arms/gsg9/v_sleeve_gsg9.mdl"),
		},
		{
			name = "IDF",
			model = Model("models/weapons/v_models/csgo/arms/idf/v_sleeve_idf.mdl"),
		},

		-- DZ sleeve
		{
			name = "Dangerzone Jumpsuit",
			model = Model("models/weapons/v_models/csgo/arms/jumpsuit/v_sleeve_jumpsuit.mdl"),
		},

		{
			name = "Pirate's Watch",
			model = Model("models/weapons/v_models/csgo/arms/pirate/v_pirate_watch.mdl"),
		},

		-- "Professional"
		{
			name = "Professional Agents",
			model = Model("models/weapons/v_models/csgo/arms/professional/v_sleeve_professional.mdl"), -- Variant I, Variant J
		},

		-- SAS
		{
			name = "SAS Agent",
			model = Model("models/weapons/v_models/csgo/arms/sas/v_sleeve_sas.mdl"),
		},
		{
			name = "SAS Officer",
			model = Model("models/weapons/v_models/csgo/arms/sas/v_sleeve_sas_ukmtp.mdl"), -- Variant F
		}, -- TODO - varG to be added (NZSAS Officer)

		-- Separatist sleeve
		{
			name = "Separatist",
			model = Model("models/weapons/v_models/csgo/arms/separatist/v_sleeve_separatist.mdl"),
		},

		-- Seal Team 6
		{
			name = "Seal Team 6 (Flektarn)",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_flektarn.mdl"), -- After 3 hours of trying to identify what agent this is i can safely say that i have no clue what valve is smoking but i need some
		},
		{
			name = "Seal Team 6 Agent (Green)",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_green.mdl"), -- Default 2 (?)
		},
		{
			name = "Seal Team 6 Agent (Beige)",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_st6.mdl"), -- Default
		},
		{
			name = "NSWC Seal Soldier",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_st6_v2_variante.mdl"), -- Variant E
		},
		{
			name = "NSWC Seal Buckshot (Green)",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_st6_v2_variantg.mdl"), -- Variant G
		},
		{
			name = "KSK Commando",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_st6_v2_variantk.mdl"), --  Variant K[sk] - Not a st6 !!!
		},
		{
			name = "USAF TACP McCoy",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_st6_v2_variantm.mdl"), -- Variant M
		},
		{
			name = "USAF TACP",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_usaf.mdl"), -- Unused(???)
		},

		-- SWAT Team
		{
			name = "SWAT Agent (Black)",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat.mdl"),
		},
		{
			name = "SWAT Agent (Blue)",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_blue.mdl"),
		},
		{
			name = "SWAT Agent (Green)",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_green.mdl"),
		},

		-- i just got out the hospital
		{
			name = "Wristband",
			model = Model("models/weapons/v_models/csgo/arms/wristband/v_sleeve_wristband.mdl"),
		},

		{
			name = "SEAL Frogman",
			model = Model("models/weapons/v_models/csgo/arms/diver/v_sleeve_diver_wetsuit.mdl"),
		},

		{
			name = "FBI Syfers",
			model = Model("models/weapons/v_models/csgo/arms/fbi/v_sleeve_fbi_gray.mdl"),
		},

		{
			name = "Sabre Rezen (Orange)",
			model = Model("models/weapons/v_models/csgo/arms/balkan/v_sleeve_balkan_v2_variantk.mdl"),
		},
		{
			name = "Sabre Dragomir (Beige)",
			model = Model("models/weapons/v_models/csgo/arms/balkan/v_sleeve_balkan_v2_variantl.mdl"),
		},

		{
			name = "Gendarmerie Agent",
			model = Model("models/weapons/v_models/csgo/arms/gendarmerie/v_sleeve_gendarmerie.mdl"),
		},
		{
			name = "Gendarmerie Rouchard",
			model = Model("models/weapons/v_models/csgo/arms/gendarmerie/v_sleeve_gendarmerie_variantc.mdl"),
		},

		{
			name = "Darryl's Accessories (Gold)",
			model = Model("models/weapons/v_models/csgo/arms/professional/v_professional_watch.mdl"),
		},
		{
			name = "Darryl's Accessories (Silver)",
			model = Model("models/weapons/v_models/csgo/arms/professional/v_professional_watch_silver.mdl"),
		},

		{
			name = "NSWC SEAl Buckshot (Blue)",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_st6_v2_variantj.mdl"),
		},
		{
			name = "TACP Calvary McCoy",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_st6_v2_variantl.mdl"),
		},
		{
			name = "Brazilian Tenente",
			model = Model("models/weapons/v_models/csgo/arms/st6/v_sleeve_st6_v2_variantn.mdl"),
		},

		{
			name = "SWAT Farlow (Green)",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_breecher.mdl"),
		},
		{
			name = "SWAT Farlow (Forest Camo)",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_breecher_variantk.mdl"),
		},
		{
			name = "SWAT Bio-haz",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_gasmask_blue.mdl"),
		},
		{
			name = "SWAT Chem-haz",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_gasmask_green.mdl"),
		},
		{
			name = "SWAT Bombson",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_generic.mdl"),
		},
		{
			name = "SWAT Jamison",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_leader.mdl"),
		},
		{
			name = "SWAT Kask",
			model = Model("models/weapons/v_models/csgo/arms/swat/v_sleeve_swat_medic.mdl"),
		},
	}

	local swcs_hands = CreateClientConVar("swcs_hands", "0", nil, nil, "Sets the model of your hands when holding a swcs weapon\n(0 = GMod hands)")
	local swcs_hands_skin = CreateClientConVar("swcs_hands_skin", "0", nil, nil, "Sets the skin tone of your hands when using CS:GO hands")
	local swcs_sleeves = CreateClientConVar("swcs_sleeves", "0", nil, nil, "Sets the sleeves of your hands when holding a swcs weapon (requires swcs_hands > 0)")

	local csgo_hands = NULL
	local csgo_sleeves = NULL

	-- handle user's hands
	hook.Add("PreDrawViewModel", "swcs.hands", function(vm, ply, wep)
		if not wep.IsSWCSWeapon then return end

		local iCvarHands = swcs_hands:GetInt()
		wep.UseHands = iCvarHands <= 0

		local bFlipVM = wep.ViewModelFlip

		if iCvarHands <= 0 then return end

		local tHandsData = swcs.HandsMap[iCvarHands]
		if not tHandsData then return end

		local strHandsModel = tHandsData.model

		if not IsValid(csgo_hands) and strHandsModel ~= "" then
			csgo_hands = ClientsideModel(strHandsModel, RENDERGROUP_VIEWMODEL)
			csgo_hands:SetNoDraw(true)
			csgo_hands:SetParent(vm)
			csgo_hands:AddEffects(EF_BONEMERGE)
			csgo_hands:AddEffects(EF_BONEMERGE_FASTCULL)
		end

		-- if model change
		if csgo_hands:GetModel() ~= strHandsModel then
			csgo_hands:SetModel(strHandsModel)
		end

		-- full update/lag can cause this
		if csgo_hands:GetParent() ~= vm then
			csgo_hands:SetParent(vm)
		end

		-- skin change
		if csgo_hands:GetSkin() ~= swcs_hands_skin:GetInt() then
			csgo_hands:SetSkin(swcs_hands_skin:GetInt())
		end

		if bFlipVM then
			render.CullMode(MATERIAL_CULLMODE_CW)
		end

		-- sleeves!
		local iCvarSleeves = swcs_sleeves:GetInt()
		local tSleevesData = swcs.SleevesMap[iCvarSleeves]
		if iCvarSleeves > 0 and tSleevesData then
			local strSleevesModel = tSleevesData.model

			if not IsValid(csgo_sleeves) then
				csgo_sleeves = ClientsideModel(strSleevesModel, RENDERGROUP_VIEWMODEL)
				csgo_sleeves:SetNoDraw(true)
				csgo_sleeves:SetParent(vm)
				csgo_sleeves:AddEffects(EF_BONEMERGE)
				csgo_sleeves:AddEffects(EF_BONEMERGE_FASTCULL)
			end

			if csgo_sleeves:GetModel() ~= strSleevesModel then
				csgo_sleeves:SetModel(strSleevesModel)
			end

			if csgo_sleeves:GetParent() ~= vm then
				csgo_sleeves:SetParent(vm)
			end

			csgo_sleeves:DrawModel()
		end

		csgo_hands:DrawModel()

		if bFlipVM then
			render.CullMode(MATERIAL_CULLMODE_CCW)
		end

		render.RenderFlashlights(function()
			if bFlipVM then
				render.CullMode(MATERIAL_CULLMODE_CW)
			end

			if iCvarSleeves > 0 and csgo_sleeves:IsValid() then
				csgo_sleeves:DrawModel()
			end

			if csgo_hands:IsValid() then
				csgo_hands:DrawModel()
			end

			if bFlipVM then
				render.CullMode(MATERIAL_CULLMODE_CCW)
			end
		end)
	end)

	--CreateClientConVar("swcs_classic_vm_fov", "0", nil, nil, "Toggles between 68 FOV (0) and 54 FOV (1) for viewmodels")
	CreateClientConVar("swcs_viewmodel_fov", "68.0", nil, nil, "")
end

--local PLAYER_FALL_PUNCH_THRESHOLD = 350
swcs.PLAYER_FATAL_FALL_SPEED = 922.5 -- hl2 == 922.5f, csgo == 1024
function swcs._CheckFalling(ply, wep)
	local flFallVel = ply.m_flFallVelocity or 0

	-- this function really deals with landing, not falling, so ignore everything else
	if ply:GetGroundEntity() == NULL or flFallVel < 0 then return end

	if flFallVel > 16.0 and flFallVel <= swcs.PLAYER_FATAL_FALL_SPEED then
		-- punch view when we hit the ground
		local punchAngle = wep:GetUninterpolatedViewPunchAngle()
		punchAngle.x = (flFallVel * 0.001)

		if punchAngle.x < 0.75 then
			punchAngle.x = 0.75
		end

		wep:SetViewPunchAngle(punchAngle)
	end

	if wep.OnLand then
		wep:OnLand(flFallVel)
	end

	ply.m_flFallVelocity = 0
end
local CheckFalling = swcs._CheckFalling

-- weapon slowdown & defusing c4 freeze
local swcs_view_dip_anim = CLIENT and CreateClientConVar("swcs_view_dip_anim", "1")
hook.Add("SetupMove", "swcs.movement", function(ply, move, cmd)
	if not ply:IsValid() then return end

	local plyTable = ply:GetTable()

	if not plyTable.m_flFallVelocity then
		plyTable.m_flFallVelocity = 0
	end

	local wep = ply:GetActiveWeapon()

	-- done to fix gmod's shoot pos being behind 1 tick on client
	plyTable.m_vSavedShootPos = ply:GetShootPos()

	if ply:GetNWBool("m_bIsDefusing", false) then
		move:SetMaxClientSpeed(1)
		move:SetMaxSpeed(1)

		-- remove IN_JUMP
		move:SetButtons(bit.band(move:GetButtons(), bit.bnot(IN_JUMP)))
	end

	if wep:IsValid() then
		local wepTable = wep:GetTable()
		if wepTable.IsSWCSWeapon then
			local flMaxSpeed = wepTable.GetMaxSpeed and wepTable.GetMaxSpeed(wep) or 250
			local mult = flMaxSpeed / 250
			if mult < 0 then
				mult = 1
			end

			if cmd:KeyDown(IN_ATTACK) and wepTable.GetShotsFired(wep) >= 1 and wep:Clip1() > 0 then
				mult = mult * wepTable.GetAttackMovespeedFactor(wep)
			end

			-- freeze
			if flMaxSpeed == 0 then
				move:SetMaxClientSpeed(1)
				move:SetMaxSpeed(1)
			else
				move:SetMaxClientSpeed(move:GetMaxClientSpeed() * mult)
				move:SetMaxSpeed(move:GetMaxSpeed() * mult)
			end

			CheckFalling(ply, wep)
			local flFallVel = -move:GetVelocity().z

			plyTable.m_flFallVelocity = flFallVel

			-- if we just landed, dip the player's view
			local flOldFallVel = plyTable.m_flOldFallVelocity or 0

			if
				CLIENT
				and IsFirstTimePredicted()
				and not plyTable.m_bInLanding
				and swcs_view_dip_anim and swcs_view_dip_anim:GetBool()
				and ply:OnGround()
				and flFallVel <= 0.1
				and flOldFallVel > 10.0
				and flOldFallVel <= swcs.PLAYER_FATAL_FALL_SPEED
			then
				plyTable.m_bInLanding = true
				plyTable.m_flLandingTime = UnPredictedCurTime()
				plyTable.m_flFallDipVelocity = flOldFallVel
			end

			if wepTable.OnMove then
				wepTable.OnMove(wep, ply, move, cmd, wepTable)
			end

			plyTable.m_flOldFallVelocity = flFallVel

			if SERVER then
				local bEnableZoom = ply:GetInfoNum("swcs_enable_zoom", 0) > 0
				local bContextualZoom = ply:GetInfoNum("swcs_contextual_zoom", 1) > 0

				if not bEnableZoom or (bContextualZoom and wepTable.GetHasZoom(wep)) or wepTable.IsZoomed(wep) then
					if plyTable.swcs_canzoom == nil then
						plyTable.swcs_canzoom = ply:GetCanZoom()
					end

					ply:SetCanZoom(false)
				elseif plyTable.swcs_canzoom ~= nil then
					ply:SetCanZoom(plyTable.swcs_canzoom)
					plyTable.swcs_canzoom = nil
				end
			end
		else
			-- restore & set nil when we switch off a swcs weapon
			if SERVER and plyTable.swcs_canzoom ~= nil then
				ply:SetCanZoom(plyTable.swcs_canzoom)
				plyTable.swcs_canzoom = nil
			end
		end
	end
end)

-- third person recoil
hook.Add("UpdateAnimation", "swcs.ply_anim", function(ply)
	local wep = ply:GetActiveWeapon()
	if wep.IsSWCSWeapon then
		local flEyePitch = ply:GetPoseParameter("aim_pitch")
		if CLIENT then
			local iPoseParam = ply:LookupPoseParameter("aim_pitch")

			if iPoseParam ~= -1 then
				local flMin, flMax = ply:GetPoseParameterRange(iPoseParam)
				flEyePitch = math.Remap(flEyePitch, 0, 1, flMin, flMax)
			end
		end

		flEyePitch = math.NormalizeAngle(flEyePitch + wep:GetNW2Float("m_flThirdpersonRecoil", 0))
		ply:SetPoseParameter("aim_pitch", flEyePitch)
	end
end)

if SERVER then
	resource.AddSingleFile("resource/localization/en/swcs.properties")
	resource.AddWorkshop("2193997180")

	local swcs_helmet_on_spawn = GetConVar("swcs_helmet_on_spawn")
	local swcs_defuser_on_spawn = GetConVar("swcs_defuser_on_spawn")

	hook.Add("PlayerSpawn", "swcs.playerspawn", function(ply, transition)
		-- map transition SWEP:Initialize()
		if transition then
			for _, w in ipairs(ply:GetWeapons()) do
				if w.IsSWCSWeapon then
					w:Initialize(false, true)
				end
			end
		end

		if swcs_helmet_on_spawn:GetBool() then
			ply:GiveHelmet()
		end
		if swcs_defuser_on_spawn:GetBool() then
			ply:GiveDefuser()
		end
	end)
end
