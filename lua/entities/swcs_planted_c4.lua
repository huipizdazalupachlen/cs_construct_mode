AddCSLuaFile()

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

ENT.PrintName = "C4"
ENT.Author = "homonovus"

ENT.m_flNextBeep = 0
ENT.m_flNextGlow = 0
ENT.m_flLastDefuseTime = 0
ENT.m_bHasExploded = false
ENT.m_bExplodeWarning = false
ENT.m_bTriggerWarning = false
ENT.m_bBeingDefused = false
ENT.m_flNextDigitRandomizeTime = 0
ENT.m_iLastRandomInt = 0

AccessorFunc(ENT, "m_flNextBeep", "NextBeep", FORCE_NUMBER)
AccessorFunc(ENT, "m_flNextGlow", "NextGlow", FORCE_NUMBER)
AccessorFunc(ENT, "m_flLastDefuseTime", "LastDefuseTime", FORCE_NUMBER)
AccessorFunc(ENT, "m_bHasExploded", "HasExploded", FORCE_BOOL)
AccessorFunc(ENT, "m_bExplodeWarning", "ExplodeWarning", FORCE_BOOL)
AccessorFunc(ENT, "m_bTriggerWarning", "TriggerWarning", FORCE_BOOL)
AccessorFunc(ENT, "m_bBeingDefused", "BeingDefused", FORCE_BOOL)
AccessorFunc(ENT, "m_flNextDigitRandomizeTime", "NextDigitRandomizeTime", FORCE_NUMBER)
AccessorFunc(ENT, "m_iLastRandomInt", "LastRandomInt", FORCE_NUMBER)

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "BombTicking")
	self:NetworkVar("Bool", 1, "BombDefused")
	self:NetworkVar("Bool", 2, "TrainingMode")
	self:NetworkVar("Float", 0, "C4Blow")
	self:NetworkVar("Float", 1, "TimerLength")
	self:NetworkVar("Float", 2, "DefuseLength")
	self:NetworkVar("Float", 3, "DefuseCountDown")
	self:NetworkVar("Entity", 0, "BombDefuser")

	self.IsBombActive = self.GetBombTicking
end

sound.Add({
	name = "C4_CSGO.ExplodeWarning",
	channel = CHAN_STATIC,
	volume = 1,
	level = 60,
	sound = Sound("ui/arm_bomb.wav"),
})
sound.Add({
	name = "C4_CSGO.PlantSound",
	channel = CHAN_STATIC,
	volume = 0.3,
	level = 60,
	sound = Sound("weapons/csgo/c4/c4_beep2.wav"),
})
sound.Add({
	name = "C4_CSGO.Explode",
	channel = CHAN_STATIC,
	volume = 1,
	level = 100,
	sound = Sound("weapons/csgo/c4/c4_explode1.wav"),
})
sound.Add({
	name = "C4_CSGO.Explode_Training",
	channel = CHAN_STATIC,
	volume = 1,
	level = 80,
	sound = Sound("training/firewerks_burst_02.wav"),
})
sound.Add({
	name = "C4_CSGO.ExplodeTriggerTrip",
	channel = CHAN_STATIC,
	volume = 1,
	sound = Sound("items/csgo/nvg_on.wav"),
})
sound.Add({
	name = "C4_CSGO.DisarmStart",
	channel = CHAN_STATIC,
	volume = 1,
	sound = Sound("weapons/csgo/c4/c4_disarmstart.wav"),
})
sound.Add({
	name = "C4_CSGO.DisarmFinish",
	channel = CHAN_STATIC,
	volume = 1,
	sound = Sound("weapons/csgo/c4/c4_disarmfinish.wav"),
})

-- amount of time a player can stop defusing and continue
local C4_DEFUSE_GRACE_PERIOD = 0.5

-- amount of time a player is forced to continue defusing after not USEing. this effects other player's ability to interrupt
local C4_DEFUSE_LOCKIN_PERIOD = 0.05

