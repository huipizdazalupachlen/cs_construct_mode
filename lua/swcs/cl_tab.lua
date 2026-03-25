hook.Add("AddToolMenuCategories", "swcs.categories", function()
	spawnmenu.AddToolCategory("Utilities", "swcs", "SWCS")
end)

presets.Add("swcs_hands", "SAS", {
	swcs_hands = "11",
	swcs_hands_skin = "0",
	swcs_sleeves = "19",
})
presets.Add("swcs_hands", "Phoenix Connection", {
	swcs_hands = "8",
	swcs_hands_skin = "0",
	swcs_sleeves = "0",
})
presets.Add("swcs_hands", "Dangerzone", {
	swcs_hands = "7",
	swcs_hands_skin = "0",
	swcs_sleeves = "16",
})

local sv_cvars = {
	"swcs_weapon_sync_seed",
	"weapon_accuracy_nospread",
	"swcs_weapon_individual_ammo",
	"swcs_hl2_ammo",
	"weapon_accuracy_shotgun_spread_patterns",
	"swcs_helmet_on_spawn",
	"swcs_defuser_on_spawn",
	"weapon_recoil_scale",
	"sv_showimpacts",
	"swcs_deploy_override",
	"swcs_damage_scale",
	"swcs_damage_scale_head",
}

local cl_cvars = {
	"swcs_experm_interp",
	"swcs_fx_impact_style",
	"swcs_fx_blood_style",
	"swcs_fx_weapon_barrel_smoke",
	"swcs_fx_weapon_barrel_heat",
	"swcs_updated_icon",
	"swcs_knives_unified",
	"swcs_group_others",
	"swcs_view_dip_anim",
}

local xh_cvars = {
	"swcs_crosshairdot",
	"swcs_crosshairstyle",
	"swcs_crosshaircolor",
	"swcs_crosshairalpha",
	"swcs_crosshaircolor_r",
	"swcs_crosshaircolor_g",
	"swcs_crosshaircolor_b",
	"swcs_crosshair_dynamic_splitdist",
	"swcs_crosshairgap_useweaponvalue",
	"swcs_crosshairgap",
	"swcs_crosshairsize",
	"swcs_crosshairthickness",
	"swcs_crosshair_dynamic_splitalpha_innermod",
	"swcs_crosshair_dynamic_splitalpha_outermod",
	"swcs_crosshair_drawoutline",
	"swcs_crosshair_outlinethickness",
	"swcs_crosshairusealpha",
	"swcs_crosshair_t",
}

local vm_cvars = {
	"swcs_viewmodel_fov",
	"viewmodel_offset_x",
	"viewmodel_offset_y",
	"viewmodel_offset_z",
	"viewmodel_recoil",
	"swcs_use_headbob",
	"cl_bobcycle",
	"cl_bobamt_vert",
	"cl_bobamt_lat",
	"cl_bob_lower_amt",
	"swcs_gunlowerangle",
	"swcs_gunlowerspeed",
	"swcs_drawtracers_firstperson",
	"swcs_drawtracers_movetonotintersect",

	"swcs_scope_blur",
	"swcs_righthand",

	--"cl_viewmodel_shift_left_amt",
	--"cl_viewmodel_shift_right_amt",
}

