AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

--[[
	CS Construct Bot — base_ai + навигация по nav mesh (A*)
	- Движение: A* по nav mesh → цепочка waypoints → SCHED_FORCED_GO_RUN
	- Бой: Source engine AI (SCHED_RANGE_ATTACK1) — совместим с arc9
	- Фазы: FREEZE (закупка), LIVE (бой + патруль)
]]

-- ============================================
-- КОНСТАНТЫ
-- ============================================

local STATE_IDLE   = 0
local STATE_PATROL = 1
local STATE_COMBAT = 2
local STATE_PURSUE = 3

local DIFFICULTY_CFG = {
	[1] = { reaction = 0.70, scanInterval = 0.30, memoryTime = 2.0 },
	[2] = { reaction = 0.30, scanInterval = 0.15, memoryTime = 4.0 },
	[3] = { reaction = 0.10, scanInterval = 0.08, memoryTime = 6.0 },
}

local ROLE_POOL = { "sniper", "pusher", "pusher", "lurker", "support", "default" }

local ROLE_WEAPONS = {
	sniper = {
		[1] = { full = { "weapon_swcs_awp", "weapon_swcs_ssg08" }, smg = { "weapon_swcs_ssg08" }, eco = { "weapon_swcs_deagle", "weapon_swcs_p250" } },
		[2] = { full = { "weapon_swcs_awp", "weapon_swcs_ssg08" }, smg = { "weapon_swcs_ssg08" }, eco = { "weapon_swcs_deagle", "weapon_swcs_p250" } },
	},
	pusher = {
		[1] = { full = { "weapon_swcs_ak47", "weapon_swcs_sg556", "weapon_swcs_galilar" }, smg = { "weapon_swcs_ump45", "weapon_swcs_mp7", "weapon_swcs_nova" }, eco = { "weapon_swcs_p250", "weapon_swcs_deagle" } },
		[2] = { full = { "weapon_swcs_m4a1", "weapon_swcs_m4a1_silencer", "weapon_swcs_aug", "weapon_swcs_famas" }, smg = { "weapon_swcs_ump45", "weapon_swcs_mp7", "weapon_swcs_nova" }, eco = { "weapon_swcs_p250", "weapon_swcs_deagle" } },
	},
	lurker = {
		[1] = { full = { "weapon_swcs_ak47", "weapon_swcs_mac10", "weapon_swcs_mp7" }, smg = { "weapon_swcs_mac10", "weapon_swcs_mp7", "weapon_swcs_bizon" }, eco = { "weapon_swcs_p250", "weapon_swcs_tec9" } },
		[2] = { full = { "weapon_swcs_m4a1", "weapon_swcs_mp9", "weapon_swcs_mp7" }, smg = { "weapon_swcs_mp9", "weapon_swcs_mp7", "weapon_swcs_bizon" }, eco = { "weapon_swcs_p250", "weapon_swcs_deagle" } },
	},
	support = {
		[1] = { full = { "weapon_swcs_ak47", "weapon_swcs_galilar" }, smg = { "weapon_swcs_ump45", "weapon_swcs_mp7", "weapon_swcs_nova" }, eco = { "weapon_swcs_p250", "weapon_swcs_deagle" } },
		[2] = { full = { "weapon_swcs_m4a1", "weapon_swcs_m4a1_silencer", "weapon_swcs_famas" }, smg = { "weapon_swcs_ump45", "weapon_swcs_mp7", "weapon_swcs_nova" }, eco = { "weapon_swcs_p250", "weapon_swcs_deagle" } },
	},
	default = {
		[1] = { full = { "weapon_swcs_ak47", "weapon_swcs_sg556", "weapon_swcs_galilar" }, smg = { "weapon_swcs_ump45", "weapon_swcs_mp7", "weapon_swcs_bizon", "weapon_swcs_nova" }, eco = { "weapon_swcs_p250", "weapon_swcs_deagle" } },
		[2] = { full = { "weapon_swcs_m4a1", "weapon_swcs_m4a1_silencer", "weapon_swcs_aug", "weapon_swcs_famas" }, smg = { "weapon_swcs_ump45", "weapon_swcs_mp7", "weapon_swcs_bizon", "weapon_swcs_nova" }, eco = { "weapon_swcs_p250", "weapon_swcs_deagle" } },
	},
}