function ENT:Use(activator, caller, type, int)
	local curtime = engine.TickInterval() * engine.TickCount()
	if not self:GetBombTicking() or self:GetC4Blow() < curtime --[[or mp_c4_cannot_be_defused.GetBool() == true]] then
		-- self:SetUse(NULL) ? SetUseType() ??
		return
	end

	local ply = activator
	if not (ply:IsValid() and ply:IsPlayer()) or ply:GetNWBool("m_bIsDefusing", false) then
		return
	end

	if not ply:OnGround() and ply:Alive() then
		ply:PrintMessage(HUD_PRINTCENTER, "#swcs.c4_defuse_mustbeonground")
		return
	end

	if hook.Run("SWCSCanDisarmC4", ply, self) == false then
		return
	end

	-- if not a bot, do extra LOS checking...

	if self:GetBeingDefused() then
		-- already being defused
		if ply ~= self:GetBombDefuser() then return end

		self:SetLastDefuseTime(curtime)
	else
		self:EmitSound("C4_CSGO.DisarmStart")

		self:SetDefuseLength(ply:HasDefuser() and 5 or 10)
		self:SetDefuseCountDown(curtime + self:GetDefuseLength())
		ply:SetNWFloat("m_flDefuseCountDown", curtime + self:GetDefuseLength())
		ply:SetNWFloat("m_flSWCSDefuseLength", self:GetDefuseLength())

		self:SetBombDefuser(ply)
		self:SetBeingDefused(true)
		ply:SetNWBool("m_bIsDefusing", true)

		self:SetLastDefuseTime(curtime)

		-- start the progress bar

		hook.Run("SWCSBeginDefusingC4", ply, self, ply:HasDefuser())
		--player->OnStartedDefuse();

		self:Fire("OnBombBeginDefuse", nil, 0, ply, self)
	end
end

function ENT:OnRemove()
	if self:GetBombDefuser():IsValid() then
		self:GetBombDefuser():SetNWBool("m_bIsDefusing", false)
	end
end

ENT.Model = "models/weapons/csgo/w_c4_planted.mdl"
function ENT:Precache()
	util.PrecacheModel(self.Model)
end

local mp_c4timer = CreateConVar("mp_c4timer", "40", {FCVAR_REPLICATED, FCVAR_NOTIFY}, "how long from when the C4 is armed until it blows", 10)

