AddCSLuaFile()
ENT.Base = "swcs_base_item"
DEFINE_BASECLASS(ENT.Base)
ENT.Category = "#spawnmenu.category.swcs"
ENT.Spawnable = true
ENT.Model = Model("models/props_survival/upgrades/upgrade_dz_armor.mdl")
ENT.PrintName = "#swcs_kevlar"
ENT.PhysicsSounds = true

sound.Add({
	name = "Survival.ArmorPickup",
	channel = CHAN_STATIC,
	volume = 1,
	level = 75,
	pitch = {98, 102},
	sound = Sound("survival/armor_pickup_01.wav"),
})

function ENT:CanInteract(actor)
	if actor:Armor() >= 100 then return false end

	return BaseClass.CanInteract(self, actor)
end

function ENT:OnInteract(actor)
	actor:SetArmor(100)
	actor:EmitSound("Survival.ArmorPickup")
end
