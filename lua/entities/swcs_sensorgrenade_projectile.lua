AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = math.huge
ENT.PrintName = "Tactical Awareness Grenade"

DEFINE_BASECLASS(ENT.Base)

local TAG = "swcs_sensorgrenade_projectile"

local GRENADE_MODEL = "models/weapons/csgo/w_eq_sensorgrenade_thrown.mdl"

local THINK_ARM = 1
local THINK_SENSOR = 2
local THINK_REMOVE = 3

ENT.ThinkFuncs = {
	[THINK_ARM] = function(self)
		if self:GetFinalVelocity():Length() > 0.2 then
			self:NextThink(CurTime() + 0.2)
			return true
		end

		self:SetExpireTime(CurTime() + 2.0)
		self:SetThinkFuncIndex(THINK_SENSOR)
		self:CallThinkFunc(THINK_SENSOR)
		return true
	end,
	[THINK_SENSOR] = function(self)
		local pThrower = self:GetThrower()
		if not pThrower:IsValid() then
			return
		end

		if SERVER and CurTime() > self:GetNextDetectPlayerSound() then
			self:EmitSound("Sensor.WarmupBeep")
			self:SetNextDetectPlayerSound(CurTime() + 1.0)
		end

		if CurTime() < self:GetExpireTime() then
			self:NextThink(CurTime() + 0.1)
			return true
		else
			if SERVER or (CLIENT and IsFirstTimePredicted()) then
				self:EmitSound("Sensor.Detonate")
				ParticleEffectAttach("weapon_sensorgren_detonate", PATTACH_POINT_FOLLOW, self, self:LookupAttachment("Wick"))
			end

			self:DoDetectWave()
		end

		return true
	end,
	[THINK_REMOVE] = function(self)
		--if SERVER then self:Remove() end
		return true
	end,
}

local flMaxTraceDist = 1600
function ENT:DoDetectWave()
	if not SERVER then return end

	-- tell the bots about the gunfire
	local hThrower = self:GetThrower()
	if not IsValid(hThrower) then
		return
	end

	local tTargettedEntities = {}
	for _, ent in ipairs(ents.FindInSphere(self:GetPos(), flMaxTraceDist)) do
		local bIsPlayer = ent:IsPlayer()
		if not (bIsPlayer or ent:IsNPC() or ent:IsNextBot()) then continue end
		if bIsPlayer and (ent:GetObserverMode() ~= OBS_MODE_NONE) then continue end
		if ent == hThrower then continue end

		-- you hate me </3
		if ent:IsNPC() and ent:Disposition(hThrower) == D_LI then continue end

		local flDistance = ent:EyePos():Distance(self:GetPos())
		if swcs.IsLineBlockedBySmoke(ent:EyePos(), self:GetPos(), 1) then
			-- if we are outside half the max dist and don't trace, dont show
			if flDistance > flMaxTraceDist / 2 then
				continue
			end
		end

		local tr = util.TraceLine({
			start = ent:EyePos(),
			endpos = self:GetPos(),
			mask = MASK_VISIBLE,
			filter = ent,
			collisiongroup = COLLISION_GROUP_DEBRIS,
		})

		if tr.Hit then
			local tr2 = util.TraceLine({
				start = ent:GetPos() + Vector(0, 0, 16),
				endpos = self:GetPos(),
				mask = MASK_VISIBLE,
				filter = ent,
				collisiongroup = COLLISION_GROUP_DEBRIS,
			})

			if tr2.Hit then
				-- if we are outside half the max dist and don't trace, dont show
				if flDistance > flMaxTraceDist / 2 then
					continue
				end
			end
		end

		table.insert(tTargettedEntities, ent)
	end

	if SERVER then
		hook.Run("SWCSSensorGrenadeDetonate", self, tTargettedEntities)
	end

	self:SetThinkFuncIndex(THINK_REMOVE)
	if SERVER then SafeRemoveEntityDelayed(self, 0.25) end
end

