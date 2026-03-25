SWEP.Base = "weapon_swcs_knife"
SWEP.Category = "#spawnmenu.category.swcs_knives"

SWEP.Slot = 0

SWEP.PrintName = "Knife (Gun Game)"
SWEP.Spawnable = true
SWEP.HoldType = "knife"

SWEP.WorldModel = Model("models/weapons/csgo/w_knife_gg.mdl")
SWEP.ViewModel = Model("models/weapons/csgo/v_knife_gg.mdl")
if CLIENT then
	SWEP.SelectIcon = Material("hud/swcs/select/knifegg.png", "smooth")
end

SWEP.ItemDefAttributes = [=["attributes 08/03/2020" {
	"primary clip size" "-1"
	"is full auto" "1"
	"armor ratio"		"1.700000"
	"recoil seed" "0"
	"recoil angle variance" "0"
	"recoil magnitude" "0"
	"recoil magnitude variance" "0"
	"recoil angle variance alt" "0"
	"recoil magnitude alt" "0"
	"recoil magnitude variance alt" "0"
}]=]
SWEP.ItemDefVisuals = [=["visuals 08/03/2020" {
	"weapon_type" "knife"
}]=]

SWEP.IsKnife = true
SWEP.AutoSpawnable = false
SWEP.TTTPreventSpawning = true

