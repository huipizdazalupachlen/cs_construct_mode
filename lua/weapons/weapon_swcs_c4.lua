SWEP.Base = "weapon_swcs_base"
SWEP.Category = "#spawnmenu.category.swcs"

SWEP.Slot = 4
DEFINE_BASECLASS(SWEP.Base)

SWEP.PrintName = "C4 Explosive"
SWEP.Spawnable = true
SWEP.HoldType = "slam"
SWEP.WorldModel = Model("models/weapons/csgo/w_ied.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_ied.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/c4.png", "smooth")
end

SWEP.NoViewModelFlip = true
SWEP.ViewModelFlip = false

SWEP.Primary.Ammo = ""
SWEP.Primary.Automatic = true

AccessorFunc(SWEP, "m_bBombPlanted", "BombPlanted", FORCE_BOOL)
AccessorFunc(SWEP, "m_szScreenText", "ScreenText", FORCE_STRING)
SWEP:SetScreenText("") -- lol

if CLIENT then
	local size = ScreenScaleH(68)
	if ScrH() > 1080 then
		size = 68 * (1080 / 480)
	end

	surface.CreateFont("C4FontView", {
		font = "Courier New",
		size = size,
		weight = 600,
	})
end

sound.Add({
	name = "c4.draw",
	channel = CHAN_STATIC,
	level = 60,
	volume = 0.1,
	sound = Sound("weapons/csgo/c4/c4_draw.wav"),
})
sound.Add({
	name = "c4.initiate",
	channel = CHAN_STATIC,
	level = 80,
	volume = 0.8,
	sound = Sound(")weapons/csgo/c4/c4_initiate.wav"),
})
sound.Add({
	name = "c4.keypressquiet",
	channel = CHAN_STATIC,
	level = 40,
	volume = 0.22,
	sound = {
		Sound(")weapons/csgo/c4/key_press1.wav"), Sound(")weapons/csgo/c4/key_press2.wav"),
		Sound(")weapons/csgo/c4/key_press3.wav"), Sound(")weapons/csgo/c4/key_press4.wav"),
		Sound(")weapons/csgo/c4/key_press5.wav"), Sound(")weapons/csgo/c4/key_press6.wav"),
		Sound(")weapons/csgo/c4/key_press7.wav"),
	},
})
sound.Add({
	name = "c4.plantquiet",
	channel = CHAN_STATIC,
	level = 45,
	volume = 0.4,
	sound = Sound(")weapons/csgo/c4/c4_plant_quiet.wav"),
})

local WEAPON_C4_ARM_TIME = 3.0

function SWEP:FireAnimationEvent(pos, ang, event, options, src_ent)
	if event == 7001 then
		self:SetScreenText(options)

		return true
	end

	return BaseClass.FireAnimationEvent(pos, ang, event, options, src_ent)
end

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)

	self:NetworkVar("Bool", "StartedArming")
	self:NetworkVar("Bool", "BombPlacedAnimation")
	self:NetworkVar("Bool", "ShowC4LED")
	self:NetworkVar("Bool", "IsPlantingViaUse")
	self:NetworkVar("Float", "ArmedTime")
end

function SWEP:Initialize()
	BaseClass.Initialize(self)

	function self:GetMaxSpeed()
		if self:GetStartedArming() then
			return 0
		else
			return self.ItemAttributes["max player speed"]
		end
	end

	self.Primary.Automatic = true
end

function SWEP:Holster(nextWep)
	if self:GetStartedArming() then
		self:AbortBombPlant()
	end

	return BaseClass.Holster(self, nextWep)
end

function SWEP:OnDrop(...)
	BaseClass.OnDrop(self, ...)

	if self:GetStartedArming() then
		self:AbortBombPlant()
	end
end

local swcs_c4_training = CreateConVar("swcs_c4_training", "0", FCVAR_ARCHIVE, "C4 will use its training mode explosion")
if SERVER and SERVERID then -- metastruct
	swcs_c4_training:SetBool(true)
end

