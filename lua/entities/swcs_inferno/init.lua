include("shared.lua")

ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

local InfernoDebug = GetConVar("inferno_debug")

-- Fire burning things and smoke constants
local InfernoFire_HalfWidth = 30.0
local InfernoFire_FullHeight = 80.0

local TAG = "swcs_inferno"

ENT.m_NetworkTimer = swcs.CountdownTimer()
-- called every :Think() while the inferno is burning
function ENT:NetworkAllFire(tbl)
	tbl = tbl or self:GetTable()

	if not tbl.m_NetworkFilter then
		tbl.m_NetworkFilter = RecipientFilter()
	end

	if not tbl.m_NetworkTimer:IsElapsed() then return end

	tbl.m_NetworkTimer:Start(0.25)

	-- populate filter
	local PlayersList = tbl.m_NetworkFilter:GetPlayers()

	tbl.m_NetworkFilter:AddPVS(self:GetPos())

	local NewPlayersList = tbl.m_NetworkFilter:GetPlayers()

	local Players, NewPlayers = {}, {}

	for i = 1, #PlayersList do
		Players[PlayersList[i]] = true
	end

	for i = 1, #NewPlayersList do
		-- player was not already in PVS, add to NewPlayers list
		if not Players[NewPlayersList[i]] then
			table.insert(NewPlayers, NewPlayersList[i])
		end
	end

	if #NewPlayers == 0 then return end

	-- send full update to new players in PVS
	net.Start(TAG, false)
	net.WriteEntity(self)
	net.WriteBool(true) -- this is a full update

	net.WriteUInt(self:GetFireCount(), 6) -- expected amount

	for i = 0, self:GetFireCount() - 1 do
		local fire = tbl.m_fire[i]

		net.WriteBool(fire and true or false)
		if not fire then continue end

		net.WriteFloat(tbl.m_fireXDelta[i])
		net.WriteFloat(tbl.m_fireYDelta[i])
		net.WriteFloat(tbl.m_fireZDelta[i])
		net.WriteBool(tbl.m_bFireIsBurning[i])
		net.WriteNormal(tbl.m_BurnNormal[i])
	end
	net.Send(NewPlayers)
end

