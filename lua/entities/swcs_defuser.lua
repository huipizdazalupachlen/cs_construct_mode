AddCSLuaFile()
ENT.Base = "swcs_base_item"
ENT.Category = "#spawnmenu.category.swcs"
ENT.Spawnable = true
ENT.Model = Model("models/weapons/csgo/w_defuser.mdl")
ENT.PrintName = "#swcs_defuser"
ENT.PhysicsSounds = true

function ENT:CanInteract(actor)
	return not actor:HasDefuser()
end

function ENT:OnInteract(actor)
	actor:GiveDefuser()
end
