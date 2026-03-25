AddCSLuaFile()

CreateConVar("swcs_damage_scale", "1", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Percentage to scale damage by", 0, 1)
CreateConVar("swcs_damage_scale_head", "1", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Percentage to scale damage to the head by", 0, 1)
local NpcDamageScale = CreateConVar("swcs_damage_scale_npc", "0.5", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Percentage to scale damage from NPCs to players by", 0, 1)

local function ScaleDamage(victim, hitgroup, dmg)
	local atk, infl = dmg:GetAttacker(), dmg:GetInflictor()
	local wep = NULL

	if infl:IsValid() and infl:IsWeapon() then
		wep = infl
	end

	if not wep:IsValid() then
		if atk:IsValid() and atk.GetActiveWeapon then
			wep = atk:GetActiveWeapon()

			-- why does lvs return a table
			if not isentity(wep) then
				wep = NULL
			end
		end
	end

	if wep:IsValid() and wep:IsWeapon() and wep.IsSWCSWeapon then
		if atk:IsPlayer() then
			wep:ApplyDamageScale(dmg, hitgroup, dmg:GetDamage(), atk:IsPlayer())
		elseif atk:IsNPC() or atk:IsNextBot() then
			dmg:ScaleDamage(NpcDamageScale:GetFloat())
		end

		-- client doesnt deal damage, and we return true so that we can hide the engine blood spatter effect
		-- return false so that the gamemode func doesnt get called
		-- TODO: add toggle for this??
		if CLIENT then return true end
	end
end
hook.Add("ScalePlayerDamage", "swcs.dmg", ScaleDamage)
hook.Add("ScaleNPCDamage", "swcs.dmg", ScaleDamage)

hook.Add("HandlePlayerArmorReduction", "swcs", function(ply, dmg)
	local infl = dmg:GetInflictor()

	local iArmorValue = ply:Armor()

	if iArmorValue <= 0 then return end
	if not infl:IsValid() then return end

	local bOurThings = false

	if infl:IsWeapon() and infl.IsSWCSWeapon then
		bOurThings = true
	elseif infl:GetClass() == "swcs_inferno" then
		bOurThings = true
	elseif infl.IsSWCSGrenade then
		bOurThings = true
	end

	if not bOurThings then return end

	local flArmorBonus = 0.5
	local flArmorRatio = 0.5
	local flDamage = dmg:GetDamage()

	local iDamageType = dmg:GetDamageType()
	if bit.band(iDamageType, DMG_BURN) ~= 0 then
		-- mark fire damage dealt
	elseif bit.band(iDamageType, DMG_BLAST) ~= 0 then
		-- if we know this is a grenade, use it's armor ratio, otherwise
		-- use the he grenade armor ratio

		if infl.ItemAttributes and tonumber(infl.ItemAttributes["armor ratio"]) then
			flArmorRatio = flArmorRatio * tonumber(infl.ItemAttributes["armor ratio"])
		else
			flArmorRatio = flArmorRatio * 1.2
		end
	elseif infl.ItemAttributes and tonumber(infl.ItemAttributes["armor ratio"]) then
		flArmorRatio = flArmorRatio * tonumber(infl.ItemAttributes["armor ratio"])
	end

	local fDamageToHealth = flDamage
	local fDamageToArmor = 0
	local fHeavyArmorBonus = 1.0

	--if ply:HasHeavyArmor() then
	--	flArmorRatio = flArmorRatio * 0.5
	--	flArmorBonus = 0.33
	--	fHeavyArmorBonus = 0.33
	--end

	local bDamageAppliesToArmor = bit.band(dmg:GetDamageType(), bit.bor(DMG_BULLET, DMG_BLAST, DMG_CLUB, DMG_SLASH, DMG_GENERIC)) ~= 0

	if bDamageAppliesToArmor and iArmorValue > 0 and swcs.IsArmored(ply, ply:LastHitGroup()) then
		fDamageToHealth = flDamage * flArmorRatio
		fDamageToArmor = (flDamage - fDamageToHealth) * (flArmorBonus * fHeavyArmorBonus)

		local armorValue = iArmorValue

		-- Does this use more armor than we have?
		if fDamageToArmor > armorValue then
			fDamageToHealth = flDamage - armorValue / flArmorBonus
			fDamageToArmor = armorValue
			armorValue = 0
		else
			if fDamageToArmor < 0 then
				fDamageToArmor = 1
			end

			armorValue = armorValue - fDamageToArmor
		end

		ply:SetArmor(armorValue)

		flDamage = fDamageToHealth
		dmg:SetDamage(flDamage)

		if armorValue <= 0 then
			--ply:SetHasHeavyArmor(false)
			ply:RemoveHelmet()
		end
	end

	-- go away gamemode hook
	if swcs.InSandbox then
		return true
	end
end)