-- ============================================
-- A* НАВИГАЦИЯ ПО NAV MESH
-- ============================================

local function FindNavPath(startPos, endPos)
	local startArea = navmesh.GetNearestNavArea(startPos)
	local endArea   = navmesh.GetNearestNavArea(endPos)
	if not startArea or not endArea then return nil end
	if startArea == endArea then return { endPos } end

	-- A* поиск
	local openSet  = { [startArea] = true }
	local openList = { startArea }
	local cameFrom = {}
	local gScore   = { [startArea] = 0 }
	local fScore   = { [startArea] = startPos:Distance(endPos) }

	local iterations = 0
	while #openList > 0 and iterations < 500 do
		iterations = iterations + 1

		-- Находим узел с наименьшим fScore
		local bestIdx, bestArea, bestF = 1, openList[1], fScore[openList[1]] or math.huge
		for i = 2, #openList do
			local f = fScore[openList[i]] or math.huge
			if f < bestF then bestIdx = i bestArea = openList[i] bestF = f end
		end

		if bestArea == endArea then
			-- Восстанавливаем путь
			local path = { endPos }
			local node = endArea
			while cameFrom[node] do
				node = cameFrom[node]
				if node ~= startArea then
					table.insert(path, 1, node:GetCenter())
				end
			end
			return path
		end

		table.remove(openList, bestIdx)
		openSet[bestArea] = nil

		for _, neighbor in ipairs(bestArea:GetAdjacentAreas()) do
			local tentG = (gScore[bestArea] or 0) + bestArea:GetCenter():Distance(neighbor:GetCenter())
			if tentG < (gScore[neighbor] or math.huge) then
				cameFrom[neighbor] = bestArea
				gScore[neighbor]   = tentG
				fScore[neighbor]   = tentG + neighbor:GetCenter():Distance(endPos)
				if not openSet[neighbor] then
					openSet[neighbor] = true
					table.insert(openList, neighbor)
				end
			end
		end
	end

	return nil
end

-- ============================================
-- ИНИЦИАЛИЗАЦИЯ
-- ============================================

