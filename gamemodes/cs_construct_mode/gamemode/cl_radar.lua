-- ============================================================
-- CS2-STYLE SQUARE RADAR
-- Квадратный радар с севером вверху, иконки — треугольники
-- ============================================================

local RDR_PAD       = 12     -- отступ от края экрана
local RDR_SIZE_FRAC = 0.195  -- сторона квадрата = ScrH() * RDR_SIZE_FRAC
local RDR_INNER_PAD = 2      -- отступ между рамкой и картой

CS_RADAR_BOTTOM = 0

-- ============================================================
-- OVERVIEW
-- ============================================================
local OV_DEFAULT = { pos_x = -2476, pos_y = 3239, scale = 4.4 }
local overviewCache = {}

local function parseOverviewTxt(mapName)
	if overviewCache[mapName] then return overviewCache[mapName] end
	local txt = file.Read("resource/overviews/" .. mapName .. ".txt", "GAME")
	if txt then
		local px = tonumber(txt:match('"pos_x"%s+"([%-%.%d]+)"'))
		local py = tonumber(txt:match('"pos_y"%s+"([%-%.%d]+)"'))
		local sc = tonumber(txt:match('"scale"%s+"([%-%.%d]+)"'))
		if px and py and sc then
			overviewCache[mapName] = { pos_x = px, pos_y = py, scale = sc }
			return overviewCache[mapName]
		end
	end
	if mapName:find("dust2") then
		overviewCache[mapName] = OV_DEFAULT
	else
		overviewCache[mapName] = { pos_x = 0, pos_y = 0, scale = 1, nomap = true }
	end
	return overviewCache[mapName]
end

local matCache = {}
local function getOverviewMat(mapName)
	if matCache[mapName] ~= nil then return matCache[mapName] end
	local m = Material("overviews/" .. mapName .. "_radar")
	if not m:IsError() then matCache[mapName] = m return m end
	m = Material("overviews/de_dust2_radar")
	if not m:IsError() then matCache[mapName] = m return m end
	matCache[mapName] = false
	return false
end

-- ============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

-- Мировые координаты → нормализованные [-1, 1] для радара
local function worldToNorm(wx, wy, ov)
	local u = (wx - ov.pos_x) / (1024 * ov.scale)
	local v = (ov.pos_y - wy) / (1024 * ov.scale)
	return (u - 0.5) * 2, (v - 0.5) * 2
end

-- Проверка: точка в видимой зоне карты
local function inBounds(nx, ny)
	return nx >= -1 and nx <= 1 and ny >= -1 and ny <= 1
end

-- Треугольная иконка игрока (кончик = направление взгляда)
local function drawPlayerTriangle(px, py, yaw, r, col)
	local rad  = math.rad(yaw)
	local sinY = math.sin(rad)
	local cosY = math.cos(rad)
	-- Кончик — вперёд
	local tipX = px + sinY * r * 1.4
	local tipY = py - cosY * r * 1.4
	-- Основание — назад
	local baseX = px - sinY * r
	local baseY = py + cosY * r
	-- Левый и правый углы основания
	local leftX  = baseX + cosY * r * 0.85
	local leftY  = baseY + sinY * r * 0.85
	local rightX = baseX - cosY * r * 0.85
	local rightY = baseY - sinY * r * 0.85

	draw.NoTexture()
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	surface.DrawPoly({
		{ x = tipX,   y = tipY   },
		{ x = leftX,  y = leftY  },
		{ x = rightX, y = rightY },
	})
end

-- ============================================================
-- ЦВЕТА
-- ============================================================
local COL_SELF   = Color(255, 255, 255, 255)
local COL_ALLY   = Color(100, 225, 115, 255)
local COL_ENEMY  = Color(215,  55,  55, 220)
local COL_DEAD   = Color(120, 120, 130, 130)
local COL_SHADOW = Color(  0,   0,   0, 160)
local COL_BOMB   = Color(255, 200,   0)

