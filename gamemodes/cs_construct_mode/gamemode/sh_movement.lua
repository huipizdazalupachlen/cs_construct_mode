--[[
	CS Construct — Система движения в стиле CS:GO
	- Скорость зависит от активного оружия
	- Ходьба (Shift): 135 u/s
	- Антибхоп: задержка между прыжками
	- Ускорение в воздухе ограничено (sv_airaccelerate 12)
]]

-- ============================================================
-- СКОРОСТИ ОРУЖИЙ (units/sec, как в CS:GO)
-- ============================================================

local WEAPON_SPEEDS = {
	-- Пистолеты
	["weapon_swcs_glock"]     = 300,
	["weapon_swcs_usp_silencer"]       = 295,
	["weapon_swcs_hkp2000"]     = 300,
	["weapon_swcs_p250"]      = 300,
	["weapon_swcs_fiveseven"] = 300,
	["weapon_swcs_tec9"]      = 300,
	["weapon_swcs_deagle"]    = 290,
	["weapon_swcs_elite"]     = 300,
	["weapon_swcs_cz75"]      = 300,
	["weapon_swcs_revolver"]  = 275,

	-- ПП
	["weapon_swcs_mac10"]  = 300,
	["weapon_swcs_mp9"]    = 300,
	["weapon_swcs_mp7"]    = 290,
	["weapon_swcs_mp5sd"]    = 295,
	["weapon_swcs_ump45"]    = 290,
	["weapon_swcs_p90"]    = 290,
	["weapon_swcs_bizon"]  = 300,

	-- Дробовики
	["weapon_swcs_nova"]     = 290,
	["weapon_swcs_xm1014"]   = 270,
	["weapon_swcs_mag7"]     = 280,
	["weapon_swcs_sawedoff"] = 290,

	-- Винтовки
	["weapon_swcs_famas"]   = 280,
	["weapon_swcs_galilar"] = 270,
	["weapon_swcs_ak47"]    = 270,
	["weapon_swcs_m4a1"]    = 280,
	["weapon_swcs_m4a1_silencer"]   = 280,
	["weapon_swcs_sg556"]   = 265,
	["weapon_swcs_aug"]     = 275,

	-- Снайперские
	["weapon_swcs_ssg08"]  = 290,
	["weapon_swcs_awp"]    = 255,
	["weapon_swcs_scar20"] = 265,
	["weapon_swcs_g3sg1"]  = 265,

	-- Пулемёты
	["weapon_swcs_negev"] = 200,
	["weapon_swcs_m249"]  = 250,
}

-- Скорость по слоту (fallback для нераспознанного оружия)
local SLOT_SPEEDS = {
	[1] = 275,  -- винтовки/SMG/дробовики
	[2] = 300,  -- пистолеты
	[3] = 310,  -- нож
}

local WALK_SPEED     = 170   -- Shift: тихий шаг
local KNIFE_SPEED    = 310   -- голые руки / нож
local JUMP_COOLDOWN  = 0.45  -- задержка между прыжками (анти-бхоп, CS:GO ~0.5s)

-- ============================================================
-- ВСПОМОГАТЕЛЬНАЯ: скорость из активного оружия
-- ============================================================

local function getWeaponSpeed(ply)
	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return KNIFE_SPEED end

	local cls = wep:GetClass()
	local spd = WEAPON_SPEEDS[cls]
	if spd then return spd end

	-- Если класс не найден — определяем по слоту
	local slot = CS_GetWeaponSlot and CS_GetWeaponSlot(cls) or 3
	return SLOT_SPEEDS[slot] or KNIFE_SPEED
end

-- ============================================================
-- SetupMove: скорость + ходьба + антибхоп
-- ============================================================

function GM:SetupMove(ply, mv, cmd)
	if not ply:IsPlayer() then return end

	-- Движение только для игроков в активных командах
	local team = ply:Team()
	if team ~= TEAM_T and team ~= TEAM_CT then return end

	-- Антибхоп: запрещаем прыжок до истечения кулдауна
	if cmd:KeyDown(IN_JUMP) and ply:IsOnGround() then
		local last = ply.CSMode_LastJump or 0
		if (CurTime() - last) < JUMP_COOLDOWN then
			-- Сбрасываем кнопку прыжка
			cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_JUMP)))
		else
			ply.CSMode_LastJump = CurTime()
		end
	end

	-- Shift = тихий шаг (как в CS:GO), без Shift = обычный бег по оружию
	-- В GMod по умолчанию Shift = спринт. Мы инвертируем: Shift = замедление.
	local maxSpeed = getWeaponSpeed(ply)

	if cmd:KeyDown(IN_SPEED) then
		-- Shift зажат — тихий шаг
		maxSpeed = WALK_SPEED
	end

	mv:SetMaxClientSpeed(maxSpeed)
	mv:SetMaxSpeed(maxSpeed)
end

-- ============================================================
-- Сервер: установка физических конваров CS:GO
-- ============================================================

local JUMP_POWER = 220  -- немного выше дефолтного GMod (200), ниже CS:GO (268)

if SERVER then
	timer.Simple(1, function()
		RunConsoleCommand("sv_airaccelerate", "12")
		RunConsoleCommand("sv_accelerate",    "5.5")
		RunConsoleCommand("sv_friction",      "5.2")
		RunConsoleCommand("sv_maxspeed",      "320")
		RunConsoleCommand("sv_stopspeed",     "80")
	end)

	-- Тихая ходьба (Shift): глушим шаги как в CS:GO
	hook.Add("PlayerFootstep", "CSMode_SilentWalk", function(ply)
		if ply:KeyDown(IN_SPEED) then
			return true  -- подавляем звук шага
		end
	end)

	hook.Add("PlayerSpawn", "CSMode_MovementInit", function(ply)
		ply.CSMode_LastJump = 0
		-- Убираем стандартный спринт GMod: ставим RunSpeed = WalkSpeed
		-- Shift обрабатывается в SetupMove как замедление
		local defaultSpeed = 300
		ply:SetWalkSpeed(defaultSpeed)
		ply:SetRunSpeed(defaultSpeed)
		ply:SetMaxSpeed(defaultSpeed)
		ply:SetJumpPower(JUMP_POWER)
		-- Высота камеры как в CS:GO (фикс "crotch camera" при приседе)
		ply:SetViewOffset(Vector(0, 0, 64))
		ply:SetViewOffsetDucked(Vector(0, 0, 46))
	end)
end
