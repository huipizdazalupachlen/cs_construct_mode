-- ============================================================
-- CS Construct — Лобби в стиле CS2
-- ============================================================

local LobbyFrame = nil
local CurrentGameMode = GAMEMODE_COMPETITIVE
local SelectedKnife = nil

-- Цвета CS2
local CS2_BG         = Color(14, 14, 18, 252)
local CS2_PANEL      = Color(22, 22, 28, 240)
local CS2_PANEL_LT   = Color(28, 28, 36, 230)
local CS2_BORDER     = Color(44, 44, 52, 255)
local CS2_TEXT       = Color(210, 210, 215, 255)
local CS2_MUTED      = Color(100, 100, 110, 255)
local CS2_ACCENT     = Color(87, 186, 255, 255)    -- голубой как в CS2 HUD моде
local CS2_GREEN      = Color(76, 175, 80, 255)
local CS2_T          = Color(222, 155, 53, 255)    -- оранжево-жёлтый T CS2
local CS2_CT         = Color(93, 121, 174, 255)    -- синий CT CS2
local CS2_BTN        = Color(38, 38, 46, 255)
local CS2_BTN_HOVER  = Color(50, 50, 60, 255)
local CS2_BTN_ACTIVE = Color(62, 100, 60, 255)

-- Шрифты
surface.CreateFont("CS2_Lobby_Title", { font = "Goodland SemiBold", size = 28, antialias = true })
surface.CreateFont("CS2_Lobby_Sub",   { font = "Goodland SemiBold", size = 16, antialias = true })
surface.CreateFont("CS2_Lobby_Btn",   { font = "Goodland SemiBold", size = 15, antialias = true })
surface.CreateFont("CS2_Lobby_Small", { font = "Goodland SemiBold", size = 12, antialias = true })
surface.CreateFont("CS2_Lobby_Big",   { font = "Goodland SemiBold", size = 20, antialias = true })
surface.CreateFont("CS2_Lobby_Knife", { font = "Goodland SemiBold", size = 13, antialias = true })

net.Receive("CSMode_OpenLobby", function()
	CurrentGameMode = net.ReadUInt(8)
	OpenLobby()
end)

net.Receive("CSMode_LobbyUpdate", function()
	CurrentGameMode = net.ReadUInt(8)
	if IsValid(LobbyFrame) and LobbyFrame.RefreshGameMode then
		LobbyFrame:RefreshGameMode()
	end
end)