-- ============================================================
-- HUD HOOK
-- ============================================================
hook.Add("HUDPaint", "CSMode_Radar", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	if CSCL.Phase == PHASE_LOBBY then return end

	local sh = ScrH()
	local S  = math.floor(sh * RDR_SIZE_FRAC)
	local ox = RDR_PAD
	local oy = RDR_PAD
	local HS = (S - RDR_INNER_PAD * 2) / 2
	local cx = ox + S / 2
	local cy = oy + S / 2

	CS_RADAR_BOTTOM = oy + S + RDR_PAD

	local mapName = game.GetMap()
	local ov      = parseOverviewTxt(mapName)
	local mat     = not ov.nomap and getOverviewMat(mapName) or false
	local useOv   = ov.nomap and OV_DEFAULT or ov

	-- ---- Фон ----
	draw.NoTexture()
	surface.SetDrawColor(12, 14, 18, 215)
	surface.DrawRect(ox, oy, S, S)

	-- ---- Карта ----
	local mp = RDR_INNER_PAD
	if mat then
		surface.SetMaterial(mat)
		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawTexturedRect(ox + mp, oy + mp, S - mp * 2, S - mp * 2)
		-- Тёмный оверлей для читаемости иконок
		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 75)
		surface.DrawRect(ox + mp, oy + mp, S - mp * 2, S - mp * 2)
	else
		-- Сетка если карта неизвестна
		surface.SetDrawColor(30, 35, 44, 100)
		local step = math.floor(S / 4)
		for dx = step, S - step, step do
			surface.DrawLine(ox + dx, oy, ox + dx, oy + S)
		end
		for dy = step, S - step, step do
			surface.DrawLine(ox, oy + dy, ox + S, oy + dy)
		end
	end

	local lpTeam  = lp:Team()
	local lpAlive = lp:Alive()
	local showAll = (CSCL.GameMode == GAMEMODE_TRAINING) or not lpAlive

	local triR     = math.max(4, math.floor(HS * 0.048))
	local selfTriR = triR + 2

	-- ---- Игроки ----
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) then continue end
		local plyrTeam = ply:Team()
		if plyrTeam ~= TEAM_T and plyrTeam ~= TEAM_CT then continue end

		local isSelf  = ply == lp
		local isEnemy = plyrTeam ~= lpTeam

		if isEnemy and not showAll then continue end

		local pos = ply:GetPos()
		local nx, ny = worldToNorm(pos.x, pos.y, useOv)
		if not inBounds(nx, ny) then continue end

		local sx = math.floor(cx + nx * HS)
		local sy = math.floor(cy + ny * HS)

		if not ply:Alive() then
			if isSelf then continue end
			-- Мёртвый союзник — маленький серый квадрат
			local ds = 3
			surface.SetDrawColor(COL_DEAD.r, COL_DEAD.g, COL_DEAD.b, COL_DEAD.a)
			surface.DrawRect(sx - ds, sy - ds, ds * 2, ds * 2)
			continue
		end

		local yaw = ply:EyeAngles().y
		local r   = isSelf and selfTriR or triR
		local col
		if isSelf then
			col = COL_SELF
		elseif not isEnemy then
			col = COL_ALLY
		else
			col = COL_ENEMY
		end

		-- Тень
		drawPlayerTriangle(sx + 1, sy + 1, yaw, r, COL_SHADOW)
		-- Иконка
		drawPlayerTriangle(sx, sy, yaw, r, col)
	end

	-- ---- Боты (workshop NPCs) ----
	local botClasses = {
		["css_bot_t_csgo"]  = TEAM_T,
		["css_bot_ct_csgo"] = TEAM_CT,
	}
	for cls, botTeam in pairs(botClasses) do
		for _, bot in ipairs(ents.FindByClass(cls)) do
			if not IsValid(bot) then continue end
			local isEnemy = botTeam ~= lpTeam
			if isEnemy and not showAll then continue end

			local pos = bot:GetPos()
			local nx, ny = worldToNorm(pos.x, pos.y, useOv)
			if not inBounds(nx, ny) then continue end

			local sx  = math.floor(cx + nx * HS)
			local sy  = math.floor(cy + ny * HS)
			local yaw = bot:GetAngles().y
			local col = isEnemy and COL_ENEMY or COL_ALLY

			drawPlayerTriangle(sx + 1, sy + 1, yaw, triR, COL_SHADOW)
			drawPlayerTriangle(sx, sy, yaw, triR, col)
		end
	end

	-- ---- Бомба ----
	for _, ent in ipairs(ents.FindByClass("swcs_planted_c4")) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local nx, ny = worldToNorm(pos.x, pos.y, useOv)
		if not inBounds(nx, ny) then continue end

		local sx    = math.floor(cx + nx * HS)
		local sy    = math.floor(cy + ny * HS)
		local pulse = math.floor(math.abs(math.sin(CurTime() * 3.5)) * 110 + 145)
		local bs    = math.max(4, math.floor(HS * 0.04))

		surface.SetDrawColor(COL_BOMB.r, COL_BOMB.g, COL_BOMB.b, pulse)
		surface.DrawRect(sx - bs, sy - 1, bs * 2, 2)
		surface.DrawRect(sx - 1, sy - bs, 2, bs * 2)
	end

	-- ---- Рамка (поверх всего) ----
	draw.NoTexture()
	surface.SetDrawColor(20, 22, 28, 255)
	surface.DrawOutlinedRect(ox - 1, oy - 1, S + 2, S + 2, 1)
	surface.SetDrawColor(55, 62, 75, 255)
	surface.DrawOutlinedRect(ox, oy, S, S, 1)

	-- ---- Подпись карты ----
	draw.SimpleText(mapName, "CS2H_Tiny",
		ox + S / 2, oy + S + 3,
		Color(65, 75, 90, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)
