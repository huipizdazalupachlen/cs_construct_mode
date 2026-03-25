include("shared.lua")

local TAG = "swcs_inferno"

local InfernoDebug = GetConVar("inferno_debug")
local InfernoDlightSpacing = CreateClientConVar("inferno_dlight_spacing", "200", nil, nil, "Inferno dlights are at least this far apart")
local InfernoDlights = CreateClientConVar("inferno_dlights", "30", nil, nil, "Min FPS at which molotov dlights will be created")
local InfernoFire = CreateClientConVar("inferno_fire", "2")

net.Receive(TAG, function()
	local ent = net.ReadEntity()

	-- not valid somehow?
	if not ent:IsValid() then return end

	-- localize to reduce ENT.__index calls
	local entTable = ent:GetTable()

	-- what the fuck?
	local fireXDelta = entTable.m_fireXDelta
	if not fireXDelta then return end

	local fireYDelta = entTable.m_fireYDelta
	local fireZDelta = entTable.m_fireZDelta
	local fireIsBurning = entTable.m_bFireIsBurning
	local fireNormal = entTable.m_BurnNormal

	local bFullUpdate = net.ReadBool()

	if bFullUpdate then
		local iFireCount = net.ReadUInt(6)

		for i = 0, iFireCount - 1 do
			local ok = net.ReadBool()
			if not ok then continue end

			fireXDelta[i] = net.ReadFloat()
			fireYDelta[i] = net.ReadFloat()
			fireZDelta[i] = net.ReadFloat()
			fireIsBurning[i] = net.ReadBool()
			fireNormal[i] = net.ReadNormal()
		end
	else
		local iFire = net.ReadUInt(6)

		fireXDelta[iFire] = net.ReadFloat()
		fireYDelta[iFire] = net.ReadFloat()
		fireZDelta[iFire] = net.ReadFloat()
		fireIsBurning[iFire] = net.ReadBool()
		fireNormal[iFire] = net.ReadNormal()
	end
end)

ENT.m_drawable = {}
ENT.m_drawableCount = 0
ENT.m_lastFireCount = 0

local OLD_FIRE_MASK = 1
local NEW_FIRE_MASK = 2

local FIRE_STATE_STARTING = 0
local FIRE_STATE_BURNING = 1
local FIRE_STATE_GOING_OUT = 2
local FIRE_STATE_FIRE_OUT = 3
local FIRE_STATE_UNKNOWN = 4

AccessorFunc(ENT, "m_lastFireCount", "LastFireCount", FORCE_NUMBER)
AccessorFunc(ENT, "m_drawableCount", "DrawableCount", FORCE_NUMBER)

-- Monitor changes and recompute render bounds
function ENT:Think()
	local bIsAttachedToMovingObject = self:GetMoveParent():IsValid()
	local selfTable = self:GetTable()

	if selfTable.GetLastFireCount(self) ~= selfTable.GetFireCount(self) or bIsAttachedToMovingObject then
		selfTable.SynchronizeDrawables(self, selfTable)
		selfTable.SetLastFireCount(self, selfTable.GetFireCount(self))
	end

	local bDidRecomputeBounds = false

	-- update Drawables
	for i = 0, selfTable.GetDrawableCount(self) - 1 do
		local draw = selfTable.m_drawable[i]
		if not draw then continue end

		if draw.m_state == FIRE_STATE_STARTING then
			local growRate = draw.m_maxSize / 2
			draw.m_size = growRate * (RealTime() - draw.m_stateTimestamp)

			if draw.m_size > draw.m_maxSize then
				draw.m_size = draw.m_maxSize
				draw:SetState(FIRE_STATE_BURNING)
			end
		elseif draw.m_state == FIRE_STATE_GOING_OUT then
			local dieRate = draw.m_maxSize / 2
			draw.m_size = draw.m_maxSize - dieRate * (RealTime() - draw.m_stateTimestamp)

			if draw.m_size <= 0 then
				draw:SetState(FIRE_STATE_FIRE_OUT)

				selfTable.RecomputeBounds(self)
				bDidRecomputeBounds = true
			end
		end
	end

	if bIsAttachedToMovingObject and not bDidRecomputeBounds then
		selfTable.RecomputeBounds(self)
	end

	selfTable.UpdateParticles(self, selfTable)

	return true
end