function SWEP:PrimaryAttack()
	if SERVER and game.SinglePlayer() then
		self:CallOnClient("PrimaryAttack")
	end

	local bArmingTimeSatisfied = false

	local owner = self:GetPlayerOwner()
	if not owner then return end

	local onGround = owner:IsFlagSet(FL_ONGROUND)
	local groundEntity = onGround and owner:GetGroundEntity() or NULL
	---@class TraceResult
	local trPlant = {}
	if groundEntity:IsValid() or groundEntity:IsWorld() then
		if groundEntity:IsPlayer() or swcs.IsBreakableEntity(groundEntity) then
			onGround = false
		end

		if onGround then
			util.TraceHull({
				start = self:GetPos() + Vector(0, 0, 8),
				endpos = self:GetPos() - Vector(0, 0, 38),
				mins = Vector(-3, -3, 0),
				maxs = Vector(3, 3, 16),
				mask = MASK_PLAYERSOLID,
				filter = owner,
				collisiongroup = COLLISION_GROUP_PLAYER_MOVEMENT,
				output = trPlant,
			})

			if (trPlant.fraction == 1.0) then
				onGround = false
			end
		end
	end

	local bInBombZone = hook.Run("SWCSInBombZone", owner)
	if bInBombZone == nil then
		bInBombZone = true
	end

	if not self:GetStartedArming() and not self:GetBombPlanted() then
		if bInBombZone and onGround then
			self:SetStartedArming(true)
			self:SetArmedTime(CurTime() + WEAPON_C4_ARM_TIME)
			self:SetBombPlacedAnimation(false)

			-- force crouch here

			self:PlayPlantInitSound()

			self:SetWeaponAnim(ACT_VM_PRIMARYATTACK)
		else
			if not owner:GetUseEntity():IsValid() then
				if not bInBombZone then
					owner:PrintMessage(HUD_PRINTCENTER, "#swcs.c4_plant_atsite")
				else
					owner:PrintMessage(HUD_PRINTCENTER, "#swcs.c4_plant_mustbeonground")
				end
			end

			self:SetNextPrimaryFire(CurTime() + 1)

			return
		end
	else
		if not onGround or not bInBombZone then
			-- alert player
			if not bInBombZone then
				owner:PrintMessage(HUD_PRINTCENTER, "#swcs.c4_plant_atsite")
			else
				owner:PrintMessage(HUD_PRINTCENTER, "#swcs.c4_plant_mustbeonground")
			end

			self:AbortBombPlant()

			if self:GetBombPlacedAnimation() then
				self:SetWeaponAnim(ACT_VM_DRAW)
			else
				self:SetWeaponAnim(ACT_VM_IDLE)
			end

			return
		else
			if CurTime() >= self:GetArmedTime() then
				bArmingTimeSatisfied = true
			elseif CurTime() >= (self:GetArmedTime() - 0.75) and not self:GetBombPlacedAnimation() then
				self:SetBombPlacedAnimation(true)
				self:SetWeaponAnim(ACT_VM_SECONDARYATTACK)
			end
		end
	end

	if bArmingTimeSatisfied and self:GetStartedArming() then
		self:SetStartedArming(false)
		self:SetArmedTime(0)

		if bInBombZone then
			if SERVER then
				local pC4 = ents.Create("swcs_planted_c4")
				if pC4:IsValid() then
					pC4:SetPos(owner:GetPos())
					local ang = owner:GetAngles()
					ang.p = 0
					ang.r = 0
					pC4:SetAngles(ang)
					pC4:SetOwner(owner)
					pC4:Spawn()

					hook.Run("PlayerSpawnedSENT", owner, pC4)

					if trPlant.Fraction < 1 then
						pC4:SetPos(trPlant.HitPos)

						--bomb aligns to planted surface normal within a threshold
						if math.abs(trPlant.HitNormal:Dot(Vector(0, 0, 1))) > 0.65 then
							local vecFlatForward = owner:GetForward()
							vecFlatForward.z = 0
							vecFlatForward:Normalize()

							local vecC4Right = vecFlatForward:Cross(trPlant.HitNormal)
							local vecC4Forward = vecC4Right:Cross(-trPlant.HitNormal)

							local C4Angle = vecC4Forward:AngleEx(trPlant.HitNormal)
							pC4:SetAngles(C4Angle)
						end
					end

					if swcs_c4_training:GetBool() then
						pC4:SetTrainingMode(true)
					end

					hook.Run("SWCSPlantedC4", self, owner, pC4)
				end

				-- Play the plant sound.
				EmitSound("c4.plantquiet", pC4:GetPos())

				-- No more c4!
				self:SwitchToPreviousWeapon()
				owner:StripWeapon(self:GetClass())
			end

			-- unforce crouch

			self:SetBombPlanted(true)

			return
		else
			owner:PrintMessage(HUD_PRINTCENTER, "#swcs.c4_plant_atsite")
			-- alert player

			self:SetNextPrimaryFire(CurTime() + 1)

			return
		end
	end

	self:SetNextPrimaryFire(CurTime() + 0.3)
	self:SetWeaponIdleTime(CurTime() + util.SharedRandom("C4IdleTime", 10, 15))
