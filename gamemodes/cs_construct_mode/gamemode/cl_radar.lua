-- ============================================================
-- CS:GO-STYLE CIRCULAR ROTATING RADAR
-- ============================================================

local RDR_PAD       = 10       -- pixels from screen edge
local RDR_SIZE_FRAC = 0.195    -- diameter = ScrH() * this
local RADAR_ZOOM    = 1200     -- world units visible in radar radius
local RING_WIDTH    = 3        -- outer ring thickness (pixels)

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
-- UNIT CIRCLE CACHE
-- ============================================================
local CIRC_SEGS = 60
local _ccos, _csin = {}, {}
for i = 0, CIRC_SEGS - 1 do
	local a = math.pi * 2 * i / CIRC_SEGS
	_ccos[i + 1] = math.cos(a)
	_csin[i + 1] = math.sin(a)
end

local function buildCirclePoly(cx, cy, r)
	local poly = {}
	for i = 1, CIRC_SEGS do
		poly[i] = { x = cx + _ccos[i] * r, y = cy + _csin[i] * r }
	end
	return poly
end

-- ============================================================
-- STENCIL CIRCLE CLIP
-- ============================================================
local function beginCircleClip(cx, cy, r)
	render.SetStencilEnable(true)
	render.ClearStencil()
	render.SetStencilWriteMask(0xFF)
	render.SetStencilTestMask(0xFF)
	render.SetStencilReferenceValue(1)
	-- Write 1 to stencil inside the circle (using always-fail trick)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
	render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
	render.SetStencilPassOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
	draw.NoTexture()
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawPoly(buildCirclePoly(cx, cy, r))
	-- From now on: only draw where stencil == 1
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
end

local function endCircleClip()
	render.SetStencilEnable(false)
end

-- ============================================================
-- PLAYER ICON (filled triangle pointing in direction)
-- ============================================================
local function drawPlayerArrow(px, py, yaw_deg, r, col)
	local rad  = math.rad(yaw_deg)
	local s    = math.sin(rad)
	local c    = math.cos(rad)
	-- Tip: forward
	local tipX = px + s * r * 1.4
	local tipY = py - c * r * 1.4
	-- Base center: backward
	local bx   = px - s * r
	local by   = py + c * r
	draw.NoTexture()
	surface.SetDrawColor(col.r, col.g, col.b, col.a or 255)
	surface.DrawPoly({
		{ x = tipX,            y = tipY            },
		{ x = bx + c * r * 0.85, y = by + s * r * 0.85 },
		{ x = bx - c * r * 0.85, y = by - s * r * 0.85 },
	})
end

-- ============================================================
-- COLORS
-- ============================================================
local COL_SELF   = Color(100, 220, 100, 255)   -- bright green (local player)
local COL_ALLY   = Color( 75, 170,  75, 220)   -- darker green (teammates)
local COL_ENEMY  = Color(220,  75,  75, 220)   -- red (enemies)
local COL_DEAD   = Color(100, 100, 110, 130)   -- grey (dead teammates)
local COL_SHADOW = Color(  0,   0,   0, 140)
local COL_BOMB   = Color(255, 200,   0)
local COL_RING   = Color( 80, 195, 230, 210)   -- CS:GO cyan ring
local COL_BG     = Color( 10,  12,  16, 220)

