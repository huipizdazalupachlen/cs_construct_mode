--[[
	CS Construct — shared definitions.

	ConVars (server, created in init.lua):
	  cs_construct_min_players      — минимум игроков с выбранной командой для старта раундов (по умолчанию 1).
	  cs_construct_freeze_time      — фриз + покупка, секунды.
	  cs_construct_round_time       — длительность боя, секунды.
	  cs_construct_round_end_delay  — пауза после раунда перед следующим фризом.
	  cs_construct_start_money      — стартовые деньги.
	  cs_construct_win_money          — бонус за победу в раунде.
	  cs_construct_lose_money         — бонус за поражение.
	  cs_construct_kill_reward        — деньги за убийство.
	  cs_construct_timeout_favors_ct  — 1: по таймауту побеждает CT; 0: ничья, обе команды получают lose-бонус.

	Спавны gm_construct: правьте таблицы TEAM_SPAWNS ниже (Vector/Angle).
	Поддерживаются имена карт: gm_construct, gm_constract (опечатка в запросе).
]]

GM.Name = "CS Construct"
GM.Author = "Addon"
GM.Email = ""
GM.Website = ""

-- Система движения CS:GO (скорость по оружию, антибхоп, ходьба)
include("sh_movement.lua")

-- Фазы раунда (синхронизируются с клиентом)
PHASE_LOBBY = 0
PHASE_WAITING = 1
PHASE_FREEZE = 2
PHASE_LIVE = 3
PHASE_ROUND_END = 4

-- Команды (team.SetUp на сервере с теми же ID)
TEAM_T = 1
TEAM_CT = 2

-- Модели персонажей для команд
-- T: CS:GO T-side playermodels (addon 481607813, extracted_481607813)
-- CT: CS:GO CT-side playermodels (addon 481358078, пока базовые GMod)
CS_TEAM_MODELS = {
	[TEAM_T] = {
		"models/csgopheonix1pm.mdl",
		"models/csgopheonix2pm.mdl",
		"models/csgoseparatist1pm.mdl",
		"models/csgoseparatist2pm.mdl",
		"models/csgoanarchist1pm.mdl",
		"models/csgoanarchist2pm.mdl",
		"models/csgobalkan1pm.mdl",
		"models/csgobalkan2pm.mdl",
		"models/csgoleet1pm.mdl",
		"models/csgoleet2pm.mdl",
	},
	[TEAM_CT] = {
		"models/csgofbi1pm.mdl",
		"models/csgofbi2pm.mdl",
		"models/csgosas1pm.mdl",
		"models/csgosas2pm.mdl",
		"models/csgoswat1pm.mdl",
		"models/csgoswat2pm.mdl",
		"models/csgogign1pm.mdl",
		"models/csgogign2pm.mdl",
		"models/csgoidf1pm.mdl",
		"models/csgoidf2pm.mdl",
	},
}

-- Модели NPC-ботов для npc_citizen.
-- Важно: npc_citizen требует citizen-совместимый скелет.
-- T: CS:GO T-side NPC модели (addon 481607813, extracted_481607813)
-- CT: базовые GMod модели до установки CT addon
CS_BOT_MODELS = {
	[TEAM_T] = {
		"models/csgopheonix1npc.mdl",
		"models/csgopheonix2npc.mdl",
		"models/csgopheonix3npc.mdl",
		"models/csgopheonix4npc.mdl",
		"models/csgoseparatist1npc.mdl",
		"models/csgoseparatist2npc.mdl",
		"models/csgoseparatist3npc.mdl",
		"models/csgoseparatist4npc.mdl",
		"models/csgoanarchist1npc.mdl",
		"models/csgoanarchist2npc.mdl",
		"models/csgobalkan1npc.mdl",
		"models/csgobalkan2npc.mdl",
		"models/csgoleet1npc.mdl",
		"models/csgoleet2npc.mdl",
	},
	[TEAM_CT] = {
		"models/csgofbi1npc.mdl",
		"models/csgofbi2npc.mdl",
		"models/csgofbi3npc.mdl",
		"models/csgofbi4npc.mdl",
		"models/csgosas1npc.mdl",
		"models/csgosas2npc.mdl",
		"models/csgoswat1npc.mdl",
		"models/csgoswat2npc.mdl",
		"models/csgogign1npc.mdl",
		"models/csgogign2npc.mdl",
		"models/csgoidf1npc.mdl",
		"models/csgoidf2npc.mdl",
	},
}