hook.Add("PopulateToolMenu", "swcs.tabs", function()
	-- server settings
	spawnmenu.AddToolMenuOption("Utilities", "swcs", "sv_settings", "#spawnmenu.menu.swcs.sv_settings_name", "", "", function(pnl)
		pnl:AddControl("Header", {Description = "#spawnmenu.menu.swcs.sv_settings_header"})

		-- reset this panel's cvars
		local reset = pnl:Button("#spawnmenu.menu.swcs_reset_cvars")
		if not LocalPlayer():IsListenServerHost() then
			reset:SetEnabled(false)
		end
		function reset:DoClick()
			for _, name in ipairs(sv_cvars) do
				local cvar = GetConVar(name)
				RunConsoleCommand(name, cvar:GetDefault())
			end
		end

		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_sync_seed", "swcs_weapon_sync_seed")
		pnl:ControlHelp("#spawnmenu.menu.swcs_cvar_sync_seed_desc")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_nospread", "weapon_accuracy_nospread")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_individual_ammo", "swcs_weapon_individual_ammo")
		pnl:ControlHelp("#spawnmenu.menu.swcs_cvar_individual_ammo_desc")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_hl2_ammo", "swcs_hl2_ammo")
		pnl:ControlHelp("#spawnmenu.menu.swcs_cvar_hl2_ammo_desc")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_shotgun_spread", "weapon_accuracy_shotgun_spread_patterns")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_helmet_spawn", "swcs_helmet_on_spawn")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_defuser_spawn", "swcs_defuser_on_spawn")

		pnl:NumSlider("#spawnmenu.menu.swcs_cvar_recoil_scale", "weapon_recoil_scale", 0, 10, 1)
		pnl:NumSlider("#spawnmenu.menu.swcs_cvar_show_impacts", "sv_showimpacts", 0, 3, 0)
		pnl:ControlHelp("#spawnmenu.menu.swcs_cvar_show_impacts_desc")
		pnl:NumSlider("#spawnmenu.menu.swcs_cvar_deploy_speed_mult", "swcs_deploy_override", 0, 4, 1)

		pnl:NumSlider("#spawnmenu.menu.swcs_cvar_damage_mult", "swcs_damage_scale", 0, 1, 2)
		pnl:ControlHelp("#spawnmenu.menu.swcs_cvar_damage_mult_desc")
		pnl:NumSlider("#spawnmenu.menu.swcs_cvar_headshot_damage_mult", "swcs_damage_scale_head", 0, 1, 2)
		pnl:ControlHelp("#spawnmenu.menu.swcs_cvar_headshot_damage_mult_desc")
	end)

	-- clientside settings
	spawnmenu.AddToolMenuOption("Utilities", "swcs", "cl_settings", "#spawnmenu.menu.swcs.cl_settings_name", "", "", function(pnl)
		pnl:AddControl("Header", {Description = "#spawnmenu.menu.swcs_cl_settings_header"})

		local reset = pnl:Button("#spawnmenu.menu.swcs_reset_cvars")
		function reset:DoClick()
			for _, name in ipairs(cl_cvars) do
				local cvar = GetConVar(name)
				cvar:Revert()
			end
		end

		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_experm_interp", "swcs_experm_interp")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_csgo_impacts", "swcs_fx_impact_style")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_csgo_blood", "swcs_fx_blood_style")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_barrel_smoke", "swcs_fx_weapon_barrel_smoke")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_barrel_heat", "swcs_fx_weapon_barrel_heat")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_view_dip", "swcs_view_dip_anim")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_enable_hl2_zoom", "swcs_enable_zoom")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_contextual_zoom", "swcs_contextual_zoom")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_candycorn", "swcs_halloween_casings")

		pnl:AddControl("Header", {Description = "#spawnmenu.menu.swcs_spawnmenu_settings_header"})
		pnl:ControlHelp("#spawnmenu.menu.swcs_spawnmenu_settings_desc")
		pnl:Button("#spawnmenu.menu.swcs_spawnmenu_reload", "spawnmenu_reload")

		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_updated_icon", "swcs_updated_icon")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_knives_unified_category", "swcs_knives_unified")
		pnl:CheckBox("#spawnmenu.menu.swcs_cvar_group_others", "swcs_group_others")
	end)

	-- crosshair settings
	spawnmenu.AddToolMenuOption("Utilities", "swcs", "xhair_settings", "#spawnmenu.menu.swcs_crosshair_settings_name", "", "", function(pnl)
		local reset = pnl:Button("#spawnmenu.menu.swcs_reset_cvars")
		function reset:DoClick()
			for _, name in ipairs(xh_cvars) do
				local cvar = GetConVar(name)
				cvar:Revert()
			end
		end

		---@class EditablePanel
		local DrawBoard = vgui.Create("EditablePanel", pnl)
		DrawBoard:Dock(TOP)
		function DrawBoard:PerformLayout()
			self:SetTall(pnl:GetWide())
		end

		-- crosshair preview
		do
			local swcs_crosshairdot = GetConVar"swcs_crosshairdot"
			local swcs_crosshairstyle = GetConVar"swcs_crosshairstyle"
			local swcs_crosshaircolor = GetConVar"swcs_crosshaircolor"
			local swcs_crosshairalpha = GetConVar"swcs_crosshairalpha"
			local swcs_crosshaircolor_r = GetConVar"swcs_crosshaircolor_r"
			local swcs_crosshaircolor_g = GetConVar"swcs_crosshaircolor_g"
			local swcs_crosshaircolor_b = GetConVar"swcs_crosshaircolor_b"
			local swcs_crosshair_dynamic_splitdist = GetConVar"swcs_crosshair_dynamic_splitdist"
			local swcs_crosshairgap_useweaponvalue = GetConVar"swcs_crosshairgap_useweaponvalue"
			local swcs_crosshairgap = GetConVar"swcs_crosshairgap"
			local swcs_crosshairsize = GetConVar"swcs_crosshairsize"
			local swcs_crosshairthickness = GetConVar"swcs_crosshairthickness"
			local swcs_crosshair_dynamic_splitalpha_innermod = GetConVar"swcs_crosshair_dynamic_splitalpha_innermod"
			local swcs_crosshair_dynamic_splitalpha_outermod = GetConVar"swcs_crosshair_dynamic_splitalpha_outermod"
			local swcs_crosshair_dynamic_maxdist_splitratio = GetConVar"swcs_crosshair_dynamic_maxdist_splitratio"
			local swcs_crosshair_drawoutline = GetConVar"swcs_crosshair_drawoutline"
			local swcs_crosshair_outlinethickness = GetConVar"swcs_crosshair_outlinethickness"
			local swcs_crosshairusealpha = GetConVar"swcs_crosshairusealpha"
			local swcs_crosshair_t = GetConVar"swcs_crosshair_t"

			local function DrawCrosshairRect(r, g, b, a, x0, y0, x1, y1, bAdditive)
				local w = math.max(x0, x1) - math.min(x0, x1)
				local h = math.max(y0, y1) - math.min(y0, y1)

				if swcs_crosshair_drawoutline:GetBool() then
					local flThick = swcs_crosshair_outlinethickness:GetFloat() * 2
					surface.SetDrawColor(0, 0, 0, a)
					surface.DrawRect(x0 - math.floor(flThick / 2), y0 - math.floor(flThick / 2), w + flThick, h + flThick)
				end

				surface.SetDrawColor(r, g, b, a)

				if bAdditive then
					surface.DrawTexturedRect(x0, y0, w, h)
				else
					surface.DrawRect(x0, y0, w, h)
				end
			end

			local SWITCH_CrosshairColor = {
				[0] = Color(250, 50, 50),
				Color(50, 250, 50),
				Color(250, 250, 50),
				Color(50, 50, 250),
				Color(50, 250, 250),
				function()
					return Color(
						swcs_crosshaircolor_r:GetInt(),
						swcs_crosshaircolor_g:GetInt(),
						swcs_crosshaircolor_b:GetInt()
					)
				end,
			}

			local function YRES(y)
				return y * (ScrH() / 480)
			end

			local bg = Material("hlmv/background")

			DrawBoard.m_flCrosshairDistance = 0
			function DrawBoard:Paint(w, h)
				surface.SetAlphaMultiplier(1)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(bg)
				surface.DrawTexturedRect(0, 0, w, h)

				local r, g, b = 50, 250, 50
				if SWITCH_CrosshairColor[swcs_crosshaircolor:GetInt()] then
					local col = SWITCH_CrosshairColor[swcs_crosshaircolor:GetInt()]

					if isfunction(col) then
						col = col()
					end

					r, g, b = col.r, col.g, col.b
				end

				local alpha = math.Clamp(swcs_crosshairalpha:GetInt(), 0, 255)

				if not self.m_iCrosshairTextureID then
					self.m_iCrosshairTextureID = surface.GetTextureID("vgui/white_additive")
				end

				local bAdditive = not swcs_crosshairusealpha:GetBool()
				if bAdditive then
					surface.SetTexture(self.m_iCrosshairTextureID)
					alpha = 200
				end

				local fHalfFov = math.rad(90) * 0.5
				local flInaccuracy = (math.abs(math.sin(RealTime())) * 0.1)
				local flSpread = 0

				local fSpreadDistance = ((flInaccuracy + flSpread) * 320 / math.tan(fHalfFov))
				local flCappedSpreadDistance = fSpreadDistance
				local flMaxCrossDistance = swcs_crosshair_dynamic_splitdist:GetFloat()
				if fSpreadDistance > flMaxCrossDistance then
					flCappedSpreadDistance = flMaxCrossDistance
				end

				local iSpreadDistance = swcs_crosshairstyle:GetInt() < 4 and math.floor(YRES(fSpreadDistance)) or 2
				local iCappedSpreadDistance = swcs_crosshairstyle:GetInt() < 4 and math.floor(YRES(flCappedSpreadDistance)) or 2

				local fCrosshairDistanceGoal = swcs_crosshairgap_useweaponvalue:GetBool() and 0 or 4 -- The minimum distance the crosshair can achieve...

				-- 0 = default
				-- 1 = default static
				-- 2 = classic standard
				-- 3 = classic dynamic
				-- 4 = classic static
				-- if ( cl_dynamiccrosshair.GetBool() )

				if self.m_flCrosshairDistance > fCrosshairDistanceGoal then
					if swcs_crosshairstyle:GetInt() == 5 then
						self.m_flCrosshairDistance = self.m_flCrosshairDistance - 42 * FrameTime()
					else
						self.m_flCrosshairDistance = Lerp(FrameTime() / 0.025, fCrosshairDistanceGoal, self.m_flCrosshairDistance)
					end
				end

				-- clamp max crosshair expansion
				self.m_flCrosshairDistance = math.Clamp(self.m_flCrosshairDistance, fCrosshairDistanceGoal, 25.0)

				local iCrosshairDistance, iBarSize, iBarThickness
				local iCappedCrosshairDistance = 0

				iCrosshairDistance = math.floor((self.m_flCrosshairDistance * ScrH() / 1200.0) + swcs_crosshairgap:GetFloat())
				iBarSize = math.floor(YRES(swcs_crosshairsize:GetFloat()))
				iBarThickness = math.max(1, math.floor(YRES(swcs_crosshairthickness:GetFloat())))

				-- 0 = default
				-- 1 = default static
				-- 2 = classic standard
				-- 3 = classic dynamic
				-- 4 = classic static
				-- if weapon_debug_spread_show:GetInt() == 2
				if iSpreadDistance > 0 and swcs_crosshairstyle:GetInt() == 2 or swcs_crosshairstyle:GetInt() == 3 then
					iCrosshairDistance = iSpreadDistance + swcs_crosshairgap:GetFloat()

					if swcs_crosshairstyle:GetInt() == 2 then
						iCappedCrosshairDistance = iCappedSpreadDistance + swcs_crosshairgap:GetFloat()
					end
				elseif swcs_crosshairstyle:GetInt() == 4 or (iSpreadDistance == 0 and (swcs_crosshairstyle:GetInt() == 2 or swcs_crosshairstyle:GetInt() == 3)) then
					iCrosshairDistance = fCrosshairDistanceGoal + swcs_crosshairgap:GetFloat()
					iCappedCrosshairDistance = 4 + swcs_crosshairgap:GetFloat()
				end

				local iCenterX = math.floor(w / 2)
				local iCenterY = math.floor(h / 2)

				-- 0 = default
				-- 1 = default static
				-- 2 = classic standard
				-- 3 = classic dynamic
				-- 4 = classic static

				local flAlphaSplitInner = swcs_crosshair_dynamic_splitalpha_innermod:GetFloat()
				local flAlphaSplitOuter = swcs_crosshair_dynamic_splitalpha_outermod:GetFloat()
				local flSplitRatio = swcs_crosshair_dynamic_maxdist_splitratio:GetFloat()
				local iInnerCrossDist = iCrosshairDistance
				local flLineAlphaInner = alpha
				local flLineAlphaOuter = alpha
				local iBarSizeInner = iBarSize
				local iBarSizeOuter = iBarSize

				-- draw the crosshair that splits off from the main xhair
				if swcs_crosshairstyle:GetInt() == 2 and fSpreadDistance > flMaxCrossDistance then
					iInnerCrossDist = iCappedCrosshairDistance
					flLineAlphaInner = alpha * flAlphaSplitInner
					flLineAlphaOuter = alpha * flAlphaSplitOuter
					iBarSizeInner = math.ceil(iBarSize * (1.0 - flSplitRatio))
					iBarSizeOuter = math.floor(iBarSize * flSplitRatio)

					-- draw horizontal crosshair lines
					local iInnerLeft = (iCenterX - iCrosshairDistance - iBarThickness / 2) - iBarSizeInner
					local iInnerRight = iInnerLeft + 2 * (iCrosshairDistance + iBarSizeInner) + iBarThickness
					local iOuterLeft = iInnerLeft - iBarSizeOuter
					local iOuterRight = iInnerRight + iBarSizeOuter
					local y0 = iCenterY - iBarThickness / 2
					local y1 = y0 + iBarThickness
					DrawCrosshairRect(r, g, b, flLineAlphaOuter, iOuterLeft, y0, iInnerLeft, y1, bAdditive)
					DrawCrosshairRect(r, g, b, flLineAlphaOuter, iInnerRight, y0, iOuterRight, y1, bAdditive)

					-- draw vertical crosshair lines
					local iInnerTop = (iCenterY - iCrosshairDistance - iBarThickness / 2) - iBarSizeInner
					local iInnerBottom = iInnerTop + 2 * (iCrosshairDistance + iBarSizeInner) + iBarThickness
					local iOuterTop = iInnerTop - iBarSizeOuter
					local iOuterBottom = iInnerBottom + iBarSizeOuter
					local x0 = iCenterX - iBarThickness / 2
					local x1 = x0 + iBarThickness
					if not swcs_crosshair_t:GetBool() then DrawCrosshairRect(r, g, b, flLineAlphaOuter, x0, iOuterTop, x1, iInnerTop, bAdditive) end
					DrawCrosshairRect(r, g, b, flLineAlphaOuter, x0, iInnerBottom, x1, iOuterBottom, bAdditive)
				end

				-- draw horizontal crosshair lines
				local iInnerLeft = iCenterX - iInnerCrossDist - (iBarThickness / 2)
				local iInnerRight = iInnerLeft + (2 * iInnerCrossDist) + iBarThickness
				local iOuterLeft = iInnerLeft - iBarSizeInner
				local iOuterRight = iInnerRight + iBarSizeInner
				local y0 = iCenterY - (iBarThickness / 2)
				local y1 = y0 + iBarThickness
				DrawCrosshairRect(r, g, b, flLineAlphaInner, iOuterLeft, y0, iInnerLeft, y1, bAdditive)
				DrawCrosshairRect(r, g, b, flLineAlphaInner, iInnerRight, y0, iOuterRight, y1, bAdditive)

				-- draw vertical crosshair lines
				local iInnerTop = iCenterY - iInnerCrossDist - (iBarThickness / 2)
				local iInnerBottom = iInnerTop + (2 * iInnerCrossDist) + iBarThickness
				local iOuterTop = iInnerTop - iBarSizeInner
				local iOuterBottom = iInnerBottom + iBarSizeInner
				local x0 = iCenterX - (iBarThickness / 2)
				local x1 = x0 + iBarThickness
				if not swcs_crosshair_t:GetBool() then DrawCrosshairRect(r, g, b, flLineAlphaInner, x0, iOuterTop, x1, iInnerTop, bAdditive) end
				DrawCrosshairRect(r, g, b, flLineAlphaInner, x0, iInnerBottom, x1, iOuterBottom, bAdditive)

				-- draw dot
				if swcs_crosshairdot:GetBool() then
					local x0 = iCenterX - iBarThickness / 2
					local x1 = x0 + iBarThickness
					local y0 = iCenterY - iBarThickness / 2
					local y1 = y0 + iBarThickness
					DrawCrosshairRect(r, g, b, alpha, x0, y0, x1, y1, bAdditive)
				end
			end
		end

		-- crosshair code
		local exportCodeText
		do
			local importTextEntry = pnl:TextEntry("#spawnmenu.menu.swcs_import_crosshair_code", "")
			importTextEntry:SetTooltip("#spawnmenu.menu.swcs_import_crosshair_code_desc")
			function importTextEntry:OnEnter()
				local code = self:GetValue()

				if swcs.ApplyCrosshairCode(code) then
					self:SetText("")
					exportCodeText:SetText(code)
				end
			end

			exportCodeText = pnl:TextEntry("#spawnmenu.menu.swcs_export_crosshair_code", "")
			exportCodeText:SetTooltip("#spawnmenu.menu.swcs_export_crosshair_code_desc")
			exportCodeText:SetEnabled(false)
			function exportCodeText:Think()
				local code = LocalPlayer().swcs_CrosshairCode
				if code ~= self:GetText() and code ~= nil then
					self:SetText(code)
				end
			end
			function exportCodeText:OnGetFocus()
				hook.Run("OnTextEntryGetFocus", self)

				SetClipboardText(self:GetText())
			end

			pnl:ControlHelp("#spawnmenu.menu.swcs_import_crosshair_desc")
		end

		pnl:CheckBox("#spawnmenu.menu.swcs_crosshair_use_custom", "swcs_crosshair")
		pnl:CheckBox("#spawnmenu.menu.swcs_crosshair_use_spectator", "swcs_crosshair_use_spectator")
		pnl:CheckBox("#spawnmenu.menu.swcs_crosshair_follow_recoil", "swcs_crosshair_recoil")

		local style = pnl:ComboBox("#spawnmenu.menu.swcs_crosshair_style", "swcs_crosshairstyle")
		style:AddChoice("#spawnmenu.menu.swcs_crosshair_style_default", 0)
		style:AddChoice("#spawnmenu.menu.swcs_crosshair_style_default_static", 1)
		style:AddChoice("#spawnmenu.menu.swcs_crosshair_style_accurate_split", 2)
		style:AddChoice("#spawnmenu.menu.swcs_crosshair_style_accurate_dynamic", 3)
		style:AddChoice("#spawnmenu.menu.swcs_crosshair_style_classic_static", 4)
		style:AddChoice("#spawnmenu.menu.swcs_crosshair_style_classic_dynamic", 5)

		pnl:CheckBox("#spawnmenu.menu.swcs_crosshair_outline", "swcs_crosshair_drawoutline")
		pnl:NumSlider("#spawnmenu.menu.swcs_crosshair_outline_thickness", "swcs_crosshair_outlinethickness", 0.1, 3, 1)

		local cmb_color = pnl:ComboBox("#spawnmenu.menu.swcs_crosshair_color", "swcs_crosshaircolor")
		cmb_color:AddChoice("#spawnmenu.menu.swcs_crosshair_color_red", 0)
		cmb_color:AddChoice("#spawnmenu.menu.swcs_crosshair_color_green", 1)
		cmb_color:AddChoice("#spawnmenu.menu.swcs_crosshair_color_yellow", 2)
		cmb_color:AddChoice("#spawnmenu.menu.swcs_crosshair_color_blue", 3)
		cmb_color:AddChoice("#spawnmenu.menu.swcs_crosshair_color_cyan", 4)
		cmb_color:AddChoice("#spawnmenu.menu.swcs_crosshair_color_custom", 5)

		pnl:CheckBox("#spawnmenu.menu.swcs_crosshair_use_alpha", "swcs_crosshairusealpha")

		local colormix = vgui.Create("DColorMixer", pnl)
		colormix:SetConVarR("swcs_crosshaircolor_r")
		colormix:SetConVarG("swcs_crosshaircolor_g")
		colormix:SetConVarB("swcs_crosshaircolor_b")
		colormix:SetConVarA("swcs_crosshairalpha")
		pnl:AddItem(colormix)

		pnl:CheckBox("#spawnmenu.menu.swcs_crosshair_t", "swcs_crosshair_t")
		pnl:CheckBox("#spawnmenu.menu.swcs_crosshair_dot", "swcs_crosshairdot")
		pnl:NumSlider("#spawnmenu.menu.swcs_crosshair_thickness", "swcs_crosshairthickness", 0, 20, 1)
		pnl:NumSlider("#spawnmenu.menu.swcs_crosshair_size", "swcs_crosshairsize", 0, 250, 0)
		pnl:NumSlider("#spawnmenu.menu.swcs_crosshair_center_gap", "swcs_crosshairgap", 0, 250, 0)
		pnl:CheckBox("#spawnmenu.menu.swcs_crosshair_weapon_gap", "swcs_crosshairgap_useweaponvalue")
	end)

	-- viewmodel settings
	spawnmenu.AddToolMenuOption("Utilities", "swcs", "viewmodel", "#spawnmenu.menu.swcs_viewmodel_settings_name", "", "", function(pnl)
		pnl:AddControl("Header", {Description = "#spawnmenu.menu.swcs_viewmodel_settings_header"})

		local reset = pnl:Button("#spawnmenu.menu.swcs_reset_cvars")
		function reset:DoClick()
			for _, name in ipairs(vm_cvars) do
				local cvar = GetConVar(name)
				cvar:Revert()
			end
		end

		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_fov", "swcs_viewmodel_fov", 54, 68, 0)

		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_offset_x", "viewmodel_offset_x", -2.5, 2.5, 1)
		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_offset_y", "viewmodel_offset_y", -2.5, 2.5, 1)
		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_offset_z", "viewmodel_offset_z", -2.5, 2.5, 1)

		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_recoil_tracking", "viewmodel_recoil", 0.0, 1, 2)
		local style = pnl:ComboBox("#spawnmenu.menu.swcs_viewmodel_headbob_style", "swcs_use_headbob")
		style:AddChoice("#spawnmenu.menu.swcs_viewmodel_headbob_style_gmod", 0)
		style:AddChoice("#spawnmenu.menu.swcs_viewmodel_headbob_style_old", 1)
		style:AddChoice("#spawnmenu.menu.swcs_viewmodel_headbob_style_csgo", 2)

		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_bob_frequency", "cl_bobcycle", 0.1, 2.0, 2)
		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_bob_vertical", "cl_bobamt_vert", 0.1, 2.0, 1)
		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_bob_lateral", "cl_bobamt_lat", 0.1, 2.0, 1)
		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_bob_loweramt", "cl_bob_lower_amt", 5, 30, 1)

		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_lowering_angle", "swcs_gunlowerangle", -10, 10, 1)
		pnl:NumSlider("#spawnmenu.menu.swcs_viewmodel_lowering_speed", "swcs_gunlowerspeed", 0, 10, 1)

		pnl:CheckBox("#spawnmenu.menu.swcs_viewmodel_tracers_fp", "swcs_drawtracers_firstperson")
		pnl:CheckBox("#spawnmenu.menu.swcs_viewmodel_tracers_move", "swcs_drawtracers_movetonotintersect")

		pnl:CheckBox("#spawnmenu.menu.swcs_viewmodel_ironsight_blur", "swcs_scope_blur")
		pnl:CheckBox("#spawnmenu.menu.swcs_viewmodel_righthand", "swcs_righthand")

		--[[
			cl_viewmodel_shift_left_amt( "cl_viewmodel_shift_left_amt","1.5", FCVAR_ARCHIVE, "The amount the viewmodel shifts to the left when shooting accuracy increases.", true, 0.5, true, 2.0 );
			cl_viewmodel_shift_right_amt( "cl_viewmodel_shift_right_amt","0.75", FCVAR_ARCHIVE, "The amount the viewmodel shifts to the right when shooting accuracy decreases.", true, 0.25, true, 2.0 );
		]]
	end)

	-- hands
	spawnmenu.AddToolMenuOption("Utilities", "swcs", "hands", "#spawnmenu.menu.swcs_hands_settings_name", "", "", function(pnl)
		pnl:AddControl("Header", {Description = "#spawnmenu.menu.swcs_hands_settings_header"})

		pnl:ToolPresets("swcs_hands", {
			["swcs_hands"] = 0,
			["swcs_hands_skin"] = 0,
			["swcs_sleeves"] = 0,
		})

		local hands = pnl:ComboBox("#spawnmenu.menu.swcs_hands_model", "swcs_hands")
		hands:SetSortItems(false)

		for i = 0, #swcs.HandsMap do
			hands:AddChoice(swcs.HandsMap[i].name, i)
		end

		pnl:NumSlider("#spawnmenu.menu.swcs_hands_skin", "swcs_hands_skin", 0, 6, 0)

		local sleeves = pnl:ComboBox("#spawnmenu.menu.swcs_hands_sleeves", "swcs_sleeves")
		sleeves:SetSortItems(false)

		for i = 0, #swcs.SleevesMap do
			sleeves:AddChoice(swcs.SleevesMap[i].name, i)
		end
	end)
