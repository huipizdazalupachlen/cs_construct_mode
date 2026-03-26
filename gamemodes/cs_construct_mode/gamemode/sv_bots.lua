--[[
	CS Construct — Система ботов
	Использует готовые NPC из workshop-мода CS:GO ботов:
	  css_bot_t_csgo  — T-сторона
	  css_bot_ct_csgo — CT-сторона
]]

CSBots = CSBots or {}
CSBots.List = CSBots.List or {}

local cv_bots_enabled  = CreateConVar("cs_construct_bots_enabled",  "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Включить ботов")
local cv_bots_autofill = CreateConVar("cs_construct_bots_autofill", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Автозаполнение мест ботами")

local BOT_CLASS = {
	[TEAM_T]  = "css_bot_t_csgo",
	[TEAM_CT] = "css_bot_ct_csgo",
}

-- ============================================================
-- ОТНОШЕНИЯ БОТА К ИГРОКАМ И ДРУГИМ БОТАМ
-- ============================================================

function CSBots.UpdateBotRelationships(npc)
	if not IsValid(npc) then return end
	local botTeam = npc.BotTeam or TEAM_T

	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) then
			if ply:Team() == botTeam then
				npc:AddEntityRelationship(ply, D_LI, 99)
			else
				npc:AddEntityRelationship(ply, D_HT, 99)
			end
		end
	end

	for _, other in ipairs(CSBots.List) do
		if IsValid(other) and other ~= npc then
			if (other.BotTeam or TEAM_T) == botTeam then
				npc:AddEntityRelationship(other, D_LI, 99)
				other:AddEntityRelationship(npc, D_LI, 99)
			else
				npc:AddEntityRelationship(other, D_HT, 99)
				other:AddEntityRelationship(npc, D_HT, 99)
			end
		end
	end
end

-- Обновить отношения всех ботов (при смене команды игроком)
function CSBots.UpdateAllRelationships()
	for _, npc in ipairs(CSBots.List) do
		CSBots.UpdateBotRelationships(npc)
	end
end

-- ============================================================
-- СПАВН БОТА
-- ============================================================

function CSBots.SpawnBot(team)
	if not cv_bots_enabled:GetBool() then
		print("[CS Bots] SpawnBot: боты отключены (convar)")
		return
	end

	local cls = BOT_CLASS[team]
	if not cls then
		print("[CS Bots] SpawnBot: неизвестная команда " .. tostring(team))
		return
	end

	local pos, ang = CS_PickTeamSpawn(team)
	if not pos then
		print("[CS Bots] ОШИБКА: нет точки спавна для команды " .. team)
		return
	end

	print("[CS Bots] Создаём " .. cls .. " на позиции " .. tostring(pos))
	local npc = ents.Create(cls)
	if not IsValid(npc) then
		print("[CS Bots] ОШИБКА: ents.Create(\"" .. cls .. "\") вернул невалидный entity — мод на ботов не загружен?")
		return
	end

	npc.BotTeam = team
	npc:SetPos(pos + Vector(0, 0, 10))
	npc:SetAngles(ang)
	npc:Spawn()
	npc:Activate()
	npc:DropToFloor()

	table.insert(CSBots.List, npc)

	-- Устанавливаем отношения после инициализации NPC
	timer.Simple(0.2, function()
		CSBots.UpdateBotRelationships(npc)
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

	-- Убираем всех workshop-ботов (в т.ч. тех, кого не было в списке)
	for _, cls in ipairs({"css_bot_t_csgo", "css_bot_ct_csgo"}) do
		for _, e in ipairs(ents.FindByClass(cls)) do
			if IsValid(e) then e:Remove() end
		end
	end
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
	local phase = CSConstruct and CSConstruct.Phase
	if phase == PHASE_LIVE then return end

	-- Не спавним ботов, пока ни один игрок не выбрал команду
	local totalHumans = CSBots.CountPlayers(TEAM_T) + CSBots.CountPlayers(TEAM_CT)
	if totalHumans == 0 then return end

	local ppTeam = CS_GetGameModePlayersPerTeam and
		CS_GetGameModePlayersPerTeam(CSConstruct and CSConstruct.GameMode or GAMEMODE_COMPETITIVE) or 5

	print("[CS Bots] BalanceTeams: фаза=" .. tostring(phase) .. " ppTeam=" .. ppTeam)

	for _, tid in ipairs({TEAM_T, TEAM_CT}) do
		local humans = CSBots.CountPlayers(tid)
		local bots   = CSBots.CountBots(tid)
		local needed = math.max(0, ppTeam - humans)
		print("[CS Bots]  команда=" .. tid .. " люди=" .. humans .. " боты=" .. bots .. " нужно=" .. needed)
		while bots < needed do CSBots.SpawnBot(tid) bots = bots + 1 end
		while bots > needed do CSBots.RemoveBot(tid) bots = bots - 1 end
	end
end

-- ============================================================
-- ОЧИСТКА СПИСКА (мёртвые NPC убираем из отслеживания)
-- ============================================================

timer.Create("CSBots_CleanList", 2, 0, function()
	for i = #CSBots.List, 1, -1 do
		local bot = CSBots.List[i]
		if not IsValid(bot) or bot:Health() <= 0 then
			table.remove(CSBots.List, i)
		end
	end
end)

-- ============================================================
-- ХУКИ БАЛАНСИРОВКИ И ОТНОШЕНИЙ
-- ============================================================

hook.Add("CSBots_PlayerPickedTeam", "CSBots_AutoFill", function(ply, newTeam)
	if newTeam ~= TEAM_T and newTeam ~= TEAM_CT then return end
	CSBots.BalanceTeams()
	timer.Simple(0.3, CSBots.UpdateAllRelationships)
end)

hook.Add("PlayerChangedTeam", "CSBots_Balance", function(ply, old, new)
	if new ~= TEAM_T and new ~= TEAM_CT then return end
	CSBots.BalanceTeams()
	timer.Simple(0.3, CSBots.UpdateAllRelationships)
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

-- Диагностика: cs_bot_debug в консоли сервера
concommand.Add("cs_bot_debug", function()
	print("[CS Bots] === ДИАГНОСТИКА ===")
	print("[CS Bots] enabled=" .. tostring(cv_bots_enabled:GetBool()))
	print("[CS Bots] autofill=" .. tostring(cv_bots_autofill:GetBool()))
	print("[CS Bots] CSConstruct.Phase=" .. tostring(CSConstruct and CSConstruct.Phase))
	print("[CS Bots] GameMode=" .. tostring(CSConstruct and CSConstruct.GameMode))
	print("[CS Bots] CSBots.List size=" .. #CSBots.List)
	print("[CS Bots] css_bot_t_csgo registered=" .. tostring(scripted_ents.GetList()["css_bot_t_csgo"] ~= nil))
	print("[CS Bots] css_bot_ct_csgo registered=" .. tostring(scripted_ents.GetList()["css_bot_ct_csgo"] ~= nil))
	local tSpawn, _ = CS_PickTeamSpawn(TEAM_T)
	local ctSpawn, _ = CS_PickTeamSpawn(TEAM_CT)
	print("[CS Bots] Спавн T: " .. tostring(tSpawn))
	print("[CS Bots] Спавн CT: " .. tostring(ctSpawn))
	print("[CS Bots] ====================")
end)

print("[CS Construct] sv_bots.lua загружен")
