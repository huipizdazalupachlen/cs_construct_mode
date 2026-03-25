AddCSLuaFile()
ENT.Type = "anim"
ENT.Spawnable = false
ENT.Category = "#spawnmenu.category.swcs"
ENT.Model = Model("models/weapons/csgo/v_shield.mdl")

ENT.m_bUsed = false

local ITEM_PICKUP_BOX_BLOAT = 12

function ENT:Initialize()
	self:SetModel(self.Model)

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetTrigger(true)

		local phys = self:GetPhysicsObject()

		if not phys:IsValid() then
			local mins, maxs = self:GetModelBounds()
			self:PhysicsInitBox(mins, maxs)

			phys = self:GetPhysicsObject()
		end

		if phys:IsValid() then
			phys:Wake()
		end

		self:UseTriggerBounds(true, ITEM_PICKUP_BOX_BLOAT)

		self:SetUseType(SIMPLE_USE)
	end

	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
end

function ENT:OnInteract(actor)
	--
end
function ENT:CanInteract(actor)
	if self.m_bUsed then
		return false
	end

	return true
end

function ENT:Use(actor, caller)
	if not (actor:IsValid() and actor:IsPlayer()) then return end

	if not self:CanInteract(actor) then
		if actor == caller and not self:IsPlayerHolding() then -- is this how you check if the player is the one who used it, rather than logic relay?
			local can = hook.Run("AllowPlayerPickup", actor, self)

			if can == nil or can == true then
				actor:PickupObject(self)
			end
		end

		return
	end

	self:OnInteract(actor)

	self.m_bUsed = true

	SafeRemoveEntity(self)
end

function ENT:StartTouch(ent)
	if not (ent:IsValid() and ent:IsPlayer()) then return end
	if not self:CanInteract(ent) then return end

	self:OnInteract(ent)

	self.m_bUsed = true

	SafeRemoveEntity(self)
end
