AddCSLuaFile()

ENT.Base = "baseswcsgrenade_projectile"
ENT.m_flTimeToDetonate = math.huge
ENT.m_flLastBounce = 0.0
ENT.m_bSmokeEffectSpawned = false
ENT.PrintName = "Smoke Grenade"

DEFINE_BASECLASS(ENT.Base)

sound.Add({
	name = "BaseSmokeEffect_CSGO.Sound",
	channel = CHAN_STATIC,
	volume = 1.0,
	pitch = 100, -- PITCH_NORM
	level = 85,
	sound = Sound(")weapons/csgo/smokegrenade/smoke_emit.wav"),
})

local GRENADE_MODEL = "models/weapons/csgo/w_eq_smokegrenade_thrown.mdl"

function ENT:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", 0, "DidSmokeEffect")
	self:NetworkVar("Bool", 1, "SelfRemove")
	self:NetworkVar("Int", 3, "SmokeEffectTickBegin")

	if CLIENT then
		self:NetworkVarNotify("SmokeEffectTickBegin", self.OnDataChanged)
		self:NetworkVarNotify("DidSmokeEffect", self.OnDataChanged)
	end
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

	self:SetLocalAngularVelocity(angvel)
	self:SetFinalAngularVelocity(angvel)
	self:SetActualCollisionGroup(COLLISION_GROUP_PROJECTILE)

	return self
end

function ENT:Initialize()
	self:SetModel(GRENADE_MODEL)

	BaseClass.Initialize(self)

	self:SetDetonateTimerLength(self.m_flTimeToDetonate)
end

ENT.m_smokeParticleEffect = NULL
function ENT:SpawnSmokeEffect()
	if (not self.m_bSmokeEffectSpawned) then
		self.m_bSmokeEffectSpawned = true

		local vOrigin = self:GetNetworkOrigin()

		local pSmokeEffect = CreateParticleSystem(self, "explosion_smokegrenade", 0, 0, vector_origin)

		if pSmokeEffect then
			self.m_smokeParticleEffect = pSmokeEffect
			pSmokeEffect:SetSortOrigin(vOrigin)
			pSmokeEffect:SetControlPoint(0, vOrigin)
			pSmokeEffect:SetControlPoint(1, vOrigin)
			pSmokeEffect:SetControlPointOrientation(0, Vector(1, 0, 0), Vector(0, -1, 0), Vector(0, 0, 1))
		end

		if self:GetSmokeEffectTickBegin() > 0 then
			local nSkipFrames = engine.TickCount() - self:GetSmokeEffectTickBegin()
			if nSkipFrames > 4 and pSmokeEffect then
				--Note: pSmokeEffect->Simulate( flSkipSeconds ) would be ideal, but it doesn't work well for long intervals. SkipToTime would be even better but it will extinguish the particle effect if it skips past 2 seconds due to some perf heuristic, and it's not clear if it skips correctly either.
				-- this doesn't happen often, and when it does, it's on connection or on replay begin/end, so a little hitch shouldn't be a problem.
				for i = 2, nSkipFrames, 2 do
					--pSmokeEffect:Render()
					--pSmokeEffect->Simulate( gpGlobals->interval_per_tick * 2 )
				end
			end
		end
	end
end

function ENT:OnRemove()
	if not self:GetSelfRemove() and self.m_smokeParticleEffect:IsValid() then
		self.m_smokeParticleEffect:StopEmission(false, true)
	end
end

function ENT:OnDataChanged(name, old, new)
	if (name == "SmokeEffectTickBegin" and new > 0 --[[or self:GetDidSmokeEffect()]]) and not self.m_bSmokeEffectSpawned then
		self:SpawnSmokeEffect()
		-- And the smoke grenade particle began! - every call but the first is extraneous here
		-- AddSmokeGrenadeHandle( this )
	end
end

-- Implement this so we never call the base class,
-- but this should never be called either.
function ENT:Detonate()
	assert(false, "Smoke grenade handles its own detonation\n")
end
function ENT:DetonateOnNextThink()
	local vel = Vector()
	local ang = Angle()

	self:SetVelocity(vel)
	self:SetLocalAngularVelocity(ang)
	self:SetFinalVelocity(vel)
	self:SetFinalAngularVelocity(ang)
end

function ENT:AdditionalThink(selfTable)
	selfTable = selfTable or self:GetTable()
	if selfTable.GetFinalVelocity(self):Length() > 0.1 then
		-- Still moving. Don't detonate yet.
		return true
	end

	selfTable.SmokeDetonate(self)
end