-- Ножи из CS:GO аддона (правильные названия из csgo_knives_sweps)
-- Включая базовые ножи и популярные скины
CS_KNIVES = {
	-- SWCS ножи (регистрируются через sh_knives.lua как weapon_swcs_knife_*)
	"weapon_swcs_knife_ghost",          -- Spectral Shiv
	"weapon_swcs_knife_bayonet",        -- Bayonet
	"weapon_swcs_knife_css",            -- Classic
	"weapon_swcs_knife_flip",           -- Flip
	"weapon_swcs_knife_gut",            -- Gut
	"weapon_swcs_knife_karambit",       -- Karambit
	"weapon_swcs_knife_m9_bayonet",     -- M9 Bayonet
	"weapon_swcs_knife_tactical",       -- Huntsman
	"weapon_swcs_knife_falchion",       -- Falchion
	"weapon_swcs_knife_survival_bowie", -- Bowie
	"weapon_swcs_knife_butterfly",      -- Butterfly
	"weapon_swcs_knife_push",           -- Shadow Daggers
	"weapon_swcs_knife_cord",           -- Paracord
	"weapon_swcs_knife_canis",          -- Survival
	"weapon_swcs_knife_ursus",          -- Ursus
	"weapon_swcs_knife_gypsy_jackknife",-- Navaja
	"weapon_swcs_knife_outdoor",        -- Nomad
	"weapon_swcs_knife_stiletto",       -- Stiletto
	"weapon_swcs_knife_widowmaker",     -- Talon
	"weapon_swcs_knife_skeleton",       -- Skeleton
	"weapon_swcs_knife_kukri",          -- Kukri
	-- Базовые (T/CT по умолчанию)
	"weapon_swcs_knife_t",              -- Default T
	"weapon_swcs_knife_ct",             -- Default CT
}