end

function SWEP:Think()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	if owner:KeyDown(IN_ATTACK) or (owner:KeyDown(IN_USE) and self:GetIsPlantingViaUse()) then
		if self:GetNextPrimaryFire() <= CurTime() then
			self:PrimaryAttack()
		end
	else
		self:WeaponIdle()
	end

	if owner:KeyDown(IN_USE) and not owner:GetUseEntity():IsValid() then
		self:SetIsPlantingViaUse(true)
	elseif not owner:KeyDown(IN_USE) then
		self:SetIsPlantingViaUse(false)
		self.m_bProcessActivities = true
	end

	self:PostThink()
end

function SWEP:OnMove(owner, mv, cmd, selfTable)
	selfTable = selfTable or self:GetTable()
	BaseClass.OnMove(self, owner, mv, cmd, selfTable)

	if selfTable.GetStartedArming(self) then
		mv:AddKey(IN_DUCK)
		if owner:GetMoveType() == MOVETYPE_WALK and mv:KeyDown(IN_JUMP) then
			mv:SetButtons(bit.band(mv:GetButtons(), bit.bnot(IN_JUMP)))
		end
	end
end

function SWEP:WeaponIdle()
	if self:GetStartedArming() then
		self:AbortBombPlant()
		if game.SinglePlayer() then
			self:CallOnClient("AbortBombPlant")
		end

		-- unforce crouch

		if self:GetBombPlacedAnimation() then
			self:SetWeaponAnim(ACT_VM_DRAW)
		else
			self:SetWeaponAnim(ACT_VM_IDLE)
		end
	else
		BaseClass.WeaponIdle(self)
	end
end

function SWEP:AbortBombPlant()
	self:SetStartedArming(false)
	self:SetNextPrimaryFire(CurTime() + 1)
	self:SetScreenText("")
end

function SWEP:PlayPlantInitSound()
	local owner = self:GetPlayerOwner()
	if not owner then return end

	if SERVER or (CLIENT and IsFirstTimePredicted()) then
		self:EmitSound("c4.initiate")
	end
end

local FormatViewModelAttachment = swcs.FormatViewModelAttachment
local VectorTransform = swcs.VectorTransform

local colArmed = Color(32, 0, 0, 220)

local SCALE_FUDGE = 1
local a = "controlpanel%d_ll"
local b = "controlpanel%d_ur"
function SWEP:PostDrawViewModel(vm, _, owner)
	BaseClass.PostDrawViewModel(self, vm, _, owner)

	for i = 0, math.huge do
		local nLLAttachmentIndex = vm:LookupAttachment(Format(a, i))
		if nLLAttachmentIndex <= 0 then return end

		--local nURAttachmentIndex = vm:LookupAttachment(Format(b, i))
		--if nURAttachmentIndex <= 0 then return end

		local attData = vm:GetAttachment(nLLAttachmentIndex)
		local att1Pos = FormatViewModelAttachment(attData.Pos)

		--local attData2 = vm:GetAttachment(nURAttachmentIndex)
		--local att2Pos = FormatViewModelAttachment(attData2.Pos)
		--
		--local panelToWorld = Matrix()
		--local worldToPanel
		--
		--panelToWorld:SetTranslation(att1Pos)
		--panelToWorld:SetAngles(attData.Ang)
		--
		--worldToPanel = Matrix(panelToWorld)
		--worldToPanel:Invert()
		--
		--panelToWorld:SetTranslation(att2Pos)
		--panelToWorld:SetAngles(attData2.Ang)
		--
		--local lr, lrlocal = panelToWorld:GetTranslation(), Vector()
		--VectorTransform(lr, worldToPanel, lrlocal)
		--
		--local flWidth = math.abs( lrlocal.x ) * SCALE_FUDGE
		--local flHeight = math.abs( lrlocal.y ) * SCALE_FUDGE

		cam.Start3D2D(att1Pos, attData.Ang, 0.004)
		surface.SetFont("C4FontView")
		local w = surface.GetTextSize("*******")
		draw.SimpleText(self:GetScreenText(), "C4FontView", w + (w / 3), 0, colArmed, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
		cam.End3D2D()
	end
end
