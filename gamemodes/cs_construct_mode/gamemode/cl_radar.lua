-- ============================================================
-- CS2-STYLE CIRCULAR RADAR  (top-right corner)
-- ============================================================

-- Radar geometry (screen-relative, computed on first draw)
local RDR_PAD  = 12          -- отступ от края экрана
local RDR_FRAC = 0.105       -- радиус = ScrH() * RDR_FRAC

-- После первого кадра сюда записываем нижний край радара,
-- чтобы killfeed мог начинаться ниже него.
CS_RADAR_BOTTOM = 0

-- ============================================================
-- OVERVIEW: координаты карты
-- ============================================================
-- pos_x, pos_y — левый верхний угол текстуры в мировых единицах
-- scale        — мировых единиц на пиксель текстуры
-- Стандарт de_dust2 (используется как запасной вариант)
local OV_DEFAULT = { pos_x = -2476, pos_y = 3239, scale = 4.4 }

local overviewCache = {}   -- [mapName] = { pos_x, pos_y, scale }

local function parseOverviewTxt(mapName)
	if overviewCache[mapName] then return overviewCache[mapName] end

	-- Пробуем прочитать из resource/overviews/<map>.txt
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

	-- Фоллбэк: если карта называется de_dust2new — используем dust2
	if mapName:find("dust2") then
		overviewCache[mapName] = OV_DEFAULT
	else
		-- Для неизвестной карты — нулевые данные (без текстуры)
		overviewCache[mapName] = { pos_x = 0, pos_y = 0, scale = 1, nomap = true }
	end
	return overviewCache[mapName]
end

-- ============================================================
-- ОБЗОРНАЯ ТЕКСТУРА
-- ============================================================
local matCache = {}
local MAT_ERROR = nil  -- лениво инициализируется

local function getOverviewMat(mapName)
	if matCache[mapName] ~= nil then return matCache[mapName] end

	-- Пробуем стандартный путь CS:GO overview
	local paths = {
		"overviews/" .. mapName .. "_radar",
		"overviews/de_dust2_radar",   -- фоллбэк на dust2 если карта его вариант
	}
	for _, p in ipairs(paths) do
		local m = Material(p)
		if not m:IsError() then
			matCache[mapName] = m
			return m
		end
		-- Пробуем и без .vmt расширения
	end
	matCache[mapName] = false  -- нет текстуры
	return false
end

-- ============================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

-- Мировые координаты -> позиция на радаре (относительно центра), нормировано [-1, 1]
local function worldToNorm(wx, wy, ov)
	-- u, v — координаты на текстуре 1024×1024 в диапазоне [0, 1]
	local u = (wx - ov.pos_x) / (1024 * ov.scale)
	local v = (ov.pos_y - wy) / (1024 * ov.scale)
	-- центрируем: [-0.5, 0.5] -> [-1, 1]
	return (u - 0.5) * 2, (v - 0.5) * 2
end

-- Закрашенный круг через DrawPoly
local _cpoly = {}
local function filledCircle(cx, cy, r, col)
	local steps = 20
	for i = 1, steps do
		local a = (i / steps) * math.pi * 2
		_cpoly[i] = { x = cx + math.cos(a) * r, y = cy + math.sin(a) * r }
	end
	draw.NoTexture()
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	surface.DrawPoly(_cpoly)
end

-- Кружок (контур)
local function circleOutline(cx, cy, r, thick, col)
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	for i = 0, 360, 2 do
		local a1 = math.rad(i)
		local a2 = math.rad(i + 2)
		-- рисуем тонкие прямоугольники по окружности
		local x1, y1 = cx + math.cos(a1) * r, cy + math.sin(a1) * r
		local x2, y2 = cx + math.cos(a2) * r, cy + math.sin(a2) * r
		surface.DrawLine(math.floor(x1), math.floor(y1), math.floor(x2), math.floor(y2))
	end
end

-- Стрелка направления от точки
local function drawArrow(cx, cy, yaw, len, col)
	local rad = math.rad(yaw)
	local ex = cx + math.sin(rad) * len
	local ey = cy - math.cos(rad) * len
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	surface.DrawLine(math.floor(cx), math.floor(cy), math.floor(ex), math.floor(ey))
	-- Наконечник-треугольник
	local w1 = math.rad(yaw + 145)
	local w2 = math.rad(yaw - 145)
	draw.NoTexture()
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	surface.DrawPoly({
		{ x = ex,                              y = ey                              },
		{ x = ex + math.sin(w1) * len * 0.42, y = ey - math.cos(w1) * len * 0.42 },
		{ x = ex + math.sin(w2) * len * 0.42, y = ey - math.cos(w2) * len * 0.42 },
	})
end

-- ============================================================
-- СТЕНСИЛ-МАСКА (круговое клиппирование)
-- ============================================================
local function beginCircleClip(cx, cy, r)
	render.ClearStencil()
	render.SetStencilEnable(true)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)
	render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
	render.SetStencilPassOperation(STENCILOPERATION_ZERO)
	render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
	render.SetStencilReferenceValue(1)

	local poly = {}
	for i = 1, 36 do
		local a = (i / 36) * math.pi * 2
		poly[i] = { x = cx + math.cos(a) * r, y = cy + math.sin(a) * r }
	end
	draw.NoTexture()
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawPoly(poly)

	render.SetStencilFailOperation(STENCILOPERATION_ZERO)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilZFailOperation(STENCILOPERATION_ZERO)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	render.SetStencilReferenceValue(1)