end)

local knives_unified = CreateClientConVar("swcs_knives_unified", "0", true, false, "Whether or not to have the knives in the main CS:GO category", 0, 1)
local group_others = CreateClientConVar("swcs_group_others", "1", true, false, "Whether or not to group other SWCS addons under the CS:GO category", 0, 1)

local function StringRequest(strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText)
	local Window = Derma_StringRequest(strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText)

	local InnerPanel, TextEntry = Window:GetChild(4)

	if InnerPanel and IsValid(InnerPanel) and InnerPanel:GetName() == "DPanel" then
		TextEntry = InnerPanel:GetChild(1)
	end

	if TextEntry and IsValid(TextEntry) and TextEntry:GetName() == "DTextEntry" then
		TextEntry:SetPlaceholderText(strDefaultText or "")
		TextEntry.AllowInput = function(self, char)
			local text = self:GetText()

			if #text > 19 then
				return true
			end

			local charIndex = string.byte(char) - 32
			if charIndex < 0 or charIndex > 94 then
				return true
			end

			return false
		end
	end

	return Window
end

local function OpenMenuExtra(pan, menu)
	pan:_OpenMenuExtra(menu)

	local classname = pan:GetSpawnName()
	local plyInventory = swcs.econ.GetInventory(LocalPlayer())
	local econItem = plyInventory[classname]
	local bHasStatTrak = econItem and econItem.bHasStatTrak
	local bHasUID = econItem and econItem.strCustomName and #econItem.strCustomName > 0


	local SWEP = weapons.GetStored(classname)

	if SWEP.SupportsNameTags or SWEP.SupportsStatTracks then
		menu:AddSpacer()
	end

	-- add stattrak
	local submenu, menuoption
	if SWEP.SupportsStatTracks then
		submenu, menuoption = menu:AddSubMenu("#spawnmenu.menu.swcs_stattrak")
		menuoption:SetIcon("icon16/database.png")
		submenu:AddOption(bHasStatTrak and "#spawnmenu.menu.swcs_remove_stattrak" or "#spawnmenu.menu.swcs_apply_stattrak", function()
			if not econItem then
				econItem = swcs.econ.EconItem(classname)
				plyInventory[classname] = econItem
			end

			---@diagnostic disable-next-line: need-check-nil
			econItem.bHasStatTrak = not econItem.bHasStatTrak
			swcs.econ.UpdateInventory()
		end):SetIcon(bHasStatTrak and "icon16/database_delete.png" or "icon16/database_add.png")
		if bHasStatTrak and econItem.iStatTrakScore > 0 then
			submenu:AddOption("#spawnmenu.menu.swcs_reset_stattrak", function()
				if not econItem then return end

				econItem.iStatTrakScore = 0
				swcs.econ.UpdateInventory()
			end):SetIcon("icon16/database_refresh.png")
		end
	end

	-- add nametag
	if SWEP.SupportsNameTags then
		submenu, menuoption = menu:AddSubMenu("#spawnmenu.menu.swcs_uid")
		menuoption:SetIcon("icon16/tag_blue.png")
		submenu:AddOption(bHasUID and "#spawnmenu.menu.swcs_edit_uid" or "#spawnmenu.menu.swcs_apply_uid", function()
			if not econItem then
				econItem = swcs.econ.EconItem(classname)
				plyInventory[classname] = econItem
			end

			---@diagnostic disable-next-line: need-check-nil
			StringRequest("#swcs.edit_uid.menu_title", "#swcs.edit_uid.menu_desc", econItem.strCustomName or "", function(strText)
				if not econItem then
					econItem = swcs.econ.EconItem(classname)
					plyInventory[classname] = econItem
				end

				econItem.strCustomName = strText
				swcs.econ.UpdateInventory()
			end)
		end):SetIcon(bHasUID and "icon16/tag_blue_edit.png" or "icon16/tag_blue_add.png")
		if bHasUID then
			submenu:AddOption("#spawnmenu.menu.swcs_remove_uid", function()
				if not econItem then return end

				econItem.strCustomName = ""
				swcs.econ.UpdateInventory()
			end):SetIcon("icon16/tag_blue_delete.png")
		end
	end