if swcs.InTTT then
	SWEP.PrintName = "Golden Knife"
	SWEP.AutoSpawnable = false

	SWEP.Slot = 6

	SWEP.CanBuy = {ROLE_TRAITOR} -- only traitors can buy

	SWEP.IsSilent = true
	SWEP.Kind = WEAPON_EQUIP

	SWEP.Primary.Ammo = nil
	SWEP.AmmoEnt = nil

	SWEP.LimitedStock = true
	SWEP.AllowDrop = true

	if CLIENT then
		SWEP.EquipMenuData = {
			type = "item_weapon",
			desc = "knife_desc",
		}
	end

	function SWEP:TTTStab(tr)
		local owner = self:GetPlayerOwner()
		if not (owner and owner:IsValid()) then return end
		local vForward = owner:GetAimVector()

		local bDidHit = tr.Fraction < 1
		if bDidHit then
			local ent = tr.Entity

			self:SetWeaponAnim(ACT_VM_HITCENTER)

			local info = DamageInfo()
			info:SetInflictor(owner)
			info:SetAttacker(owner)
			info:SetDamage(2000)
			info:SetDamageType(DMG_SLASH)
			info:SetDamagePosition(tr.HitPos)
			info:SetReportedPosition(tr.StartPos)

			local force = vForward:GetNormal() * GetConVar("phys_pushscale"):GetFloat()
			info:SetDamageForce(force)

			if SERVER and ent:IsPlayer() then
				ent:SetLastHitGroup(HITGROUP_GENERIC)
			end

			-- TTT CODE START --

			-- first a straight up line trace to see if we aimed nicely
			local retr = util.TraceLine({
				start = tr.StartPos,
				endpos = tr.HitPos,
				filter = owner,
				mask = MASK_SHOT_HULL,
			})

			-- if that fails, just trace to worldcenter so we have SOMETHING
			if retr.Entity ~= ent then
				local center = ent:LocalToWorld(ent:OBBCenter())
				retr = util.TraceLine({
					start = tr.StartPos,
					endpos = center,
					filter = owner,
					mask = MASK_SHOT_HULL,
				})
			end

			-- create knife effect creation fn
			local bone = retr.PhysicsBone
			local pos = retr.HitPos
			local norm = tr.Normal
			local ang = Angle(-28, 0, 0) + norm:Angle()
			ang:RotateAroundAxis(ang:Right(), -90)
			pos = pos - (ang:Forward() * 7)

			ent.effect_fn = function(rag)
				-- we might find a better location
				local rtr = util.TraceLine({
					start = pos,
					endpos = pos + norm * 40,
					filter = owner,
					mask = MASK_SHOT_HULL,
				})

				if IsValid(rtr.Entity) and rtr.Entity == rag then
					bone = rtr.PhysicsBone
					pos = rtr.HitPos
					ang = Angle(-28, 0, 0) + rtr.Normal:Angle()
					ang:RotateAroundAxis(ang:Right(), -90)
					pos = pos - (ang:Forward() * 10)
				end

				---@class Entity
				local knife = ents.Create("prop_physics")
				knife:SetModel("models/weapons/csgo/w_knife_gg.mdl")
				knife:SetPos(pos)
				knife:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
				knife:SetAngles(ang)
				knife.CanPickup = false

				knife:Spawn()

				local phys = knife:GetPhysicsObject()
				if IsValid(phys) then
					phys:EnableCollisions(false)
				end

				constraint.Weld(rag, knife, bone, 0, 0, true)

				-- need to close over knife in order to keep a valid ref to it
				rag:CallOnRemove("ttt_knife_cleanup", function() SafeRemoveEntity(knife) end)
			end

			-- TTT CODE END --

			if SERVER then
				-- disable player pushback on bullet damage
				-- what the fuck
				if ent:IsPlayer() then
					owner:AddSolidFlags(FSOLID_TRIGGER)
				end

				if ent:IsPlayer() then
					ent:TakeDamageInfo(info)
				else
					ent:DispatchTraceAttack(info, tr)
				end

				if ent:IsPlayer() then
					owner:RemoveSolidFlags(FSOLID_TRIGGER)
				end
			end

			if SERVER then
				self:Remove()
			end
		else
			self:EmitSound("Weapon_Knife_CSGO.Slash")

			local null_info = DamageInfo()
			null_info:SetDamageType(DMG_CLUB)
			game.GetWorld():DispatchTraceAttack(null_info, tr)

			self:SetWeaponAnim(ACT_VM_MISSCENTER)
		end

		owner:SetAnimation(PLAYER_ATTACK1)
	end

	function SWEP:PrimaryAttack()
		local owner = self:GetPlayerOwner()
		if not owner then return end

		if owner then
			owner:LagCompensation(true)
		end


		local fRange = 65

		local vForward = owner:GetAimVector()
		local vecSrc = owner:GetShootPos()
		local vecEnd = vecSrc + vForward * fRange

		local tr = util.TraceLine({
			start = vecSrc,
			endpos = vecEnd,
			mask = MASK_SOLID,
			collisiongroup = COLLISION_GROUP_NONE,
			filter = owner,
		})
		if not tr.Hit then
			util.TraceHull({
				start = vecSrc,
				endpos = vecEnd,
				mask = MASK_SOLID,
				collisiongroup = COLLISION_GROUP_NONE,
				filter = owner,
				mins = vector_origin,
				maxs = vector_origin,
				output = tr,
			})
		end

		if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
			self:TTTStab(tr)
		else
			self:SwingOrStab(Primary_Mode)
		end

		if owner then
			owner:LagCompensation(false)
		end
	end

	-- all TTT code
	function SWEP:SecondaryAttack()
		self:SetNextPrimaryFire(CurTime() + 1.1)
		self:SetNextSecondaryFire(CurTime() + 1.4)

		self:SendWeaponAnim(ACT_VM_MISSCENTER)

		if SERVER then
			local ply = self:GetOwner()
			if not IsValid(ply) then return end

			ply:SetAnimation(PLAYER_ATTACK1)

			local ang = ply:EyeAngles()

			if ang.p < 90 then
				ang.p = -10 + ang.p * ((90 + 10) / 90)
			else
				ang.p = 360 - ang.p
				ang.p = -10 + ang.p * -((90 + 10) / 90)
			end

			local vel = math.Clamp((90 - ang.p) * 5.5, 550, 800)

			local vfw = ang:Forward()
			local vrt = ang:Right()

			local src = ply:GetPos() + (ply:Crouching() and ply:GetViewOffsetDucked() or ply:GetViewOffset())

			src = src + (vfw * 1) + (vrt * 3)

			local thr = vfw * vel + ply:GetVelocity()

			local knife_ang = Angle(-28, 0, 0) + ang
			knife_ang:RotateAroundAxis(knife_ang:Right(), -90)

			---@class Entity
			local knife = ents.Create("ttt_knife_proj")
			if not IsValid(knife) then return end
			knife:SetPos(src)
			knife:SetAngles(knife_ang)

			knife:Spawn()

			knife.Damage = 50

			knife:SetOwner(ply)

			local phys = knife:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity(thr)
				phys:AddAngleVelocity(Vector(0, 1500, 0))
				phys:Wake()
			end

			SafeRemoveEntity(self)
		end
	end
end
