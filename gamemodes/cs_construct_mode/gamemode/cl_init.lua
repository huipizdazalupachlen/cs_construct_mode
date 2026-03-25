include("shared.lua")
include("cl_lobby.lua")

-- Configurable keybinds (defined before cl_f4menu.lua uses them)
CreateConVar("csm_key_buy",      tostring(KEY_B),   {FCVAR_ARCHIVE, FCVAR_CLIENTSIDE}, "Клавиша меню закупки")
CreateConVar("csm_key_settings", tostring(KEY_F4),  {FCVAR_ARCHIVE, FCVAR_CLIENTSIDE}, "Клавиша настроек F4")

include("cl_f4menu.lua")

CSCL = CSCL or {}
CSCL.Phase = PHASE_WAITING
CSCL.RoundNum = 0
CSCL.ScoreT = 0
CSCL.ScoreCT = 0
CSCL.PhaseEndsAt = 0
CSCL.RoundEndsAt = 0
CSCL.Money = 0
CSCL.GameMode = GAMEMODE_COMPETITIVE
CSCL.LastBDown = false
CSCL.TeamFrame = nil
CSCL.BuyFrame = nil
CSCL.KillFeed = {}

include("cl_radar.lua")

-- ============================================================
-- CS2 HUD STYLE PALETTE
-- ============================================================

local CS2 = {
	bg       = Color(12, 12, 16, 240),
	panel    = Color(20, 20, 26, 230),
	panelLt  = Color(28, 28, 36, 220),
	border   = Color(42, 42, 50),
	text     = Color(220, 220, 225),
	muted    = Color(95, 95, 105),
	accent   = Color(87, 186, 255),      -- голубой акцент (как в моде)
	green    = Color(76, 175, 80),
	red      = Color(210, 55, 55),
	t        = Color(234, 170, 59),
	ct       = Color(93, 130, 195),
	white    = Color(255, 255, 255),
	armorCol = Color(0, 26, 255),
}

-- Customizable HUD color (like the mod)
CreateClientConVar("cs2hud_r", "87", true, false)
CreateClientConVar("cs2hud_g", "186", true, false)
CreateClientConVar("cs2hud_b", "255", true, false)

local function hudColor()
	return Color(
		GetConVar("cs2hud_r"):GetInt(),
		GetConVar("cs2hud_g"):GetInt(),
		GetConVar("cs2hud_b"):GetInt()
	)
end

-- ============================================================
-- FONTS (Goodland SemiBold from mod + Arial fallbacks)
-- ============================================================

surface.CreateFont("CS2H_HP",      { font = "Goodland SemiBold", size = ScreenScale(15), antialias = true })
surface.CreateFont("CS2H_Ammo",    { font = "Goodland SemiBold", size = ScreenScale(22), antialias = true })
surface.CreateFont("CS2H_AmmoSm",  { font = "Goodland SemiBold", size = ScreenScale(10), antialias = true })
surface.CreateFont("CS2H_Money",   { font = "Goodland SemiBold", size = ScreenScale(12), antialias = true })
surface.CreateFont("CS2H_Score",   { font = "Goodland SemiBold", size = ScreenScale(14), antialias = true })
surface.CreateFont("CS2H_Timer",   { font = "Goodland SemiBold", size = ScreenScale(10), antialias = true })
surface.CreateFont("CS2H_Small",   { font = "Goodland SemiBold", size = ScreenScale(7),  antialias = true })
surface.CreateFont("CS2H_Tiny",    { font = "Goodland SemiBold", size = ScreenScale(5),  antialias = true })
surface.CreateFont("CS2H_WinBig",  { font = "Goodland SemiBold", size = ScreenScale(20), antialias = true })
surface.CreateFont("CS2H_WinSub",  { font = "Goodland SemiBold", size = ScreenScale(9),  antialias = true })
surface.CreateFont("CS2H_KF",      { font = "Goodland SemiBold", size = ScreenScale(6),  antialias = true })

-- Buy menu / Scoreboard / UI fonts (Goodland SemiBold)
local function mkFont(name, size)
	surface.CreateFont(name, { font = "Goodland SemiBold", size = size, antialias = true })
end
mkFont("CS2_BuyTitle", 18)
mkFont("CS2_BuyCat", 13)
mkFont("CS2_BuyItem", 13)
mkFont("CS2_BuyPrice", 12)
mkFont("CS2_SB_Title", 20)
mkFont("CS2_SB_Hdr", 11)
mkFont("CS2_SB_Name", 13)
mkFont("CS2_SB_Stat", 13)
mkFont("CS2_SB_Map", 11)

-- Materials

local matGrad   = surface.GetTextureID("gui/gradient")

-- Circular avatar (simple AvatarImage, created once)
local CS2Avatar = nil
local CS2AvatarBG = nil

-- ============================================================
-- UTILITIES
-- ============================================================

local function fmtTime(t)
	if t <= 0 then return "0:00" end
	local s = math.max(0, math.ceil(t))
	return string.format("%d:%02d", math.floor(s / 60), s % 60)
end

local function pW(pct) return ScrW() * pct / 100 end
local function pH(pct) return ScrH() * pct / 100 end

local function shortWeaponName(cls)
	if not cls then return "" end
	return cls:gsub("weapon_swcs_", ""):gsub("weapon_", "")
end

-- Killfeed weapon icon cache
local kfIconOverrides = {
	["weapon_swcs_knife_ct"] = "hud/swcs/select/knife.png",
	["weapon_swcs_knife_t"]  = "hud/swcs/select/knife_t.png",
	["weapon_swcs_knife_gg"] = "hud/swcs/select/knifegg.png",
}
local kfIcons = {}
local function getKFIcon(cls)
	if kfIcons[cls] ~= nil then return kfIcons[cls] end
	local path = kfIconOverrides[cls]
	if not path then
		path = "hud/swcs/select/" .. shortWeaponName(cls) .. ".png"
	end
	kfIcons[cls] = file.Exists("materials/" .. path, "GAME") and Material(path, "smooth noclamp") or false
	return kfIcons[cls]
end

local weaponIcons = {}
local function getWeaponIcon(cls)
	if weaponIcons[cls] then return weaponIcons[cls] end
	local mat = Material("entities/" .. cls .. ".png", "smooth")
	if mat and not mat:IsError() then weaponIcons[cls] = mat return mat end
	return nil
end

-- Weapons that don't show ammo
local ammoBlacklist = {
	["weapon_physgun"] = true, ["weapon_physcannon"] = true,
	["weapon_crowbar"] = true, ["weapon_fists"] = true, ["gmod_tool"] = true,
}

-- ============================================================
-- NETWORKING
-- ============================================================

net.Receive("CSMode_SyncState", function()
	CSCL.Phase = net.ReadUInt(8)
	CSCL.RoundNum = net.ReadUInt(16)
	CSCL.ScoreT = net.ReadUInt(16)
	CSCL.ScoreCT = net.ReadUInt(16)
	CSCL.PhaseEndsAt = net.ReadFloat()
	CSCL.RoundEndsAt = net.ReadFloat()
	CSCL.Money = net.ReadUInt(32)
	CSCL.GameMode = net.ReadUInt(8)
end)

net.Receive("CSMode_OpenTeamSelect", function() CSConstruct_OpenTeamMenu() end)

CSCL.RoundWinData = nil
CSCL.BombNotif = nil
net.Receive("CSMode_CleanupDecals", function() RunConsoleCommand("r_cleardecals") end)

net.Receive("CSMode_BombEvent", function()
	local event = net.ReadString()
	if event == "planted" then
		surface.PlaySound("cs_construct_mode/bombpl.mp3")
		CSCL.BombNotif = { text = "БОМБА ЗАЛОЖЕНА", color = Color(255, 160, 0), time = CurTime(), duration = 3.5 }
	elseif event == "defused" then
		surface.PlaySound("cs_construct_mode/bombdef.mp3")
		CSCL.BombNotif = { text = "БОМБА ОБЕЗВРЕЖЕНА", color = Color(100, 200, 255), time = CurTime(), duration = 3.5 }
	end
end)

net.Receive("CSMode_RoundWin", function()
	CSCL.RoundWinData = {
		team = net.ReadUInt(8),
		reason = net.ReadString(),
		time = CurTime(),
		duration = 5,
	}
end)

-- ============================================================
-- KILLFEED
-- ============================================================

net.Receive("CSMode_KillFeedEntry", function()
	local atkName  = net.ReadString()
	local atkTeam  = net.ReadUInt(8)
	local atkIdx   = net.ReadUInt(16)
	local vicName  = net.ReadString()
	local vicTeam  = net.ReadUInt(8)
	local vicIdx   = net.ReadUInt(16)
	local wepClass = net.ReadString()
	local hs       = net.ReadBool()
	local suicide  = net.ReadBool()

	if not CSCL or (CSCL.Phase ~= PHASE_LIVE and CSCL.Phase ~= PHASE_ROUND_END) then return end

	local lp = LocalPlayer()
	local lpIdx = IsValid(lp) and lp:EntIndex() or -1
	local entry = {
		time        = CurTime(),
		duration    = 6,
		killerName  = atkName,
		killerTeam  = atkTeam,
		victimName  = vicName,
		victimTeam  = vicTeam,
		weaponClass = wepClass,
		headshot    = hs,
		suicide     = suicide,
		isMe        = (lpIdx == atkIdx or lpIdx == vicIdx),
	}
	table.insert(CSCL.KillFeed, 1, entry)
	while #CSCL.KillFeed > 6 do table.remove(CSCL.KillFeed) end
end)