end

local CategoryMap = {
	["rifle"] = "#spawnmenu.category.swcs_rifles",
	["shotgun"] = "#spawnmenu.category.swcs_shotguns",
	["machinegun"] = "#spawnmenu.category.swcs_mgs",
	["pistol"] = "#spawnmenu.category.swcs_pistols",
	["sniperrifle"] = "#spawnmenu.category.swcs_snipers",
	["submachinegun"] = "#spawnmenu.category.swcs_smgs",
	["knife"] = "#spawnmenu.category.swcs_knives",
	["grenade"] = "#spawnmenu.category.swcs_grenades",
	["other"] = "#spawnmenu.category.other",
	["stackableitem"] = "#spawnmenu.category.other",
	["breach charge"] = "#spawnmenu.category.other",
	["shield"] = "#spawnmenu.category.swcs_melee",
	["melee"] = "#spawnmenu.category.swcs_melee",
}
hook.Add("PopulateWeapons", "swcs.creation_tab", function(pnlContent, tree, _)
	timer.Simple(0, function()
		-- Loop through the weapons and add them to the menu
		local Weapons = list.Get("Weapon")
		local Categorised = {}

		local strCategoryMain = language.GetPhrase("#spawnmenu.category.swcs")
		local strCategoryKnives = language.GetPhrase("#spawnmenu.category.swcs_knives")

		-- Build into categories
		for k, weapon in pairs(Weapons) do
			if not weapon.Spawnable then continue end
			if not weapons.IsBasedOn(k, "weapon_swcs_base") or weapon.IsBaseWep then continue end

			local Category = language.GetPhrase(weapon.Category) or "Other"
			if not isstring(Category) then Category = tostring(Category) end

			if Category == strCategoryKnives and knives_unified:GetBool() then
				Category = strCategoryMain
			end

			local swep = weapons.Get(weapon.ClassName)

			local SubCategory = "other"

			if swep and swep.ClassName ~= "weapon_swcs_taser" then
				local keyvals = util.KeyValuesToTable(swep.ItemDefVisuals or "")
				local strWeaponType = string.lower(keyvals.weapon_type or "")

				if strWeaponType ~= "" then
					SubCategory = strWeaponType
				end

				if not isstring(SubCategory) then
					SubCategory = tostring(SubCategory)
				end
			end

			if CategoryMap[SubCategory] then
				SubCategory = CategoryMap[SubCategory]
			end

			Categorised[Category] = Categorised[Category] or {}
			Categorised[Category][SubCategory] = Categorised[Category][SubCategory] or {}
			table.insert(Categorised[Category][SubCategory], weapon)
		end

		-- Loop through each category
		for _, node in next, tree:Root():GetChildNodes() do
			local nodeText = node:GetText()

			if nodeText ~= strCategoryMain then
				if nodeText == strCategoryKnives and knives_unified:GetBool() then
					node:Remove()
					continue
				end

				if Categorised[nodeText] and group_others:GetBool() then
					local csgo_node
					for _, child_node in next, tree:Root():GetChildNodes() do
						if child_node:GetText() == strCategoryMain then
							csgo_node = child_node
							break
						end
					end

					if IsValid(csgo_node) then
						csgo_node:InsertNode(node)
						node:SetDrawLines(true)
					end
				end

				continue
			end

			local SubCategories = Categorised[nodeText]
			if not SubCategories then continue end

			-- When we click on the node - populate it using this function
			node.DoPopulate = function(self)
				-- If we've already populated it - recreate it.
				if IsValid(self.PropPanel) then
					self.PropPanel:Remove()
				end

				-- Create the container panel
				self.PropPanel = vgui.Create("ContentContainer", pnlContent)
				self.PropPanel:SetVisible(false)
				self.PropPanel:SetTriggerSpawnlistChange(false)

				for name, weps in SortedPairs(SubCategories) do
					if not table.IsEmpty(SubCategories) then
						---@diagnostic disable-next-line: param-type-mismatch
						local label = vgui.Create("ContentHeader", self.PropPanel)
						label:SetText(CategoryMap[name] or name)
						self.PropPanel:Add(label)
					end

					for _, ent in SortedPairsByMemberValue(weps, "PrintName") do
						---@diagnostic disable-next-line: param-type-mismatch
						spawnmenu.CreateContentIcon(ent.ScriptedEntityType or "weapon", self.PropPanel, {
							nicename  = ent.PrintName or ent.ClassName,
							spawnname = ent.ClassName,
							material  = ent.IconOverride or ("entities/" .. ent.ClassName .. ".png"),
							admin     = ent.AdminOnly,
						})
					end
				end
			end
		end

		-- Select the first node
		local FirstNode = tree:Root():GetChildNode(0)
		if IsValid(FirstNode) then
			FirstNode:InternalDoClick()
		end

		timer.Simple(0, function()
			tree:Root():ExpandRecurse(true)
		end)
	end)
end)