if SERVER then
	hook.Add("SWCSSensorGrenadeDetonate", "swcs.tanade", function(grenade, tTargets)
		if not grenade:GetThrower():IsValid() then return end

		net.Start(TAG)
		net.WriteUInt(math.min(#tTargets, 255), 8)
		net.WriteVector(grenade:GetPos())

		for i = 1, math.min(#tTargets, 255) do
			local ent = tTargets[i]
			net.WriteEntity(ent)

			if ent:IsPlayer() then
				--ent:SetIsSpotted(true)
				--ent:SetIsSpottedBy(grenade:GetThrower())
				--ent.m_flDetectedByEnemySensorTime = CurTime()
				ent:SWCS_Blind(0.2, 1.0, 128)
				ent:EmitSound("Sensor.WarmupBeep")
			end
		end

		net.Send(grenade:GetThrower())
	end)
else
	local DebugLines = {}
	local function DebugDrawLine(vecAbsStart, vecAbsEnd, r, g, b, ignorez, duration)
		table.insert(DebugLines, {
			vecAbsStart = vecAbsStart,
			vecAbsEnd = vecAbsEnd,
			r = r,
			g = g,
			b = b,
			ignorez = ignorez,
			endtime = CurTime() + duration,
		})
	end

	local tWallhackedEnts = {}
	net.Receive(TAG, function()
		local count = net.ReadUInt(8)
		local pos = net.ReadVector()

		local curtime = CurTime()

		local newEntries = {}

		for i = 1, count do
			local ent = net.ReadEntity()
			if not ent:IsValid() then continue end

			table.insert(newEntries, {
				ent = ent,
				time = curtime + 5,
			})
		end

		for i = 1, #newEntries do
			local v = newEntries[i]
			local ent = v.ent

			if not ent:IsValid() or
				v.time < curtime or
				(ent:IsPlayer() and not ent:Alive()) or
				(ent:IsNPC() and ent:Health() <= 0)
			then
				continue
			end

			DebugDrawLine(pos, ent:WorldSpaceCenter(), 90, 0, 0, true, 1.5)

			table.insert(tWallhackedEnts, v)
		end
	end)

	hook.Add("PostDrawTranslucentRenderables", "swcs.tanade", function(depth, sky, sky3d)
		if sky then return end

		local curtime = CurTime()
		for _, v in ipairs(DebugLines) do
			if v.endtime < curtime then continue end

			render.DrawLine(v.vecAbsStart, v.vecAbsEnd, Color(v.r, v.g, v.b, 255), not v.ignorez)
		end
	end)

	hook.Add("PreDrawHalos", "swcs.tanade", function()
		if #tWallhackedEnts == 0 then return end

		local t = {}
		local curtime = CurTime()

		local i = 1
		local wep = NULL
		repeat
			local v = tWallhackedEnts[i]
			local ent = v.ent
			if not ent:IsValid() or v.time < curtime or (ent:IsPlayer() and not ent:Alive()) or (ent:IsNPC() and ent:Health() <= 0) then
				table.remove(tWallhackedEnts, i)
				continue
			end

			table.insert(t, ent)

			-- also highlight their weapon
			wep = ent.GetActiveWeapon and ent:GetActiveWeapon() or NULL
			if wep:IsValid() then
				table.insert(t, wep)
			end
			i = i + 1
		until i > #tWallhackedEnts

		if #t > 0 then
			halo.Add(t, Color(255, 0, 0, 255), 1, 1, 1, true, true)
		end
	end)

	local swcs_health_glow = CreateClientConVar("swcs_health_glow", "1", true, false, "Enable health glow effect on players")

	local MATERIAL_HEALTH = CreateMaterial("glow_health_color", "UnlitGeneric", {
		["$color"] = "[220 0 0]",
	})

	hook.Add("RenderScreenspaceEffects", "swcs.tanade", function()
		if not swcs_health_glow:GetBool() then return end

		local localPlayer = LocalPlayer()

		for _, t in ipairs(tWallhackedEnts) do
			local ply = t.ent
			if not IsValid(ply) or ply == localPlayer then continue end
			if (ply:IsPlayer() and not ply:Alive()) or (ply:IsNPC() and ply:Health() <= 0) then continue end

			local health = ply:Health()

			local plyTable = ply:GetTable()
			plyTable.m_flHealthFadeAlpha = plyTable.m_flHealthFadeAlpha or health

			if plyTable.m_flHealthFadeAlpha > 0 then
				plyTable.m_flHealthFadeAlpha = plyTable.m_flHealthFadeAlpha - (FrameTime() * 0.4)
			end

			if plyTable.m_flHealthFadeValue and plyTable.m_flHealthFadeValue ~= health then
				plyTable.m_flHealthFadeAlpha = 1
			end

			plyTable.m_flHealthFadeValue = health

			-- only need to update the effect if we can see it
			if plyTable.m_flHealthFadeAlpha <= 0 then continue end

			local flGlowPulseSpeed = Lerp(plyTable.m_flHealthFadeValue / 100, 30, 10)

			local alpha = plyTable.m_flHealthFadeAlpha * (0.4 * (math.sin(flGlowPulseSpeed * CurTime()) + 1.4))

			local pos = ply:GetPos()

			render.SetStencilWriteMask(0xFF)
			render.SetStencilTestMask(0xFF)
			render.SetStencilReferenceValue(0)
			render.SetStencilPassOperation(STENCIL_KEEP)
			render.SetStencilZFailOperation(STENCIL_KEEP)
			render.ClearStencil()

			render.SetStencilEnable(true)
			render.SetStencilReferenceValue(1)
			render.SetStencilCompareFunction(STENCIL_NEVER)
			render.SetStencilFailOperation(STENCIL_REPLACE)

			local vPlayerScreenPos = pos:ToScreen()
			if vPlayerScreenPos.visible then
				vPlayerScreenPos = Vector(vPlayerScreenPos.x, vPlayerScreenPos.y)

				local flHealthLeft = (100 - plyTable.m_flHealthFadeValue) / 100
				local flHealthHeightOffset = 72

				if ply:IsPlayer() and ply:Crouching() then
					flHealthHeightOffset = 55
				end

				local vPlayerScreenHealthPos = (pos + Vector(0, 0, flHealthLeft * flHealthHeightOffset)):ToScreen()
				if vPlayerScreenHealthPos.visible then
					vPlayerScreenHealthPos = Vector(vPlayerScreenHealthPos.x, vPlayerScreenHealthPos.y)

					local vPlayerScreenSpaceSizeA = (pos + Vector(0, 0, 100)):ToScreen()
					vPlayerScreenSpaceSizeA = Vector(vPlayerScreenSpaceSizeA.x, vPlayerScreenSpaceSizeA.y)

					local flPlayerScreenCoverage = vPlayerScreenPos:Distance(vPlayerScreenSpaceSizeA)

					if flPlayerScreenCoverage < ScrH() * 2 then
						local flHealthWidth, flHealthHeight = flPlayerScreenCoverage, flPlayerScreenCoverage - 0
						local flHealthPosX, flHealthPosY = vPlayerScreenHealthPos.x - (flPlayerScreenCoverage * 0.5), vPlayerScreenHealthPos.y

						render.SetColorMaterial()
						render.DrawScreenQuadEx(flHealthPosX, flHealthPosY - flHealthHeight, flHealthWidth, flHealthHeight)
					end
				end
			end

			render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
			render.SetStencilFailOperation(STENCIL_KEEP)

			cam.Start3D()
			render.SetBlend(alpha)
			render.ModelMaterialOverride(MATERIAL_HEALTH)
			render.SetColorModulation(220 / 255, 0, 0)

			ply:DrawModel()
			cam.End3D()

			render.SetColorModulation(1, 1, 1)
			---@diagnostic disable-next-line: missing-parameter
			render.ModelMaterialOverride()

			render.SetStencilEnable(false)
		end
	end)
end

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Int", 3, "ThinkFuncIndex")
	self:NetworkVar("Float", 1, "ExpireTime")
	self:NetworkVar("Float", 2, "NextDetectPlayerSound")
end

function ENT:Create(pos, angs, vel, angvel, owner)
	self:SetPos(pos)
	self:SetAngles(angs)

	self:SetVelocity(vel)
	self:SetInitialVelocity(vel)

	if IsValid(owner) then
		self:SetThrower(owner)
		self:SetOwner(owner)
	end

	self:SetTimer(2.0)
	self:SetTimeToDetonate(CurTime() + 9999)

	self:SetLocalAngularVelocity(angvel)
	self:SetFinalAngularVelocity(angvel)
	self:SetActualCollisionGroup(COLLISION_GROUP_PROJECTILE)

	return self
end

function ENT:SetTimer(flTimer)
	self:SetThinkFuncIndex(THINK_ARM)

	self:NextThink(CurTime() + flTimer)
	self:SetNextDetectPlayerSound(CurTime())
end

function ENT:CleanupStickyProjectiles(parent, bRemoveSelf)
	parent = parent or self:GetParent()

	if parent:IsValid() then
		local children = parent.swcs_StickyProjectiles
		if not istable(children) or table.Count(children) == 0 then return end

		local child, prevchild = nil, nil
		child = next(children)
		while child ~= nil do
			if (bRemoveSelf and child == self) or not child:IsValid() then
				children[child] = nil
			else
				prevchild = child
			end

			child = next(children, prevchild)
		end
	end
end

function ENT:OnLostParent(parent)
	self:CleanupStickyProjectiles(parent, true)
end

function ENT:Initialize()
	self:SetModel(GRENADE_MODEL)

	BaseClass.Initialize(self)

	if SERVER then
		self:CallOnRemove("swcs_sensorgrenade", function(ent)
			ent:CleanupStickyProjectiles(nil, true)
		end)
	end

	self:SetDetonateTimerLength(self.m_flTimeToDetonate)
end

function ENT:Detonate()
	assert(false, "SensorGrenade grenade handles its own detonation")
end

function ENT:BounceSound()
	self:EmitSound("Flashbang.Bounce")
end

---@param tr TraceResult
---@param other Entity
function ENT:OnBounced(tr, other)
	if bit.band(other:GetSolidFlags(), bit.bor(FSOLID_TRIGGER, FSOLID_VOLUME_CONTENTS)) ~= 0 then
		return
	end

	if bit.band(tr.SurfaceFlags, SURF_SKY) ~= 0 then
		return
	end

	local children = other.swcs_StickyProjectiles
	if istable(children) and table.Count(children) >= 10 then
		return
	end

	-- don't hit the guy that launched this grenade
	if other == self:GetThrower() then
		return
	end

	if other:GetClass() == "func_breakable" then
		return
	end

	if other:GetClass() == "func_breakable_surf" then
		return
	end

	-- don't detonate on ladders
	if other:GetClass() == "func_ladder" then
		return
	end

	if other:IsNPC() or other:IsPlayer() or other:IsNextBot() then
		-- don't break if we hit an actor - wait until we hit the environment
		return
	else
		local iBoneIndex
		if tr.PhysicsBone then
			iBoneIndex = other:TranslatePhysBoneToBone(tr.PhysicsBone)
		end

		if iBoneIndex and iBoneIndex ~= -1 then
			local boneMatrix = other:GetBoneMatrix(iBoneIndex)
			local bonePos = boneMatrix:GetTranslation()
			local boneAngles = boneMatrix:GetAngles()

			local localPos = WorldToLocal(tr.HitPos, Angle(), bonePos, boneAngles)

			self:FollowBone(other, iBoneIndex)
			self:SetLocalPos(localPos)
			self:SetLocalAngles(Angle())
		elseif other:IsValid() then
			self:SetParent(other)

			local pos = other:WorldToLocal(tr.HitPos)
			self:SetLocalPos(pos)
		end

		if not other:IsWorld() then
			if not other.swcs_StickyProjectiles then
				other.swcs_StickyProjectiles = setmetatable({}, {__mode = "k"})

				other:CallOnRemove("swcs.sticky_proj", function(ent)
					if not istable(children) or #children == 0 then return end

					for _, child in next, children do
						if child:IsValid() then
							child:SetParent(NULL)

							local pos = child:GetPos()
							child:SetPos(pos)
							child:Set_Pos(pos)
						end
					end
				end)
			end

			other.swcs_StickyProjectiles[self] = true
		end

		self:Set_Pos(tr.HitPos)

		self:SetVelocity(vector_origin)
		self:SetLocalVelocity(vector_origin)
		self:SetAbsVelocity(vector_origin)
		self:SetFinalVelocity(vector_origin)
		self:NextThink(CurTime() + 1.0)
		self:SetThinkFuncIndex(THINK_ARM)
		self:SetNWMoveType(MOVETYPE_NONE)
		self:SetMoveType(MOVETYPE_NONE)

		if SERVER then
			self:EmitSound("Sensor.Activate")
		end

		self:SetExpireTime(CurTime() + 15)

		-- stick the grenade onto the target surface using the closest rotational alignment to match the in-flight orientation,
		-- ( like breach charges )

		local vecSurfNormal = tr.HitNormal
		local vecProjectileX = self:GetAngles():Forward()
		local vecProjectileZ = self:GetAngles():Up()

		-- sensor grenades can stick on either of two sides, unlike the breach charges. So they don't need to flip when they land on their 'backs'.
		if vecSurfNormal:Dot(-vecProjectileZ) < 0 then
			vecSurfNormal:Mul(-1)
		end

		local vecProjRight = vecProjectileX:Cross(vecSurfNormal)
		local vecProjForward = vecProjRight:Cross(-vecSurfNormal)
		local angSurface = vecProjForward:AngleEx(-vecSurfNormal)

		self:SetAngles(angSurface)
		self:SetLocalAngularVelocity(Angle())
		self:SetFinalAngularVelocity(Angle())
	end
end

function ENT:AdditionalThink(selfTable)
	selfTable = selfTable or self:GetTable()
	return selfTable.CallThinkFunc(self, selfTable.GetThinkFuncIndex(self))
end

function ENT:CallThinkFunc(iThinkFunc)
	if iThinkFunc ~= 0 then
		local fnThink = self.ThinkFuncs[iThinkFunc]
		if isfunction(fnThink) then
			return fnThink(self)
		end
	end
end
