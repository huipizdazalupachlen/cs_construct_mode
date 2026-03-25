hook.Add("InitPostEntity", "swcs_cs2_models", function()

	local akadaka = weapons.GetStored("weapon_swcs_ak47")
	akadaka.ViewModel = Model"models/weapons/cs2/v_rif_ak47_hd.mdl"
	akadaka.WorldModel = Model"models/weapons/cs2/w_rif_ak47_hd.mdl"
	
	local awg = weapons.GetStored("weapon_swcs_aug")
	awg.ViewModel = Model"models/weapons/cs2/v_rif_aug_hd_correct.mdl"
	awg.WorldModel = Model"models/weapons/cs2/w_rif_aug_hd.mdl"
	awg.ItemAttributes["aimsight lens mask"] = "models/weapons/cs2/v_rif_aug_scopelensmask_hd.mdl"
	awg.ItemAttributes["aimsight eye pos"] = "-1.58 -3.64 -0.27"
	awg.ItemAttributes["aimsight pivot angle"] = "0.78 -0.1 -0.03"
	
	local awp = weapons.GetStored("weapon_swcs_awp")
	awp.ViewModel = Model"models/weapons/cs2/v_snip_awp_hd.mdl"
	awp.WorldModel = Model"models/weapons/cs2/w_snip_awp_hd.mdl"
	
	local cz75 = weapons.GetStored("weapon_swcs_cz75")
	cz75.ViewModel = Model"models/weapons/cs2/v_pist_cz_75_hd.mdl"
	cz75.WorldModel = Model"models/weapons/cs2/w_pist_cz_75_hd.mdl"

	local degala = weapons.GetStored("weapon_swcs_deagle")
	degala.ViewModel = Model"models/weapons/cs2/v_pist_deagle_hd.mdl"
	degala.WorldModel = Model"models/weapons/cs2/w_pist_deagle_hd.mdl"
	
	local elite = weapons.GetStored("weapon_swcs_elite")
	elite.ViewModel = Model"models/weapons/cs2/v_pist_elite_hd.mdl"
	elite.WorldModel = Model"models/weapons/cs2/w_pist_elite_hd.mdl"
	
	local famas = weapons.GetStored("weapon_swcs_famas")
	famas.ViewModel = Model"models/weapons/cs2/v_rif_famas_hd.mdl"
	famas.WorldModel = Model"models/weapons/cs2/w_rif_famas_hd.mdl"
	
	local fiveseven = weapons.GetStored("weapon_swcs_fiveseven")
	fiveseven.ViewModel = Model"models/weapons/cs2/v_pist_fiveseven_hd.mdl"
	fiveseven.WorldModel = Model"models/weapons/cs2/w_pist_fiveseven_hd.mdl"
	
	local g3 = weapons.GetStored("weapon_swcs_g3sg1")
	g3.ViewModel = Model"models/weapons/cs2/v_snip_g3sg1_hd.mdl"
	g3.WorldModel = Model"models/weapons/cs2/w_snip_g3sg1_hd.mdl"
	
	local galil = weapons.GetStored("weapon_swcs_galilar")
	galil.ViewModel = Model"models/weapons/cs2/v_rif_galilar_hd.mdl"
	galil.WorldModel = Model"models/weapons/cs2/w_rif_galilar_hd.mdl"
	
	local gock = weapons.GetStored("weapon_swcs_glock")
	gock.ViewModel = Model"models/weapons/cs2/v_pist_glock18_hd.mdl"
	gock.WorldModel = Model"models/weapons/cs2/w_pist_glock18_hd.mdl"

	local m249 = weapons.GetStored("weapon_swcs_m249")
	m249.ViewModel = Model"models/weapons/cs2/v_mach_m249para_hd.mdl"
	m249.WorldModel = Model"models/weapons/cs2/w_mach_m249_hd.mdl"
	
	local m4a4 = weapons.GetStored("weapon_swcs_m4a1")
	m4a4.ViewModel = Model"models/weapons/cs2/v_rif_m4a1_hd.mdl"
	m4a4.WorldModel = Model"models/weapons/cs2/w_rif_m4a1_hd.mdl"
	
	local m4a1 = weapons.GetStored("weapon_swcs_m4a1_silencer")
	m4a1.ViewModel = Model"models/weapons/cs2/v_rif_m4a1_s_hd.mdl"
	m4a1.WorldModel = Model"models/weapons/cs2/w_rif_m4a1_s_hd.mdl"
	
	local mac10 = weapons.GetStored("weapon_swcs_mac10")
	mac10.ViewModel = Model"models/weapons/cs2/v_smg_mac10_hd.mdl"
	mac10.WorldModel = Model"models/weapons/cs2/w_smg_mac10_hd.mdl"
	
	local swag7 = weapons.GetStored("weapon_swcs_mag7")
	swag7.ViewModel = Model"models/weapons/cs2/v_shot_mag7_hd.mdl"
	swag7.WorldModel = Model"models/weapons/cs2/w_shot_mag7_hd.mdl"
	
	local mp5sd = weapons.GetStored("weapon_swcs_mp5sd")
	mp5sd.ViewModel = Model"models/weapons/cs2/v_smg_mp5sd_hd.mdl"
	mp5sd.WorldModel = Model"models/weapons/cs2/w_smg_mp5sd_hd.mdl"
	
	local mp7 = weapons.GetStored("weapon_swcs_mp7")
	mp7.ViewModel = Model"models/weapons/cs2/v_smg_mp7_hd.mdl"
	mp7.WorldModel = Model"models/weapons/cs2/w_smg_mp7_hd.mdl"
	
	local mp9 = weapons.GetStored("weapon_swcs_mp9")
	mp9.ViewModel = Model"models/weapons/cs2/v_smg_mp9_hd.mdl"
	mp9.WorldModel = Model"models/weapons/cs2/w_smg_mp9_hd.mdl"
	
	local negev = weapons.GetStored("weapon_swcs_negev")
	negev.ViewModel = Model"models/weapons/cs2/v_mach_negev_hd.mdl"
	negev.WorldModel = Model"models/weapons/cs2/w_mach_negev_hd.mdl"
	
	local nogla = weapons.GetStored("weapon_swcs_nova")
	nogla.ViewModel = Model"models/weapons/cs2/v_shot_nova_hd.mdl"
	nogla.WorldModel = Model"models/weapons/cs2/w_shot_nova_hd.mdl"
	
	local piss90 = weapons.GetStored("weapon_swcs_p90")
	piss90.ViewModel = Model"models/weapons/cs2/v_smg_p90_hd.mdl"
	piss90.WorldModel = Model"models/weapons/cs2/w_smg_p90_hd.mdl"
	
	local piss250 = weapons.GetStored("weapon_swcs_p250")
	piss250.ViewModel = Model"models/weapons/cs2/v_pist_p250_hd.mdl"
	piss250.WorldModel = Model"models/weapons/cs2/w_pist_p250_hd.mdl"
	
	local piss2000 = weapons.GetStored("weapon_swcs_hkp2000")
	piss2000.ViewModel = Model"models/weapons/cs2/v_pist_hkp2000_hd.mdl"
	piss2000.WorldModel = Model"models/weapons/cs2/w_pist_hkp2000_hd.mdl"
	
	local bizon = weapons.GetStored("weapon_swcs_bizon")
	bizon.ViewModel = Model"models/weapons/cs2/v_smg_bizon_hd.mdl"
	bizon.WorldModel = Model"models/weapons/cs2/w_smg_bizon_hd.mdl"
	
	local bolber = weapons.GetStored("weapon_swcs_revolver")
	bolber.ViewModel = Model"models/weapons/cs2/v_pist_revolver_hd.mdl"
	bolber.WorldModel = Model"models/weapons/cs2/w_pist_revolver_hd.mdl"
	
	local sawedoff = weapons.GetStored("weapon_swcs_sawedoff")
	sawedoff.ViewModel = Model"models/weapons/cs2/v_shot_sawedoff_hd.mdl"
	sawedoff.WorldModel = Model"models/weapons/cs2/w_shot_sawedoff_hd.mdl"
	
	local scar = weapons.GetStored("weapon_swcs_scar20")
	scar.ViewModel = Model"models/weapons/cs2/v_snip_scar20_hd.mdl"
	scar.WorldModel = Model"models/weapons/cs2/w_snip_scar20_hd.mdl"
	
	local sg556 = weapons.GetStored("weapon_swcs_sg556")
	sg556.ViewModel = Model"models/weapons/cs2/v_rif_sg556_hd.mdl"
	sg556.WorldModel = Model"models/weapons/cs2/w_rif_sg556_hd.mdl"
	
	local scout = weapons.GetStored("weapon_swcs_ssg08")
	scout.ViewModel = Model"models/weapons/cs2/v_snip_ssg08_hd.mdl"
	scout.WorldModel = Model"models/weapons/cs2/w_snip_ssg08_hd.mdl"
	
	local tec9 = weapons.GetStored("weapon_swcs_tec9")
	tec9.ViewModel = Model"models/weapons/cs2/v_pist_tec9_hd.mdl"
	tec9.WorldModel = Model"models/weapons/cs2/w_pist_tec9_hd.mdl"

	local oospa = weapons.GetStored("weapon_swcs_usp_silencer")
	oospa.ViewModel = Model"models/weapons/cs2/v_pist_usps_hd.mdl"
	oospa.WorldModel = Model"models/weapons/cs2/w_pist_223_hd.mdl"
	
	local xm1014 = weapons.GetStored("weapon_swcs_xm1014")
	xm1014.ViewModel = Model"models/weapons/cs2/v_shot_xm1014_hd.mdl"
	xm1014.WorldModel = Model"models/weapons/cs2/w_shot_xm1014_hd.mdl"
	
	local ump45 = weapons.GetStored("weapon_swcs_ump45")
	ump45.ViewModel = Model"models/weapons/cs2/v_smg_ump45_hd.mdl"
	ump45.WorldModel = Model"models/weapons/cs2/w_smg_ump45_hd.mdl"
	
	local zeus = weapons.GetStored("weapon_swcs_taser")
	zeus.ViewModel = Model"models/weapons/cs2/v_eq_taser_hd.mdl"
	zeus.WorldModel = Model"models/weapons/cs2/w_eq_taser_hd.mdl"
	
	local decoy = weapons.GetStored("weapon_swcs_decoy")
	decoy.ViewModel = Model"models/weapons/cs2/v_eq_decoy_hd.mdl"
	decoy.WorldModel = Model"models/weapons/cs2/w_eq_decoy_hd.mdl"
	
	local flash = weapons.GetStored("weapon_swcs_flashbang")
	flash.ViewModel = Model"models/weapons/cs2/v_eq_flashbang_hd.mdl"
	flash.WorldModel = Model"models/weapons/cs2/w_eq_flashbang_hd.mdl"
	
	local frag = weapons.GetStored("weapon_swcs_hegrenade")
	frag.ViewModel = Model"models/weapons/cs2/v_eq_fraggrenade_hd.mdl"
	frag.WorldModel = Model"models/weapons/cs2/w_eq_fraggrenade_hd.mdl"
	
	local incnade = weapons.GetStored("weapon_swcs_incgrenade")
	incnade.ViewModel = Model"models/weapons/cs2/v_eq_incendiarygrenade_hd.mdl"
	incnade.WorldModel = Model"models/weapons/cs2/w_eq_incendiarygrenade_hd.mdl"
	
	local molly = weapons.GetStored("weapon_swcs_molotov")
	molly.ViewModel = Model"models/weapons/cs2/v_eq_molotov_hd.mdl"
	molly.WorldModel = Model"models/weapons/cs2/w_eq_molotov_hd.mdl"
	
	local smonk = weapons.GetStored("weapon_swcs_smokegrenade")
	smonk.ViewModel = Model"models/weapons/cs2/v_eq_smokegrenade_hd.mdl"
	smonk.WorldModel = Model"models/weapons/cs2/w_eq_smokegrenade_hd.mdl"
	
	local allahuakbar = weapons.GetStored("weapon_swcs_c4")
	allahuakbar.ViewModel = Model"models/weapons/cs2/v_ied_hd.mdl"
	allahuakbar.WorldModel = Model"models/weapons/cs2/w_ied_hd.mdl"
	
end)