local swcs_update_icon = CreateClientConVar("swcs_updated_icon", "1", true, false, "Use the updated CSGO icon for the weapons tab categories", 0, 1)
local updated_icon = Material("swcs/icon_csgo.png")

local icon = (swcs_update_icon:GetBool() and not updated_icon:IsError()) and "swcs/icon_csgo.png" or "games/16/csgo.png"
list.Set("ContentCategoryIcons", language.GetPhrase("#spawnmenu.category.swcs"), icon)
list.Set("ContentCategoryIcons", language.GetPhrase("#spawnmenu.category.swcs_knives"), icon)

cvars.AddChangeCallback("swcs_updated_icon", function(_, _, new)
	icon = (new and not updated_icon:IsError()) and "swcs/icon_csgo.png" or "games/16/csgo.png"
	list.Set("ContentCategoryIcons", language.GetPhrase("#spawnmenu.category.swcs"), icon)
	list.Set("ContentCategoryIcons", language.GetPhrase("#spawnmenu.category.swcs_knives"), icon)
end)

if spawnmenu then
	local weaponConstructor
	spawnmenu.AddContentType("swcs_weapon", function(container, data)
		if not weaponConstructor then
			weaponConstructor = spawnmenu.GetContentType("weapon")
		end

		---@class ContentIcon
		local pnl = weaponConstructor(container, data)

		pnl:ScanForNPCWeapons()

		pnl._OpenMenuExtra = pnl._OpenMenuExtra or pnl.OpenMenuExtra
		pnl.OpenMenuExtra = OpenMenuExtra

		return pnl
	end)
end
