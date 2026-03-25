AddCSLuaFile()
ENT.Base = "swcs_base_item"
DEFINE_BASECLASS(ENT.Base)
ENT.Category = "#spawnmenu.category.swcs"
ENT.Spawnable = true
ENT.Model = Model("models/props_survival/upgrades/upgrade_dz_helmet.mdl")
ENT.PrintName = "#swcs_helmet"
ENT.PhysicsSounds = true

function ENT:CanInteract(actor)
	if actor:HasHelmet() then
		return false
	end

	return BaseClass.CanInteract(self, actor)
end

function ENT:OnInteract(actor)
	actor:GiveHelmet()
	actor:EmitSound("Survival.ArmorPickup")
end