function ENT:Initialize()
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	if SERVER then self:PhysicsInit(SOLID_VPHYSICS) end
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:AddFlags(FL_OBJECT)

	self:SetModel(self.Model)

	self:SetCollisionBounds(Vector(), Vector(8, 8, 8))
	--self:SetSurroundingBounds(Vector(-8, -8, -8), Vector(8,8,8))

	self:NextThink(0.1)

	self:SetTimerLength(mp_c4timer:GetInt())

	local curtime = engine.TickCount() * engine.TickInterval()

	self:SetC4Blow(curtime + self:GetTimerLength())

	if CLIENT then
		self:SetNextBeep(curtime + 1)
	end

	self:SetFriction(0.9)

	self:SetBombTicking(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:Sleep()
		phys:EnableMotion(false)
	end
end

local function ATTN_TO_SNDLVL(a)
	return math.floor(a) ~= 0 and (50 + (20 / a)) or 0
end

function ENT:ClientThink()
	-- If it's dormant, don't beep or anything..
	if self:IsDormant() then return end

	if not self:GetBombTicking() then
		return
	end

	local curtime = CurTime()

	if self:GetC4Blow() - curtime < 1.0 and not self:GetTriggerWarning() then
		self:EmitSound("C4_CSGO.ExplodeTriggerTrip")

		local ledAttachmentIndex = self:LookupAttachment("led")
		ParticleEffectAttach("c4_timer_light_trigger", PATTACH_POINT_FOLLOW, self, ledAttachmentIndex)

		self:SetTriggerWarning(true)
	end

	if ((self:GetC4Blow() - curtime) < 0.0 and not self:GetExplodeWarning()) then
		self:EmitSound("C4_CSGO.ExplodeWarning")

		self:SetExplodeWarning(true)
	end

	if curtime > self:GetNextBeep() then
		local fComplete = ((self:GetC4Blow() - curtime) / self:GetTimerLength())
		fComplete = math.Clamp(fComplete, 0, 1)

		local attenuation = math.min(0.3 + 0.6 * fComplete, 1.0)

		if (self:GetC4Blow() - curtime) > 1 then
			self:EmitSound("C4_CSGO.PlantSound", ATTN_TO_SNDLVL(attenuation))
		end

		local freq = math.max(0.1 + 0.9 * fComplete, 0.15)

		self:SetNextBeep(curtime + freq)
	end

	if curtime > self:GetNextGlow() then
		if curtime > self:GetNextGlow() and (self:GetC4Blow() - curtime) > 1.0 then
			local ledAttachmentIndex = self:LookupAttachment("led")
			ParticleEffectAttach("c4_timer_light", PATTACH_POINT_FOLLOW, self, ledAttachmentIndex)
		end

		local freq = 0.1 + (0.9 * ((self:GetC4Blow() - curtime) / self:GetTimerLength()))

		if freq < 0.15 then
			freq = 0.15
		end

		self:SetNextGlow(curtime + freq)
	end
end

function ENT:Think()
	if CLIENT then
		self:ClientThink()
		return
	end

	if self:GetHasExploded() or not self:GetBombTicking() then
		return
	end

	local curtime = CurTime()

	self:NextThink(0.05)

	-- IF the timer has expired ! blow this bomb up!
	if self:GetC4Blow() <= curtime then
		-- kick off defuser
		if self:GetBombDefuser():IsValid() then
			self:GetBombDefuser():SetNWBool("m_bIsDefusing", false)
			self:SetBombDefuser(NULL)
			self:SetBeingDefused(false)
		end

		if self:GetC4Blow() + 1 <= curtime then
			local vecSpot = self:GetPos()
			vecSpot.z = vecSpot.z + 8

			local tr = util.TraceLine({
				start = vecSpot,
				endpos = vecSpot + Vector(0, 0, -40),
				mask = MASK_SOLID,
				filter = self,
			})

			hook.Run("SWCSC4Detonated", self)

			if self:GetTrainingMode() then
				self:TrainingExplode(tr)

				timer.Simple(2.5, function()
					if self:IsValid() then
						self:AddEffects(EF_NODRAW)
					end
				end)
			else
				self:Explode(tr, DMG_BLAST)
			end

			SafeRemoveEntityDelayed(self, 5)

			return true
		end
	end

	-- make sure our defuser exists
	if self:GetBeingDefused() then
		if not self:GetBombDefuser():IsValid() then
			self:SetBeingDefused(false)
		end
	else
		self:SetBombDefuser(NULL)
	end

	-- if the defusing process has started
	if self:GetBeingDefused() and self:GetBombDefuser():IsValid() --[[ and not mp_c4_cannot_be_defused:GetBool()]] then
		local pBombDefuser = self:GetBombDefuser()

		-- if the defusing process has not ended yet
		if curtime < self:GetDefuseCountDown() then
			local iOnGround = pBombDefuser:IsOnGround()

			local bPlayerStoppedHoldingUse = not pBombDefuser:KeyDown(IN_USE) and (curtime > self:GetLastDefuseTime() + C4_DEFUSE_LOCKIN_PERIOD)

			local cfgUseEntity = swcs.GetUseConfigurationForHighPriorityUseEntity(self)
			local bPlayerUseIsValidNow = cfgUseEntity.m_pEntity == self and swcs.UseByPlayerNow(cfgUseEntity, pBombDefuser, EPlayerUseType_Progress)

			if bPlayerStoppedHoldingUse or not bPlayerUseIsValidNow or not iOnGround then
				if not iOnGround and pBombDefuser:Alive() then
					pBombDefuser:PrintMessage(HUD_PRINTCENTER, "#swcs.c4_defuse_mustbeonground")
				end

				pBombDefuser:SetNWBool("m_bIsDefusing", false)
				hook.Run("SWCSC4DefuseAborted", pBombDefuser, self)

				self:SetDefuseCountDown(0)
				self:SetBeingDefused(false)
			end

			return true
		end

		-- return true to say bomb has been defused, false to deny defuse
		local check = hook.Run("SWCSCheckC4Defused", pBombDefuser, self)
		if check == false then
			hook.Run("SWCSC4DefuseAborted", pBombDefuser, self)
			self:SetDefuseCountDown(0)
			return true
		else
			hook.Run("SWCSC4Defused", pBombDefuser, self)

			self:EmitSound("C4_CSGO.DisarmFinish")

			self:SetBombTicking(false)

			pBombDefuser:SetNWBool("m_bIsDefusing", false)

			if swcs.IsParty() then
				ParticleEffect("weapon_confetti_balloons", self:GetPos(), Angle())
				self:EmitSound("Weapon_PartyHorn_CSGO.Single")
			end

			self:SetBombDefuser(NULL)
			self:SetBeingDefused(false)
			self:SetBombDefused(true)

			self:SetDefuseLength(10)

			if SERVER then
				self:Fire("BombDefused", nil, 0, pBombDefuser, self)
			end

			SafeRemoveEntityDelayed(self, 5)

			return true
		end

		self:SetBeingDefused(false)
		self:SetBombDefuser(NULL)

		return true
	end

	return true
end

function ENT:TrainingExplode(tr, dmgtype)
	-- Check to see if the round is over after the bomb went off...
	self:SetBombTicking(false)
	self:SetHasExploded(true)

	-- Pull out of the wall a bit
	if tr.Fraction ~= 1 then
		tr.HitPos:Add(tr.HitNormal * 0.6)
	end

	ParticleEffect("c4_train_ground_effect", tr.HitPos, Angle())

	-- Sound! for everyone
	--CBroadcastRecipientFilter filter;
	--EmitSound( filter, 0, "tr.C4Explode", &GetAbsOrigin() );
	self:EmitSound("C4_CSGO.Explode_Training")

	-- Decal!
	util.Decal("Scorch", tr.StartPos, tr.HitPos, self)

	-- Shake!
	if SERVER then
		util.ScreenShake(tr.HitPos, 25, 150, 1, 3000)
	end

	self:SetOwner(NULL)

	self:Fire("OnBombExploded", nil, 0, self, self)
end

function ENT:Explode(tr, dmgtype)
	self:SetBombTicking(false)
	self:SetHasExploded(true)
	self:SetBombDefused(false)

	local flBombRadius = 500

	-- if mapinfo then bombradius = mapinfo.bombradius

	-- output to func_bomb_target->BombExplode

	-- Pull out of the wall a bit
	if (tr.Fraction ~= 1.0) then
		self:SetPos(tr.HitPos + tr.HitNormal * 0.6)
	end

	-- dispatch particle
	local pos = self:GetPos() + Vector(0, 0, 8)
	ParticleEffect("explosion_c4_500", pos, angle_zero)

	-- Sound! for everyone
	self:EmitSound("C4_CSGO.Explode")

	util.Decal("Scorch", tr.StartPos, tr.HitPos, self)

	if SERVER then
		util.ScreenShake(tr.HitPos, 25, 150, 1, 3000)
		self:AddEffects(EF_NODRAW)
	end

	local dmg = DamageInfo()
	dmg:SetInflictor(self)

	local owner = self:GetOwner()
	if owner:IsValid() then
		dmg:SetAttacker(owner)
	else
		dmg:SetAttacker(self)
	end

	dmg:SetDamage(flBombRadius)
	dmg:SetDamageType(dmgtype)

	self:SetOwner(NULL) -- can't traceline attack owner if this is set

	swcs.RadiusDamage(
		dmg,
		self:GetPos(),
		flBombRadius * 3.5, -- don't ask me, this is how CS does it.
		true)

	self:Fire("OnBombExploded", nil, 0, self, self)
end

function ENT:GetDefuseProgress()
	local flProgress = 1.0

	if self:GetDefuseCountDown() ~= 0 and self:GetDefuseLength() > 0.0 then
		flProgress = ((self:GetDefuseCountDown() - CurTime()) / self:GetDefuseLength())
	end

	return flProgress
end

function ENT:GetDetonationProgress()
	local fComplete = 0.0
	if self:GetTimerLength() > 0.0 then
		fComplete = ((self:GetC4Blow() - CurTime()) / self:GetTimerLength())
	end

	return fComplete
end

if CLIENT then
	-- how long to spend decoding each digit
	local flTransitionTimes = {0.9, 0.8, 0.6, 0.45, 0.25, 0.15, 0.0}

	-- the defuse code, taken from the view model animation, v_c4.mdl
	local cDefuseCode = "7355608"
	local cArmedDisplay = "*******"

	-- convert an integer into the readable character version of that number
	local _char_0 = string.byte("0")
	local function INT_TO_CHAR(i)
		return string.char(_char_0 + i)
	end

	local colArmed = Color(32, 0, 0, 220)
	local colDefused = Color(32, 32, 32, 220)
	local colInvisible = Color(0, 0, 0, 0)
	local a = "controlpanel%d_ll"
	local b = "controlpanel%d_ur"

	function ENT:Draw(flags)
		self:DrawModel(flags)

		local curtime = CurTime()

		for i = 0, math.huge do
			local nLLAttachmentIndex = self:LookupAttachment(Format(a, i))
			if nLLAttachmentIndex <= 0 then return end

			local nURAttachmentIndex = self:LookupAttachment(Format(b, i))
			if nURAttachmentIndex <= 0 then return end

			local attData = self:GetAttachment(nLLAttachmentIndex)
			local att1Pos = attData.Pos

			local flProgress = self:GetDefuseProgress()

			local textCol = colArmed
			local strText = ""

			-- If flProgress is less than 0, the bomb has been defused
			if flProgress <= 0.0 then
				-- Flash when the bomb has been defused
				if flProgress > -0.2 then -- flash for 2 seconds
					local x = math.floor(flProgress * 100)

					if x % 2 == 0 then
						textCol = colInvisible
					else
						textCol = colDefused
					end
				else
					textCol = colDefused
				end

				-- Show the full, decoded defuse code
				strText = cDefuseCode
			elseif flProgress < 1.0 then -- defuse in progress
				-- Initial display
				local buf = cArmedDisplay

				local iDigitPos = 1

				while flTransitionTimes[iDigitPos] and flProgress <= flTransitionTimes[iDigitPos] do
					-- Fill in the previously decoded digits
					buf = buf:sub(1, iDigitPos - 1) .. cDefuseCode:sub(iDigitPos, iDigitPos) .. buf:sub(iDigitPos + 1)
					iDigitPos = math.min(iDigitPos + 1, 7)
				end

				-- Animate the character that we're decoding
				-- Value drawn will be based on how long we've been
				-- decoding this character
				local flTimeInThisChar = 1.0 - flTransitionTimes[1]

				if iDigitPos > 0 then
					flTimeInThisChar = flTransitionTimes[iDigitPos] - (flTransitionTimes[iDigitPos + 1] or 0)
				end

				local flPercentDecoding = (flProgress - flTransitionTimes[iDigitPos]) / flTimeInThisChar

				-- Determine when to next change the digit that we're decoding
				if self.m_flNextDigitRandomizeTime < curtime then
					-- Get a new random int to draw
					self.m_iLastRandomInt = g_ursRandom:RandomInt(0, 9)

					if flPercentDecoding > 0.7 then
						self.m_flNextDigitRandomizeTime = curtime + 0.05
					elseif flPercentDecoding > 0.5 then
						self.m_flNextDigitRandomizeTime = curtime + 0.1
					elseif flPercentDecoding > 0.3 then
						self.m_flNextDigitRandomizeTime = curtime + 0.15
					else
						self.m_flNextDigitRandomizeTime = curtime + 0.3
					end
				end

				-- Settle on the real value if we're close
				if flPercentDecoding < 0.2 then
					--buf[iDigitPos] = cDefuseCode[iDigitPos]
					buf = string.SetChar(buf, iDigitPos, cDefuseCode[iDigitPos])
				else -- else use a random digit
					--buf[iDigitPos] = INT_TO_CHAR( self.m_iLastRandomInt )
					buf = string.SetChar(buf, iDigitPos, INT_TO_CHAR(self.m_iLastRandomInt))
				end

				textCol = colArmed
				strText = buf
			else
				-- Not being defused - draw the armed string
				textCol = colArmed
				strText = cArmedDisplay
			end

			cam.Start3D2D(att1Pos, attData.Ang, 0.004)
			surface.SetFont("C4FontView")
			local w, _ = surface.GetTextSize(strText)

			draw.SimpleText(strText, "C4FontView", w + (w / 3), 0, textCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			cam.End3D2D()
		end
	end
end