function ENT:SynchronizeDrawables(selfTable)
	local drawables = selfTable.m_drawable
	-- mark all fires as "burning" as "unknown" - active ones will be reset
	for i = 0, selfTable.GetDrawableCount(self) - 1 do
		local fire = drawables[i]
		if not fire then continue end

		if fire.m_state == FIRE_STATE_BURNING then
			fire.m_state = FIRE_STATE_UNKNOWN
		end
	end

	local vInfernoOrigin = self:GetPos()

	for i = 0, selfTable.GetFireCount(self) - 1 do
		local firePos = Vector(vInfernoOrigin)

		local vecFlamePos = Vector(selfTable.m_fireXDelta[i], selfTable.m_fireYDelta[i], selfTable.m_fireZDelta[i])

		firePos:Add(vecFlamePos)

		local fireNormal = selfTable.m_BurnNormal[i]
		local info = selfTable.GetDrawable(self, firePos)

		if selfTable.m_bFireIsBurning[i] == false then
			if info and info.m_state ~= FIRE_STATE_FIRE_OUT then
				info.m_state = FIRE_STATE_FIRE_OUT

				-- render bounds changed
				selfTable.RecomputeBounds(self)
			end

			continue
		elseif info then
			-- existing fire continues to burn
			if info.m_state == FIRE_STATE_UNKNOWN then
				info.m_state = FIRE_STATE_BURNING
			end
		else
			-- new fire
			info = {
				m_pos = firePos, -- < position of flame
				m_normal = fireNormal, -- < normal of flame surface
				m_frame = 0, -- < current animation frame
				m_framerate = 0, -- < rate of animation
				m_mirror = false, -- < if true, flame is mirrored about vertical axis

				m_dlightIndex = 0,

				m_state = FIRE_STATE_STARTING, -- < the state of this fire
				m_stateTimestamp = 0, -- < when the fire entered its current state
				SetState = function(fire, state)
					fire.m_state = state
					fire.m_stateTimestamp = RealTime()
				end,

				m_size = 0, -- < current flame size
				m_maxSize = 0, -- < maximum size of full-grown flame

				Draw = function() -- < render this flame
				end,
			}
			drawables[i] = info

			info:SetState(FIRE_STATE_STARTING)
			info.m_framerate = g_ursRandom:RandomFloat(0.04, 0.06)
			info.m_mirror = g_ursRandom:RandomFloat(0, 100) < 50
			info.m_maxSize = g_ursRandom:RandomFloat(70, 90)

			local closeDlight = false

			if closeDlight then
				info.m_dlightIndex = 0
			else
				info.m_dlightIndex = self:EntIndex() + selfTable.GetDrawableCount(self)
			end

			selfTable.RecomputeBounds(self)

			selfTable.SetDrawableCount(self, selfTable.GetDrawableCount(self) + 1)
		end
	end

	-- any fires still in the UNKNOWN state are now GOING_OUT
	for i = 0, selfTable.GetDrawableCount(self) - 1 do
		local fire = drawables[i]
		if not fire then continue end

		if fire.m_state == FIRE_STATE_UNKNOWN then
			fire:SetState(FIRE_STATE_GOING_OUT)
		end
	end
end

local function VectorsAreEqual(a, b, tolerance)
	if math.abs(a.x - b.x) > tolerance then
		return false
	end
	if math.abs(a.y - b.y) > tolerance then
		return false
	end

	return math.abs(a.z - b.z) <= tolerance
end

function ENT:GetDrawable(pos)
	local drawables = self.m_drawable
	for i = 0, self:GetDrawableCount() - 1 do
		local fire = drawables[i]
		if not fire then continue end

		if VectorsAreEqual(fire.m_pos, pos, 12) then
			fire.m_pos:Set(pos)
			return fire
		end
	end
end

ENT.m_burnParticleEffect = NULL
function ENT:UpdateParticles(selfTable)
	if selfTable.GetDrawableCount(self) > 0 and bit.band(InfernoFire:GetInt(), NEW_FIRE_MASK) ~= 0 then
		if not (selfTable.m_burnParticleEffect and selfTable.m_burnParticleEffect:IsValid()) then
			selfTable.m_burnParticleEffect = CreateParticleSystem(self, selfTable.GetParticleEffectName(self), PATTACH_ABSORIGIN_FOLLOW)
		else
			for i = 0, selfTable.GetDrawableCount(self) - 1 do
				local draw = selfTable.m_drawable[i]
				if not draw then continue end

				if draw.m_state >= FIRE_STATE_FIRE_OUT then
					local vecCenter = Vector(draw.m_pos)
					vecCenter.z = vecCenter.z - 9999
					draw.m_pos:Set(vecCenter)
					draw.m_size = 0

					-- this sucks
					if i ~= 0 then
						--selfTable.m_burnParticleEffect:SetControlPoint( i, Vector(math.huge, math.huge, math.huge) )
					end
				else
					--selfTable.m_burnParticleEffect:SetControlPointEntity(i, selfTable)
					selfTable.m_burnParticleEffect:SetControlPoint(i, draw.m_pos)

					if i % 2 == 0 then
						-- Elight, for perf reasons only for every other fire
					end
				end
			end

			self:SetNextClientThink(0.1)

			selfTable.m_burnParticleEffect:SetSortOrigin(self:GetRenderOrigin())

			if InfernoDebug:GetBool() then
				local min, max = self:GetRenderBounds()
				debugoverlay.Cross(self:GetRenderOrigin(), 5, 0.01, Color(255, 0, 255))
				debugoverlay.Box(self:GetRenderOrigin(), min, max, 0.01, Color(255, 0, 255, 16))
			end
		end
	else
		if selfTable.m_burnParticleEffect and selfTable.m_burnParticleEffect:IsValid() then
			selfTable.m_burnParticleEffect:StopEmission()
		end
	end