-- ============================================================
-- HUD PAINT — CS2 HUD MOD STYLE
-- ============================================================

hook.Add("HUDPaint", "CSConstruct_HUD", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	if CSCL.Phase == PHASE_LOBBY then return end
	if not lp:Alive() then return end

	local sw, sh = ScrW(), ScrH()
	local hc = hudColor()
	local weapon = lp:GetActiveWeapon()

	local tleft = 0
	if CSCL.Phase == PHASE_FREEZE or CSCL.Phase == PHASE_ROUND_END then
		tleft = math.max(0, CSCL.PhaseEndsAt - CurTime())
	elseif CSCL.Phase == PHASE_LIVE then
		tleft = math.max(0, CSCL.RoundEndsAt - CurTime())
	end

	-- ========== CENTER BOTTOM: Avatar Circle + Gradient Lines ==========
	local circleX = sw / 2
	local circleY = pH(93.7)
	local circleR = pH(3.79)

	-- Gradient lines from center
	local lineLen = pW(19.9)
	local lineThick = pH(0.19)
	local lineY = pH(93.6)

	surface.SetDrawColor(hc)
	surface.SetTexture(matGrad)
	surface.DrawTexturedRectRotated(sw / 2.63, lineY, lineLen, lineThick, 180)
	surface.DrawTexturedRectRotated(sw / 1.611, lineY, lineLen, lineThick, 0)

	-- Circle outline
	surface.DrawCircle(circleX, circleY, circleR, hc)

	-- Avatar (simple square AvatarImage — no stencil needed)
	local avSize = math.floor(circleR * 1.6)
	local avX = math.floor(sw / 2 - avSize / 2)
	local avY = math.floor(circleY - avSize / 2)

	if not IsValid(CS2Avatar) then
		CS2Avatar = vgui.Create("AvatarImage")
		if IsValid(CS2Avatar) then
			CS2Avatar:SetPaintedManually(true)
			CS2Avatar:ParentToHUD()
		end
	end
	if IsValid(CS2Avatar) then
		CS2Avatar:SetPos(avX, avY)
		CS2Avatar:SetSize(avSize, avSize)
		CS2Avatar:SetPlayer(lp, 64)

		-- Clip to circle using stencil
		render.ClearStencil()
		render.SetStencilEnable(true)
		render.SetStencilWriteMask(1)
		render.SetStencilTestMask(1)
		render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
		render.SetStencilPassOperation(STENCILOPERATION_ZERO)
		render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
		render.SetStencilReferenceValue(1)

		-- Draw circle mask
		local poly = {}
		for a = 0, 360 do
			local rad = math.rad(a)
			poly[#poly + 1] = { x = circleX + math.cos(rad) * (avSize / 2), y = circleY + math.sin(rad) * (avSize / 2) }
		end
		draw.NoTexture()
		surface.SetDrawColor(255, 255, 255)
		surface.DrawPoly(poly)

		render.SetStencilFailOperation(STENCILOPERATION_ZERO)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
		render.SetStencilReferenceValue(1)

		CS2Avatar:PaintManual()

		render.SetStencilEnable(false)
		render.ClearStencil()
	end

	-- ========== HEALTH (left of center) ==========
	local health = lp:Health()
	local armor = lp:Armor()

	local hpBarW = pW(3)
	local hpBarH = pH(0.5)
	local hpBarX = pW(25)
	local hpBarY = pH(95.5)

	-- HP number
	local hpColor = hc
	if health < 30 then hpColor = Color(255, 64, 64) end
	draw.SimpleText(tostring(health), "CS2H_HP", hpBarX + hpBarW * 0.5, hpBarY - pH(2), hpColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	-- HP low glow
	if health < 30 then
		surface.SetDrawColor(255, 64, 64, 50)
		surface.DrawTexturedRectRotated(hpBarX + hpBarW * 0.5, hpBarY - pH(2), pW(2), pH(5), 90)
	end

	-- HP bar
	draw.RoundedBox(0, hpBarX, hpBarY, hpBarW, hpBarH, Color(255, 51, 51, 140))
	local hpFill = math.Clamp(hpBarW * (health / 100), 0, hpBarW)
	draw.RoundedBox(0, hpBarX, hpBarY, hpFill, hpBarH, hc)

	-- ========== ARMOR (left of health) ==========
	if armor > 0 then
		local arBarW = pW(3)
		local arBarH = pH(0.5)
		local arBarX = pW(21)
		local arBarY = pH(95.5)

		draw.SimpleText(tostring(armor), "CS2H_HP", arBarX + arBarW * 0.5, arBarY - pH(2), hc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.RoundedBox(0, arBarX, arBarY, arBarW, arBarH, Color(160, 160, 160, 140))
		local arFill = math.Clamp(arBarW * (armor / 100), 0, arBarW)
		draw.RoundedBox(0, arBarX, arBarY, arFill, arBarH, CS2.armorCol)
	end

	-- ========== AMMO (right of center) ==========
	if IsValid(weapon) and not ammoBlacklist[weapon:GetClass()] then
		local ammo1 = weapon:Clip1()
		local ammo2 = lp:GetAmmoCount(weapon:GetPrimaryAmmoType())

		if ammo1 >= 0 then
			local iconSize = sh / 480 * 14.23

			-- Firemode icon (drawn via primitives)
			do
				local fm = 1
				if weapon.GetCurrentFiremode and isfunction(weapon.GetCurrentFiremode) then
					fm = weapon:GetCurrentFiremode() or 1
				end
				local ix = pW(79.5)
				local iy = pH(93.8)
				local bw = iconSize * 0.38
				local bh = iconSize * 0.72
				local count = (fm < 0) and 1 or (fm > 1) and 3 or 1
				local showAuto = (fm < 0)
				local spacing = bw + iconSize * 0.18
				local startX = ix - (count - 1) * spacing * 0.5
				draw.NoTexture()
				surface.SetDrawColor(hc.r, hc.g, hc.b, hc.a or 255)
				for i = 0, count - 1 do
					local bx = startX + i * spacing
					-- Bullet tip (rounded top)
					draw.RoundedBoxEx(math.floor(bw / 2), math.floor(bx - bw / 2), math.floor(iy - bh / 2), math.ceil(bw), math.ceil(bh * 0.55), hc, true, true, false, false)
					-- Bullet casing (flat bottom)
					surface.DrawRect(math.floor(bx - bw / 2), math.floor(iy - bh / 2 + bh * 0.45), math.ceil(bw), math.ceil(bh * 0.38))
				end
				if showAuto then
					for i = 1, 3 do
						surface.DrawRect(math.floor(ix + bw + i * iconSize * 0.22), math.floor(iy - bh * 0.12), math.ceil(iconSize * 0.1), math.ceil(bh * 0.22))
					end
				end
			end

			-- Reserve ammo
			draw.SimpleText(" | " .. ammo2, "CS2H_AmmoSm", pW(75), pH(92.5), hc)

			-- Clip ammo
			local clipColor = ammo1 > 4 and hc or Color(255, 0, 0)
			draw.SimpleText(tostring(ammo1), "CS2H_Ammo", pW(75), pH(93.3), clipColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
		end
	end

	-- ========== BOMB ZONE INDICATOR ==========
	if lp:Team() == TEAM_T and lp:Alive() and CSCL.Phase == PHASE_LIVE then
		local wep = lp:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "weapon_swcs_c4" then
			local inZone, siteName = CS_IsInBombZone(lp:GetPos())
			if inZone then
				draw.SimpleText("ЗОНА " .. (siteName or ""), "CS2H_Money", sw / 2, pH(87), Color(255, 200, 0, 220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				draw.SimpleText("НЕ В ЗОНЕ", "CS2H_Money", sw / 2, pH(87), Color(200, 80, 80, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		end
	end

	-- ========== MONEY (far left) ==========
	draw.SimpleText("$" .. CSCL.Money, "CS2H_Money", pW(2), pH(93.6), hc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	-- ========== TOP CENTER: SCORE PANEL ==========
	local topW, topH = pW(14), pH(5)
	local topX = (sw - topW) / 2
	local topY = pH(1)

	-- T side
	draw.RoundedBoxEx(4, topX, topY, topW / 2 - 1, topH, Color(CS2.t.r, CS2.t.g, CS2.t.b, 25), true, false, true, false)
	draw.SimpleText(tostring(CSCL.ScoreT), "CS2H_Score", topX + topW / 4, topY + topH / 2, CS2.t, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	-- CT side
	draw.RoundedBoxEx(4, topX + topW / 2 + 1, topY, topW / 2 - 1, topH, Color(CS2.ct.r, CS2.ct.g, CS2.ct.b, 25), false, true, false, true)
	draw.SimpleText(tostring(CSCL.ScoreCT), "CS2H_Score", topX + topW * 3 / 4, topY + topH / 2, CS2.ct, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	-- Divider
	surface.SetDrawColor(CS2.border)
	surface.DrawRect(topX + topW / 2 - 1, topY + pH(0.8), 2, topH - pH(1.6))

	-- Timer — если бомба заложена, показываем её таймер
	local timerText, timerCol
	local bombEnt = ents.FindByClass("swcs_planted_c4")[1]
	if IsValid(bombEnt) and bombEnt:GetBombTicking() then
		local bombLeft = math.max(0, bombEnt:GetC4Blow() - CurTime())
		timerText = fmtTime(bombLeft)
		timerCol  = bombLeft <= 10 and CS2.red or Color(255, 140, 0)
	else
		timerText = fmtTime(tleft)
		timerCol  = (tleft <= 10 and CSCL.Phase == PHASE_LIVE) and CS2.red or CS2.text
	end
	draw.SimpleText(timerText, "CS2H_Timer", sw / 2, topY + topH + pH(0.5), timerCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

	-- Round / Phase
	draw.SimpleText("R" .. CSCL.RoundNum, "CS2H_Tiny", topX - pW(0.5), topY + topH / 2, CS2.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	draw.SimpleText(CS_PhaseName(CSCL.Phase), "CS2H_Tiny", topX + topW + pW(0.5), topY + topH / 2, CS2.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	-- Player alive dots
	local tPly, ctPly = {}, {}
	for _, p in ipairs(player.GetAll()) do
		if p:Team() == TEAM_T then table.insert(tPly, p)
		elseif p:Team() == TEAM_CT then table.insert(ctPly, p) end
	end

	local dotR = pH(0.4)
	local dotGap = pH(0.3)
	for i = #tPly, 1, -1 do
		local dx = topX - pH(1) - (dotR * 2 + dotGap) * (#tPly - i + 1)
		local dy = topY + topH / 2
		draw.RoundedBox(dotR, dx, dy - dotR, dotR * 2, dotR * 2, tPly[i]:Alive() and CS2.t or Color(CS2.t.r, CS2.t.g, CS2.t.b, 40))
	end
	for i = 1, #ctPly do
		local dx = topX + topW + pH(1) + (dotR * 2 + dotGap) * (i - 1)
		local dy = topY + topH / 2
		draw.RoundedBox(dotR, dx, dy - dotR, dotR * 2, dotR * 2, ctPly[i]:Alive() and CS2.ct or Color(CS2.ct.r, CS2.ct.g, CS2.ct.b, 40))
	end

	-- ========== BUY HINT ==========
	if CSCL.Phase == PHASE_FREEZE and (lp:Team() == TEAM_T or lp:Team() == TEAM_CT) then
		local _bkn = GetConVar("csm_key_buy") and input.GetKeyName(GetConVar("csm_key_buy"):GetInt()) or "B"
		draw.SimpleText("[" .. (_bkn or "B"):upper() .. "] BUY", "CS2H_Tiny", sw / 2, pH(88), CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	-- ========== KILLFEED CS2 (top right) ==========
	local kfX    = sw - pW(1)
	local kfY    = pH(2)
	local kfH    = pH(2.8)
	local kfGap  = pH(0.35)
	local kfPad  = pW(0.4)
	local kfIcon = kfH * 0.82  -- icon is slightly smaller than row height

	for i = #CSCL.KillFeed, 1, -1 do
		if CurTime() - CSCL.KillFeed[i].time > CSCL.KillFeed[i].duration then table.remove(CSCL.KillFeed, i) end
	end

	surface.SetFont("CS2H_KF")

	-- Cache skull width once per frame
	local skullW = select(1, surface.GetTextSize("☠")) + kfPad * 0.5

	for i, entry in ipairs(CSCL.KillFeed) do
		local elapsed = CurTime() - entry.time
		local alpha = 255
		if elapsed < 0.12 then
			alpha = math.floor(255 * (elapsed / 0.12))
		elseif elapsed > entry.duration - 0.7 then
			alpha = math.floor(255 * ((entry.duration - elapsed) / 0.7))
		end
		if alpha <= 0 then continue end

		local y = kfY + (i - 1) * (kfH + kfGap)

		-- Team colors
		local killerCol = entry.killerTeam == TEAM_T and CS2.t or (entry.killerTeam == TEAM_CT and CS2.ct or CS2.text)
		local victimCol = entry.victimTeam == TEAM_T and CS2.t or (entry.victimTeam == TEAM_CT and CS2.ct or CS2.text)
		killerCol = Color(killerCol.r, killerCol.g, killerCol.b, alpha)
		victimCol = Color(victimCol.r, victimCol.g, victimCol.b, alpha)

		-- Text widths
		local kW = (not entry.suicide and entry.killerName ~= "") and select(1, surface.GetTextSize(entry.killerName)) or 0
		local vW = select(1, surface.GetTextSize(entry.victimName or ""))

		-- Total entry width
		local totalW = kfPad
		if kW > 0 then totalW = totalW + kW + kfPad end
		totalW = totalW + kfIcon + kfPad
		if entry.headshot then totalW = totalW + skullW end
		totalW = totalW + vW + kfPad

		local bgX = kfX - totalW

		-- Background
		local bgA = entry.isMe and 55 or 100
		draw.RoundedBox(3, bgX, y, totalW, kfH, Color(10, 12, 15, math.floor(bgA * alpha / 255)))
		-- Highlight bar for local player involvement
		if entry.isMe then
			surface.SetDrawColor(hc.r, hc.g, hc.b, math.floor(200 * alpha / 255))
			surface.DrawRect(bgX, y, 2, kfH)
		end

		-- Draw content left-to-right
		local cx = bgX + kfPad

		-- Killer name
		if kW > 0 then
			draw.SimpleText(entry.killerName, "CS2H_KF", cx, y + kfH * 0.5, killerCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			cx = cx + kW + kfPad
		end

		-- Weapon icon
		local iconMat = getKFIcon(entry.weaponClass)
		if iconMat then
			local iconY = y + (kfH - kfIcon) * 0.5
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.SetMaterial(iconMat)
			surface.DrawTexturedRect(cx, iconY, kfIcon, kfIcon)
		end
		cx = cx + kfIcon + kfPad

		-- Headshot skull (orange)
		if entry.headshot then
			draw.SimpleText("☠", "CS2H_KF", cx, y + kfH * 0.5, Color(255, 90, 0, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			cx = cx + skullW
		end

		-- Victim name
		draw.SimpleText(entry.victimName or "?", "CS2H_KF", cx, y + kfH * 0.5, victimCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	-- ========== ROUND WIN BANNER ==========
	if CSCL.RoundWinData then
		local elapsed = CurTime() - CSCL.RoundWinData.time
		if elapsed < CSCL.RoundWinData.duration then
			local alpha = 255
			if elapsed < 0.3 then alpha = math.floor(255 * (elapsed / 0.3))
			elseif elapsed > CSCL.RoundWinData.duration - 0.5 then alpha = math.floor(255 * ((CSCL.RoundWinData.duration - elapsed) / 0.5)) end

			local winText, winColor = "DRAW", Color(180, 180, 180, alpha)
			if CSCL.RoundWinData.team == TEAM_T then
				winText = "TERRORISTS WIN"
				winColor = Color(CS2.t.r, CS2.t.g, CS2.t.b, alpha)
			elseif CSCL.RoundWinData.team == TEAM_CT then
				winText = "COUNTER-TERRORISTS WIN"
				winColor = Color(CS2.ct.r, CS2.ct.g, CS2.ct.b, alpha)
			end

			local reasonMap = { elimination = "Elimination", time = "Time expired", draw = "Both eliminated", time_draw = "Time expired" }
			local banH = pH(10)
			local banY = sh / 2 - banH / 2
			surface.SetDrawColor(0, 0, 0, math.floor(200 * alpha / 255))
			surface.DrawRect(0, banY, sw, banH)
			surface.SetDrawColor(winColor.r, winColor.g, winColor.b, math.floor(120 * alpha / 255))
			surface.DrawRect(0, banY, sw, 2)
			surface.DrawRect(0, banY + banH - 2, sw, 2)

			draw.SimpleText(winText, "CS2H_WinBig", sw / 2, sh / 2 - pH(1), winColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			local rt = reasonMap[CSCL.RoundWinData.reason] or ""
			if rt ~= "" then
				draw.SimpleText(rt, "CS2H_WinSub", sw / 2, sh / 2 + pH(3), Color(160, 160, 160, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
		else
			CSCL.RoundWinData = nil
		end
	end

	-- Bomb event notification (planted / defused)
	if CSCL.BombNotif then
		local n = CSCL.BombNotif
		local elapsed = CurTime() - n.time
		if elapsed < n.duration then
			local alpha = 255
			if elapsed < 0.25 then
				alpha = math.floor(255 * (elapsed / 0.25))
			elseif elapsed > n.duration - 0.5 then
				alpha = math.floor(255 * ((n.duration - elapsed) / 0.5))
			end
			local c = n.color
			draw.SimpleText(n.text, "CS2H_WinBig", sw / 2, sh * 0.38, Color(c.r, c.g, c.b, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		else
			CSCL.BombNotif = nil
		end
	end
end)

-- Clean up avatar
hook.Add("ShutDown", "CS2_CleanAvatar", function()
	if IsValid(CS2Avatar) then CS2Avatar:Remove() CS2Avatar = nil end
end)

hook.Add("InitPostEntity", "CS2_InitAvatar", function()
	if IsValid(CS2Avatar) then CS2Avatar:Remove() end
	CS2Avatar = nil
end)

-- ============================================================
-- VIEWMODEL BOB — уменьшаем тряску через ConVar'ы движка
-- ============================================================

hook.Add("InitPostEntity", "CSConstruct_ReduceBob", function()
	-- cl_bob контролирует амплитуду тряски viewmodel (дефолт Source ~0.002)
	-- Ставим минимальное значение — почти нет тряски, как в CS:GO
	RunConsoleCommand("cl_bob",      "0.0005")
	RunConsoleCommand("cl_bobcycle", "0.98")
	RunConsoleCommand("cl_bobup",    "0.5")
end)

-- ============================================================
-- BUY MENU
-- ============================================================

local buyNumberKeys = { KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9 }

function CSConstruct_RequestBuyIndex(idx)
	if CurTime() - (CSCL._buyDebounce or 0) < 0.12 then return end
	if CSCL.Phase ~= PHASE_FREEZE then return end
	local lp = LocalPlayer()
	if not IsValid(lp) or not lp:Alive() or lp:IsTyping() then return end
	if lp:Team() ~= TEAM_T and lp:Team() ~= TEAM_CT then return end
	if idx < 1 or idx > #CS_WEAPON_ORDER then return end
	local cls = CS_WEAPON_ORDER[idx]
	local price = CS_WEAPON_PRICES[cls]
	if not price or CSCL.Money < price then return end
	CSCL._buyDebounce = CurTime()
	net.Start("CSMode_BuyWeapon") net.WriteString(cls) net.SendToServer()
end

function CSConstruct_CloseBuyMenu()
	local p = CSCL.BuyFrame
	if not IsValid(p) then CSCL.BuyFrame = nil return end
	CSCL.BuyFrame = nil p:Remove()
end

function CSConstruct_OpenBuyMenu()
	if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end
	if CSCL.Phase ~= PHASE_FREEZE or IsValid(CSCL.BuyFrame) then return end

	local lp = LocalPlayer()
	local playerTeam = lp:Team()
	local hc = hudColor()

	local menuW, menuH = 720, 540
	local f = vgui.Create("DFrame")
	CSCL.BuyFrame = f
	f:SetTitle("") f:SetDraggable(false) f:ShowCloseButton(false)
	f:SetSize(menuW, menuH) f:Center()

	f.Paint = function(_, w, h)
		draw.RoundedBox(8, 0, 0, w, h, CS2.bg)
		draw.RoundedBoxEx(8, 0, 0, w, 50, CS2.panel, true, true, false, false)
		-- Gradient lines under header
		local lineLen = w * 0.3
		surface.SetDrawColor(hc)
		surface.SetTexture(matGrad)
		surface.DrawTexturedRectRotated(w / 2 - lineLen / 2 - 40, 48, lineLen, 1, 180)
		surface.DrawTexturedRectRotated(w / 2 + lineLen / 2 + 40, 48, lineLen, 1, 0)

		draw.SimpleText("BUY MENU", "CS2_BuyTitle", 18, 15, CS2.text)
		draw.SimpleText("$" .. tostring(CSCL.Money), "CS2_BuyTitle", w - 60, 15, hc, TEXT_ALIGN_RIGHT)
	end

	local closeBtn = vgui.Create("DButton", f)
	closeBtn:SetPos(menuW - 46, 10) closeBtn:SetSize(32, 30) closeBtn:SetText("")
	closeBtn.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(200, 55, 55) or Color(55, 55, 60))
		draw.SimpleText("X", "CS2_BuyCat", w / 2, h / 2, CS2.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	closeBtn.DoClick = CSConstruct_CloseBuyMenu

	local scroll = vgui.Create("DScrollPanel", f)
	scroll:SetPos(10, 56) scroll:SetSize(menuW - 20, menuH - 66)
	local sbar = scroll:GetVBar() sbar:SetWide(4)
	sbar.Paint = function() end sbar.btnUp.Paint = function() end sbar.btnDown.Paint = function() end
	sbar.btnGrip.Paint = function(s, w, h) draw.RoundedBox(2, 0, 0, w, h, CS2.border) end

	local container = vgui.Create("DPanel", scroll)
	container:Dock(FILL) container:SetPaintBackground(false)

	local yPos = 0
	local cardW, cardH, cardGap = 160, 60, 5
	local maxCols = math.floor((menuW - 40) / (cardW + cardGap))

	for _, category in ipairs(CS_WEAPON_CATEGORIES) do
		local catP = vgui.Create("DPanel", container)
		catP:SetPos(0, yPos) catP:SetSize(menuW - 40, 24) catP:SetPaintBackground(false)
		catP.Paint = function(_, w, h)
			surface.SetDrawColor(hc.r, hc.g, hc.b, 40) surface.DrawRect(0, h - 1, w, 1)
			draw.SimpleText(category.name, "CS2_BuyCat", 6, h / 2, hc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
		yPos = yPos + 28

		local col = 0
		for _, cls in ipairs(category.weapons) do
			local price = CS_WEAPON_PRICES[cls]
			local teamRestr = CS_WEAPON_TEAMS[cls]
			local available = (teamRestr == nil or teamRestr == playerTeam)
			local name = (CS_ITEM_DISPLAY and CS_ITEM_DISPLAY[cls]) or cls:gsub("weapon_swcs_", ""):upper():gsub("_", " ")
			local icon = getWeaponIcon(cls)

			local btn = vgui.Create("DButton", container)
			btn:SetPos(col * (cardW + cardGap), yPos) btn:SetSize(cardW, cardH) btn:SetText("")

			btn.Paint = function(s, w, h)
				local canAfford = CSCL.Money >= (price or 99999)
				local bg = CS2.panelLt
				if not available then bg = Color(38, 22, 22, 200)
				elseif not canAfford then bg = Color(24, 24, 28, 200)
				elseif s:IsHovered() then bg = Color(36, 40, 48, 240) end
				draw.RoundedBox(5, 0, 0, w, h, bg)
				if canAfford and available and s:IsHovered() then
					surface.SetDrawColor(hc.r, hc.g, hc.b, 50) surface.DrawOutlinedRect(0, 0, w, h, 1)
				end
				if icon then
					surface.SetDrawColor(255, 255, 255, (not available or not canAfford) and 70 or 200)
					surface.SetMaterial(icon) surface.DrawTexturedRect(8, (h - 30) / 2, 30, 30)
				end
				draw.SimpleText(name, "CS2_BuyItem", 44, 10, not available and Color(130, 65, 65) or (not canAfford and CS2.muted or CS2.text))
				draw.SimpleText("$" .. (price or "?"), "CS2_BuyPrice", w - 8, h - 10, not canAfford and CS2.red or (not available and CS2.muted or hc), TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
				if not available and teamRestr then
					local tagCol = teamRestr == TEAM_T and CS2.t or CS2.ct
					draw.SimpleText(teamRestr == TEAM_T and "T" or "CT", "CS2_SB_Map", w - 8, 8, Color(tagCol.r, tagCol.g, tagCol.b, 120), TEXT_ALIGN_RIGHT)
				end
			end
			btn.DoClick = function()
				if not available or CSCL.Money < (price or 99999) or CSCL.Phase ~= PHASE_FREEZE then return end
				net.Start("CSMode_BuyWeapon") net.WriteString(cls) net.SendToServer()
			end

			col = col + 1
			if col >= maxCols then col = 0 yPos = yPos + cardH + cardGap end
		end
		if col > 0 then yPos = yPos + cardH + cardGap end
		yPos = yPos + 6
	end

	container:SetTall(yPos)
	f:MakePopup() f:SetKeyboardInputEnabled(false)
	f.OnRemove = function() CSCL.BuyFrame = nil end
end

-- ============================================================
-- TEAM SELECT
-- ============================================================

function CSConstruct_CloseTeamMenu()
	if IsValid(CSCL.TeamFrame) then CSCL.TeamFrame:Remove() CSCL.TeamFrame = nil end
end

function CSConstruct_OpenTeamMenu()
	if IsValid(CSCL.TeamFrame) then return end
	local lp = LocalPlayer()
	if not IsValid(lp) or lp:Team() == TEAM_T or lp:Team() == TEAM_CT then return end

	local hc = hudColor()
	local f = vgui.Create("DFrame")
	CSCL.TeamFrame = f
	f:SetTitle("") f:SetDraggable(false) f:ShowCloseButton(false)
	f:SetSize(300, 140) f:Center() f:MakePopup()
	f.Paint = function(_, w, h)
		draw.RoundedBox(8, 0, 0, w, h, CS2.bg)
		surface.SetDrawColor(CS2.border) surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.SimpleText("SELECT TEAM", "CS2_BuyTitle", w / 2, 16, CS2.text, TEXT_ALIGN_CENTER)
		-- Gradient lines
		local lc = hudColor()
		surface.SetDrawColor(lc)
		surface.SetTexture(matGrad)
		surface.DrawTexturedRectRotated(w / 2 - 50, 38, 80, 1, 180)
		surface.DrawTexturedRectRotated(w / 2 + 50, 38, 80, 1, 0)
	end

	local function mkBtn(y, tid, label, col)
		local b = vgui.Create("DButton", f)
		b:SetPos(20, y) b:SetSize(260, 38) b:SetText("")
		b.Paint = function(s, w, h)
			draw.RoundedBox(5, 0, 0, w, h, s:IsHovered() and Color(col.r, col.g, col.b, 50) or Color(col.r, col.g, col.b, 25))
			surface.SetDrawColor(col.r, col.g, col.b, 70) surface.DrawOutlinedRect(0, 0, w, h, 1)
			draw.SimpleText(label, "CS2_BuyCat", w / 2, h / 2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
		b.DoClick = function()
			net.Start("CSMode_SelectTeam") net.WriteUInt(tid, 8) net.SendToServer()
			CSConstruct_CloseTeamMenu()
		end
	end
	mkBtn(46, TEAM_T, "TERRORISTS", CS2.t)
	mkBtn(90, TEAM_CT, "COUNTER-TERRORISTS", CS2.ct)
	f.OnRemove = function() CSCL.TeamFrame = nil end
end

-- ============================================================
-- KEY HANDLING
-- ============================================================

hook.Add("Think", "CSConstruct_BuyKey", function()
	local lp = LocalPlayer()
	if not IsValid(lp) or gui.IsGameUIVisible() then return end
	local _buyKey = (GetConVar("csm_key_buy") and GetConVar("csm_key_buy"):GetInt()) or KEY_B
	if IsValid(CSCL.BuyFrame) then
		if not lp:IsTyping() and input.WasKeyPressed(_buyKey) then
			CSConstruct_CloseBuyMenu() CSCL._buyBSuppressUntil = CurTime() + 0.25 CSCL.LastBDown = true return
		end
		if not lp:IsTyping() and input.WasKeyPressed(KEY_ESCAPE) then
			CSConstruct_CloseBuyMenu() CSCL._buyBSuppressUntil = CurTime() + 0.25 return
		end
		if input.WasMousePressed(MOUSE_RIGHT) then
			local h = vgui.GetHoveredPanel() local under = false local p = h
			while IsValid(p) do if p == CSCL.BuyFrame then under = true break end p = p:GetParent() end
			if not under then CSConstruct_CloseBuyMenu() CSCL._buyBSuppressUntil = CurTime() + 0.25 return end
		end
	end
	if not IsValid(CSCL.BuyFrame) and vgui.CursorVisible() then return end
	local down = input.IsKeyDown(_buyKey)
	if down and not CSCL.LastBDown then
		if IsValid(CSCL.BuyFrame) then CSConstruct_CloseBuyMenu() CSCL._buyBSuppressUntil = CurTime() + 0.25
		elseif lp:Alive() and (lp:Team() == TEAM_T or lp:Team() == TEAM_CT) and CSCL.Phase == PHASE_FREEZE then
			if CurTime() >= (CSCL._buyBSuppressUntil or 0) then CSConstruct_OpenBuyMenu() end
		end
	end
	CSCL.LastBDown = down
end)

hook.Add("Think", "CSConstruct_BuyNumberKeys", function()
	if gui.IsGameUIVisible() then return end
	local lp = LocalPlayer()
	if not IsValid(lp) or lp:IsTyping() or CSCL.Phase ~= PHASE_FREEZE or not lp:Alive() then return end
	if lp:Team() ~= TEAM_T and lp:Team() ~= TEAM_CT then return end
	for i, key in ipairs(buyNumberKeys) do
		if i > #CS_WEAPON_ORDER then break end
		if input.WasKeyPressed(key) then CSConstruct_RequestBuyIndex(i) break end
	end
end)


hook.Add("PlayerBindPress", "CSConstruct_CloseBuyBinds", function(ply, bind, pressed)
	if not pressed or ply ~= LocalPlayer() or not IsValid(CSCL.BuyFrame) then return end
	if bind == "cancelselect" or bind == "pause" then
		CSConstruct_CloseBuyMenu() CSCL._buyBSuppressUntil = CurTime() + 0.25 return true
	end
end, 1000)

-- ============================================================
-- WEAPON SLOT SWITCHING
-- ============================================================

hook.Add("PlayerBindPress", "CSConstruct_WeaponSlots", function(ply, bind, pressed)
	if not pressed or ply ~= LocalPlayer() then return end
	if gui.IsGameUIVisible() or ply:IsTyping() or not ply:Alive() then return end
	local slotNum = tonumber(bind:match("^slot(%d+)$"))
	if not slotNum or slotNum < 1 or slotNum > 5 then return end
	local slotWeapons = {}
	for _, wep in ipairs(ply:GetWeapons()) do
		if IsValid(wep) and CS_GetWeaponSlot(wep:GetClass()) == slotNum then table.insert(slotWeapons, wep) end
	end
	if #slotWeapons > 0 then
		local cur = ply:GetActiveWeapon() local idx = 0
		if IsValid(cur) then for i, w in ipairs(slotWeapons) do if w == cur then idx = i break end end end
		input.SelectWeapon(idx > 0 and #slotWeapons > 1 and slotWeapons[(idx % #slotWeapons) + 1] or slotWeapons[1])
		return true
	end
end)

-- ============================================================
-- SCOREBOARD
-- ============================================================

local sbVisible = false
function GM:ScoreboardShow() sbVisible = true end
function GM:ScoreboardHide() sbVisible = false end

hook.Add("HUDPaint", "CSConstruct_Scoreboard", function()
	if not sbVisible then return end
	local sw, sh = ScrW(), ScrH()
	local hc = hudColor()
	local bW = math.min(680, sw * 0.68)
	local bX = (sw - bW) / 2
	local curY = sh * 0.06

	local tPly, ctPly = {}, {}
	for _, p in ipairs(player.GetAll()) do
		if p:Team() == TEAM_T then table.insert(tPly, p)
		elseif p:Team() == TEAM_CT then table.insert(ctPly, p) end
	end
	table.sort(tPly, function(a, b) return a:Frags() > b:Frags() end)
	table.sort(ctPly, function(a, b) return a:Frags() > b:Frags() end)

	-- Background overlay
	surface.SetDrawColor(0, 0, 0, 160)
	surface.DrawRect(0, 0, sw, sh)

	-- Header with gradient lines (like HUD mod)
	local hdrH = 50
	draw.RoundedBoxEx(6, bX, curY, bW, hdrH, CS2.bg, true, true, false, false)

	-- Gradient lines from center of header
	local hdrCX = bX + bW / 2
	local hdrCY = curY + hdrH - 4
	local lineLen = bW * 0.35
	surface.SetDrawColor(hc)
	surface.SetTexture(matGrad)
	surface.DrawTexturedRectRotated(hdrCX - lineLen / 2 - 30, hdrCY, lineLen, 1, 180)
	surface.DrawTexturedRectRotated(hdrCX + lineLen / 2 + 30, hdrCY, lineLen, 1, 0)

	-- Score
	draw.SimpleText(tostring(CSCL.ScoreT), "CS2_SB_Title", bX + bW / 2 - 32, curY + hdrH / 2 - 4, CS2.t, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(":", "CS2_SB_Title", bX + bW / 2, curY + hdrH / 2 - 4, hc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(tostring(CSCL.ScoreCT), "CS2_SB_Title", bX + bW / 2 + 32, curY + hdrH / 2 - 4, CS2.ct, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	-- Map & round
	draw.SimpleText(game.GetMap():upper(), "CS2_SB_Map", bX + 14, curY + hdrH / 2 - 4, CS2.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText("ROUND " .. CSCL.RoundNum, "CS2_SB_Map", bX + bW - 14, curY + hdrH / 2 - 4, CS2.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	curY = curY + hdrH + 1

	local colK = bX + bW - 210
	local colD = bX + bW - 165
	local colA = bX + bW - 120
	local colM = bX + bW - 65
	local colP = bX + bW - 20

	local function drawSection(players, teamColor, teamName)
		local secH = 26
		-- Section header with team color accent
		draw.RoundedBox(0, bX, curY, bW, secH, Color(teamColor.r, teamColor.g, teamColor.b, 25))
		-- Accent line left
		surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, 160)
		surface.DrawRect(bX, curY, 3, secH)
		-- Gradient line under header
		surface.SetDrawColor(teamColor.r, teamColor.g, teamColor.b, 60)
		surface.DrawRect(bX, curY + secH - 1, bW, 1)

		draw.SimpleText(teamName, "CS2_SB_Hdr", bX + 14, curY + secH / 2, teamColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		draw.SimpleText("K", "CS2_SB_Hdr", colK, curY + secH / 2, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("D", "CS2_SB_Hdr", colD, curY + secH / 2, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("A", "CS2_SB_Hdr", colA, curY + secH / 2, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("$", "CS2_SB_Hdr", colM, curY + secH / 2, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("MS", "CS2_SB_Hdr", colP, curY + secH / 2, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		curY = curY + secH + 1

		local rowH = 34
		if #players == 0 then
			draw.RoundedBox(0, bX, curY, bW, rowH, CS2.panel)
			draw.SimpleText("No players", "CS2_SB_Stat", bX + bW / 2, curY + rowH / 2, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			curY = curY + rowH + 1
		end
		for i, ply in ipairs(players) do
			if not IsValid(ply) then continue end
			local isMe = (ply == LocalPlayer())
			local alive = ply:Alive()

			-- Row background
			local bg = (i % 2 == 0) and CS2.panel or CS2.panelLt
			if isMe then bg = Color(hc.r, hc.g, hc.b, 18) end
			draw.RoundedBox(0, bX, curY, bW, rowH, bg)

			-- My row accent
			if isMe then
				surface.SetDrawColor(hc.r, hc.g, hc.b, 180)
				surface.DrawRect(bX, curY, 3, rowH)
			end

			-- Status indicator
			local statusCol = alive and CS2.green or CS2.red
			draw.RoundedBox(4, bX + 10, curY + (rowH - 8) / 2, 8, 8, statusCol)
			if not alive then
				-- X mark on dead
				surface.SetDrawColor(255, 255, 255, 200)
				local dx, dy = bX + 12, curY + rowH / 2 - 2
				surface.DrawLine(dx, dy, dx + 4, dy + 4)
				surface.DrawLine(dx + 4, dy, dx, dy + 4)
			end

			-- Avatar letter
			draw.RoundedBox(3, bX + 24, curY + 4, rowH - 8, rowH - 8, Color(teamColor.r, teamColor.g, teamColor.b, 35))
			local initial = ply:Nick():sub(1, 1):upper()
			draw.SimpleText(initial, "CS2_SB_Stat", bX + 24 + (rowH - 8) / 2, curY + rowH / 2, teamColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			-- Name
			local nameCol = alive and CS2.text or Color(CS2.muted.r, CS2.muted.g, CS2.muted.b, 160)
			draw.SimpleText(ply:Nick(), "CS2_SB_Name", bX + 24 + rowH - 4, curY + rowH / 2, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

			-- Stats
			draw.SimpleText(tostring(ply:Frags()), "CS2_SB_Stat", colK, curY + rowH / 2, CS2.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText(tostring(ply:Deaths()), "CS2_SB_Stat", colD, curY + rowH / 2, CS2.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			draw.SimpleText("0", "CS2_SB_Stat", colA, curY + rowH / 2, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			-- Money (own team only)
			local lp2 = LocalPlayer()
			if IsValid(lp2) and ply:Team() == lp2:Team() then
				local m = ply == lp2 and CSCL.Money or 0
				draw.SimpleText("$" .. m, "CS2_SB_Stat", colM, curY + rowH / 2, hc, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				draw.SimpleText("-", "CS2_SB_Stat", colM, curY + rowH / 2, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

			-- Ping
			local ping = ply:Ping()
			local pCol = ping > 100 and CS2.red or (ping > 60 and Color(220, 190, 50) or CS2.green)
			draw.SimpleText(tostring(ping), "CS2_SB_Stat", colP, curY + rowH / 2, pCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			curY = curY + rowH + 1
		end
		curY = curY + 6
	end

	drawSection(tPly, CS2.t, "TERRORISTS")
	drawSection(ctPly, CS2.ct, "COUNTER-TERRORISTS")

	-- Footer with gradient lines
	local footH = 26
	draw.RoundedBoxEx(6, bX, curY, bW, footH, CS2.bg, false, false, true, true)
	local footCX = bX + bW / 2
	local footCY = curY + 4
	surface.SetDrawColor(hc.r, hc.g, hc.b, 80)
	surface.SetTexture(matGrad)
	surface.DrawTexturedRectRotated(footCX - bW * 0.15 - 20, footCY, bW * 0.25, 1, 180)
	surface.DrawTexturedRectRotated(footCX + bW * 0.15 + 20, footCY, bW * 0.25, 1, 0)
	draw.SimpleText("CS CONSTRUCT", "CS2_SB_Map", footCX, curY + footH / 2, Color(hc.r, hc.g, hc.b, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

-- ============================================================
-- CROSSHAIR — алгоритм SWCS (iBarSize = YRES, iCrosshairDistance по стилю)
-- ============================================================

local g_XhairDist     = 0   -- animated crosshair distance (like m_flCrosshairDistance in SWCS)
local g_LastWepEnt    = nil -- last weapon entity, to detect weapon switches
local g_LastShots     = 0   -- last GetShotsFired() value

hook.Add("HUDPaint", "CSConstruct_Crosshair", function()
	local lp = LocalPlayer()
	if not IsValid(lp) or not lp:Alive() then return end
	if lp:Team() ~= TEAM_T and lp:Team() ~= TEAM_CT then return end
	if CSCL.Phase == PHASE_LOBBY then return end
	if lp:GetFOV() < 75 then return end  -- скрываем при прицеливании через оптику

	-- Снайперские винтовки: прицел не показываем совсем (как в CS:GO)
	local _wep = lp:GetActiveWeapon()
	if IsValid(_wep) then
		local _cls = _wep:GetClass()
		if _cls == "weapon_swcs_awp" or _cls == "weapon_swcs_ssg08"
		or _cls == "weapon_swcs_scar20" or _cls == "weapon_swcs_g3sg1" then
			return
		end
	end

	local cvSize = GetConVar("swcs_crosshairsize")
	if not cvSize then return end

	-- Читаем все ConVar'ы SWCS
	local st     = (GetConVar("swcs_crosshairstyle") or GetConVar("swcs_crosshairsize")) and GetConVar("swcs_crosshairstyle"):GetInt() or 4
	local gap    = GetConVar("swcs_crosshairgap")          and GetConVar("swcs_crosshairgap"):GetFloat()          or 0
	local fixGap = GetConVar("swcs_crosshair_fixedgap")    and GetConVar("swcs_crosshair_fixedgap"):GetFloat()    or 3
	local thick  = GetConVar("swcs_crosshairthickness")    and GetConVar("swcs_crosshairthickness"):GetFloat()    or 1
	local dot    = GetConVar("swcs_crosshairdot")          and GetConVar("swcs_crosshairdot"):GetBool()           or false
	local tStyle = GetConVar("swcs_crosshair_t")           and GetConVar("swcs_crosshair_t"):GetBool()            or false
	local alpha  = GetConVar("swcs_crosshairalpha")        and GetConVar("swcs_crosshairalpha"):GetInt()          or 200
	local ol     = GetConVar("swcs_crosshair_drawoutline") and GetConVar("swcs_crosshair_drawoutline"):GetBool()  or false
	local olT    = GetConVar("swcs_crosshair_outlinethickness") and GetConVar("swcs_crosshair_outlinethickness"):GetFloat() or 1
	local preset = GetConVar("swcs_crosshaircolor")        and GetConVar("swcs_crosshaircolor"):GetInt()          or 1
	local useAlpha = GetConVar("swcs_crosshairusealpha")   and GetConVar("swcs_crosshairusealpha"):GetBool()      or false

	local cr, cg, cb = 50, 250, 50
	if     preset == 0 then cr, cg, cb = 250, 50,  50
	elseif preset == 2 then cr, cg, cb = 250, 250, 50
	elseif preset == 3 then cr, cg, cb = 50,  50,  250
	elseif preset == 4 then cr, cg, cb = 50,  250, 250
	elseif preset == 5 then
		cr = GetConVar("swcs_crosshaircolor_r") and GetConVar("swcs_crosshaircolor_r"):GetInt() or 255
		cg = GetConVar("swcs_crosshaircolor_g") and GetConVar("swcs_crosshaircolor_g"):GetInt() or 0
		cb = GetConVar("swcs_crosshaircolor_b") and GetConVar("swcs_crosshaircolor_b"):GetInt() or 255
	end

	-- SWCS использует additive текстуру когда useAlpha = false
	local bAdd = not useAlpha
	if bAdd then
		alpha = 200
	end

	-- Функция масштабирования — как в SWCS (YRES)
	local sh = ScrH()
	local function YRES(y) return y * (sh / 480) end

	-- Размеры линий (как в SWCS)
	local iBarSize  = math.floor(YRES(cvSize:GetFloat()))
	local iBarThick = math.max(1, math.floor(YRES(thick)))

	-- Base crosshair gap goal (minimum distance)
	local fGoal = (GetConVar("swcs_crosshairgap_useweaponvalue") and GetConVar("swcs_crosshairgap_useweaponvalue"):GetBool()) and 0 or 4

	local wep = lp:GetActiveWeapon()
	local bHasWep = IsValid(wep) and wep.GetInaccuracy and wep.GetSpread

	-- Styles 2 and 3: crosshair distance driven by actual weapon inaccuracy (YRES scaled)
	local iSpreadDistance = 0
	if bHasWep and (st == 2 or st == 3) then
		local fHalfFov = math.rad(lp:GetFOV()) * 0.5
		local fSpreadDist = (wep:GetInaccuracy(true) + wep:GetSpread()) * 320.0 / math.tan(fHalfFov)
		iSpreadDistance = math.floor(YRES(fSpreadDist))
	end

	-- Styles 0 and 5: expand g_XhairDist when shots are fired, then decay
	if bHasWep and (st == 0 or st == 5) and wep.GetShotsFired then
		-- Reset counter on weapon switch so we don't see a false spike
		if wep ~= g_LastWepEnt then
			g_LastWepEnt  = wep
			g_LastShots   = wep:GetShotsFired()
		end
		local shots = wep:GetShotsFired()
		if shots > g_LastShots and (lp:KeyDown(IN_ATTACK) or lp:KeyDown(IN_ATTACK2)) and wep:Clip1() >= 0 then
			if st == 5 then
				-- Classic Dynamic: direct bump by recoil magnitude
				local recoil = (wep.GetRecoilMagnitude and wep.GetWeaponMode)
					and wep:GetRecoilMagnitude(wep:GetWeaponMode()) or 4
				g_XhairDist = g_XhairDist + recoil / 3.5
			else
				-- Default Dynamic (style 0): bump by crosshair delta distance
				local iDelta = wep.GetCrosshairDeltaDistance and wep:GetCrosshairDeltaDistance() or 3
				g_XhairDist = g_XhairDist + iDelta
			end
		end
		g_LastShots = shots
	end

	-- Animate g_XhairDist toward base goal
	if st == 5 then
		g_XhairDist = g_XhairDist - 42 * FrameTime()
	else
		g_XhairDist = Lerp(FrameTime() / 0.025, fGoal, g_XhairDist)
	end
	g_XhairDist = math.Clamp(g_XhairDist, fGoal, 25.0)

	-- Resolve final crosshair distance by style
	local iCrossDist
	if st == 1 then
		-- Default Static: fixed gap only
		iCrossDist = fixGap
	elseif st == 4 then
		-- Classic Static: base goal + fixed gap
		iCrossDist = fGoal + fixGap
	elseif (st == 2 or st == 3) and iSpreadDistance > 0 then
		-- Accurate styles: live spread distance
		iCrossDist = iSpreadDistance + gap
	else
		-- Default (0), Classic Dynamic (5), and fallback for 2/3 with no weapon
		iCrossDist = math.floor(g_XhairDist * sh / 1200.0 + gap)
	end

	local cx = math.floor(ScrW() / 2)
	local cy = math.floor(ScrH() / 2)

	-- Функция рисования прямоугольника (x0,y0 — x1,y1)
	local function DrawXRect(r, g, b, a, x0, y0, x1, y1)
		local rw = math.max(x0, x1) - math.min(x0, x1)
		local rh = math.max(y0, y1) - math.min(y0, y1)
		if rw <= 0 or rh <= 0 then return end
		if ol then
			local ft = olT * 2
			surface.SetDrawColor(0, 0, 0, a)
			surface.DrawRect(x0 - math.floor(ft/2), y0 - math.floor(ft/2), rw + ft, rh + ft)
		end
		surface.SetDrawColor(r, g, b, a)
		if bAdd then
			if not g_XhairTexID then g_XhairTexID = surface.GetTextureID("vgui/white_additive") end
			surface.SetTexture(g_XhairTexID)
			surface.DrawTexturedRect(x0, y0, rw, rh)
		else
			surface.DrawRect(x0, y0, rw, rh)
		end
	end

	-- Горизонтальные линии
	local iIL = cx - iCrossDist - (iBarThick / 2)
	local iIR = iIL + (2 * iCrossDist) + iBarThick
	local y0  = cy - (iBarThick / 2)
	local y1  = y0 + iBarThick
	DrawXRect(cr, cg, cb, alpha, iIL - iBarSize, y0, iIL, y1)
	DrawXRect(cr, cg, cb, alpha, iIR, y0, iIR + iBarSize, y1)

	-- Вертикальные линии
	local iIT = cy - iCrossDist - (iBarThick / 2)
	local iIB = iIT + (2 * iCrossDist) + iBarThick
	local x0  = cx - (iBarThick / 2)
	local x1  = x0 + iBarThick
	if not tStyle then DrawXRect(cr, cg, cb, alpha, x0, iIT - iBarSize, x1, iIT) end
	DrawXRect(cr, cg, cb, alpha, x0, iIB, x1, iIB + iBarSize)

	-- Центральная точка
	if dot then
		local dx0 = cx - iBarThick / 2
		local dy0 = cy - iBarThick / 2
		DrawXRect(cr, cg, cb, alpha, dx0, dy0, dx0 + iBarThick, dy0 + iBarThick)
	end
end)

-- CSConstruct_OpenCrosshairSettings удалена — настройки прицела в меню F4

local function CSConstruct_OpenCrosshairSettings()
	if IsValid(CSCL.CrosshairMenu) then CSCL.CrosshairMenu:Remove() CSCL.CrosshairMenu = nil return end
	local hc = hudColor()

	local settW = 320
	local prevW = 180
	local totalW = settW + prevW + 20
	local totalH = 500

	local f = vgui.Create("DFrame")
	CSCL.CrosshairMenu = f
	f:SetTitle("")
	f:SetSize(totalW, totalH)
	f:Center()
	f:MakePopup()

	f.Paint = function(_, w, h)
		draw.RoundedBox(8, 0, 0, w, h, CS2.bg)
		surface.SetDrawColor(CS2.border)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		draw.RoundedBoxEx(8, 0, 0, w, 40, CS2.panel, true, true, false, false)
		surface.SetDrawColor(CS2.border)
		surface.DrawRect(0, 39, w, 1)
		draw.SimpleText("CROSSHAIR", "CS2_BuyTitle", 14, 11, CS2.text)
	end

	-- Close X
	local clBtn = vgui.Create("DButton", f)
	clBtn:SetPos(totalW - 36, 6)
	clBtn:SetSize(28, 28)
	clBtn:SetText("")
	clBtn.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, s:IsHovered() and Color(200, 55, 55) or Color(55, 55, 60))
		draw.SimpleText("X", "CS2_BuyCat", w / 2, h / 2, CS2.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	clBtn.DoClick = function() f:Close() end

	-- ====== PREVIEW (right side) ======
	local prevPanel = vgui.Create("DPanel", f)
	prevPanel:SetPos(settW + 12, 46)
	prevPanel:SetSize(prevW, totalH - 56)
	prevPanel.Paint = function(_, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(6, 6, 10))
		-- Grid
		surface.SetDrawColor(18, 18, 24)
		for i = 0, w, 16 do surface.DrawLine(i, 0, i, h) end
		for i = 0, h, 16 do surface.DrawLine(0, i, w, i) end
		draw.SimpleText("PREVIEW", "CS2_SB_Map", w / 2, 6, CS2.muted, TEXT_ALIGN_CENTER)

		-- Read ConVars
		local cvSize = GetConVar("swcs_crosshairsize")
		if not cvSize then
			draw.SimpleText("SWCS not loaded", "CS2_SB_Map", w / 2, h / 2, CS2.red, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			return
		end

		local xSize = cvSize:GetFloat()
		local xGap = GetConVar("swcs_crosshairgap") and GetConVar("swcs_crosshairgap"):GetFloat() or 0
		local xThick = math.max(0.5, GetConVar("swcs_crosshairthickness") and GetConVar("swcs_crosshairthickness"):GetFloat() or 1)
		local xDot = GetConVar("swcs_crosshairdot") and GetConVar("swcs_crosshairdot"):GetBool() or false
		local xT = GetConVar("swcs_crosshair_t") and GetConVar("swcs_crosshair_t"):GetBool() or false
		local xAlpha = GetConVar("swcs_crosshairalpha") and GetConVar("swcs_crosshairalpha"):GetInt() or 200
		local xOL = GetConVar("swcs_crosshair_drawoutline") and GetConVar("swcs_crosshair_drawoutline"):GetBool() or false
		local xOLT = GetConVar("swcs_crosshair_outlinethickness") and GetConVar("swcs_crosshair_outlinethickness"):GetFloat() or 1
		local xStyle = GetConVar("swcs_crosshairstyle") and GetConVar("swcs_crosshairstyle"):GetInt() or 4

		if xStyle == 1 or xStyle == 4 then
			xGap = GetConVar("swcs_crosshair_fixedgap") and GetConVar("swcs_crosshair_fixedgap"):GetFloat() or 3
		end

		-- Color
		local xPreset = GetConVar("swcs_crosshaircolor") and GetConVar("swcs_crosshaircolor"):GetInt() or 1
		local cr, cg, cb = 0, 255, 0
		if xPreset == 0 then cr, cg, cb = 255, 0, 0
		elseif xPreset == 2 then cr, cg, cb = 255, 255, 0
		elseif xPreset == 3 then cr, cg, cb = 0, 0, 255
		elseif xPreset == 4 then cr, cg, cb = 0, 255, 255
		elseif xPreset == 5 then
			cr = GetConVar("swcs_crosshaircolor_r") and GetConVar("swcs_crosshaircolor_r"):GetInt() or 255
			cg = GetConVar("swcs_crosshaircolor_g") and GetConVar("swcs_crosshaircolor_g"):GetInt() or 0
			cb = GetConVar("swcs_crosshaircolor_b") and GetConVar("swcs_crosshaircolor_b"):GetInt() or 255
		end

		local col = Color(cr, cg, cb, xAlpha)
		local olC = Color(0, 0, 0, xAlpha)
		local cx, cy = math.floor(w / 2), math.floor(h / 2)

		-- Scale 2.5x for preview
		local sc = 2.5
		local gS = xGap * sc
		local sS = xSize * sc
		local tS = math.max(1, xThick * sc)
		local htS = math.floor(tS / 2)
		local oS = math.max(1, math.floor(xOLT * sc))

		local lines = {}
		if not xT then table.insert(lines, { cx - htS, cy - gS - sS, tS, sS }) end
		table.insert(lines, { cx - htS, cy + gS, tS, sS })
		table.insert(lines, { cx - gS - sS, cy - htS, sS, tS })
		table.insert(lines, { cx + gS, cy - htS, sS, tS })

		if xOL then
			surface.SetDrawColor(olC)
			for _, l in ipairs(lines) do surface.DrawRect(l[1] - oS, l[2] - oS, l[3] + oS * 2, l[4] + oS * 2) end
		end
		surface.SetDrawColor(col)
		for _, l in ipairs(lines) do surface.DrawRect(l[1], l[2], l[3], l[4]) end

		if xDot then
			local ds = math.max(2, tS)
			local dh = math.floor(ds / 2)
			if xOL then surface.SetDrawColor(olC) surface.DrawRect(cx - dh - oS, cy - dh - oS, ds + oS * 2, ds + oS * 2) end
			surface.SetDrawColor(col) surface.DrawRect(cx - dh, cy - dh, ds, ds)
		end

		-- Style name
		local styleNames = { [0] = "Default", "Default Static", "Accurate Split", "Accurate Dynamic", "Classic Static", "Old CS" }
		draw.SimpleText(styleNames[xStyle] or "", "CS2_SB_Map", w / 2, h - 6, CS2.muted, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
	end

	-- ====== SETTINGS (left side, scrollable) ======
	local scrollW = settW - 16

	local scroll = vgui.Create("DScrollPanel", f)
	scroll:SetPos(8, 46)
	scroll:SetSize(scrollW, totalH - 56)

	local sb = scroll:GetVBar()
	sb:SetWide(4)
	sb.Paint = function() end
	sb.btnUp.Paint = function() end
	sb.btnDown.Paint = function() end
	sb.btnGrip.Paint = function(s, bw, bh) draw.RoundedBox(2, 0, 0, bw, bh, CS2.border) end

	local innerW = scrollW - 12 -- usable width inside scroll

	local function addHdr(text)
		local p = vgui.Create("DPanel", scroll)
		p:Dock(TOP)
		p:DockMargin(0, 6, 0, 3)
		p:SetTall(18)
		p:SetPaintBackground(false)
		p.Paint = function(_, pw, ph2)
			surface.SetDrawColor(hc.r, hc.g, hc.b, 40)
			surface.DrawRect(0, ph2 - 1, pw, 1)
			draw.SimpleText(text, "CS2_BuyCat", 2, ph2 / 2, hc, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		end
	end

	local function addSl(label, cv, mn, mx, dec)
		local p = vgui.Create("DPanel", scroll)
		p:Dock(TOP)
		p:DockMargin(0, 0, 0, 2)
		p:SetTall(44)
		p:SetPaintBackground(false)
		p.Paint = function(_, pw, ph2)
			draw.SimpleText(label, "CS2_SB_Map", 2, 6, CS2.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end

		local sl = vgui.Create("DNumSlider", p)
		sl:SetPos(2, 18)
		sl:SetSize(innerW - 4, 22)
		sl:SetMin(mn)
		sl:SetMax(mx)
		sl:SetDecimals(dec or 0)
		sl:SetConVar(cv)
		sl:SetText("")
	end

	local function addCk(label, cv)
		local p = vgui.Create("DCheckBoxLabel", scroll)
		p:Dock(TOP)
		p:DockMargin(2, 2, 0, 2)
		p:SetTall(18)
		p:SetText(label)
		p:SetConVar(cv)
		p:SetTextColor(CS2.text)
		p:SetFont("CS2_SB_Map")
	end

	-- == CS2 CODE ==
	addHdr("CS2 CODE")

	local codeRow = vgui.Create("DPanel", scroll)
	codeRow:Dock(TOP)
	codeRow:DockMargin(0, 0, 0, 4)
	codeRow:SetTall(28)
	codeRow:SetPaintBackground(false)

	local codeEntry = vgui.Create("DTextEntry", codeRow)
	codeEntry:SetPos(0, 0)
	codeEntry:SetSize(innerW - 70, 26)
	codeEntry:SetPlaceholderText("CSGO-XXXXX-XXXXX-...")
	codeEntry:SetFont("CS2_SB_Map")

	local applyBtn = vgui.Create("DButton", codeRow)
	applyBtn:SetPos(innerW - 64, 0)
	applyBtn:SetSize(60, 26)
	applyBtn:SetText("")
	applyBtn.Paint = function(s, bw, bh)
		draw.RoundedBox(3, 0, 0, bw, bh, s:IsHovered() and Color(55, 120, 55) or Color(45, 90, 45))
		draw.SimpleText("APPLY", "CS2_SB_Map", bw / 2, bh / 2, CS2.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	applyBtn.DoClick = function()
		local code = codeEntry:GetValue()
		if code ~= "" and swcs and swcs.ApplyCrosshairCode then
			swcs.ApplyCrosshairCode(code)
		end
	end

	-- == STYLE ==
	addHdr("STYLE")

	local styleBox = vgui.Create("DComboBox", scroll)
	styleBox:Dock(TOP)
	styleBox:DockMargin(0, 0, 0, 4)
	styleBox:SetTall(24)
	styleBox:AddChoice("0 - Default", 0)
	styleBox:AddChoice("1 - Default Static", 1)
	styleBox:AddChoice("2 - Accurate Split", 2)
	styleBox:AddChoice("3 - Accurate Dynamic", 3)
	styleBox:AddChoice("4 - Classic Static", 4)
	styleBox:AddChoice("5 - Old CS", 5)
	local curStyle = GetConVar("swcs_crosshairstyle")
	if curStyle then styleBox:ChooseOptionID(curStyle:GetInt() + 1) end
	styleBox.OnSelect = function(_, _, _, d) RunConsoleCommand("swcs_crosshairstyle", tostring(d)) end

	-- == SIZE & GAP ==
	addHdr("SIZE & GAP")
	addSl("Size", "swcs_crosshairsize", 0, 20)
	addSl("Gap", "swcs_crosshairgap", -10, 10)
	addSl("Thickness", "swcs_crosshairthickness", 0.5, 5, 1)
	addSl("Fixed Gap", "swcs_crosshair_fixedgap", 0, 20)
	addCk("Center Dot", "swcs_crosshairdot")
	addCk("T-Style (no top)", "swcs_crosshair_t")

	-- == COLOR ==
	addHdr("COLOR")

	local colorBox = vgui.Create("DComboBox", scroll)
	colorBox:Dock(TOP)
	colorBox:DockMargin(0, 0, 0, 4)
	colorBox:SetTall(24)
	colorBox:AddChoice("0 - Red", 0)
	colorBox:AddChoice("1 - Green", 1)
	colorBox:AddChoice("2 - Yellow", 2)
	colorBox:AddChoice("3 - Blue", 3)
	colorBox:AddChoice("4 - Cyan", 4)
	colorBox:AddChoice("5 - Custom RGB", 5)
	local curCol = GetConVar("swcs_crosshaircolor")
	if curCol then colorBox:ChooseOptionID(curCol:GetInt() + 1) end
	colorBox.OnSelect = function(_, _, _, d) RunConsoleCommand("swcs_crosshaircolor", tostring(d)) end

	addSl("Red", "swcs_crosshaircolor_r", 0, 255)
	addSl("Green", "swcs_crosshaircolor_g", 0, 255)
	addSl("Blue", "swcs_crosshaircolor_b", 0, 255)
	addSl("Alpha", "swcs_crosshairalpha", 0, 255)

	-- == OUTLINE ==
	addHdr("OUTLINE")
	addCk("Draw Outline", "swcs_crosshair_drawoutline")
	addSl("Thickness", "swcs_crosshair_outlinethickness", 0.1, 3, 1)

	f.OnRemove = function() CSCL.CrosshairMenu = nil end
end

-- ============================================================
-- HIDE DEFAULT HUD
-- ============================================================

local hudHide = {
	CHudHealth = true, CHudBattery = true, CHudAmmo = true,
	CHudSecondaryAmmo = true, CHudWeaponSelection = true,
	CHudDamageIndicator = true, CHudZoom = true,
	CHudPoisonDamageIndicator = true, CHudGeiger = true,
	CHudSquadStatus = true, CHudQuickInfo = true,
	CHudWeapon = true, CHudHistoryResource = true, CHudHL2Info = true,
	CHudCrosshair = true, -- прицел рисуем сами через CSConstruct_Crosshair
}
function GM:HUDShouldDraw(name)
	if hudHide[name] then return false end
	local bc = self.BaseClass
	if bc and bc.HUDShouldDraw then return bc.HUDShouldDraw(self, name) end
	return true
end
function GM:HUDDrawPickupHistory() end
hook.Add("SpawnMenuOpen", "CSConstruct_BlockSpawnMenu", function() return true end)
concommand.Add("cs_construct_close_buy", function() CSConstruct_CloseBuyMenu() CSCL._buyBSuppressUntil = CurTime() + 0.25 end)