-- ============================================================
-- HUD HOOK
-- ============================================================
hook.Add("HUDPaint", "CSMode_Radar", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end
	if CSCL.Phase == PHASE_LOBBY then return end

	local sh = ScrH()
	local S  = math.floor(sh * RDR_SIZE_FRAC)
	local R  = S / 2
	local ox = RDR_PAD
	local oy = RDR_PAD
	local cx = math.floor(ox + R)
	local cy = math.floor(oy + R)

	CS_RADAR_BOTTOM = oy + S + RDR_PAD

	local mapName = game.GetMap()
	local ov      = parseOverviewTxt(mapName)
	local useOv   = ov.nomap and OV_DEFAULT or ov
	local mat     = not ov.nomap and getOverviewMat(mapName) or false

	local lpPos   = lp:GetPos()
	local lpYaw   = lp:EyeAngles().y
	local lpTeam  = lp:Team()
	local lpAlive = lp:Alive()
	local showAll = (CSCL.GameMode == GAMEMODE_TRAINING) or not lpAlive

	-- Pixels per world unit
	local radarScale = R / RADAR_ZOOM
	local innerR     = R - RING_WIDTH

	-- Pre-compute trig
	local lpYaw_rad = math.rad(lpYaw)
	local lcosY     = math.cos(lpYaw_rad)
	local lsinY     = math.sin(lpYaw_rad)

	-- World XY → radar screen position (player-centred, player-oriented).
	-- Source Engine: forward = (cosY, sinY), right = (-sinY, cosY)
	-- screen +X = player right, screen -Y = player forward
	local function worldToRadar(wx, wy)
		local dx = wx - lpPos.x
		local dy = wy - lpPos.y
		local rx = (dy * lcosY - dx * lsinY) * radarScale
		local ry = -(dx * lcosY + dy * lsinY) * radarScale
		return cx + rx, cy + ry
	end

	local function inCircle(sx, sy)
		local dx = sx - cx
		local dy = sy - cy
		return dx * dx + dy * dy <= innerR * innerR
	end

	-- ---- Outer ring + background ----
	draw.NoTexture()
	surface.SetDrawColor(COL_RING.r, COL_RING.g, COL_RING.b, COL_RING.a)
	surface.DrawPoly(buildCirclePoly(cx, cy, R))
	surface.SetDrawColor(COL_BG.r, COL_BG.g, COL_BG.b, COL_BG.a)
	surface.DrawPoly(buildCirclePoly(cx, cy, innerR))

	-- ---- Stencil clip at inner radius ----
	beginCircleClip(cx, cy, innerR)

	-- ---- Map texture (rotating, player-centred) ----
	if mat then
		-- The overview texture's 4 world-space corners.
		-- UV (0,0) = world top-left  = (pos_x, pos_y)
		-- UV (1,0) = world top-right = (pos_x + w, pos_y)
		-- UV (1,1) = world bot-right = (pos_x + w, pos_y - w)
		-- UV (0,1) = world bot-left  = (pos_x,     pos_y - w)
		-- worldToRadar handles rotation+translation, so we just project each corner.
		local w = 1024 * useOv.scale
		local x0, y0 = worldToRadar(useOv.pos_x,     useOv.pos_y    )
		local x1, y1 = worldToRadar(useOv.pos_x + w, useOv.pos_y    )
		local x2, y2 = worldToRadar(useOv.pos_x + w, useOv.pos_y - w)
		local x3, y3 = worldToRadar(useOv.pos_x,     useOv.pos_y - w)
		surface.SetMaterial(mat)
		surface.SetDrawColor(255, 255, 255, 200)
		surface.DrawPoly({
			{ x = x0, y = y0, u = 0, v = 0 },
			{ x = x1, y = y1, u = 1, v = 0 },
			{ x = x2, y = y2, u = 1, v = 1 },
			{ x = x3, y = y3, u = 0, v = 1 },
		})
		-- Dark overlay for icon readability
		draw.NoTexture()
		surface.SetDrawColor(0, 0, 0, 65)
		surface.DrawPoly(buildCirclePoly(cx, cy, innerR))
	else
		-- Grid fallback
		surface.SetDrawColor(30, 35, 44, 120)
		local wunit = innerR / radarScale
		local step  = math.floor(wunit / 3)
		for d = -math.floor(wunit), math.floor(wunit), step do
			local lx0, ly0 = worldToRadar(lpPos.x + d, lpPos.y - wunit)
			local lx1, ly1 = worldToRadar(lpPos.x + d, lpPos.y + wunit)
			local lx2, ly2 = worldToRadar(lpPos.x - wunit, lpPos.y + d)
			local lx3, ly3 = worldToRadar(lpPos.x + wunit, lpPos.y + d)
			surface.DrawLine(lx0, ly0, lx1, ly1)
			surface.DrawLine(lx2, ly2, lx3, ly3)
		end
	end

	-- ---- Player icons ----
	local triR     = math.max(4, math.floor(innerR * 0.048))
	local selfTriR = triR + 2

	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) then continue end
		local plyrTeam = ply:Team()
		if plyrTeam ~= TEAM_T and plyrTeam ~= TEAM_CT then continue end

		local isSelf  = ply == lp
		local isEnemy = plyrTeam ~= lpTeam
		if isEnemy and not showAll then continue end

		if isSelf then
			-- Local player: always at centre, always pointing up (radar rotates with them)
			if not lpAlive then continue end
			drawPlayerArrow(cx + 1, cy + 1, 0, selfTriR, COL_SHADOW)
			drawPlayerArrow(cx, cy, 0, selfTriR, COL_SELF)
			continue
		end

		local pos = ply:GetPos()
		local sx, sy = worldToRadar(pos.x, pos.y)
		if not inCircle(sx, sy) then continue end

		if not ply:Alive() then
			local ds = 3
			draw.NoTexture()
			surface.SetDrawColor(COL_DEAD.r, COL_DEAD.g, COL_DEAD.b, COL_DEAD.a)
			surface.DrawRect(sx - ds, sy - ds, ds * 2, ds * 2)
			continue
		end

		-- Direction relative to local player's facing
		local relYaw = ply:EyeAngles().y - lpYaw
		local col    = not isEnemy and COL_ALLY or COL_ENEMY
		drawPlayerArrow(sx + 1, sy + 1, relYaw, triR, COL_SHADOW)
		drawPlayerArrow(sx, sy, relYaw, triR, col)
	end

	-- ---- Bots ----
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
			local sx, sy = worldToRadar(pos.x, pos.y)
			if not inCircle(sx, sy) then continue end

			local relYaw = bot:GetAngles().y - lpYaw
			local col    = isEnemy and COL_ENEMY or COL_ALLY
			drawPlayerArrow(sx + 1, sy + 1, relYaw, triR, COL_SHADOW)
			drawPlayerArrow(sx, sy, relYaw, triR, col)
		end
	end

	-- ---- Planted bomb ----
	for _, ent in ipairs(ents.FindByClass("swcs_planted_c4")) do
		if not IsValid(ent) then continue end
		local pos = ent:GetPos()
		local sx, sy = worldToRadar(pos.x, pos.y)
		if not inCircle(sx, sy) then continue end

		local pulse = math.floor(math.abs(math.sin(CurTime() * 3.5)) * 110 + 145)
		local bs    = math.max(4, math.floor(innerR * 0.04))
		draw.NoTexture()
		surface.SetDrawColor(COL_BOMB.r, COL_BOMB.g, COL_BOMB.b, pulse)
		surface.DrawRect(sx - bs, sy - 1, bs * 2, 2)
		surface.DrawRect(sx - 1, sy - bs, 2, bs * 2)
	end

	-- ---- End stencil clip ----
	endCircleClip()

	-- ---- Map name label ----
	draw.SimpleText(mapName, "CS2H_Tiny",
		cx, oy + S + 3,
		Color(65, 75, 90, 180), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
end)