function CS_GetRandomKnife()
	if #CS_KNIVES == 0 then
		return "weapon_crowbar" -- Fallback на монтировку
	end
	return CS_KNIVES[math.random(#CS_KNIVES)]
end

-- Цены оружия SWCS (как в CS:GO)
CS_WEAPON_PRICES = {
	-- Пистолеты
	["weapon_swcs_glock"] = 200,
	["weapon_swcs_usp_silencer"] = 200,
	["weapon_swcs_hkp2000"] = 200,
	["weapon_swcs_p250"] = 300,
	["weapon_swcs_fiveseven"] = 500,
	["weapon_swcs_tec9"] = 500,
	["weapon_swcs_deagle"] = 700,
	["weapon_swcs_elite"] = 400,
	["weapon_swcs_cz75"] = 500,
	["weapon_swcs_revolver"] = 600,
	
	-- Пистолеты-пулеметы (SMG)
	["weapon_swcs_mac10"] = 1050,
	["weapon_swcs_mp9"] = 1250,
	["weapon_swcs_mp7"] = 1500,
	["weapon_swcs_ump45"] = 1200,
	["weapon_swcs_p90"] = 2350,
	["weapon_swcs_bizon"] = 1400,
	["weapon_swcs_mp5sd"] = 1500,
	
	-- Дробовики
	["weapon_swcs_nova"] = 1050,
	["weapon_swcs_xm1014"] = 2000,
	["weapon_swcs_mag7"] = 1300,
	["weapon_swcs_sawedoff"] = 1100,
	
	-- Винтовки
	["weapon_swcs_famas"] = 2050,
	["weapon_swcs_galilar"] = 1800,
	["weapon_swcs_ak47"] = 2700,
	["weapon_swcs_m4a1"] = 3100,
	["weapon_swcs_m4a1_silencer"] = 2900,
	["weapon_swcs_sg556"] = 3000,
	["weapon_swcs_aug"] = 3300,
	
	-- Снайперские винтовки
	["weapon_swcs_ssg08"] = 1700,
	["weapon_swcs_awp"] = 4750,
	["weapon_swcs_scar20"] = 5000,
	["weapon_swcs_g3sg1"] = 5000,
	
	-- Пулеметы
	["weapon_swcs_negev"] = 1700,
	["weapon_swcs_m249"] = 5200,

	-- Гранаты
	["weapon_swcs_hegrenade"] = 300,
	["weapon_swcs_flashbang"] = 200,
	["weapon_swcs_smokegrenade"] = 300,
	["weapon_swcs_molotov"] = 400,
	["weapon_swcs_incgrenade"] = 600,
	["weapon_swcs_decoy"] = 50,

	-- Снаряжение
	["item_kevlar"]      = 650,   -- Броня
	["item_assaultsuit"] = 1000,  -- Броня + шлем
	["item_defuser"]     = 400,   -- Набор сапёра (CT only)
}

-- Ограничения по командам (nil = обе команды, TEAM_T = только T, TEAM_CT = только CT)
CS_WEAPON_TEAMS = {
	-- Только T
	["weapon_swcs_glock"] = TEAM_T,
	["weapon_swcs_tec9"] = TEAM_T,
	["weapon_swcs_mac10"] = TEAM_T,
	["weapon_swcs_sawedoff"] = TEAM_T,
	["weapon_swcs_galilar"] = TEAM_T,
	["weapon_swcs_ak47"] = TEAM_T,
	["weapon_swcs_sg556"] = TEAM_T,
	["weapon_swcs_g3sg1"] = TEAM_T,
	
	-- Только CT
	["weapon_swcs_usp_silencer"] = TEAM_CT,
	["weapon_swcs_hkp2000"] = TEAM_CT,
	["weapon_swcs_fiveseven"] = TEAM_CT,
	["weapon_swcs_mp9"] = TEAM_CT,
	["weapon_swcs_mag7"] = TEAM_CT,
	["weapon_swcs_famas"] = TEAM_CT,
	["weapon_swcs_m4a1"] = TEAM_CT,
	["weapon_swcs_m4a1_silencer"] = TEAM_CT,
	["weapon_swcs_aug"] = TEAM_CT,
	["weapon_swcs_scar20"] = TEAM_CT,

	-- Набор сапёра: только CT
	["item_defuser"] = TEAM_CT,

	-- Гранаты с ограничением
	["weapon_swcs_molotov"] = TEAM_T,
	["weapon_swcs_incgrenade"] = TEAM_CT,
}

-- Категории оружия для меню
CS_WEAPON_CATEGORIES = {
	{
		name = "Пистолеты",
		weapons = {
			"weapon_swcs_glock", "weapon_swcs_usp_silencer", "weapon_swcs_hkp2000", "weapon_swcs_p250",
			"weapon_swcs_fiveseven", "weapon_swcs_tec9", "weapon_swcs_deagle", "weapon_swcs_elite",
			"weapon_swcs_cz75", "weapon_swcs_revolver"
		}
	},
	{
		name = "Пистолеты-пулеметы",
		weapons = {
			"weapon_swcs_mac10", "weapon_swcs_mp9", "weapon_swcs_mp7", "weapon_swcs_ump45",
			"weapon_swcs_p90", "weapon_swcs_bizon", "weapon_swcs_mp5sd"
		}
	},
	{
		name = "Дробовики",
		weapons = {
			"weapon_swcs_nova", "weapon_swcs_xm1014", "weapon_swcs_mag7", "weapon_swcs_sawedoff"
		}
	},
	{
		name = "Винтовки",
		weapons = {
			"weapon_swcs_famas", "weapon_swcs_galilar", "weapon_swcs_ak47", "weapon_swcs_m4a1",
			"weapon_swcs_m4a1_silencer", "weapon_swcs_sg556", "weapon_swcs_aug"
		}
	},
	{
		name = "Снайперские винтовки",
		weapons = {
			"weapon_swcs_ssg08", "weapon_swcs_awp", "weapon_swcs_scar20", "weapon_swcs_g3sg1"
		}
	},
	{
		name = "Пулеметы",
		weapons = {
			"weapon_swcs_negev", "weapon_swcs_m249"
		}
	},
	{
		name = "Гранаты",
		weapons = {
			"weapon_swcs_hegrenade", "weapon_swcs_flashbang", "weapon_swcs_smokegrenade",
			"weapon_swcs_molotov", "weapon_swcs_incgrenade", "weapon_swcs_decoy"
		}
	},
	{
		name = "Снаряжение",
		weapons = { "item_kevlar", "item_assaultsuit", "item_defuser" }
	}
}

-- Отображаемые имена для предметов снаряжения
CS_ITEM_DISPLAY = {
	["item_kevlar"]      = "БРОНЯ",
	["item_assaultsuit"] = "БРОНЯ + ШЛЕМ",
	["item_defuser"]     = "НАБОР САПЁРА",
}

-- Порядок в магазине (все оружие по категориям)
CS_WEAPON_ORDER = {}
for _, cat in ipairs(CS_WEAPON_CATEGORIES) do
	for _, wep in ipairs(cat.weapons) do
		table.insert(CS_WEAPON_ORDER, wep)
	end
end

-- Слоты оружия (как в CS:GO)
-- 1 = Основное оружие (винтовки, снайперки, дробовики, пулеметы)
-- 2 = Пистолет
-- 3 = Нож
-- 4 = Гранаты
CS_WEAPON_SLOTS = {
	-- Пистолеты (слот 2)
	["weapon_swcs_glock"] = 2,
	["weapon_swcs_usp_silencer"] = 2,
	["weapon_swcs_hkp2000"] = 2,
	["weapon_swcs_p250"] = 2,
	["weapon_swcs_fiveseven"] = 2,
	["weapon_swcs_tec9"] = 2,
	["weapon_swcs_deagle"] = 2,
	["weapon_swcs_elite"] = 2,
	["weapon_swcs_cz75"] = 2,
	["weapon_swcs_revolver"] = 2,
	
	-- SMG (слот 1)
	["weapon_swcs_mac10"] = 1,
	["weapon_swcs_mp9"] = 1,
	["weapon_swcs_mp7"] = 1,
	["weapon_swcs_ump45"] = 1,
	["weapon_swcs_p90"] = 1,
	["weapon_swcs_bizon"] = 1,
	["weapon_swcs_mp5sd"] = 1,
	
	-- Дробовики (слот 1)
	["weapon_swcs_nova"] = 1,
	["weapon_swcs_xm1014"] = 1,
	["weapon_swcs_mag7"] = 1,
	["weapon_swcs_sawedoff"] = 1,
	
	-- Винтовки (слот 1)
	["weapon_swcs_famas"] = 1,
	["weapon_swcs_galilar"] = 1,
	["weapon_swcs_ak47"] = 1,
	["weapon_swcs_m4a1"] = 1,
	["weapon_swcs_m4a1_silencer"] = 1,
	["weapon_swcs_sg556"] = 1,
	["weapon_swcs_aug"] = 1,
	
	-- Снайперские винтовки (слот 1)
	["weapon_swcs_ssg08"] = 1,
	["weapon_swcs_awp"] = 1,
	["weapon_swcs_scar20"] = 1,
	["weapon_swcs_g3sg1"] = 1,
	
	-- Пулеметы (слот 1)
	["weapon_swcs_negev"] = 1,
	["weapon_swcs_m249"] = 1,

	-- Бомба (слот 5 — отдельный, не конфликтует с основным оружием)
	["weapon_swcs_c4"] = 5,

	-- Гранаты (слот 4)
	["weapon_swcs_hegrenade"]  = 4,
	["weapon_swcs_flashbang"]  = 4,
	["weapon_swcs_smokegrenade"] = 4,
	["weapon_swcs_molotov"]    = 4,
	["weapon_swcs_incgrenade"] = 4,
	["weapon_swcs_decoy"]      = 4,
}

-- Функция для получения слота оружия
function CS_GetWeaponSlot(class)
	-- Проверяем в таблице слотов
	if CS_WEAPON_SLOTS[class] then
		return CS_WEAPON_SLOTS[class]
	end
	
	-- Ножи CS:GO - слот 3
	for _, knife in ipairs(CS_KNIVES) do
		if class == knife then
			return 3
		end
	end
	
	-- Fallback для неизвестного оружия
	if class:find("pistol") or class:find("glock") or class:find("usp") or class:find("deagle") then
		return 2
	end

	-- Ближний бой — слот 3
	if class == "weapon_crowbar" or class == "weapon_stunstick" or class == "weapon_fists"
	or class:find("knife") or class:find("melee") or class:find("crowbar") then
		return 3
	end

	-- Гранаты — слот 4
	if class:find("grenade") or class:find("molotov") or class:find("incgrenade")
	or class:find("flashbang") or class:find("smoke") or class:find("decoy") then
		return 4
	end

	return 1
end

--[[
	Спавны gm_construct: по 5 точек на команду (как в CS), координаты с getpos + сдвиг ~64 юнита.
	База: CT — твоя точка; T — твоя точка. Подстройте при смене версии карты.
]]
local function V(x, y, z) return Vector(x, y, z) end
local function A(p, y, r) return Angle(p, y, r) end

TEAM_SPAWNS = TEAM_SPAWNS or {}

TEAM_SPAWNS["gm_construct"] = {
	-- T: база getpos -2142.04 -1284.02 -335.97, setang 2.23 -91.06 0
	[TEAM_T] = {
		{ pos = V(-2142.04, -1284.02, -335.97), ang = A(2.23, -91.06, 0) },
		{ pos = V(-2078.04, -1284.02, -335.97), ang = A(2.23, -91.06, 0) },
		{ pos = V(-2206.04, -1284.02, -335.97), ang = A(2.23, -91.06, 0) },
		{ pos = V(-2142.04, -1220.02, -335.97), ang = A(2.23, -91.06, 0) },
		{ pos = V(-2142.04, -1348.02, -335.97), ang = A(2.23, -91.06, 0) },
	},
	-- CT: база getpos 1591.54 60.53 -79.97, setang 1.00 -178.67 0
	[TEAM_CT] = {
		{ pos = V(1591.54, 60.53, -79.97), ang = A(1.00, -178.67, 0) },
		{ pos = V(1655.54, 60.53, -79.97), ang = A(1.00, -178.67, 0) },
		{ pos = V(1527.54, 60.53, -79.97), ang = A(1.00, -178.67, 0) },
		{ pos = V(1591.54, 124.53, -79.97), ang = A(1.00, -178.67, 0) },
		{ pos = V(1591.54, -3.47, -79.97), ang = A(1.00, -178.67, 0) },
	},
}

-- То же для опечатки в названии карты
TEAM_SPAWNS["gm_constract"] = TEAM_SPAWNS["gm_construct"]

TEAM_SPAWNS["de_dust2"] = {
	[TEAM_T] = {
		{ pos = V(-750.848328,  -852.666382, 195.714020), ang = A(7.558427,  25.131680,   0.000002) },
		{ pos = V(-1374.221436, -809.031433, 193.040985), ang = A(5.470630,   4.624897,   0.005000) },
		{ pos = V(-1111.560303, -831.885986, 197.655045), ang = A(5.070215, 124.316475,   0.000000) },
		{ pos = V(-599.509460,  -733.635620, 200.434387), ang = A(13.364207,  28.763773,  0.000170) },
		{ pos = V(-336.594971,  -846.380188, 155.238342), ang = A(7.472594,   83.647232,  0.000014) },
	},
	[TEAM_CT] = {
		{ pos = V(157.888733,  2321.234619, -62.127518), ang = A(4.984448,  -139.661499, -0.000070) },
		{ pos = V(433.718018,  2413.549561, -55.931313), ang = A(4.097848,   -67.646675, -0.000073) },
		{ pos = V(327.802582,  2489.814209, -46.579277), ang = A(8.473646,   -62.269913, -0.000000) },
		{ pos = V(306.610352,  2334.187012, -62.916023), ang = A(10.561443, -101.594925, -0.000000) },
		{ pos = V(129.394501,  2484.015137, -51.220261), ang = A(10.189643,  -52.374645,  0.002690) },
	},
}

function CS_GetSpawnTableForMap()
	local m = game.GetMap()
	if TEAM_SPAWNS[m] then return TEAM_SPAWNS[m] end
	return nil
end

-- Fallback: разделить info_player_* по координате X
function CS_GetFallbackSpawnPoints(teamId)
	local entsList = {}
	for _, c in ipairs({ "info_player_start", "info_player_deathmatch", "info_player_counterterrorist", "info_player_terrorist" }) do
		for _, e in ipairs(ents.FindByClass(c)) do
			table.insert(entsList, e)
		end
	end
	if #entsList == 0 then return nil end
	table.sort(entsList, function(a, b) return a:GetPos().x < b:GetPos().x end)
	local mid = math.ceil(#entsList / 2)
	local bucket = teamId == TEAM_T and 1 or 2
	local out = {}
	if bucket == 1 then
		for i = 1, mid do
			local e = entsList[i]
			table.insert(out, { pos = e:GetPos(), ang = e:GetAngles() })
		end
	else
		for i = mid + 1, #entsList do
			local e = entsList[i]
			table.insert(out, { pos = e:GetPos(), ang = e:GetAngles() })
		end
	end
	if #out == 0 then
		local e = entsList[1]
		return { { pos = e:GetPos() + Vector((teamId == TEAM_CT and 64 or -64), 0, 0), ang = e:GetAngles() } }
	end
	return out
end

-- Таблица занятых точек спавна на текущий раунд: [teamId] = { [spawnIndex] = true }
CS_UsedSpawns = { [1] = {}, [2] = {} }

-- Сбрасываем занятые точки в начале каждого раунда
if SERVER then
	hook.Add("CSConstruct_FreezeStart", "CS_ResetUsedSpawns", function()
		CS_UsedSpawns = { [1] = {}, [2] = {} }
	end)
end

-- Возвращает позицию и угол для спавна.
-- Гарантирует уникальную точку: каждый вызов помечает слот как занятый.
function CS_PickTeamSpawn(teamId)
	local tab = CS_GetSpawnTableForMap()
	local spots
	if tab and tab[teamId] and #tab[teamId] > 0 then
		spots = tab[teamId]
	else
		spots = CS_GetFallbackSpawnPoints(teamId)
	end
	if not spots or #spots == 0 then
		return Vector(0, 0, 72), Angle(0, 0, 0)
	end

	-- Собираем свободные индексы
	local used = CS_UsedSpawns[teamId] or {}
	local free = {}
	for i = 1, #spots do
		if not used[i] then
			table.insert(free, i)
		end
	end

	-- Если все точки заняты — сбрасываем и берём из всех
	if #free == 0 then
		CS_UsedSpawns[teamId] = {}
		used = {}
		for i = 1, #spots do free[i] = i end
	end

	-- Случайный свободный слот
	local idx = free[math.random(#free)]
	CS_UsedSpawns[teamId][idx] = true

	local s = spots[idx]
	local jitter = VectorRand() * 6
	jitter.z = 0
	local basePos = s.pos + jitter

	-- Привязываем к земле через hull-трассировку (учитывает дисплейсменты и наклонные поверхности)
	local tr = util.TraceHull({
		start  = basePos + Vector(0, 0, 36),
		endpos = basePos + Vector(0, 0, -128),
		mins   = Vector(-16, -16, 0),
		maxs   = Vector(16, 16, 72),
		mask   = MASK_PLAYERSOLID,
	})
	if tr.Hit then
		basePos = tr.HitPos + Vector(0, 0, 1)
	end

	return basePos, s.ang
end

function CS_IsValidBuyClass(cls)
	return CS_WEAPON_PRICES[cls] ~= nil
end

function CS_PhaseName(phase)
	if phase == PHASE_LOBBY then return "Лобби" end
	if phase == PHASE_WAITING then return "Ожидание" end
	if phase == PHASE_FREEZE then return "Закупка" end
	if phase == PHASE_LIVE then return "Раунд" end
	if phase == PHASE_ROUND_END then return "Конец раунда" end
	return "—"
end

function CS_GetRandomTeamModel(teamId)
	local models = CS_TEAM_MODELS[teamId]
	if not models or #models == 0 then
		return "models/player/group01/male_02.mdl" -- Fallback модель
	end
	return models[math.random(#models)]
end

-- Режимы игры
GAMEMODE_TRAINING = 0
GAMEMODE_DUEL = 1
GAMEMODE_CASUAL = 2
GAMEMODE_COMPETITIVE = 3

CS_GAME_MODES = {
	[GAMEMODE_TRAINING] = {
		name = "Тренировка",
		description = "Режим для одного игрока",
		playersPerTeam = 1,
		allowSolo = true -- Разрешает начать игру с 1 игроком в одной команде
	},
	[GAMEMODE_DUEL] = {
		name = "Дуэль",
		description = "1 против 1",
		playersPerTeam = 1
	},
	[GAMEMODE_CASUAL] = {
		name = "Напарники",
		description = "2 против 2",
		playersPerTeam = 2
	},
	[GAMEMODE_COMPETITIVE] = {
		name = "Соревновательный",
		description = "5 против 5",
		playersPerTeam = 5
	}
}

function CS_GetGameModeName(mode)
	if CS_GAME_MODES[mode] then
		return CS_GAME_MODES[mode].name
	end
	return "Неизвестный режим"
end

function CS_GetGameModePlayersPerTeam(mode)
	if CS_GAME_MODES[mode] then
		return CS_GAME_MODES[mode].playersPerTeam
	end
	return 5 -- По умолчанию 5v5
end

-- Функция для получения красивого имени ножа
function CS_GetKnifeName(knifeClass)
	local name = knifeClass
	-- Убираем префиксы SWCS и стандартные
	name = name:gsub("weapon_swcs_knife_", "")
	name = name:gsub("weapon_swcs_", "")
	name = name:gsub("weapon_knife_", "")
	name = name:gsub("weapon_", "")
	name = name:gsub("csgo_", "")
	-- Подчёркивания в пробелы
	name = name:gsub("_", " ")
	-- Каждое слово с большой буквы
	name = name:gsub("(%a)([%w]*)", function(first, rest)
		return first:upper() .. rest:lower()
	end)
	if name == "" then name = "Knife" end
	return name
end
