AddCSLuaFile()
ENT.Base = "swcs_base_item"
DEFINE_BASECLASS(ENT.Base)
ENT.Category = "#spawnmenu.category.swcs"
ENT.Spawnable = true
ENT.Model = Model("models/props_survival/upgrades/upgrade_dz_armor_helmet.mdl")
ENT.PrintName = "#swcs_helmet_kevlar"
ENT.PhysicsSounds = true

function ENT:CanInteract(actor)
	if actor:Armor() < 100 or not actor:HasHelmet() then
		return BaseClass.CanInteract(self, actor)
	end

	return false
end

function ENT:OnInteract(actor)
	if actor:Armor() < 100 then
		actor:SetArmor(100)
	end
	if not actor:HasHelmet() then
		actor:GiveHelmet()
	end
	actor:EmitSound("Survival.ArmorPickup")
end