end

local function endCircleClip()
	render.SetStencilEnable(false)
	render.ClearStencil()
end

-- ============================================================
-- ОСНОВНОЙ HUD HOOK
-- ============================================================

hook.Add("HUDPaint", "CSMode_Radar", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	if CSCL.Phase == PHASE_LOBBY then return end

	local sw, sh = ScrW(), ScrH()
	local R    = math.floor(sh * RDR_FRAC)
	local cx   = sw - RDR_PAD - R
	local cy   = RDR_PAD + R

	-- Публикуем нижний край радара (killfeed начнётся ниже)
	CS_RADAR_BOTTOM = cy + R + RDR_PAD

	local mapName = game.GetMap()
	local ov      = parseOverviewTxt(mapName)
	local mat     = not ov.nomap and getOverviewMat(mapName) or false

	-- ---- Фон (тёмный круг, виден если нет текстуры) ----
	filledCircle(cx, cy, R, Color(12, 14, 18, 215))

	-- ---- Начинаем круговой клиппинг ----
	beginCircleClip(cx, cy, R)

	-- ---- Карта (overview текстура) ----
	if mat then
		surface.SetMaterial(mat)
		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawTexturedRect(cx - R, cy - R, R * 2, R * 2)

		-- Слой затемнения поверх текстуры для читаемости точек
		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 80)
		surface.DrawRect(cx - R, cy - R, R * 2, R * 2)
	else
		-- Нет текстуры — тонкая сетка
		surface.SetDrawColor(30, 35, 44, 100)
		local step = R / 2
		for dx = -R, R, step do
			surface.DrawLine(math.floor(cx + dx), cy - R, math.floor(cx + dx), cy + R)
		end
		for dy = -R, R, step do
			surface.DrawLine(cx - R, math.floor(cy + dy), cx + R, math.floor(cy + dy))
		end
	end

	-- ---- Игроки ----
	local lpTeam  = lp:Team()
	local lpAlive = lp:Alive()
	local showAll = (CSCL.GameMode == GAMEMODE_TRAINING) or not lpAlive

	local dotR   = math.max(3, math.floor(R * 0.045))
	local arrowL = math.max(6, math.floor(R * 0.12))

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) then continue end
		local isPlaying = ply:Team() == TEAM_T or ply:Team() == TEAM_CT
		if not isPlaying then continue end

		local isSelf     = ply == lp
		local isEnemy    = ply:Team() ~= lpTeam
		if isEnemy and not showAll then continue end
		if not ply:Alive() and not isSelf then continue end

		local pos = ply:GetPos()
		local nx, ny

		if ov.nomap then
			-- Нет данных о карте — динамическая нормировка не реализована,
			-- просто пропускаем отображение без текстуры
			nx, ny = worldToNorm(pos.x, pos.y, OV_DEFAULT)
		else
			nx, ny = worldToNorm(pos.x, pos.y, ov)
		end

		local sx = cx + nx * R
		local sy = cy + ny * R

		local col
		if isSelf then
			col = Color(100, 225, 115, 255)
		elseif not isEnemy then
			col = Color(65, 175, 80, 220)
		else
			col = Color(215, 55, 55, 220)
		end

		local r = isSelf and (dotR + 1) or dotR

		-- Тень
		filledCircle(sx, sy, r + 1.5, Color(0, 0, 0, 140))
		-- Точка
		filledCircle(sx, sy, r, col)
		-- Стрелка взгляда
		local yaw = ply:EyeAngles().y
		drawArrow(sx, sy, yaw, arrowL, Color(col.r, col.g, col.b, 200))
	end

	-- ---- Установленная бомба ----
	for _, ent in ipairs(ents.FindByClass("swcs_planted_c4")) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local nx, ny = worldToNorm(pos.x, pos.y, ov.nomap and OV_DEFAULT or ov)
		local sx = cx + nx * R
		local sy = cy + ny * R
		local pulse = math.floor(math.abs(math.sin(CurTime() * 3.5)) * 110 + 145)
		local bs = math.max(4, math.floor(R * 0.04))
		surface.SetDrawColor(255, 200, 0, pulse)
		surface.DrawRect(math.floor(sx - bs), math.floor(sy - 1), bs * 2, 2)
		surface.DrawRect(math.floor(sx - 1), math.floor(sy - bs), 2, bs * 2)
	end

	-- ---- Конец клиппинга ----
	endCircleClip()

	-- ---- Рамка (поверх клиппинга, чтобы не обрезалась) ----
	-- Внешняя тёмная окантовка
	circleOutline(cx, cy, R + 1, 1, Color(20, 22, 28, 255))
	-- Основная рамка
	circleOutline(cx, cy, R, 1, Color(65, 72, 85, 255))

	-- ---- Метка карты ----
	draw.SimpleText(mapName, "CS2H_Tiny",
		cx, cy + R + 3,
		Color(65, 75, 90, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)
