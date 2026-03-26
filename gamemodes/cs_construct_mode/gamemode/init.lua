AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_lobby.lua")
AddCSLuaFile("cl_f4menu.lua")

include("shared.lua")
include("sv_bots.lua")

DeriveGamemode("base")

util.AddNetworkString("CSMode_SelectTeam")
util.AddNetworkString("CSMode_BuyWeapon")
util.AddNetworkString("CSMode_SyncState")
util.AddNetworkString("CSMode_OpenTeamSelect")
util.AddNetworkString("CSMode_RoundWin")
util.AddNetworkString("CSMode_OpenLobby")
util.AddNetworkString("CSMode_SelectKnife")
util.AddNetworkString("CSMode_SetGameMode")
util.AddNetworkString("CSMode_StartGame")
util.AddNetworkString("CSMode_LobbyUpdate")
util.AddNetworkString("CSMode_CleanupDecals")
util.AddNetworkString("CSMode_SelectBomb")
util.AddNetworkString("CSMode_KillFeedEntry")
util.AddNetworkString("CSMode_BombEvent")

resource.AddFile("sound/cs_construct_mode/bombpl.mp3")
resource.AddFile("sound/cs_construct_mode/bombdef.mp3")

-- ConVars (см. комментарий в shared.lua)
local cv_min_players = CreateConVar("cs_construct_min_players", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Минимум игроков с командой для старта раундов")
local cv_freeze = CreateConVar("cs_construct_freeze_time", "12", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Фриз и закупка (сек)")
local cv_round = CreateConVar("cs_construct_round_time", "120", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Длительность раунда (сек)")
local cv_end_delay = CreateConVar("cs_construct_round_end_delay", "5", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Пауза после раунда (сек)")
local cv_start_money = CreateConVar("cs_construct_start_money", "800", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Стартовые деньги")
-- Если FCVAR_ARCHIVE сохранил мусорное значение — сбрасываем на 800
timer.Simple(0, function()
	if cv_start_money:GetInt() > 16000 or cv_start_money:GetInt() < 0 then
		RunConsoleCommand("cs_construct_start_money", "800")
	end
end)
local cv_win_money = CreateConVar("cs_construct_win_money", "3250", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Бонус за победу в раунде")
local cv_lose_money = CreateConVar("cs_construct_lose_money", "1400", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Бонус за поражение")
local cv_kill = CreateConVar("cs_construct_kill_reward", "300", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Награда за убийство")
local cv_timeout_ct = CreateConVar("cs_construct_timeout_favors_ct", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "1 — по таймауту победа CT, 0 — ничья (lose-бонус обеим)")
local cv_max_rounds = CreateConVar("cs_construct_max_rounds", "16", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Раундов до победы (как в CS)")
local cv_game_mode = CreateConVar("cs_construct_game_mode", "3", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Режим игры: 1=Дуэль(1v1), 2=Напарники(2v2), 3=Соревновательный(5v5)")
local cv_lobby_enabled = CreateConVar("cs_construct_lobby_enabled", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Включить лобби перед игрой")

CSConstruct = CSConstruct or {}
-- Начальная фаза зависит от настройки лобби
CSConstruct.Phase = cv_lobby_enabled:GetBool() and PHASE_LOBBY or PHASE_WAITING
CSConstruct.GameMode = GAMEMODE_COMPETITIVE
CSConstruct.PhaseEndsAt = 0
CSConstruct.RoundEndsAt = 0
CSConstruct.RoundNum = 0
CSConstruct.ScoreT = 0
CSConstruct.ScoreCT = 0
-- Победитель прошлого раунда: TEAM_T, TEAM_CT или 0 (ничья)
CSConstruct.LastWinner = 0

local function playingTeams()
	return TEAM_T, TEAM_CT
end

local function isPlayingTeam(t)
	return t == TEAM_T or t == TEAM_CT
end

local function countTeamPickers()
	local n = 0
	-- Считаем игроков
	for _, p in ipairs(player.GetAll()) do
		if isPlayingTeam(p:Team()) then n = n + 1 end
	end
	-- Считаем ботов
	if CSBots and CSBots.List then
		for _, bot in ipairs(CSBots.List) do
			if IsValid(bot) then n = n + 1 end
		end
	end
	return n
end

local function anyOnTeam(tid)
	-- Проверяем игроков
	for _, p in ipairs(player.GetAll()) do
		if p:Team() == tid and p:Alive() then return true end
	end
	-- Проверяем ботов
	if CSBots and CSBots.List then
		for _, bot in ipairs(CSBots.List) do
			if IsValid(bot) and (bot.BotTeam or TEAM_T) == tid and bot:Health() > 0 then
				return true
			end
		end
	end
	return false
end

local function allTeamDead(tid)
	-- Проверяем игроков
	for _, p in ipairs(player.GetAll()) do
		if p:Team() == tid and p:Alive() then return false end
	end
	-- Проверяем ботов
	if CSBots and CSBots.List then
		for _, bot in ipairs(CSBots.List) do
			if IsValid(bot) and (bot.BotTeam or TEAM_T) == tid and bot:Health() > 0 then
				return false
			end
		end
	end
	return true
end

local function hasLivingTeam(tid)
	return anyOnTeam(tid)
end

local function isTrainingMode()
	return CSConstruct.GameMode == GAMEMODE_TRAINING
end

function GM:Initialize()
	team.SetUp(TEAM_T, "T", Color(220, 90, 90), true)
	team.SetUp(TEAM_CT, "CT", Color(90, 120, 220), true)
end

local function syncState(ply)
	if not IsValid(ply) then return end
	net.Start("CSMode_SyncState")
	net.WriteUInt(CSConstruct.Phase, 8)
	net.WriteUInt(CSConstruct.RoundNum, 16)
	net.WriteUInt(CSConstruct.ScoreT, 16)
	net.WriteUInt(CSConstruct.ScoreCT, 16)
	net.WriteFloat(CSConstruct.PhaseEndsAt)
	net.WriteFloat(CSConstruct.RoundEndsAt)
	net.WriteUInt(math.Clamp(ply.CSMode_Money or 0, 0, 999999), 32)
	net.WriteUInt(CSConstruct.GameMode, 8)
	net.Send(ply)
end

local function broadcastState()
	for _, p in ipairs(player.GetAll()) do
		syncState(p)
	end
end

local function openTeamSelect(ply)
	net.Start("CSMode_OpenTeamSelect")
	net.Send(ply)
end

local function openLobby(ply)
	net.Start("CSMode_OpenLobby")
	net.WriteUInt(CSConstruct.GameMode, 8)
	net.Send(ply)
end

local function broadcastLobbyUpdate()
	net.Start("CSMode_LobbyUpdate")
	net.WriteUInt(CSConstruct.GameMode, 8)
	net.Broadcast()
end

-- Выдаёт запасные патроны для оружия (3 полных магазина в резерв)
local function giveWeaponAmmo(ply, wep)
	if not IsValid(ply) or not IsValid(wep) then return end
	local ammoType = wep:GetPrimaryAmmoType()
	if ammoType < 0 then return end
	local clipSize = wep:GetMaxClip1()
	if clipSize <= 0 then return end
	-- Устанавливаем резерв = 3 магазина (как в CS:GO у большинства оружия)
	local desiredReserve = clipSize * 3
	local currentReserve = ply:GetAmmoCount(ammoType)
	if currentReserve < desiredReserve then
		ply:GiveAmmo(desiredReserve - currentReserve, ammoType, true)
	end
end

local function giveRoundLoadout(ply)
	if not IsValid(ply) or not ply:Alive() then return end
	ply:StripWeapons()
	ply:RemoveAllAmmo()
	-- Выдаем нож игрока (выбирается один раз при первом спавне)
	if not ply.CSMode_Knife then
		ply.CSMode_Knife = CS_GetRandomKnife()
	end
	ply:Give(ply.CSMode_Knife)
end

local function placeAtTeamSpawn(ply)
	if not IsValid(ply) or not isPlayingTeam(ply:Team()) then return end
	local pos, ang = CS_PickTeamSpawn(ply:Team())
	ply:SetPos(pos)
	ply:SetEyeAngles(ang)
end

local function applyRoundMoneyBonuses(winnerTeam)
	-- winnerTeam: TEAM_T, TEAM_CT или 0 (ничья по таймауту)
	local win = cv_win_money:GetInt()
	local lose = cv_lose_money:GetInt()
	
	-- Бонусы для игроков
	for _, p in ipairs(player.GetAll()) do
		if isPlayingTeam(p:Team()) then
			p.CSMode_Money = p.CSMode_Money or cv_start_money:GetInt()
			if winnerTeam == 0 then
				p.CSMode_Money = p.CSMode_Money + lose
			elseif p:Team() == winnerTeam then
				p.CSMode_Money = p.CSMode_Money + win
			else
				p.CSMode_Money = p.CSMode_Money + lose
			end
		end
	end
	
	-- Бонусы для ботов
	for _, bot in ipairs(CSBots.List) do
		if IsValid(bot) then
			bot.CSMode_Money = bot.CSMode_Money or cv_start_money:GetInt()
			if winnerTeam == 0 then
				bot.CSMode_Money = bot.CSMode_Money + lose
			elseif (bot.BotTeam or TEAM_T) == winnerTeam then
				bot.CSMode_Money = bot.CSMode_Money + win
			else
				bot.CSMode_Money = bot.CSMode_Money + lose
			end
		end
	end
end

local function cleanupRound()
	-- Трупы игроков (рагдоллы)
	for _, e in ipairs(ents.FindByClass("prop_ragdoll")) do
		if IsValid(e) then e:Remove() end
	end

	-- Тела мёртвых workshop-ботов
	for _, cls in ipairs({"css_bot_t_csgo", "css_bot_ct_csgo"}) do
		for _, e in ipairs(ents.FindByClass(cls)) do
			if IsValid(e) then e:Remove() end
		end
	end
	if CSBots then CSBots.List = {} end

	-- Заложенная бомба
	for _, e in ipairs(ents.FindByClass("swcs_planted_c4")) do
		if IsValid(e) then e:Remove() end
	end

	-- Брошенное оружие (без владельца)
	for _, e in ipairs(ents.GetAll()) do
		if IsValid(e) and e:IsWeapon() and not IsValid(e:GetOwner()) then
			e:Remove()
		end
	end

	-- Кровь и декали на клиентах
	net.Start("CSMode_CleanupDecals")
	net.Broadcast()
end

local function startFreezePhase()
	cleanupRound()
	hook.Run("CSConstruct_FreezeStart")  -- сбрасывает AI-состояние ботов (sv_bots.lua)
	CSConstruct.Phase = PHASE_FREEZE
	CSConstruct.RoundNum = CSConstruct.RoundNum + 1
	local ft = math.max(3, cv_freeze:GetFloat())
	CSConstruct.PhaseEndsAt = CurTime() + ft
	CSConstruct.RoundEndsAt = 0

	for _, p in ipairs(player.GetAll()) do
		if isPlayingTeam(p:Team()) then
			-- Сохраняем купленное оружие (без ножа — он выдаётся заново)
			local savedWeapons = {}
			for _, wep in ipairs(p:GetWeapons()) do
				if IsValid(wep) then
					local cls = wep:GetClass()
					if cls ~= "weapon_crowbar" and not table.HasValue(CS_KNIVES or {}, cls) then
						table.insert(savedWeapons, cls)
					end
				end
			end

			p.CSMode_ForceRespawn = true
			p:Spawn()
			p.CSMode_ForceRespawn = false
			p.CSMode_Frozen = true
			placeAtTeamSpawn(p)
			giveRoundLoadout(p)

			-- Восстанавливаем оружие после StripWeapons
			for _, cls in ipairs(savedWeapons) do
				local wep = p:Give(cls)
				if IsValid(wep) then
					giveWeaponAmmo(p, wep)
				end
			end
		end
	end

	-- Боты: удаляем старых, спавним свежих через BalanceTeams
	CSBots.RemoveAllBots()

	broadcastState()

	-- Небольшая задержка, чтобы cleanupRound успел отработать
	timer.Simple(0.5, function()
		if CSConstruct.Phase ~= PHASE_FREEZE then return end
		CSBots.BalanceTeams()
		-- Замораживаем ботов на время фриз-тайма
		timer.Simple(0.3, function()
			for _, bot in ipairs(CSBots.List) do
				if IsValid(bot) then bot:SetMoveType(MOVETYPE_NONE) end
			end
		end)
	end)
end

local function startLivePhase()
	CSConstruct.Phase = PHASE_LIVE
	local rt
	if isTrainingMode() then
		rt = 999999 -- Тренировка: бесконечный раунд
	else
		rt = cv_round:GetFloat()
		if rt <= 0 then rt = 120 end
	end
	CSConstruct.RoundEndsAt = CurTime() + rt
	CSConstruct.PhaseEndsAt = CSConstruct.RoundEndsAt

	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p:Alive() and isPlayingTeam(p:Team()) then
			p.CSMode_Frozen = false
		end
	end

	-- Размораживаем ботов
	for _, bot in ipairs(CSBots.List) do
		if IsValid(bot) then bot:SetMoveType(MOVETYPE_STEP) end
	end

	-- Выдаём бомбу случайному живому игроку T стороны
	local tPlayers = {}
	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p:Alive() and p:Team() == TEAM_T then
			table.insert(tPlayers, p)
		end
	end
	if #tPlayers > 0 then
		local bomber = tPlayers[math.random(#tPlayers)]
		bomber:Give("weapon_swcs_c4")
		bomber:PrintMessage(HUD_PRINTCENTER, "Вам выдана бомба!")
	end

	broadcastState()
end

local function endRound(winnerTeam, reason)
	-- winnerTeam: TEAM_T, TEAM_CT, 0 = ничья
	CSConstruct.Phase = PHASE_ROUND_END
	cleanupRound()
	CSConstruct.PhaseEndsAt = CurTime() + math.max(2, cv_end_delay:GetFloat())
	CSConstruct.RoundEndsAt = 0

	if winnerTeam == TEAM_T then
		CSConstruct.ScoreT = CSConstruct.ScoreT + 1
	elseif winnerTeam == TEAM_CT then
		CSConstruct.ScoreCT = CSConstruct.ScoreCT + 1
	end

	CSConstruct.LastWinner = winnerTeam
	applyRoundMoneyBonuses(winnerTeam)
	
	-- Отправляем сообщение о победе всем игрокам
	net.Start("CSMode_RoundWin")
	net.WriteUInt(winnerTeam, 8)
	net.WriteString(reason or "")
	net.Broadcast()
	
	-- Также выводим в чат
	local winnerName = "Ничья"
	if winnerTeam == TEAM_T then
		winnerName = "Террористы"
	elseif winnerTeam == TEAM_CT then
		winnerName = "Контр-террористы"
	end
	
	local reasonText = ""
	if reason == "elimination" then
		reasonText = " (элиминация)"
	elseif reason == "time" then
		reasonText = " (время вышло)"
	elseif reason == "draw" then
		reasonText = " (обе команды уничтожены)"
	elseif reason == "time_draw" then
		reasonText = " (время вышло)"
	elseif reason == "bomb_exploded" then
		reasonText = " (бомба взорвалась)"
	elseif reason == "bomb_defused" then
		reasonText = " (бомба обезврежена)"
	end
	
	PrintMessage(HUD_PRINTTALK, ">>> " .. winnerName .. " победили" .. reasonText .. " <<<")
	PrintMessage(HUD_PRINTTALK, "Счет: T " .. CSConstruct.ScoreT .. " - " .. CSConstruct.ScoreCT .. " CT")
	
	broadcastState()
end

local function checkRoundWinLive()
	if CSConstruct.Phase ~= PHASE_LIVE then return end
	if isTrainingMode() then return end -- В тренировке раунд бесконечен
	
	-- Подсчет живых игроков и ботов (как в CS:GO)
	local tAlive = 0
	local ctAlive = 0
	
	-- Считаем игроков
	for _, p in ipairs(player.GetAll()) do
		if IsValid(p) and p:Alive() then
			if p:Team() == TEAM_T then
				tAlive = tAlive + 1
			elseif p:Team() == TEAM_CT then
				ctAlive = ctAlive + 1
			end
		end
	end
	
	-- Считаем ботов
	for _, bot in ipairs(CSBots.List) do
		if IsValid(bot) and bot:Health() > 0 then
			if (bot.BotTeam or TEAM_T) == TEAM_T then
				tAlive = tAlive + 1
			elseif (bot.BotTeam or TEAM_T) == TEAM_CT then
				ctAlive = ctAlive + 1
			end
		end
	end
	
	-- Проверка элиминации (как в CS:GO)
	if tAlive == 0 and ctAlive == 0 then
		-- Обе команды мертвы - ничья
		endRound(0, "draw")
		return
	end
	
	if tAlive == 0 and ctAlive > 0 then
		-- T мертвы - CT победили
		endRound(TEAM_CT, "elimination")
		return
	end
	
	if ctAlive == 0 and tAlive > 0 then
		-- CT мертвы — но если бомба заложена, ждём взрыва (он сам завершит раунд)
		local bombPlanted = #ents.FindByClass("swcs_planted_c4") > 0
		if not bombPlanted then
			endRound(TEAM_T, "elimination")
		end
		return
	end
	
	-- Проверка таймаута
	if CurTime() >= CSConstruct.RoundEndsAt then
		if cv_timeout_ct:GetBool() then
			endRound(TEAM_CT, "time")
		else
			endRound(0, "time_draw")
		end
	end
end

local function thinkRound()
	if CSConstruct.Phase == PHASE_WAITING then
		if countTeamPickers() >= cv_min_players:GetInt() then
			startFreezePhase()
		end
		return
	end

	if CSConstruct.Phase == PHASE_FREEZE then
		if CurTime() >= CSConstruct.PhaseEndsAt then
			startLivePhase()
		end
		return
	end

	if CSConstruct.Phase == PHASE_LIVE then
		checkRoundWinLive()
		return
	end

	if CSConstruct.Phase == PHASE_ROUND_END then
		if CurTime() >= CSConstruct.PhaseEndsAt then
			-- Проверяем, достигла ли какая-то команда максимального количества раундов
			local maxRounds = cv_max_rounds:GetInt()
			if CSConstruct.ScoreT >= maxRounds or CSConstruct.ScoreCT >= maxRounds then
				-- Игра окончена! Сбрасываем счет и начинаем заново
				local winner = CSConstruct.ScoreT >= maxRounds and "T" or "CT"
				PrintMessage(HUD_PRINTTALK, "=== ИГРА ОКОНЧЕНА! Победила команда " .. winner .. " ===")
				PrintMessage(HUD_PRINTTALK, "Счет: T " .. CSConstruct.ScoreT .. " - " .. CSConstruct.ScoreCT .. " CT")
				
				-- Сброс счета
				CSConstruct.ScoreT = 0
				CSConstruct.ScoreCT = 0
				CSConstruct.RoundNum = 0
				
				-- Сброс денег всем игрокам
				for _, p in ipairs(player.GetAll()) do
					if isPlayingTeam(p:Team()) then
						p.CSMode_Money = cv_start_money:GetInt()
					end
				end
				
				broadcastState()
				timer.Simple(3, function()
					startFreezePhase()
				end)
			else
				startFreezePhase()
			end
		end
	end
end

timer.Create("CSConstruct_RoundThink", 0.25, 0, thinkRound)

-- ============================================================
-- Бомба: победа по заложке/разминированию
-- ============================================================

-- T победили: бомба взорвалась
hook.Add("SWCSC4Detonated", "CSMode_BombExplode", function()
	if CSConstruct.Phase ~= PHASE_LIVE then return end
	endRound(TEAM_T, "bomb_exploded")
end)

-- CT победили: бомба разряжена
hook.Add("SWCSC4Defused", "CSMode_BombDefused", function()
	if CSConstruct.Phase ~= PHASE_LIVE then return end
	endRound(TEAM_CT, "bomb_defused")
end)

-- Если CT убиты пока бомба заложена — T всё равно должны выиграть по взрыву,
-- но если CT убиты до закладки — победа T по элиминации уже обрабатывается выше.

-- ============================================================
-- НАГРАДА ЗА УБИЙСТВО БОТА
-- ============================================================

hook.Add("NPCKilled", "CSMode_BotKillReward", function(npc, attacker, inflictor)
	if CSConstruct.Phase ~= PHASE_LIVE then return end

	-- Проверяем, что это наш отслеживаемый бот
	local botTeam = nil
	for _, b in ipairs(CSBots.List) do
		if b == npc then
			botTeam = b.BotTeam or TEAM_T
			break
		end
	end
	if not botTeam then return end

	-- Килл-фид
	if IsValid(attacker) and attacker:IsPlayer() then
		local wepClass = ""
		local wep = attacker:GetActiveWeapon()
		if IsValid(wep) then wepClass = wep:GetClass() end
		local isSuicide = (attacker == npc)
		net.Start("CSMode_KillFeedEntry")
		net.WriteString(attacker:Nick())
		net.WriteUInt(attacker:Team(), 8)
		net.WriteUInt(attacker:EntIndex(), 16)
		net.WriteString(npc:GetClass() == "css_bot_ct_csgo" and "BOT CT" or "BOT T")
		net.WriteUInt(botTeam, 8)
		net.WriteUInt(0, 16)
		net.WriteString(wepClass)
		net.WriteBool(false)
		net.WriteBool(isSuicide)
		net.Broadcast()
	end

	-- Денежная награда
	if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() ~= botTeam then
		attacker.CSMode_Money = (attacker.CSMode_Money or 0) + cv_kill:GetInt()
		syncState(attacker)
	end
end)

function GM:Think()
	-- round think via timer; reserved for extensions
end

function GM:PlayerInitialSpawn(ply)
	ply.CSMode_Money = math.Clamp(cv_start_money:GetInt(), 0, 16000)
	ply.CSMode_NeedTeam = true
	ply:SetTeam(TEAM_SPECTATOR)
	timer.Simple(0.5, function()
		if not IsValid(ply) then return end
		if CSConstruct.Phase == PHASE_LOBBY and cv_lobby_enabled:GetBool() then
			openLobby(ply)
		else
			openTeamSelect(ply)
		end
		syncState(ply)
	end)
end

function GM:PlayerSpawn(ply)
	if ply.CSMode_ForceRespawn then
		self.BaseClass.PlayerSpawn(self, ply)
		return
	end

	self.BaseClass.PlayerSpawn(self, ply)

	if ply:Team() == TEAM_SPECTATOR then
		return
	end

	if not isPlayingTeam(ply:Team()) then
		return
	end

	if ply.CSMode_JoinMidRound then
		ply.CSMode_JoinMidRound = false
		timer.Simple(0, function()
			if not IsValid(ply) then return end
			if ply:Alive() then ply:KillSilent() end
		end)
		return
	end

	-- Устанавливаем модель персонажа для команды
	if isPlayingTeam(ply:Team()) then
		-- Если у игрока еще нет модели для этой команды, выбираем случайную
		if not ply.CSMode_TeamModel or ply.CSMode_LastTeam ~= ply:Team() then
			ply.CSMode_TeamModel = CS_GetRandomTeamModel(ply:Team())
			ply.CSMode_LastTeam = ply:Team()
		end
		ply:SetModel(ply.CSMode_TeamModel)
	end

	if CSConstruct.Phase == PHASE_WAITING then
		placeAtTeamSpawn(ply)
		giveRoundLoadout(ply)
		ply.CSMode_Frozen = true
	elseif CSConstruct.Phase == PHASE_FREEZE then
		placeAtTeamSpawn(ply)
		giveRoundLoadout(ply)
		ply.CSMode_Frozen = true
	elseif CSConstruct.Phase == PHASE_LIVE then
		placeAtTeamSpawn(ply)
		giveRoundLoadout(ply)
		ply.CSMode_Frozen = false
	end

	syncState(ply)
end

function GM:PlayerLoadout(ply)
	local wep
	if ply:Team() == TEAM_CT then
		wep = ply:Give("weapon_swcs_usp_silencer")
	elseif ply:Team() == TEAM_T then
		wep = ply:Give("weapon_swcs_glock")
	end
	if IsValid(wep) then
		giveWeaponAmmo(ply, wep)
	end
	return true
end

function GM:PlayerDeathThink(ply)
	if ply.CSMode_ForceRespawn then return false end
	-- В тренировочном режиме разрешаем авто-респавн
	if isTrainingMode() and isPlayingTeam(ply:Team()) then return false end
	if isPlayingTeam(ply:Team()) and (CSConstruct.Phase == PHASE_FREEZE or CSConstruct.Phase == PHASE_LIVE or CSConstruct.Phase == PHASE_ROUND_END) then
		return true
	end
	return false
end

function GM:PlayerDeath(victim, inflictor, attacker)
	if not IsValid(victim) or not isPlayingTeam(victim:Team()) then return end

	-- Broadcast kill feed entry to all clients
	if CSConstruct.Phase == PHASE_LIVE or CSConstruct.Phase == PHASE_ROUND_END then
		local hs = (victim.CS_LastHitGroup == HITGROUP_HEAD)
		local isSuicide = (attacker == victim) or not IsValid(attacker) or not attacker:IsPlayer()
		local atkName, atkTeam, atkIdx, wepClass = "", 0, 0, ""
		if not isSuicide then
			atkName = attacker:Nick()
			atkTeam = attacker:Team()
			atkIdx  = attacker:EntIndex()
			local wep = attacker:GetActiveWeapon()
			if IsValid(wep) then wepClass = wep:GetClass() end
		end
		net.Start("CSMode_KillFeedEntry")
		net.WriteString(atkName)
		net.WriteUInt(atkTeam, 8)
		net.WriteUInt(atkIdx, 16)
		net.WriteString(IsValid(victim) and victim:Nick() or "?")
		net.WriteUInt(victim:Team(), 8)
		net.WriteUInt(victim:EntIndex(), 16)
		net.WriteString(wepClass)
		net.WriteBool(hs)
		net.WriteBool(isSuicide)
		net.Broadcast()
	end

	if CSConstruct.Phase == PHASE_LIVE and IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
		if isPlayingTeam(attacker:Team()) and attacker:Team() ~= victim:Team() then
			attacker.CSMode_Money = (attacker.CSMode_Money or 0) + cv_kill:GetInt()
			syncState(attacker)
		end
	end
	if isTrainingMode() then
		-- В тренировке — респавн через 3 секунды
		timer.Simple(3, function()
			if not IsValid(victim) or victim:Alive() then return end
			if not isPlayingTeam(victim:Team()) then return end
			victim.CSMode_ForceRespawn = true
			victim:Spawn()
			victim.CSMode_ForceRespawn = false
			victim.CSMode_Frozen = false
			placeAtTeamSpawn(victim)
			giveRoundLoadout(victim)
			syncState(victim)
		end)
	else
		timer.Simple(0, function()
			if not IsValid(victim) then return end
			victim:Spectate(OBS_MODE_ROAMING)
		end)
	end
end

-- Track last hitgroup per player (for headshot detection in killfeed)
hook.Add("ScalePlayerDamage", "CSMode_KFHeadshot", function(ply, hitgroup, dmginfo)
	ply.CS_LastHitGroup = hitgroup
end)

function GM:EntityTakeDamage(target, dmginfo)
	if not IsValid(target) or not target:IsPlayer() then return end
	if CSConstruct.Phase == PHASE_FREEZE then
		dmginfo:SetDamage(0)
	end
end

net.Receive("CSMode_SelectTeam", function(_, ply)
	if not IsValid(ply) then return end
	local tid = net.ReadUInt(8)
	if tid ~= TEAM_T and tid ~= TEAM_CT then return end

	ply:SetTeam(tid)
	ply.CSMode_NeedTeam = false

	if CSConstruct.Phase == PHASE_LIVE or CSConstruct.Phase == PHASE_ROUND_END then
		ply.CSMode_JoinMidRound = true
	end

	ply:Spawn()
	syncState(ply)
	broadcastState()

	-- Сообщаем системе ботов — игрок занял место, нужно пересчитать
	hook.Run("CSBots_PlayerPickedTeam", ply, tid)
end)

net.Receive("CSMode_BuyWeapon", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	if CSConstruct.Phase ~= PHASE_FREEZE then return end
	if not isPlayingTeam(ply:Team()) then return end

	local cls = net.ReadString()
	if not CS_IsValidBuyClass(cls) then return end
	
	-- Проверка ограничений по командам
	local teamRestriction = CS_WEAPON_TEAMS[cls]
	if teamRestriction and teamRestriction ~= ply:Team() then
		-- Оружие недоступно для этой команды
		return
	end
	
	local price = CS_WEAPON_PRICES[cls]
	ply.CSMode_Money = ply.CSMode_Money or 0
	if ply.CSMode_Money < price then return end

	-- Определяем слот нового оружия
	local newSlot = CS_GetWeaponSlot(cls)

	-- Удаляем старое оружие из того же слота (кроме ножа и гранат — гранаты носятся по одной каждого типа)
	if newSlot ~= 3 and newSlot ~= 4 then
		for _, wep in ipairs(ply:GetWeapons()) do
			if IsValid(wep) then
				local wepClass = wep:GetClass()
				local wepSlot = CS_GetWeaponSlot(wepClass)
				if wepSlot == newSlot then
					ply:StripWeapon(wepClass)
				end
			end
		end
	end

	ply.CSMode_Money = ply.CSMode_Money - price

	-- Специальные предметы (броня, шлем, набор сапёра)
	if cls == "item_kevlar" then
		ply:SetArmor(100)
		syncState(ply)
		return
	elseif cls == "item_assaultsuit" then
		ply:SetArmor(100)
		ply:GiveHelmet()
		syncState(ply)
		return
	elseif cls == "item_defuser" then
		ply:GiveDefuser()
		syncState(ply)
		return
	end

	local newWep = ply:Give(cls)

	-- Выдаём запасные патроны
	if IsValid(newWep) then
		giveWeaponAmmo(ply, newWep)
		-- Автоматически переключаемся на купленное оружие
		ply:SelectWeapon(cls)
	end

	syncState(ply)
end)

-- Прямой выбор бомбы по клавише 5 (клиент → сервер)
net.Receive("CSMode_SelectBomb", function(_, ply)
	if not IsValid(ply) or not ply:Alive() then return end
	local bomb = ply:GetWeapon("weapon_swcs_c4")
	if IsValid(bomb) then
		ply:SelectWeapon(bomb)
	end
end)

hook.Add("PlayerDisconnected", "CSConstruct_Sync", function()
	timer.Simple(0, broadcastState)
end)

function GM:Move(ply, mv)
	-- Блокировка движения во время фриза, но разрешение поворота камеры
	if ply.CSMode_Frozen then
		mv:SetForwardSpeed(0)
		mv:SetSideSpeed(0)
		mv:SetUpSpeed(0)
		mv:SetVelocity(Vector(0, 0, 0))
		return true
	end
end

function GM:PlayerCanPickupWeapon(ply, wep)
	-- Разрешаем подбирать оружие во время фриз-тайма
	return true
end

-- Применить перчатки без рестарта: перезагружает руки игрока
concommand.Add("cs_apply_hands", function(ply)
	if not IsValid(ply) then return end
	timer.Simple(0, function()
		if IsValid(ply) then ply:SetupHands() end
	end)
end)

function GM:PlayerNoClip(ply, desiredState)
	-- Запрещаем ноуклип
	return false
end


-- Реалистичные звуки шагов
local footstepSounds = {
	concrete = {
		"player/footsteps/concrete1.wav",
		"player/footsteps/concrete2.wav",
		"player/footsteps/concrete3.wav",
		"player/footsteps/concrete4.wav",
	},
	metal = {
		"player/footsteps/metal1.wav",
		"player/footsteps/metal2.wav",
		"player/footsteps/metal3.wav",
		"player/footsteps/metal4.wav",
	},
	dirt = {
		"player/footsteps/dirt1.wav",
		"player/footsteps/dirt2.wav",
		"player/footsteps/dirt3.wav",
		"player/footsteps/dirt4.wav",
	},
	wood = {
		"player/footsteps/wood1.wav",
		"player/footsteps/wood2.wav",
		"player/footsteps/wood3.wav",
		"player/footsteps/wood4.wav",
	},
	tile = {
		"player/footsteps/tile1.wav",
		"player/footsteps/tile2.wav",
		"player/footsteps/tile3.wav",
		"player/footsteps/tile4.wav",
	},
}

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
	if not IsValid(ply) then return true end

	-- Тихий шаг (Shift): шаги не слышны совсем (как в CS:GO)
	if ply:KeyDown(IN_SPEED) then return true end

	-- Также подавляем если скорость ниже порога ходьбы (170 u/s)
	local vel = ply:GetVelocity():Length2D()
	if vel < 170 then return true end

	-- Определяем материал поверхности
	local tr = util.TraceLine({
		start = pos,
		endpos = pos - Vector(0, 0, 10),
		filter = ply,
		mask = MASK_SOLID_BRUSHONLY
	})

	local matType = "concrete"
	if tr.Hit and tr.MatType then
		if tr.MatType == MAT_METAL then
			matType = "metal"
		elseif tr.MatType == MAT_DIRT or tr.MatType == MAT_SAND then
			matType = "dirt"
		elseif tr.MatType == MAT_WOOD then
			matType = "wood"
		elseif tr.MatType == MAT_TILE then
			matType = "tile"
		end
	end

	local sounds = footstepSounds[matType]
	if sounds and #sounds > 0 then
		local snd = sounds[math.random(#sounds)]
		local vol = vel > 240 and 0.75 or 0.55
		ply:EmitSound(snd, 70, math.random(95, 105), vol, CHAN_BODY)
	end

	return true
end

-- ============================================
-- СИСТЕМА ЛОББИ - Обработчики сетевых сообщений
-- ============================================

-- Выбор ножа игроком
net.Receive("CSMode_SelectKnife", function(_, ply)
	if not IsValid(ply) then return end
	local knifeClass = net.ReadString()
	
	-- Проверяем, что нож существует в списке
	local validKnife = false
	for _, knife in ipairs(CS_KNIVES) do
		if knife == knifeClass then
			validKnife = true
			break
		end
	end
	
	if validKnife then
		ply.CSMode_Knife = knifeClass
		PrintMessage(HUD_PRINTTALK, ply:Nick() .. " выбрал нож: " .. CS_GetKnifeName(knifeClass))
	end
end)

-- Установка режима игры
net.Receive("CSMode_SetGameMode", function(_, ply)
	if not IsValid(ply) then return end
	local mode = net.ReadUInt(8)
	
	if CS_GAME_MODES[mode] then
		CSConstruct.GameMode = mode
		cv_game_mode:SetInt(mode)
		PrintMessage(HUD_PRINTTALK, "Режим игры изменен на: " .. CS_GetGameModeName(mode))
		broadcastLobbyUpdate()
	end
end)

-- Начало игры из лобби
net.Receive("CSMode_StartGame", function(_, ply)
	if not IsValid(ply) then return end
	if CSConstruct.Phase ~= PHASE_LOBBY then return end
	
	-- Подсчитываем игроков и ботов в командах
	local tCount = 0
	local ctCount = 0
	for _, p in ipairs(player.GetAll()) do
		if p:Team() == TEAM_T then tCount = tCount + 1
		elseif p:Team() == TEAM_CT then ctCount = ctCount + 1
		end
	end
	if CSBots and CSBots.List then
		for _, bot in ipairs(CSBots.List) do
			if IsValid(bot) then
				if (bot.BotTeam or TEAM_T) == TEAM_T then tCount = tCount + 1
				elseif (bot.BotTeam or TEAM_T) == TEAM_CT then ctCount = ctCount + 1
				end
			end
		end
	end
	
	local modeData = CS_GAME_MODES[CSConstruct.GameMode]
	local requiredPerTeam = CS_GetGameModePlayersPerTeam(CSConstruct.GameMode)
	
	-- Проверяем, достаточно ли игроков
	-- Для режима тренировки разрешаем начать с 1 игроком в любой команде
	local canStart = false
	if modeData and modeData.allowSolo then
		canStart = (tCount >= requiredPerTeam or ctCount >= requiredPerTeam)
	else
		canStart = (tCount >= requiredPerTeam and ctCount >= requiredPerTeam)
	end
	
	if canStart then
		PrintMessage(HUD_PRINTTALK, "=== ИГРА НАЧИНАЕТСЯ! ===")
		PrintMessage(HUD_PRINTTALK, "Режим: " .. CS_GetGameModeName(CSConstruct.GameMode))
		-- Сбрасываем деньги всем игрокам до стартовых (защита от сохранённых значений)
		local startMoney = math.Clamp(cv_start_money:GetInt(), 0, 16000)
		for _, p in ipairs(player.GetAll()) do
			p.CSMode_Money = startMoney
		end
		CSConstruct.Phase = PHASE_WAITING
		broadcastState()
		timer.Simple(2, function()
			startFreezePhase()
		end)
	else
		if modeData and modeData.allowSolo then
			PrintMessage(HUD_PRINTTALK, "Недостаточно игроков! Нужно хотя бы " .. requiredPerTeam .. " игрок в любой команде.")
		else
			PrintMessage(HUD_PRINTTALK, "Недостаточно игроков! Нужно " .. requiredPerTeam .. " игроков в каждой команде.")
		end
		PrintMessage(HUD_PRINTTALK, "Сейчас: T=" .. tCount .. ", CT=" .. ctCount)
	end
end)


-- ============================================================
-- ЗОНЫ УСТАНОВКИ БОМБЫ
-- ============================================================

function GM:StartCommand(ply, cmd)
	-- Блокировка стрельбы во время фриз-тайма
	if CSConstruct.Phase == PHASE_FREEZE and isPlayingTeam(ply:Team()) then
		cmd:RemoveKey(IN_ATTACK)
		cmd:RemoveKey(IN_ATTACK2)
		return
	end
	-- Блокируем IN_ATTACK для C4 вне бомб-зоны
	if CSConstruct.Phase == PHASE_LIVE and ply:Team() == TEAM_T and ply:Alive() then
		local wep = ply:GetActiveWeapon()
		if IsValid(wep) and wep:GetClass() == "weapon_swcs_c4" and not CS_IsInBombZone(ply:GetPos()) then
			cmd:RemoveKey(IN_ATTACK)
			cmd:RemoveKey(IN_ATTACK2)
		end
	end
end

-- Страховка: удалить бомбу, если она всё же появилась вне зоны
hook.Add("OnEntityCreated", "CSMode_BombZoneFailsafe", function(ent)
	if not IsValid(ent) or ent:GetClass() ~= "swcs_planted_c4" then return end
	timer.Simple(0, function()
		if not IsValid(ent) then return end
		if not CS_IsInBombZone(ent:GetPos()) then
			ent:Remove()
			return
		end
		-- Оповестить всех об установке бомбы
		net.Start("CSMode_BombEvent")
		net.WriteString("planted")
		net.Broadcast()
	end)
end)

hook.Add("SWCSC4Defused", "CSMode_BombDefuseNotify", function()
	net.Start("CSMode_BombEvent")
	net.WriteString("defused")
	net.Broadcast()
end)

-- ============================================================
-- ТРЕНИРОВОЧНЫЙ РЕЖИМ: бесконечные патроны и ноуклип
-- ============================================================

hook.Add("Think", "CSMode_TrainingInfiniteAmmo", function()
	if CSConstruct.GameMode ~= GAMEMODE_TRAINING then return end
	for _, ply in ipairs(player.GetAll()) do
		if not ply:Alive() then continue end
		local wep = ply:GetActiveWeapon()
		if not IsValid(wep) then continue end
		local max1 = wep:GetMaxClip1()
		if max1 > 0 then
			wep:SetClip1(max1)
			local ammoType = wep:GetPrimaryAmmoType()
			if ammoType >= 0 then
				ply:SetAmmo(max1 * 10, ammoType)
			end
		end
	end
end)

hook.Add("PlayerNoClip", "CSMode_TrainingNoclip", function(ply)
	if CSConstruct.GameMode == GAMEMODE_TRAINING and isPlayingTeam(ply:Team()) then
		return true
	end
end)

