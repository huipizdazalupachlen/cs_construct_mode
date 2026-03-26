--[[
	CS Construct — Система ботов
	Боты: cs_construct_bot (base_ai + nav mesh A* навигация)
	Стрельба через Source engine AI (совместим с arc9)
]]

CSBots = CSBots or {}
CSBots.List = CSBots.List or {}

local cv_bots_enabled    = CreateConVar("cs_construct_bots_enabled",    "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Включить ботов")
local cv_bots_difficulty = CreateConVar("cs_construct_bots_difficulty", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Сложность ботов (1-3)")
local cv_bots_autofill   = CreateConVar("cs_construct_bots_autofill",   "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Автозаполнение мест ботами")

-- ============================================================
-- МОДЕЛИ
-- ============================================================

local BOT_MODELS = {
	[TEAM_T] = {
		"models/humans/group03/male_01.mdl", "models/humans/group03/male_02.mdl",
		"models/humans/group03/male_03.mdl", "models/humans/group03/male_04.mdl",
	},
	[TEAM_CT] = {
		"models/humans/group01/male_01.mdl", "models/humans/group01/male_02.mdl",
		"models/humans/group01/male_03.mdl", "models/humans/group01/male_04.mdl",
	},
}

-- ============================================================
-- СПАВН БОТА
-- ============================================================

function CSBots.SpawnBot(team)
	if not cv_bots_enabled:GetBool() then return end

	local pos, ang = CS_PickTeamSpawn(team)
	if not pos then
		print("[CS Bots] ОШИБКА: нет точки спавна для команды " .. team)
		return
	end

	local npc = ents.Create("cs_construct_bot")
	if not IsValid(npc) then
		print("[CS Bots] ОШИБКА: не удалось создать cs_construct_bot")
		return
	end

	-- Параметры до спавна — entity читает их в Initialize()
	npc.BotTeam      = team
	npc.CSMode_Money = 800

	local models = BOT_MODELS[team] or BOT_MODELS[TEAM_T]
	npc.BotModel = models[math.random(#models)]

	npc:SetPos(pos + Vector(0, 0, 10))
	npc:SetAngles(ang)
	npc:Spawn()
	npc:Activate()
	npc:DropToFloor()

	-- Стартовое оружие
	local pistol = (team == TEAM_T) and "weapon_swcs_glock" or "weapon_swcs_usp_silencer"
	timer.Simple(0.3, function()
		if not IsValid(npc) then return end
		npc:Give(pistol)
	end)

	return npc
end

-- ============================================================
-- УПРАВЛЕНИЕ
-- ============================================================

function CSBots.RemoveBot(team)
	for i = #CSBots.List, 1, -1 do
		local npc = CSBots.List[i]
		if IsValid(npc) and (npc.BotTeam or TEAM_T) == team then
			npc:Remove()
			table.remove(CSBots.List, i)
			return true
		end
	end
	return false
end

function CSBots.RemoveAllBots()
	for _, npc in ipairs(CSBots.List) do
		if IsValid(npc) then npc:Remove() end
	end
	CSBots.List = {}
end

function CSBots.CountBots(team)
	local n = 0
	for _, npc in ipairs(CSBots.List) do
		if IsValid(npc) and (npc.BotTeam or TEAM_T) == team then n = n + 1 end
	end
	return n
end

function CSBots.CountPlayers(team)
	local n = 0
	for _, ply in ipairs(player.GetAll()) do
		if ply:Team() == team then n = n + 1 end
	end
	return n
end

-- ============================================================
-- БАЛАНС КОМАНД
-- ============================================================

function CSBots.BalanceTeams()
	if not cv_bots_enabled:GetBool() then return end
	if not cv_bots_autofill:GetBool() then return end
	if CSConstruct and (CSConstruct.Phase == PHASE_LIVE or CSConstruct.Phase == PHASE_LOBBY) then return end

	local ppTeam = CS_GetGameModePlayersPerTeam and
		CS_GetGameModePlayersPerTeam(CSConstruct and CSConstruct.GameMode or GAMEMODE_COMPETITIVE) or 5

	for _, tid in ipairs({TEAM_T, TEAM_CT}) do
		local humans = CSBots.CountPlayers(tid)
		local bots   = CSBots.CountBots(tid)
		local needed = math.max(0, ppTeam - humans)
		while bots < needed do CSBots.SpawnBot(tid) bots = bots + 1 end
		while bots > needed do CSBots.RemoveBot(tid) bots = bots - 1 end
	end
end

-- ============================================================
-- ОЧИСТКА СПИСКА
-- ============================================================

timer.Create("CSBots_CleanList", 2, 0, function()
	for i = #CSBots.List, 1, -1 do
		if not IsValid(CSBots.List[i]) then table.remove(CSBots.List, i) end
	end
end)

-- ============================================================
-- СБРОС РАУНДА
-- ============================================================

hook.Add("CSConstruct_FreezeStart", "CSBots_ResetAI", function()
	for _, npc in ipairs(CSBots.List) do
		if IsValid(npc) and npc.ResetForNewRound then
			npc:ResetForNewRound()
		end
	end
end)

-- ============================================================
-- ХУКИ БАЛАНСИРОВКИ
-- ============================================================

hook.Add("CSBots_PlayerPickedTeam", "CSBots_AutoFill", function(ply, newTeam)
	if newTeam ~= TEAM_T and newTeam ~= TEAM_CT then return end
	CSBots.BalanceTeams()
end)

hook.Add("PlayerChangedTeam", "CSBots_Balance", function(ply, old, new)
	if new ~= TEAM_T and new ~= TEAM_CT then return end
	CSBots.BalanceTeams()
end)

hook.Add("PlayerInitialSpawn", "CSBots_Balance", function()
	timer.Simple(1.0, CSBots.BalanceTeams)
end)

hook.Add("PlayerDisconnected", "CSBots_Balance", function()
	timer.Simple(0.5, CSBots.BalanceTeams)
end)

timer.Create("CSBots_PeriodicBalance", 5, 0, function()
	if CSConstruct and CSConstruct.Phase == PHASE_LIVE then return end
	CSBots.BalanceTeams()
end)

timer.Simple(2, function()
	print("[CS Construct] Система ботов готова")
	CSBots.RemoveAllBots()
	CSBots.BalanceTeams()
end)

-- ============================================================
-- КОНСОЛЬНЫЕ КОМАНДЫ
-- ============================================================

concommand.Add("cs_bot_add", function(ply, cmd, args)
	if IsValid(ply) and not ply:IsAdmin() then return end
	local team = tonumber(args[1]) or TEAM_T
	if team ~= TEAM_T and team ~= TEAM_CT then return end
	CSBots.SpawnBot(team)
end)

concommand.Add("cs_bot_remove_all", function(ply)
	if IsValid(ply) and not ply:IsAdmin() then return end
	CSBots.RemoveAllBots()
end)

concommand.Add("cs_bot_list", function(ply)
	if not IsValid(ply) then return end
	ply:ChatPrint("T: " .. CSBots.CountBots(TEAM_T) .. " | CT: " .. CSBots.CountBots(TEAM_CT))
end)

-- ============================================================
-- ГЕНЕРАЦИЯ NAV MESH
-- ============================================================

--[[ ВРЕМЕННО ОТКЛЮЧЕНО
hook.Add("InitPostEntity", "CSBots_EnsureNavMesh", function()
	timer.Simple(3, function()
		if navmesh.IsLoaded() then
			local areas = navmesh.GetAllNavAreas()
			print("[CS Bots] Nav mesh загружен (" .. #areas .. " зон). Боты могут навигировать.")
			return
		end
		print("[CS Bots] Nav mesh отсутствует! Запускаю nav_generate...")
		RunConsoleCommand("nav_generate")
	end)
end)
]]

print("[CS Construct] sv_bots.lua загружен")