function ENT:SmokeDetonate()
	if CLIENT then return end

	self:SetSmokeEffectTickBegin(engine.TickCount())

	-- nade has exploded, tell everyone!
	hook.Run("SWCSSmokeGrenadeDetonated", self)

	-- the old way to signal the start of smoke effect; the new way is to set the particle start tick, so that we can replay and fix the bug when we lose the smoke effect when we connect right after smoke grenade went off
	self:SetDidSmokeEffect(true)

	self:EmitSound("BaseSmokeEffect_CSGO.Sound")

	self:SetRenderMode(RENDERMODE_TRANSCOLOR)

	self:SetFinalVelocity(vector_origin)
	self:SetNWMoveType(MOVETYPE_NONE)
	self:NextThink(CurTime() + 12.5)
	self.Think = self.Think_Fade

	--self:SetSolid(SOLID_NONE)
end

if vFireInstalled then
	local CONSTANT_UNITS_SMOKEGRENADERADIUS = 166
	local BCheckFirePointInSmokeCloud = swcs.CheckFirePointInSmokeCloud

	hook.Add("SWCSSmokeGrenadeDetonated", "swcs.vfire", function(grenade)
		local vGrenadePos = grenade:GetPos()
		local tEnts = ents.FindInSphere(vGrenadePos, CONSTANT_UNITS_SMOKEGRENADERADIUS)

		for _, vfire in pairs(tEnts) do
			local classname = vfire:GetClass()
			if classname ~= "vfire_cluster" and classname:find("vfire") and BCheckFirePointInSmokeCloud(vfire:GetPos(), vGrenadePos) then
				vfire:ChangeLife(0)
			end
		end
	end)
end

function ENT:Think_Fade()
	self:NextThink(CurTime())

	--local a = self:GetAlpha()
	--a = a - 1
	--self:SetAlpha( a )

	--if a == 0 then
	if SERVER then SafeRemoveEntityDelayed(self, 1.0) end
	self:SetSelfRemove(true)
	self:NextThink(CurTime() + 1.0 + engine.TickInterval())
	--end

	return true
end

function ENT:BounceSound()
	if not self:GetDidSmokeEffect() then
		self:EmitSound("SmokeGrenade_CSGO.Bounce")
	end
end

function ENT:OnBounced()
	if (self.m_flLastBounce >= (CurTime() - (3 * engine.TickInterval()))) then
		return
	end

	self.m_flLastBounce = CurTime()

	-- if the smoke grenade is above ground, trace down to the ground and see where it would end up?
	local selfPos = self:GetPos()
	local posDropSmoke = Vector(self:GetPos())
	local trSmokeTrace = {}

	util.TraceLine({
		start = posDropSmoke,
		endpos = posDropSmoke - Vector(0, 0, 166), -- CONSTANT_UNITS_SMOKEGRENADERADIUS
		mask = bit.band(MASK_PLAYERSOLID, bit.bnot(CONTENTS_PLAYERCLIP)),
		filter = {self, self:GetOwner(), self:GetOwner():IsValid() and unpack(self:GetOwner():GetChildren())},
		collisiongroup = COLLISION_GROUP_PROJECTILE,

		output = trSmokeTrace,
	})

	if not trSmokeTrace.StartSolid then
		--if ( trSmokeTrace.Fraction >= 1.0 ) then
		--    return end -- this smoke cannot drop enough to cause extinguish

		if trSmokeTrace.Fraction > 0.001 then
			posDropSmoke = trSmokeTrace.HitPos
		end
	end

	-- See if it touches any inferno?
	local tEnts = ents.FindInSphere(selfPos, 512)

	for _, ent in ipairs(tEnts) do
		if ent == self then continue end

		if ent:GetClass() == "swcs_inferno" and ent:BShouldExtinguishSmokeGrenadeBounce(self, posDropSmoke) then
			if posDropSmoke ~= selfPos then
				local vel = Vector(0, 0, 0)
				local ang = Angle(0, 0, 0)

				self:Set_Pos(posDropSmoke)
				self:SetPos(posDropSmoke)
				self:SetAngles(ang)

				self:SetVelocity(vel)
				self:SetLocalAngularVelocity(ang)
				self:SetFinalVelocity(vel)
				self:SetFinalAngularVelocity(ang)
			end

			self:SmokeDetonate()
			break
		end
	end
end

local cl_smoke_origin_height = 68.0
local cl_smoke_torus_ring_radius = 61.0
local cl_smoke_torus_ring_subradius = 88.0
local cl_smoke_edge_feather = 21.0
local cl_smoke_lower_speed = 4.5

-- If your eyes are less than this distance from the center of the visible smoke torus, we should check exact distance and may need to apply the screen overlay.
local cl_smoke_must_be_at_least_this_close_to_have_any_effect = (cl_smoke_torus_ring_radius + cl_smoke_torus_ring_subradius)

