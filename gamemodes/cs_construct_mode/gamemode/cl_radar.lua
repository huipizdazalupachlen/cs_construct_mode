-- ============================================================
-- CS2-STYLE RADAR
-- ============================================================

local RDR_SIZE  = 210   -- размер квадрата радара (px)
local RDR_PAD   = 14    -- отступ от края экрана
local RDR_DOT   = 4     -- радиус точки игрока
local RDR_ARROW = 11    -- длина стрелки направления

-- Границы мира (расширяются динамически по мере того как игроки ходят)
-- Дефолт примерно соответствует de_dust2
local rdr = {
	minX = -2500, maxX = 2100,
	minY = -1300, maxY = 3300,
}

local function rdrExpand(pos)
	if pos.x - 300 < rdr.minX then rdr.minX = pos.x - 300 end
	if pos.x + 300 > rdr.maxX then rdr.maxX = pos.x + 300 end
	if pos.y - 300 < rdr.minY then rdr.minY = pos.y - 300 end
	if pos.y + 300 > rdr.maxY then rdr.maxY = pos.y + 300 end
end

-- Мировые координаты -> пиксели радара (относительно его начала)
local function rdrProject(wx, wy)
	local fx = (wx - rdr.minX) / (rdr.maxX - rdr.minX)
	local fy = 1 - (wy - rdr.minY) / (rdr.maxY - rdr.minY)
	return fx * RDR_SIZE, fy * RDR_SIZE
end

-- Заполненный круг через DrawPoly
local _circPoly = {}
local function drawFilledCircle(cx, cy, r, col)
	local n = 16
	for i = 1, n do
		local a = (i / n) * math.pi * 2
		_circPoly[i] = { x = cx + math.cos(a) * r, y = cy + math.sin(a) * r }
	end
	draw.NoTexture()
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	surface.DrawPoly(_circPoly)
end

-- Стрелка направления от центра точки
local function drawArrow(cx, cy, yaw, len, col)
	local rad = math.rad(yaw)
	local ex = cx + math.sin(rad) * len
	local ey = cy - math.cos(rad) * len
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	surface.DrawLine(math.floor(cx), math.floor(cy), math.floor(ex), math.floor(ey))
	-- Маленький треугольник-наконечник
	local wing = math.rad(yaw + 140)
	local wing2 = math.rad(yaw - 140)
	local wx1 = ex + math.sin(wing)  * (len * 0.45)
	local wy1 = ey - math.cos(wing)  * (len * 0.45)
	local wx2 = ex + math.sin(wing2) * (len * 0.45)
	local wy2 = ey - math.cos(wing2) * (len * 0.45)
	draw.NoTexture()
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	surface.DrawPoly({
		{ x = ex,  y = ey  },
		{ x = wx1, y = wy1 },
		{ x = wx2, y = wy2 },
	})
end

-- Иконка бомбы (маленький крест)
local function drawBombIcon(cx, cy, alpha)
	local s = 5
	surface.SetDrawColor(255, 200, 0, alpha)
	surface.DrawRect(math.floor(cx - s), math.floor(cy - 1), s * 2, 2)
	surface.DrawRect(math.floor(cx - 1), math.floor(cy - s), 2, s * 2)
end

hook.Add("HUDPaint", "CSMode_Radar", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	if CSCL.Phase == PHASE_LOBBY then return end

	local sh = ScrH()
	local ox = RDR_PAD
	local oy = sh - RDR_PAD - RDR_SIZE

	-- Фон
	surface.SetDrawColor(12, 14, 18, 215)
	surface.DrawRect(ox, oy, RDR_SIZE, RDR_SIZE)

	-- Рамка (двойная для CS2-стиля)
	surface.SetDrawColor(50, 55, 65, 255)
	surface.DrawOutlinedRect(ox, oy, RDR_SIZE, RDR_SIZE)
	surface.SetDrawColor(30, 33, 40, 255)
	surface.DrawOutlinedRect(ox - 1, oy - 1, RDR_SIZE + 2, RDR_SIZE + 2)

	local lpTeam  = lp:Team()
	local lpAlive = lp:Alive()
	-- В тренировке и когда мертвы — показываем всех
	local showAll = (CSCL.GameMode == GAMEMODE_TRAINING) or not lpAlive

	-- Сетка (тонкие линии, как в CS2)
	surface.SetDrawColor(30, 35, 42, 120)
	local gridStep = RDR_SIZE / 4
	for i = 1, 3 do
		local gx = math.floor(ox + gridStep * i)
		local gy = math.floor(oy + gridStep * i)
		surface.DrawLine(gx, oy, gx, oy + RDR_SIZE)
		surface.DrawLine(ox, gy, ox + RDR_SIZE, gy)
	end

	-- Игроки
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) then continue end

		local pos = ply:GetPos()
		rdrExpand(pos)

		local isSelf     = (ply == lp)
		local isTeammate = (ply:Team() == lpTeam) and not isSelf
		local isPlaying  = ply:Team() == TEAM_T or ply:Team() == TEAM_CT
		if not isPlaying then continue end

		-- Видимость: своих всегда, врагов только showAll
		local isEnemy = ply:Team() ~= lpTeam
		if isEnemy and not showAll then continue end

		-- Мёртвых не показываем (кроме себя — чтобы не терять точку отсчёта)
		if not ply:Alive() and not isSelf then continue end

		local px, py = rdrProject(pos.x, pos.y)
		local sx = ox + px
		local sy = oy + py

		-- Цвет точки
		local col
		if isSelf then
			col = Color(100, 220, 110, 255)
		elseif isTeammate then
			col = Color(65, 175, 80, 220)
		else
			col = Color(210, 55, 55, 220)
		end

		local r = isSelf and (RDR_DOT + 1) or RDR_DOT

		-- Тень под точкой для читаемости
		drawFilledCircle(sx, sy, r + 1, Color(0, 0, 0, 120))

		-- Сама точка
		drawFilledCircle(sx, sy, r, col)

		-- Стрелка направления взгляда
		local yaw = ply:EyeAngles().y
		drawArrow(sx, sy, yaw, RDR_ARROW, Color(col.r, col.g, col.b, 200))
	end

	-- Установленная бомба
	for _, ent in ipairs(ents.FindByClass("swcs_planted_c4")) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local px, py = rdrProject(pos.x, pos.y)
		local sx = ox + px
		local sy = oy + py
		local pulse = math.floor(math.abs(math.sin(CurTime() * 3.5)) * 120 + 135)
		drawBombIcon(sx, sy, pulse)
	end

	-- Подпись
	draw.SimpleText("RADAR", "CS2H_Tiny", ox + 4, oy + RDR_SIZE - 3, Color(60, 68, 80, 180), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end)