-- Кнопка CS2
local function CS2Button(parent, x, y, w, h, text, onClick, options)
	options = options or {}
	local btn = vgui.Create("DButton", parent)
	btn:SetPos(x, y)
	btn:SetSize(w, h)
	btn:SetText("")
	btn.CS2_Active = false

	btn.Paint = function(s, bw, bh)
		local bg = CS2_BTN
		if s.CS2_Active then bg = CS2_BTN_ACTIVE end
		if s:IsHovered() then bg = Color(bg.r + 12, bg.g + 12, bg.b + 12, bg.a) end

		draw.RoundedBox(4, 0, 0, bw, bh, bg)

		local textCol = s.CS2_Active and CS2_TEXT or (options.textColor or CS2_TEXT)
		draw.SimpleText(text, options.font or "CS2_Lobby_Btn", bw / 2, bh / 2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

		if options.subText then
			draw.SimpleText(options.subText, "CS2_Lobby_Small", bw / 2, bh / 2 + 12, CS2_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		end
	end

	btn.DoClick = onClick
	return btn
end

function OpenLobby()
	if IsValid(LobbyFrame) then LobbyFrame:Remove() end

	local fw, fh = ScrW() * 0.85, ScrH() * 0.85
	LobbyFrame = vgui.Create("DFrame")
	LobbyFrame:SetSize(fw, fh)
	LobbyFrame:Center()
	LobbyFrame:SetTitle("")
	LobbyFrame:SetDraggable(false)
	LobbyFrame:ShowCloseButton(false)
	LobbyFrame:MakePopup()

	local matGrad = surface.GetTextureID("gui/gradient")

	LobbyFrame.Paint = function(self, w, h)
		-- Фон
		draw.RoundedBox(6, 0, 0, w, h, CS2_BG)
		-- Верхняя полоса с градиентными линиями
		draw.RoundedBoxEx(4, 0, 0, w, 58, Color(18, 18, 24, 250), true, true, false, false)

		-- Градиентные линии от заголовка
		local lineLen = w * 0.3
		surface.SetDrawColor(CS2_ACCENT)
		surface.SetTexture(matGrad)
		surface.DrawTexturedRectRotated(w / 2 - lineLen / 2 - 40, 55, lineLen, 1, 180)
		surface.DrawTexturedRectRotated(w / 2 + lineLen / 2 + 40, 55, lineLen, 1, 0)

		-- Circle accent in center
		surface.DrawCircle(w / 2, 56, 4, CS2_ACCENT)

		-- Заголовок
		draw.SimpleText("CS CONSTRUCT", "CS2_Lobby_Title", w / 2, 12, CS2_ACCENT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
		draw.SimpleText("LOBBY", "CS2_Lobby_Sub", w / 2, 36, CS2_MUTED, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
	end

	-- ============ ЛЕВАЯ КОЛОНКА: Команды ============
	local leftW = math.floor(fw * 0.28)
	local contentY = 70
	local contentH = fh - contentY - 16

	local teamPanel = vgui.Create("DPanel", LobbyFrame)
	teamPanel:SetPos(16, contentY)
	teamPanel:SetSize(leftW, contentH)
	teamPanel.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, CS2_PANEL)
		surface.SetDrawColor(CS2_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		-- Accent line top
		surface.SetDrawColor(CS2_ACCENT.r, CS2_ACCENT.g, CS2_ACCENT.b, 60)
		surface.DrawRect(0, 0, w, 1)
	end

	-- T секция
	local tHeader = vgui.Create("DPanel", teamPanel)
	tHeader:SetPos(0, 0)
	tHeader:SetSize(leftW, 36)
	tHeader.Paint = function(s, w, h)
		draw.RoundedBoxEx(4, 0, 0, w, h, Color(CS2_T.r, CS2_T.g, CS2_T.b, 40), true, true, false, false)
		draw.SimpleText("TERRORISTS", "CS2_Lobby_Sub", 12, h / 2, CS2_T, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local tScroll = vgui.Create("DScrollPanel", teamPanel)
	tScroll:SetPos(8, 40)
	tScroll:SetSize(leftW - 16, contentH / 2 - 80)

	for _, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_T then
			local row = vgui.Create("DPanel", tScroll)
			row:Dock(TOP)
			row:DockMargin(0, 0, 0, 2)
			row:SetTall(28)
			row.Paint = function(s, w, h)
				draw.RoundedBox(2, 0, 0, w, h, CS2_PANEL_LT)
				draw.SimpleText(ply:Nick(), "CS2_Lobby_Small", 8, h / 2, CS2_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end
	end

	local btnJoinT = CS2Button(teamPanel, 8, contentH / 2 - 36, leftW - 16, 30, "JOIN T", function()
		net.Start("CSMode_SelectTeam")
		net.WriteUInt(TEAM_T, 8)
		net.SendToServer()
	end, { textColor = CS2_T })

	-- CT секция
	local ctY = contentH / 2 + 4
	local ctHeader = vgui.Create("DPanel", teamPanel)
	ctHeader:SetPos(0, ctY)
	ctHeader:SetSize(leftW, 36)
	ctHeader.Paint = function(s, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(CS2_CT.r, CS2_CT.g, CS2_CT.b, 40))
		draw.SimpleText("COUNTER-TERRORISTS", "CS2_Lobby_Sub", 12, h / 2, CS2_CT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end

	local ctScroll = vgui.Create("DScrollPanel", teamPanel)
	ctScroll:SetPos(8, ctY + 40)
	ctScroll:SetSize(leftW - 16, contentH / 2 - 80)

	for _, ply in ipairs(player.GetAll()) do
		if ply:Team() == TEAM_CT then
			local row = vgui.Create("DPanel", ctScroll)
			row:Dock(TOP)
			row:DockMargin(0, 0, 0, 2)
			row:SetTall(28)
			row.Paint = function(s, w, h)
				draw.RoundedBox(2, 0, 0, w, h, CS2_PANEL_LT)
				draw.SimpleText(ply:Nick(), "CS2_Lobby_Small", 8, h / 2, CS2_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end
	end

	local btnJoinCT = CS2Button(teamPanel, 8, contentH - 36, leftW - 16, 30, "JOIN CT", function()
		net.Start("CSMode_SelectTeam")
		net.WriteUInt(TEAM_CT, 8)
		net.SendToServer()
	end, { textColor = CS2_CT })

	-- ============ ЦЕНТР: Режим игры ============
	local centerX = leftW + 32
	local centerW = math.floor(fw * 0.36)

	local modePanel = vgui.Create("DPanel", LobbyFrame)
	modePanel:SetPos(centerX, contentY)
	modePanel:SetSize(centerW, contentH)
	modePanel.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, CS2_PANEL)
		surface.SetDrawColor(CS2_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		surface.SetDrawColor(CS2_ACCENT.r, CS2_ACCENT.g, CS2_ACCENT.b, 60)
		surface.DrawRect(0, 0, w, 1)
		draw.SimpleText("GAME MODE", "CS2_Lobby_Sub", 12, 12, CS2_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		-- Gradient underline
		surface.SetDrawColor(CS2_ACCENT)
		surface.SetTexture(matGrad)
		surface.DrawTexturedRectRotated(w / 2 + w * 0.15, 34, w * 0.6, 1, 0)
	end

	local modeButtons = {}
	local modes = { GAMEMODE_TRAINING, GAMEMODE_DUEL, GAMEMODE_CASUAL, GAMEMODE_COMPETITIVE }
	local modeY = 44

	for _, mode in ipairs(modes) do
		local data = CS_GAME_MODES[mode]
		if data then
			local btn = CS2Button(modePanel, 12, modeY, centerW - 24, 56, "", function()
				net.Start("CSMode_SetGameMode")
				net.WriteUInt(mode, 8)
				net.SendToServer()
				CurrentGameMode = mode
				for _, b in ipairs(modeButtons) do b.CS2_Active = (b.CS2_Mode == mode) end
			end)
			btn.CS2_Mode = mode
			btn.CS2_Active = (CurrentGameMode == mode)

			btn.Paint = function(s, bw, bh)
				local bg = CS2_BTN
				if s.CS2_Active then bg = CS2_BTN_ACTIVE end
				if s:IsHovered() then bg = Color(bg.r + 10, bg.g + 10, bg.b + 10, bg.a) end
				draw.RoundedBox(4, 0, 0, bw, bh, bg)
				draw.SimpleText(data.name, "CS2_Lobby_Big", 14, 12, s.CS2_Active and CS2_ACCENT or CS2_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				draw.SimpleText(data.description, "CS2_Lobby_Small", 14, 34, CS2_MUTED, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end

			table.insert(modeButtons, btn)
			modeY = modeY + 64
		end
	end

	-- Кнопка START
	local startBtn = vgui.Create("DButton", modePanel)
	startBtn:SetPos(12, contentH - 56)
	startBtn:SetSize(centerW - 24, 44)
	startBtn:SetText("")
	startBtn.Paint = function(s, bw, bh)
		local bg = s:IsHovered() and Color(96, 195, 100) or CS2_GREEN
		draw.RoundedBox(4, 0, 0, bw, bh, bg)
		-- Gradient lines
		surface.SetDrawColor(255, 255, 255, 40)
		surface.SetTexture(matGrad)
		surface.DrawTexturedRectRotated(bw / 2 - bw * 0.15, 3, bw * 0.4, 1, 180)
		surface.DrawTexturedRectRotated(bw / 2 + bw * 0.15, 3, bw * 0.4, 1, 0)
		draw.SimpleText("START GAME", "CS2_Lobby_Big", bw / 2, bh / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	startBtn.DoClick = function()
		net.Start("CSMode_StartGame")
		net.SendToServer()
		if IsValid(LobbyFrame) then LobbyFrame:Close() end
	end

	-- ============ ПРАВАЯ КОЛОНКА: Ножи ============
	local rightX = centerX + centerW + 16
	local rightW = fw - rightX - 16

	local knifePanel = vgui.Create("DPanel", LobbyFrame)
	knifePanel:SetPos(rightX, contentY)
	knifePanel:SetSize(rightW, contentH)
	knifePanel.Paint = function(s, w, h)
		draw.RoundedBox(4, 0, 0, w, h, CS2_PANEL)
		surface.SetDrawColor(CS2_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
		surface.SetDrawColor(CS2_ACCENT.r, CS2_ACCENT.g, CS2_ACCENT.b, 60)
		surface.DrawRect(0, 0, w, 1)
		draw.SimpleText("KNIFE SELECT", "CS2_Lobby_Sub", 12, 12, CS2_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		surface.SetDrawColor(CS2_ACCENT)
		surface.SetTexture(matGrad)
		surface.DrawTexturedRectRotated(w / 2 + w * 0.15, 34, w * 0.6, 1, 0)
	end

	local knifeScroll = vgui.Create("DScrollPanel", knifePanel)
	knifeScroll:SetPos(8, 40)
	knifeScroll:SetSize(rightW - 16, contentH - 52)

	local sbar = knifeScroll:GetVBar()
	sbar:SetWide(4)
	sbar.Paint = function() end
	sbar.btnUp.Paint = function() end
	sbar.btnDown.Paint = function() end
	sbar.btnGrip.Paint = function(s, w, h)
		draw.RoundedBox(2, 0, 0, w, h, CS2_BORDER)
	end

	for _, knifeClass in ipairs(CS_KNIVES) do
		local kBtn = vgui.Create("DButton", knifeScroll)
		kBtn:Dock(TOP)
		kBtn:DockMargin(0, 0, 0, 2)
		kBtn:SetTall(30)
		kBtn:SetText("")

		kBtn.Paint = function(s, bw, bh)
			local isSelected = (SelectedKnife == knifeClass)
			local bg = isSelected and Color(48, 68, 46, 230) or CS2_PANEL_LT
			if s:IsHovered() and not isSelected then bg = Color(36, 36, 44, 240) end
			draw.RoundedBox(2, 0, 0, bw, bh, bg)
			local nameCol = isSelected and CS2_ACCENT or CS2_TEXT
			draw.SimpleText(CS_GetKnifeName(knifeClass), "CS2_Lobby_Knife", 10, bh / 2, nameCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			if isSelected then
				draw.SimpleText("✓", "CS2_Lobby_Knife", bw - 10, bh / 2, CS2_GREEN, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			end
		end

		kBtn.DoClick = function()
			SelectedKnife = knifeClass
			net.Start("CSMode_SelectKnife")
			net.WriteString(knifeClass)
			net.SendToServer()
		end
	end

	LobbyFrame.RefreshGameMode = function(self)
		for _, b in ipairs(modeButtons) do
			b.CS2_Active = (b.CS2_Mode == CurrentGameMode)
		end
	end
end

hook.Add("HUDPaint", "CSConstruct_CloseLobbyOnStart", function()
	if IsValid(LobbyFrame) and CSCL and CSCL.Phase ~= PHASE_LOBBY then
		LobbyFrame:Close()
		LobbyFrame = nil
	end
end)