function ENT:Think()
	local bExpiryCheckPerformed = false

	local tbl = self:GetTable()

	--local starttime = SysTime()
	self:NetworkAllFire(tbl)
	--print(Format("NetworkAllFire %.4fms", (SysTime() - starttime) * 1000))

	-- Run bookkeeping every 0.1s
	if tbl.m_BookkeepingTimer:Interval(0.1) then
		--local starttime = SysTime()
		bExpiryCheckPerformed = true
		if self:CheckExpired() then return end

		-- the fire grows...
		--local _starttime = SysTime()
		if self:GetFireCount() > 0 and self:GetFireCount() < math.min(self:GetMaxFlames(), MAX_INFERNO_FIRES) then
			self:Spread(tbl.m_splashVelocity)
		end
		--print(Format("Growth %.4fms", (SysTime() - _starttime) * 1000))

		-- Mark covered nav areas as damaging
		self:MarkCoveredAreaAsDamaging()
		--print(Format("Bookkeeping %.4fms", (SysTime() - starttime) * 1000))
	end

	-- Debug draw flame region
	if InfernoDebug:GetBool() then
		debugoverlay.Box(vector_origin, tbl.m_extent.lo, tbl.m_extent.hi, 0.1, Color(255, 255, 255, 10))
	end

	-- Deal damage every 0.2s
	local kDamageTimerSeconds = 0.2
	--local starttime = SysTime()

	local class = self:GetClass()
	local owner = self:GetOwner()

	while tbl.m_damageTimer:RunEvery(kDamageTimerSeconds) do
		-- Note that we run a lot of code in this RunEvery(), but we expect the loop to run 0 or 1 times
		-- in almost every case, unless this think function somehow got super delayed by the server

		if not bExpiryCheckPerformed then
			bExpiryCheckPerformed = true
			if self:CheckExpired() then return end
		end

		local center = (tbl.m_extent.lo + tbl.m_extent.hi) / 2
		local flExtents = tbl.m_extent.lo:Distance(tbl.m_extent.hi) * 0.8
		sound.EmitHint(SOUND_DANGER, center, flExtents, 0.2)

		local damageCount = 0
		local damageList = {}
		local flameRadius = 2.0 * InfernoFire_HalfWidth

		local list = ents.FindInBox(tbl.m_extent.lo, tbl.m_extent.hi)
		for i = 1, #list do
			local ent = list[i]
			if ent:GetClass() == class or not ent:IsValid() or not ent:SWCS_Alive() then continue end

			if self:IsTouchingEntity(ent, flameRadius, ent:IsPlayer()) then
				damageCount = damageCount + 1
				damageList[damageCount] = ent
			end
		end

		if damageCount == 0 then continue end

		-- Note that we expect molotov this value to be an integer (currently it is 40 * 0.2 == 8 damage per tick)
		-- If molotov DPS changes, we may need to also adjust how often damage is applied.
		--
		-- We could also change this to tick at the exact rate required to deal 1 damage (tick rate = 1 / GetDamagePerSecond())
		-- at which point we might want to consider optimizing this loop to run a single time and multiply its damage
		-- by the damage dealt, so that (for example) if molotovs deal 80 dps on a 64 tick server, we only find the targets
		-- once during the ticks when the molotov deals 2 damage.
		local baseDamage = self:GetDamagePerSecond() * kDamageTimerSeconds -- dmg / sec * sec / tick = dmg / tick

		if not tbl.m_damageRampTimer:IsElapsed() then
			baseDamage = baseDamage * tbl.m_damageRampTimer:GetElapsedRatio()
		end

		local info = DamageInfo()
		info:SetInflictor(self)
		info:SetAttacker(owner:IsValid() and owner or self)
		info:SetDamage(baseDamage)
		info:SetDamageType(self:GetDamageType())
		info:SetDamageForce(vector_origin)

		for i = 1, damageCount do
			local ent = damageList[i]
			if self:CanHarm(ent) then
				info:SetDamagePosition(ent:GetPos())

				local bAlreadySet = false
				if ent:IsEFlagSet(EFL_NO_DAMAGE_FORCES) then
					bAlreadySet = true
				else
					ent:AddEFlags(EFL_NO_DAMAGE_FORCES)
				end

				if ent:IsPlayer() then
					ent:SetLastHitGroup(HITGROUP_GENERIC)
				end
				ent:TakeDamageInfo(info)

				if not bAlreadySet then
					ent:RemoveEFlags(EFL_NO_DAMAGE_FORCES)
				end
			end
		end
	end
	--print(Format("DamageTimer %.4fms", (SysTime() - starttime) * 1000))

	self:NextThink(math.min(tbl.m_BookkeepingTimer:GetTargetTime(), tbl.m_damageTimer:GetTargetTime()))
	return true
end

-- Return true if given area overlaps any fires
function ENT:IsTouchingArea(area)
	if area:IsValid() then
		local radius = 2 * InfernoFire_HalfWidth

		for i = 0, self:GetFireCount() - 1 do
			local fire = self.m_fire[i]

			-- This flame has been extinguished or elapsed, shouldn't be considered touching
			if not fire.m_burning or fire.m_lifetime:IsElapsed() then continue end

			local close = area:GetClosestPointOnArea(fire.m_center)

			close.z = close.z + fire.m_flWaterHeight -- If the inferno was raised above the water, check the nav as if it was in the original pos

			if close:DistToSqr(fire.m_center) < radius * radius then
				return true
			end
		end
	end

	return false
end

local bDisableNavArea
local DangerBloat = 32.0

-- mark overlapping nav areas as "damaging"
function ENT:MarkCoveredAreaAsDamaging()
	if bDisableNavArea then return end

	-- bloat extents enough to ensure any non-damaging area is actually safe
	-- bloat in Z as well to catch nav areas that may be slightly above/below ground
	local low = Vector(self.m_extent.lo)
	local high = Vector(self.m_extent.hi)

	local pos = self:GetPos()

	local dangerBloat = Vector(DangerBloat, DangerBloat, DangerBloat)
	low:Sub(dangerBloat)
	high:Add(dangerBloat)

	local mins = low - pos
	local maxs = high - pos

	--debugoverlay.Box(pos, mins, maxs, 0.1, Color(255,255,255,10))

	local areas
	if navmesh.FindInBox then
		areas = navmesh.FindInBox(mins, maxs)
	else
		local bounds = maxs - mins
		areas = navmesh.Find(self:GetPos(), bounds:Length(), DangerBloat, DangerBloat)
	end

	for _, area in ipairs(areas) do
		if not area.MarkAsDamaging then break end
		if self:IsTouchingArea(area) then
			area:MarkAsDamaging(1.0)
		end
	end
end
