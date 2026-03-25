AddCSLuaFile()

-- econ as in skins and shit ;)

--[[
local ak_neon_rider = swcs.econ.GenerateEconTexture({
	basetexture = "models/weapons/customization/paints/custom/ak_neon_rider",
	wearvalue = 1
})
local ak_uv = swcs.econ.GenerateEconTexture({
	basetexture = "models/weapons/customization/uvs/weapon_ak47",
	wearvalue = 1
})

local css_uv = swcs.econ.GenerateEconTexture({
	basetexture = "models/weapons/customization/uvs/weapon_knife_css",
	wearvalue = 1
})

local awp_cat = swcs.econ.GenerateEconTexture({
	basetexture = "models/weapons/customization/paints/anodized_multi/workshop/awp_pawpaw",
	wearvalue = 1
})
local awp_medusa = swcs.econ.GenerateEconTexture({
	basetexture = "models/weapons/customization/paints/antiqued/medusa_awp",
	wearvalue = 1
})

local deagle_etched = swcs.econ.GenerateEconTexture({
	basetexture = "models/weapons/customization/paints/antiqued/etched_deagle",
	wearvalue = 1
})

local cz_etched = swcs.econ.GenerateEconTexture({
	basetexture = "models/weapons/customization/paints/antiqued/etched_cz75",
	normalmap = "models/weapons/customization/paints/antiqued/etched_cz75_normal",
	wearvalue = 1
})

local bayonet_future = swcs.econ.GenerateEconTexture({
	basetexture = "models/weapons/customization/paints/gunsmith/bayonet_future_alt",
	normalmap = "models/weapons/customization/paints/gunsmith/bayonet_future_alt_normal",
	wearvalue = 1
})
]]