-- smoke overlay
if CLIENT then
	local tSmokeGrenades = {}
	hook.Add("Tick", "swcs.smokenade_tracking", function()
		tSmokeGrenades = ents.FindByClass("swcs_smokegrenade_projectile")

		local i = 1
		repeat
			local ent = tSmokeGrenades[i]
			if not (ent and ent:IsValid()) then
				table.remove(tSmokeGrenades, i)
			else
				if not ent:GetDidSmokeEffect() then
					table.remove(tSmokeGrenades, i)
				else
					i = i + 1
				end
			end
		until i >= #tSmokeGrenades
	end)

	local pMaterial = Material("effects/overlaysmoke")
	local flSmokeOverlayAmount = 0.0
	local function RenderSmokeOverlay(bPreViewModel)
		if bPreViewModel then
			-- update the overlay

			-- Assume we have no smoke overlay
			local flOptimalSmokeOverlayAlpha = 0.0

			if #tSmokeGrenades > 0 then
				local vecPlayerEyePos = EyePos() -- LocalPlayer():EyePos()
				local vecClosestVecToSmoke = Vector()

				local hClosestSmoke = NULL
				local flTempSmokeDistance = cl_smoke_must_be_at_least_this_close_to_have_any_effect

				-- we need to find the closest smoke to prevent a later grenade in the list lifting the opacity of a potentially closer one
				for _, pGrenade in ipairs(tSmokeGrenades) do
					if not pGrenade:IsValid() then continue end
					if not pGrenade:GetDidSmokeEffect() then continue end

					local toGrenade = pGrenade:GetPos()
					toGrenade.z = toGrenade.z + cl_smoke_origin_height
					toGrenade:Sub(vecPlayerEyePos)
					--toGrenade:Normalize()

					local toGrenadeLen = toGrenade:Length()
					if toGrenadeLen < flTempSmokeDistance then
						-- save the new closest smoke
						flTempSmokeDistance = toGrenadeLen
						hClosestSmoke = pGrenade

						-- remember its vector
						vecClosestVecToSmoke:Set(toGrenade)
					end
				end

				-- only continue if we actually found a close-enough smoke
				if hClosestSmoke:IsValid() then
					local vecSmokePos = hClosestSmoke:GetPos()

					-- linear interpolation between two capped torusoids

					-- are we within the Z axis bounds?
					if math.abs(vecClosestVecToSmoke.z) < cl_smoke_torus_ring_subradius then
						local flvecClosestVecToSmokeLength2D = vecClosestVecToSmoke:Length2D()

						-- are we within the cylindrical cap-space on the XY axis?
						if flvecClosestVecToSmokeLength2D < cl_smoke_torus_ring_radius then
							-- if so we can just use z delta
							flOptimalSmokeOverlayAlpha = (cl_smoke_torus_ring_subradius - math.abs(vecClosestVecToSmoke.z)) / cl_smoke_edge_feather
						elseif flvecClosestVecToSmokeLength2D < cl_smoke_torus_ring_radius + cl_smoke_torus_ring_subradius then
							-- are we within the outer possible horizontal range of the torusoid? if so we need the distance to the nearest point on the primary radius
							local vecRingPosOnSmokePlane = Vector(vecClosestVecToSmoke.x, vecClosestVecToSmoke.y, 0):GetNormalized() * cl_smoke_torus_ring_radius

							-- and check the distance value
							local flDistanceToClosestRingPoint = (vecClosestVecToSmoke - vecRingPosOnSmokePlane):Length()
							if flDistanceToClosestRingPoint < cl_smoke_torus_ring_subradius then
								flOptimalSmokeOverlayAlpha = (cl_smoke_torus_ring_subradius - flDistanceToClosestRingPoint) / cl_smoke_edge_feather
							end
						end

						-- clamp to 0-1 range
						flOptimalSmokeOverlayAlpha = math.Clamp(flOptimalSmokeOverlayAlpha, 0.0, 1.0)
					end
				end
			end

			-- alpha can instantly increase, but decreases to the ideal at a constant rate.
			if flOptimalSmokeOverlayAlpha < flSmokeOverlayAmount then
				flOptimalSmokeOverlayAlpha = swcs.Approach(flOptimalSmokeOverlayAlpha, flSmokeOverlayAmount, FrameTime() * cl_smoke_lower_speed)
			end
			flSmokeOverlayAmount = flOptimalSmokeOverlayAlpha
		end

		if flSmokeOverlayAmount <= 0 then
			return
		else
			render.SetMaterial(pMaterial)

			local col = 90 / 255
			pMaterial:SetVector("$color", Vector(col, col, col))
			pMaterial:SetFloat("$alpha", flSmokeOverlayAmount * (bPreViewModel and 0.99 or 0.5))
			pMaterial:Recompute()

			render.DrawScreenQuad()
		end
	end

	hook.Add("PreDrawViewModels", "swcs.smoke_overlay", function()
		RenderSmokeOverlay(true)
	end)

	hook.Add("PreDrawEffects", "swcs.smoke_overlay", function()
		RenderSmokeOverlay(false)
	end)

	hook.Add("HUDDrawTargetID", "swcs.smoke_grenade", function()
		local tr = util.GetPlayerTrace(LocalPlayer())
		local trace = util.TraceLine(tr)

		if swcs.IsLineBlockedBySmoke(trace.StartPos, trace.HitPos, 1) then
			return false
		end
	end)
end