function ENT:Initialize()
	local model = self.BotModel or "models/humans/group03/male_02.mdl"
	self:SetModel(model)
	self:SetHullType(HULL_HUMAN)
	self:SetHullSizeNormal()
	self:SetNPCState(NPC_STATE_IDLE)
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_STEP)
	self:CapabilitiesAdd(bit.bor(
		CAP_MOVE_GROUND, CAP_MOVE_JUMP, CAP_TURN_HEAD,
		CAP_USE_WEAPONS, CAP_ANIMATEDFACE, CAP_USE_SHOT_REGULATOR
	))
	self:SetMaxYawSpeed(200)
	self:SetHealth(100)
	self:SetCollisionGroup(COLLISION_GROUP_NPC)

	-- CS-состояние
	self.IsCSBot           = true
	self.CSMode_Money      = self.CSMode_Money or 800
	self.BotRole           = self.BotRole or ROLE_POOL[math.random(#ROLE_POOL)]
	self.CSMode_LastBuyTime = 0
	self.BotHasBought      = false

	-- AI-состояние
	self.BotState          = STATE_IDLE
	self.BotEnemy          = nil
	self.BotEnemyLastPos   = nil
	self.BotEnemyLastSeen  = 0
	self.BotReactionReady  = 0
	self.NextScanTime      = 0
	self.NextMoveTime      = 0
	self.NextRelTime       = 0

	-- Навигация
	self.NavPath           = nil
	self.NavPathIndex      = 0
	self.NavTarget         = nil

	-- Сложность
	local diff = math.Clamp(GetConVar("cs_construct_bots_difficulty"):GetInt(), 1, 3)
	local cfg  = DIFFICULTY_CFG[diff]
	self.DiffReaction    = cfg.reaction
	self.DiffScanInterval = cfg.scanInterval
	self.DiffMemoryTime  = cfg.memoryTime

	-- Регистрация
	if CSBots and CSBots.List then
		table.insert(CSBots.List, self)
	end

	print("[CS Bot] Бот создан: " .. (self.BotTeam == TEAM_CT and "CT" or "T") .. " роль: " .. self.BotRole)
end

-- ============================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================

function ENT:Think()
	self:NextThink(CurTime() + 0.1)
	if not CSConstruct then return true end

	-- Коррекция высоты: если провалился под пол
	self:FixFloorPosition()

	local phase = CSConstruct.Phase

	-- Обновляем отношения
	if CurTime() > self.NextRelTime then
		self:UpdateRelationships()
		self.NextRelTime = CurTime() + 2
	end

	if phase == PHASE_FREEZE then
		self:FreezeThink()
	elseif phase == PHASE_LIVE then
		self:LiveThink()
	end

	return true
end

function ENT:FixFloorPosition()
	local pos = self:GetPos()
	local tr = util.TraceLine({
		start  = pos + Vector(0, 0, 10),
		endpos = pos - Vector(0, 0, 64),
		filter = self,
		mask   = MASK_NPCSOLID_BRUSHONLY,
	})
	if tr.Hit and pos.z < tr.HitPos.z - 2 then
		self:SetPos(Vector(pos.x, pos.y, tr.HitPos.z + 1))
	end
end

-- ============================================
-- ФАЗА ЗАМОРОЗКИ
-- ============================================

function ENT:FreezeThink()
	-- Полная остановка
	self:SetAbsVelocity(Vector(0, 0, 0))
	if self:GetNPCState() ~= NPC_STATE_IDLE then
		self:SetNPCState(NPC_STATE_IDLE)
		self:ClearEnemyMemory()
		self:ClearSchedule()
	end

	if not self.BotHasBought and CurTime() - self.CSMode_LastBuyTime > 0.8 then
		self:BuyWeapons()
	end
end

-- ============================================
-- ЖИВАЯ ФАЗА
-- ============================================

function ENT:LiveThink()
	-- Сканируем врагов
	if CurTime() >= self.NextScanTime then
		self:ScanForEnemies()
		self.NextScanTime = CurTime() + self.DiffScanInterval
	end

	if self.BotState == STATE_COMBAT then
		self:CombatThink()
	elseif self.BotState == STATE_PURSUE then
		self:PursueThink()
	else
		self:PatrolThink()
	end
end

-- ============================================
-- ОТНОШЕНИЯ
-- ============================================

function ENT:UpdateRelationships()
	local myTeam = self.BotTeam or TEAM_T
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) then continue end
		if ply:Team() == myTeam then
			self:AddEntityRelationship(ply, D_LI, 99)
		elseif ply:Team() == TEAM_T or ply:Team() == TEAM_CT then
			self:AddEntityRelationship(ply, D_HT, 99)
		end
	end
	if CSBots and CSBots.List then
		for _, bot in ipairs(CSBots.List) do
			if not IsValid(bot) or bot == self then continue end
			self:AddEntityRelationship(bot, (bot.BotTeam or TEAM_T) == myTeam and D_LI or D_HT, 99)
		end
	end
end

-- ============================================
-- ОБНАРУЖЕНИЕ ВРАГОВ
-- ============================================

function ENT:ScanForEnemies()
	local myTeam     = self.BotTeam or TEAM_T
	local bestTarget = nil
	local bestDistSq = 4500 * 4500

	-- Игроки
	for _, ply in ipairs(player.GetAll()) do
		if not IsValid(ply) or not ply:Alive() then continue end
		if ply:Team() == myTeam or (ply:Team() ~= TEAM_T and ply:Team() ~= TEAM_CT) then continue end
		local dSq = self:GetPos():DistToSqr(ply:GetPos())
		if dSq < bestDistSq and self:CanSeeTarget(ply) then
			bestDistSq = dSq
			bestTarget = ply
		end
	end

	-- Боты
	if CSBots and CSBots.List then
		for _, bot in ipairs(CSBots.List) do
			if not IsValid(bot) or bot == self or bot:Health() <= 0 then continue end
			if (bot.BotTeam or TEAM_T) == myTeam then continue end
			local dSq = self:GetPos():DistToSqr(bot:GetPos())
			if dSq < bestDistSq and self:CanSeeTarget(bot) then
				bestDistSq = dSq
				bestTarget = bot
			end
		end
	end

	if IsValid(bestTarget) then
		if self.BotEnemy ~= bestTarget then
			self.BotReactionReady = CurTime() + self.DiffReaction
		end
		self.BotEnemy        = bestTarget
		self.BotEnemyLastPos = bestTarget:GetPos()
		self.BotEnemyLastSeen = CurTime()
		self.BotState        = STATE_COMBAT
		self.NavPath         = nil -- бросаем патруль
	else
		if self.BotState == STATE_COMBAT and IsValid(self.BotEnemy) then
			self.BotEnemyLastPos = self.BotEnemy:GetPos()
			self.BotEnemyLastSeen = CurTime()
			self.BotState = STATE_PURSUE
		elseif self.BotState == STATE_PURSUE then
			if CurTime() - self.BotEnemyLastSeen > self.DiffMemoryTime then
				self.BotEnemy = nil
				self.BotState = STATE_PATROL
			end
		end
	end
end

function ENT:CanSeeTarget(target)
	if not IsValid(target) then return false end
	local tr = util.TraceLine({
		start  = self:EyePos(),
		endpos = target.EyePos and target:EyePos() or (target:GetPos() + Vector(0, 0, 60)),
		filter = { self, target },
		mask   = MASK_VISIBLE_AND_NPCS,
	})
	return tr.Fraction >= 0.98 or tr.Entity == target
end

-- ============================================
-- БОЙ
-- ============================================

function ENT:CombatThink()
	local enemy = self.BotEnemy
	if not IsValid(enemy) then
		self.BotState = STATE_PATROL
		return
	end

	self:SetEnemy(enemy)
	self:UpdateEnemyMemory(enemy, enemy:GetPos())
	self:SetNPCState(NPC_STATE_COMBAT)

	-- Ждём время реакции
	if CurTime() < self.BotReactionReady then
		self:SetSchedule(SCHED_COMBAT_FACE)
		return
	end

	-- Стреляем или преследуем
	if self:CanSeeTarget(enemy) then
		local wep = self:GetActiveWeapon()
		if IsValid(wep) and wep.Clip1 and wep:Clip1() > 0 then
			self:SetSchedule(SCHED_RANGE_ATTACK1)
		else
			self:SetSchedule(SCHED_CHASE_ENEMY)
		end
	else
		-- Враг скрылся — идём к последней позиции через nav mesh
		self.BotState = STATE_PURSUE
	end
end

-- ============================================
-- ПРЕСЛЕДОВАНИЕ (по nav mesh)
-- ============================================

function ENT:PursueThink()
	if not self.BotEnemyLastPos then
		self.BotState = STATE_PATROL
		return
	end
	if CurTime() - self.BotEnemyLastSeen > self.DiffMemoryTime then
		self.BotEnemy = nil
		self.BotState = STATE_PATROL
		self.NavPath  = nil
		return
	end

	self:SetNPCState(NPC_STATE_ALERT)
	self:NavigateToPos(self.BotEnemyLastPos)
end

-- ============================================
-- ПАТРУЛЬ (по nav mesh)
-- ============================================

function ENT:PatrolThink()
	if CurTime() < self.NextMoveTime then return end

	-- Выбираем новую цель если нужно
	if not self.NavTarget or (self.NavPath and #self.NavPath == 0) or not self.NavPath then
		self.NavTarget = self:PickPatrolPoint()
		self.NavPath   = nil
	end

	if self.NavTarget then
		self:SetNPCState(NPC_STATE_ALERT)
		self:NavigateToPos(self.NavTarget)
	end

	self.NextMoveTime = CurTime() + 0.5
end

function ENT:PickPatrolPoint()
	local areas = navmesh.GetAllNavAreas()
	if not areas or #areas == 0 then return nil end

	local myPos = self:GetPos()
	-- Пробуем найти точку на расстоянии 500-3000 единиц
	for _ = 1, 15 do
		local area = areas[math.random(#areas)]
		local center = area:GetCenter()
		local dist = myPos:Distance(center)
		if dist > 500 and dist < 3000 then
			return center
		end
	end
	-- Fallback: любая точка
	return areas[math.random(#areas)]:GetCenter()
end

-- ============================================
-- НАВИГАЦИЯ ПО NAV MESH
-- ============================================

function ENT:NavigateToPos(targetPos)
	-- Строим путь если его нет
	if not self.NavPath or #self.NavPath == 0 then
		self.NavPath = FindNavPath(self:GetPos(), targetPos)
		self.NavPathIndex = 1
		if not self.NavPath then
			self.NavTarget = nil
			return
		end
	end

	-- Текущий waypoint
	local wp = self.NavPath[self.NavPathIndex]
	if not wp then
		self.NavPath = nil
		self.NavTarget = nil
		return
	end

	-- Дошли до waypoint — следующий
	if self:GetPos():Distance(wp) < 80 then
		self.NavPathIndex = self.NavPathIndex + 1
		if self.NavPathIndex > #self.NavPath then
			self.NavPath   = nil
			self.NavTarget = nil
			return
		end
		wp = self.NavPath[self.NavPathIndex]
	end

	-- Двигаемся к waypoint напрямую через скорость
	if wp then
		local dir = wp - self:GetPos()
		dir.z = 0
		local len = dir:Length()
		if len > 1 then
			dir = dir / len

			-- Поворачиваем
			local yaw = math.deg(math.atan2(dir.y, dir.x))
			self:SetIdealYawAndUpdate(yaw)

			-- Двигаемся
			local speed = 200
			local curVelZ = self:GetAbsVelocity().z
			self:SetAbsVelocity(Vector(dir.x * speed, dir.y * speed, curVelZ))

			-- Анимация ходьбы
			if self:GetMovementActivity() ~= ACT_RUN then
				self:SetMovementActivity(ACT_RUN)
			end
		end
	end
end

-- ============================================
-- ЗАКУПКА ОРУЖИЯ
-- ============================================

function ENT:BuyWeapons()
	local money = self.CSMode_Money or 800
	local team  = self.BotTeam or TEAM_T
	local role  = self.BotRole or "default"

	local pools = (ROLE_WEAPONS[role] or ROLE_WEAPONS["default"])[team]
	if not pools then self.BotHasBought = true return end

	-- Раунд 1 — пистольный (как в CS:GO): только эко, независимо от денег
	local roundNum = CSConstruct and CSConstruct.RoundNum or 1
	if roundNum == 1 then
		local eco = pools.eco
		if eco and #eco > 0 then
			self:Give(eco[math.random(#eco)])
		end
		self.BotHasBought      = true
		self.CSMode_LastBuyTime = CurTime()
		return
	end

	local hasRifle = false
	for _, wep in ipairs(self:GetWeapons()) do
		if IsValid(wep) then
			local slot = CS_GetWeaponSlot and CS_GetWeaponSlot(wep:GetClass()) or 0
			if slot == 1 then hasRifle = true end
		end
	end

	if not hasRifle then
		local rawPool
		if role == "sniper" then
			rawPool = money >= 4750 and { "weapon_swcs_awp" } or money >= 1700 and { "weapon_swcs_ssg08" } or pools.eco
		elseif money >= 2500 then rawPool = pools.full
		elseif money >= 1000 then rawPool = pools.smg
		else rawPool = pools.eco end

		local valid = {}
		for _, cls in ipairs(rawPool or {}) do
			local price = CS_WEAPON_PRICES and CS_WEAPON_PRICES[cls]
			if price and money >= price then table.insert(valid, cls) end
		end

		if #valid > 0 then
			local chosen = valid[math.random(#valid)]
			self:Give(chosen)
			self.CSMode_Money = self.CSMode_Money - (CS_WEAPON_PRICES[chosen] or 0)
		end
	end

	self.BotHasBought      = true
	self.CSMode_LastBuyTime = CurTime()
end

-- ============================================
-- СМЕРТЬ
-- ============================================

function ENT:OnKilled(dmginfo)
	-- Награда за убийство
	local attacker = dmginfo:GetAttacker()
	if IsValid(attacker) and attacker:IsPlayer() and attacker:Team() ~= (self.BotTeam or TEAM_T) then
		if CSConstruct and CSConstruct.Phase == PHASE_LIVE then
			local reward = GetConVar("cs_construct_kill_reward"):GetInt()
			attacker.CSMode_Money = (attacker.CSMode_Money or 0) + reward

			net.Start("CSMode_SyncState")
			net.WriteUInt(CSConstruct.Phase, 8)
			net.WriteUInt(CSConstruct.RoundNum, 16)
			net.WriteUInt(CSConstruct.ScoreT, 16)
			net.WriteUInt(CSConstruct.ScoreCT, 16)
			net.WriteFloat(CSConstruct.PhaseEndsAt)
			net.WriteFloat(CSConstruct.RoundEndsAt)
			net.WriteUInt(math.Clamp(attacker.CSMode_Money or 0, 0, 999999), 32)
			net.WriteUInt(CSConstruct.GameMode or GAMEMODE_COMPETITIVE, 8)
			net.Send(attacker)
		end
	end

	if CSBots then table.RemoveByValue(CSBots.List, self) end

	-- Вызываем базовый OnKilled — он создаёт рагдолл и кровь
	self.BaseClass.OnKilled(self, dmginfo)
end

function ENT:OnTakeDamage(dmginfo)
	-- Передаём урон движку (кровь, хитбоксы, смерть с рагдоллом)
	self:SetHealth(self:Health() - dmginfo:GetDamage())

	local attacker = dmginfo:GetAttacker()

	if self:Health() <= 0 then
		self:OnKilled(dmginfo)
		return
	end

	-- Реакция на урон — переключаемся в бой
	if IsValid(attacker) and attacker ~= self then
		if not attacker.GetTeam or attacker:GetTeam() ~= (self.BotTeam or TEAM_T) then
			self.BotReactionReady = CurTime()
			self.BotEnemy        = attacker
			self.BotEnemyLastPos = attacker:GetPos()
			self.BotEnemyLastSeen = CurTime()
			self.BotState        = STATE_COMBAT
			self.NavPath         = nil
			self:SetEnemy(attacker)
			self:UpdateEnemyMemory(attacker, attacker:GetPos())
		end
	end
end

-- ============================================
-- СБРОС РАУНДА
-- ============================================

function ENT:ResetForNewRound()
	self.BotState          = STATE_IDLE
	self.BotHasBought      = false
	self.BotEnemy          = nil
	self.BotEnemyLastPos   = nil
	self.BotEnemyLastSeen  = 0
	self.BotReactionReady  = 0
	self.NextScanTime      = 0
	self.NextMoveTime      = 0
	self.NavPath           = nil
	self.NavPathIndex      = 0
	self.NavTarget         = nil
	self.CSMode_LastBuyTime = 0
	self:SetNPCState(NPC_STATE_IDLE)
	self:ClearEnemyMemory()
	self:ClearSchedule()
end

-- ============================================
-- СОВМЕСТИМОСТЬ
-- ============================================

function ENT:GetTeam()
	return self.BotTeam or TEAM_T
end

function ENT:SetTeam(t)
	self.BotTeam = t
end