if CLIENT then
	function SWEP:ApplyWeaponSkin(vm, owner)
		local selfTable = self:GetTable()

		if not selfTable.m_clSkinTexture then
			--local want_skin = owner:GetPData("swcs_skin")
			--if want_skin == nil then return end
			--print(vm, selfTable.m_clSkinTexture, want_skin)

			--selfTable.m_clSkinTexture = "!" .. ak_neon_rider
		end
		if not selfTable.m_clSkinTexture then return end

		--vm:SetSubMaterial(0, selfTable.m_clSkinTexture)
	end

	function SWEP:RemoveWeaponSkin(vm, owner)
		vm:SetSubMaterial(0)
	end

	local PLAYER = FindMetaTable("Player")
	---@diagnostic disable-next-line: need-check-nil
	local PLY_SteamID = PLAYER.SteamID
	local function optimized_GetBySteamID(id)
		id = string.upper(id)
		for _, ply in player.Iterator() do
			if PLY_SteamID(ply) == id then
				return ply
			end
		end

		return NULL
	end

	local ENTITY = FindMetaTable("Entity")
	local ENT_DrawModel = ENTITY.DrawModel
	local ENT_GetParent = ENTITY.GetParent
	local ENT_SetParent = ENTITY.SetParent
	local ENT_AddEffects = ENTITY.AddEffects

	local VIEWMODELADDON_EFFECTS = bit.bor(EF_NODRAW, EF_BONEMERGE, EF_BONEMERGE_FASTCULL)

	SWEP.m_viewmodelUidAddon = NULL
	SWEP.m_viewmodelStatTrakAddon = NULL
	function SWEP:CreateViewmodelAttachments(vm, econItem)
		local selfTable = self:GetTable()
		local bFlip = selfTable.ViewModelFlip

		-- stattrak
		if selfTable.SupportsStatTracks and econItem and econItem.bHasStatTrak then
			---@class Entity
			local statTrackClEnt = selfTable.m_viewmodelStatTrakAddon or NULL
			if not statTrackClEnt:IsValid() then
				statTrackClEnt = ClientsideModel(
					self:GetWeaponType() ~= "knife" and "models/weapons/csgo/stattrack.mdl" or "models/weapons/csgo/stattrack_cut.mdl",
					RENDERGROUP_VIEWMODEL)

				ENT_SetParent(statTrackClEnt, vm)
				ENT_AddEffects(statTrackClEnt, VIEWMODELADDON_EFFECTS)
				statTrackClEnt.m_Weapon = self

				selfTable.m_viewmodelStatTrakAddon = statTrackClEnt
				local strFormat = language.GetPhrase("swcs.weapon_name_stattrak")
				if strFormat == "swcs.weapon_name_stattrak" then strFormat = "StatTrak™ %s" end

				selfTable.PrintName = string.format(strFormat, language.GetPhrase(selfTable.PrintName))
			else
				-- full update
				if ENT_GetParent(statTrackClEnt) ~= vm then
					ENT_SetParent(statTrackClEnt, vm)
				end

				local iBodygroup = statTrackClEnt:GetBodygroup(0)
				if iBodygroup ~= -1 then
					if iBodygroup == 0 and bFlip then
						statTrackClEnt:SetBodygroup(0, 1)
					elseif iBodygroup == 1 and not bFlip then
						statTrackClEnt:SetBodygroup(0, 0)
					end
				end

				iBodygroup = statTrackClEnt:GetBodygroup(1)
				if iBodygroup ~= -1 then
					local ownerSID = self:GetOwner():SteamID()
					local originalOwnerSID = selfTable.GetOriginalOwnerSteamID(self)

					-- this stat trak weapon doesn't belong to the current holder, display error message on the digital display. This is impossible for knives
					if ownerSID ~= originalOwnerSID then
						statTrackClEnt:SetBodygroup(1, bFlip and 2 or 1) -- show the error screen bodygroup
					elseif iBodygroup ~= 0 then
						statTrackClEnt:SetBodygroup(1, 0)
					end
				end
			end
		end

		-- nametag
		if selfTable.SupportsNameTags and econItem and econItem.strCustomName and #econItem.strCustomName > 0 then
			local uidClEnt = selfTable.m_viewmodelUidAddon or NULL
			if not uidClEnt:IsValid() then
				local strModel = selfTable.ItemAttributes and selfTable.ItemAttributes["uid model"] or "models/weapons/csgo/uid.mdl"
				uidClEnt = ClientsideModel(strModel, RENDERGROUP_VIEWMODEL)
				ENT_SetParent(uidClEnt, vm)
				ENT_AddEffects(uidClEnt, VIEWMODELADDON_EFFECTS)
				uidClEnt.m_Weapon = self

				selfTable.m_viewmodelUidAddon = uidClEnt
				selfTable.PrintName = string.format("%q", econItem.strCustomName)
			else
				if ENT_GetParent(uidClEnt) ~= vm then
					ENT_SetParent(uidClEnt, vm)
				end

				local iBodygroup = uidClEnt:GetBodygroup(0)
				if iBodygroup ~= -1 then
					if iBodygroup == 0 and bFlip then
						uidClEnt:SetBodygroup(0, 1) -- use a special mirror-image that appears correct for lefties
					elseif iBodygroup == 1 and not bFlip then
						uidClEnt:SetBodygroup(0, 0)
					end
				end
			end
		end

		-- ownership in weapon print name
		local originalOwnerSteamID = selfTable.GetOriginalOwnerSteamID(self)
		if originalOwnerSteamID ~= self:GetOwner():SteamID() and not selfTable.bFetchedOwnerName then
			local originalOwner = optimized_GetBySteamID(originalOwnerSteamID)
			if IsValid(originalOwner) then
				selfTable.bFetchedOwnerName = true
				selfTable.strOwnerName = originalOwner:Nick()
				selfTable.PrintName = string.format("%s's %s", selfTable.strOwnerName, language.GetPhrase(selfTable.PrintName))
			else
				steamworks.RequestPlayerInfo(util.SteamIDTo64(originalOwnerSteamID), function(name)
					if not IsValid(self) then return end
					if selfTable.bFetchedOwnerName then return end

					selfTable.bFetchedOwnerName = true
					selfTable.strOwnerName = name
					selfTable.PrintName = string.format("%s's %s", selfTable.strOwnerName, language.GetPhrase(selfTable.PrintName))
				end)
			end
		end

		-- stickers?
	end

	function SWEP:RenderViewmodelAttachments(vm, econItem)
		local selfTable = self:GetTable()
		local bViewmodelFlip, bDrawn = selfTable.ViewModelFlip, false

		if bViewmodelFlip then
			render.CullMode(MATERIAL_CULLMODE_CW)
		end

		if econItem and econItem.bHasStatTrak and selfTable.m_viewmodelStatTrakAddon:IsValid() then
			ENT_DrawModel(selfTable.m_viewmodelStatTrakAddon)
			bDrawn = true
		end

		local bHasUID = econItem and econItem.strCustomName and #econItem.strCustomName > 0
		if bHasUID and selfTable.m_viewmodelUidAddon:IsValid() then
			ENT_DrawModel(selfTable.m_viewmodelUidAddon)
			bDrawn = true
		end

		if bDrawn and bViewmodelFlip then
			render.CullMode(MATERIAL_CULLMODE_CCW)
		end

		if bDrawn then
			render.RenderFlashlights(function()
				if bViewmodelFlip then
					render.CullMode(MATERIAL_CULLMODE_CW)
				end

				if econItem and econItem.bHasStatTrak and selfTable.m_viewmodelStatTrakAddon:IsValid() then
					ENT_DrawModel(selfTable.m_viewmodelStatTrakAddon)
				end

				if bHasUID and selfTable.m_viewmodelUidAddon:IsValid() then
					ENT_DrawModel(selfTable.m_viewmodelUidAddon)
				end

				if bViewmodelFlip then
					render.CullMode(MATERIAL_CULLMODE_CCW)
				end
			end)
		end
	end
end

function SWEP:NetworkPlayerEconData(owner)
	local econItem = self.m_econItem
	if not econItem then
		local ownerInv = swcs.econ.GetInventory(owner)
		if not ownerInv then return end

		econItem = ownerInv[self:GetClass()]
		if not econItem then return end

		self.m_econItem = table.Copy(econItem)
	end

	if SERVER then
		timer.Simple(0.1, function()
			if not owner:IsValid() then return end
			if not self:IsValid() then return end

			net.Start("swcs_econ")
			net.WriteUInt(3, 3) -- ECON_SEND_ITEM
			net.WriteEntity(self)

			net.WriteBool(econItem.bHasStatTrak)
			if econItem.bHasStatTrak then
				net.WriteUInt(econItem.iStatTrakScore, 32)
			end

			net.WriteString(econItem.strCustomName or "")

			-- anything else?
			net.Broadcast()
		end)
	end
end

--function SWEP:OnDrop(owner)
--	local phys = self:GetPhysicsObject()
--
--	print(owner, self, phys, phys:IsValid())
--end