end

ENT.m_maxFireHalfWidth = 30.0
ENT.m_maxFireHeight = 80.0
ENT.m_minBounds = Vector()
ENT.m_maxBounds = Vector()
function ENT:RecomputeBounds()
	local minBounds = self:GetPos() + Vector(64.9, 64.9, 64.9)
	local maxBounds = self:GetPos() + Vector(-64.9, -64.9, -64.9)

	local flMaxHalfWidth = self.m_maxFireHalfWidth

	local drawables = self.m_drawable
	for i = 0, self:GetDrawableCount() do
		local draw = drawables[i]
		if not draw then continue end

		if draw.m_state == FIRE_STATE_FIRE_OUT then continue end

		if (draw.m_pos.x - flMaxHalfWidth < minBounds.x) then
			minBounds.x = draw.m_pos.x - flMaxHalfWidth
		end

		if (draw.m_pos.x + flMaxHalfWidth > maxBounds.x) then
			maxBounds.x = draw.m_pos.x + flMaxHalfWidth
		end

		if (draw.m_pos.y - flMaxHalfWidth < minBounds.y) then
			minBounds.y = draw.m_pos.y - flMaxHalfWidth
		end

		if (draw.m_pos.y + flMaxHalfWidth > maxBounds.y) then
			maxBounds.y = draw.m_pos.y + flMaxHalfWidth
		end

		if (draw.m_pos.z < minBounds.z) then
			minBounds.z = draw.m_pos.z
		end

		if (draw.m_pos.z + self.m_maxFireHeight > maxBounds.z) then
			maxBounds.z = draw.m_pos.z + self.m_maxFireHeight
		end
	end

	self:SetRenderOrigin(self:GetPos())
	self:SetRenderBoundsWS(minBounds, maxBounds)
end

local AverageFPS = -1
local high = -1
local low = -1
local NewWeight = 0.1

local mat = Material("sprites/fire1.vmt")
function ENT:DrawFire(fire)
	local halfWidth = fire.m_size / 3.0

	local right = fire.m_mirror and -EyeAngles():Right() or EyeAngles():Right()
	local top = fire.m_pos + (vector_up * fire.m_size)
	local bottom = fire.m_pos

	local tr = top + (right * halfWidth)
	local br = bottom + (right * halfWidth)
	local bl = bottom - (right * halfWidth)
	local tl = top - (right * halfWidth)

	render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_ADD, BLEND_ONE, BLEND_ZERO, BLENDFUNC_ADD)
	render.OverrideDepthEnable(true, false)

	render.SetMaterial(mat)
	mesh.Begin(MATERIAL_QUADS, 2)
	---@diagnostic disable-next-line: missing-parameter
	mesh.Quad(bl, br, tr, tl)
	mesh.End()

	---@diagnostic disable-next-line: missing-parameter
	render.OverrideDepthEnable(false)
	render.OverrideBlend(false)

	if fire.m_dlightIndex > 0 and InfernoDlights:GetInt() >= 1 then
		local realFrameTime = RealFrameTime()
		if realFrameTime > 2 then
			realFrameTime = -1
		end
		if realFrameTime > 0 then
			local nFps = -1
			local NewFrame = 1.0 / realFrameTime

			if AverageFPS < 0 then
				AverageFPS = NewFrame
				high = math.floor(AverageFPS)
				low = math.floor(AverageFPS)
			else
				AverageFPS = AverageFPS * (1.0 - NewWeight)
				AverageFPS = AverageFPS + (NewFrame * NewWeight)
			end

			local NewFrameInt = math.floor(NewFrame)
			if NewFrameInt < low then NewFrameInt = low end
			if NewFrameInt > high then NewFrameInt = high end

			nFps = math.floor(AverageFPS)
			if nFps < InfernoDlights:GetInt() then
				fire.m_dlightIndex = 0
				return
			end
		end

		-- These are the dlight params from the Ep1 fire glows, with a slightly larger flicker
		-- (radius delta is larger, starting from 250 instead of 400).
		local scale = fire.m_size / fire.m_maxSize * 1.5

		local el = DynamicLight(fire.m_dlightIndex, true)
		local pos = Vector(bottom)
		pos.z = pos.z + (16.0 * scale)

		el.pos = pos
		el.r = 255
		el.g = 100
		el.b = 10
		el.brightness = 3
		el.size = g_ursRandom:RandomFloat(50, 131) * scale
		el.dietime = CurTime() + 0.1
	end
end

function ENT:Draw()
	if bit.band(InfernoFire:GetInt(), OLD_FIRE_MASK) == 0 then return end

	local selfTable = self:GetTable()

	for i = 0, selfTable.GetDrawableCount(self) - 1 do
		local fire = selfTable.m_drawable[i]
		if not fire then continue end

		local frame = math.floor(RealTime() / fire.m_framerate) % mat:GetTexture("$basetexture"):GetNumAnimationFrames()
		mat:SetInt("$frame", frame)

		selfTable.DrawFire(self, fire)
	end
end
