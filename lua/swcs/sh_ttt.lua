AddCSLuaFile()

local swcs = swcs
swcs.InTTT = true
swcs.ttt = swcs.ttt or {}

swcs.ttt.WeaponCategories = swcs.ttt.WeaponCategories or {}
swcs.ttt.AllWeapons = swcs.ttt.AllWeapons or {}

local ENABLE_WEAPON_REPLACE = CreateConVar("swcs_ttt_enable_replace", "1", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Enable replacing TTT weapons with SWCS weapons")
local IGNORE_WEAPON_CATEGORY = CreateConVar("swcs_ttt_ignore_category", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Ignores category for which weapons should be included for use in TTT")
local ALWAYS_REPLACE_CROWBAR = CreateConVar("swcs_ttt_always_replace_crowbar", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Always replace TTT crowbar with knives")
local DISABLE_REPLACE_CROWBAR = CreateConVar("swcs_ttt_disable_replace_crowbar", "0", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Disable replacing TTT crowbar with knives")
local PREVENT_OTHER_WEAPONS = CreateConVar("swcs_ttt_prevent_other_weapons", "1", {FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Prevent non-SWCS weapons from spawning")

local TAG = "swcs_ttt_list"

local NET_REQUEST_LIST = 0
local NET_RECEIVE_LIST = 1
local NET_FIX_ITEMS = 2
local NET_UPDATE_CVAR = 3

local cvar_ordinal = {
	[0] = ENABLE_WEAPON_REPLACE,
	IGNORE_WEAPON_CATEGORY,
	ALWAYS_REPLACE_CROWBAR,
	PREVENT_OTHER_WEAPONS,
	DISABLE_REPLACE_CROWBAR,
}

-- list of all weapons that will spawn in world when round starts
swcs.ttt.ActiveSpawnList = swcs.ttt.ActiveSpawnList or {}
swcs.ttt.ExternalWeapons = swcs.ttt.ExternalWeapons or {}

local OnListReceived

swcs.ttt.KnifeMap = swcs.ttt.KnifeMap or {
	[0] = "weapon_swcs_knife",
	"weapon_swcs_knife_ct",
	"weapon_swcs_knife_css",
	"weapon_swcs_knife_butterfly",
	"weapon_swcs_knife_canis",
	"weapon_swcs_knife_cord",
	"weapon_swcs_knife_falchion",
	"weapon_swcs_knife_gypsy_jackknife",
	"weapon_swcs_knife_outdoor",
	"weapon_swcs_knife_push",
	"weapon_swcs_knife_skeleton",
	"weapon_swcs_knife_stiletto",
	"weapon_swcs_knife_survival_bowie",
	"weapon_swcs_knife_ursus",
	"weapon_swcs_knife_widowmaker",
	"weapon_swcs_bayonet",
	"weapon_swcs_knife_flip",
	"weapon_swcs_knife_gut",
	"weapon_swcs_knife_karambit",
	"weapon_swcs_knife_m9_bayonet",
	"weapon_swcs_knife_tactical",
}

local to_disable = {
	["weapon_zm_improvised"] = true,
	["weapon_zm_mac10"] = true,
	["weapon_zm_pistol"] = true,
	["weapon_zm_revolver"] = true,
	["weapon_zm_rifle"] = true,
	["weapon_zm_shotgun"] = true,
	["weapon_zm_sledge"] = true,
	["weapon_ttt_glock"] = true,
	["weapon_ttt_m16"] = true,

	["weapon_ttt_sipistol"] = true,
	["weapon_ttt_stungun"] = true,
	["weapon_ttt_knife"] = true,
}

local function getupvalues(f)
	local i, t = 0, {}

	while true do
		i = i + 1
		local key, val = debug.getupvalue(f, i)
		if not key then break end
		t[key] = val
	end

	return t
end

if SERVER then
	util.AddNetworkString(TAG)

	local function SelectWeaponFromList(category)
		local ActiveList = {}

		for _, class in next, category do
			if not swcs.ttt.ActiveSpawnList[class] then continue end

			table.insert(ActiveList, class)
		end

		return table.Random(ActiveList)
	end

	local function ReplaceSMG(ent)
		return SelectWeaponFromList(swcs.ttt.WeaponCategories.submachinegun)
	end
	local function ReplaceShotgun(ent)
		return SelectWeaponFromList(swcs.ttt.WeaponCategories.shotgun)
	end
	local function ReplaceRifle(ent)
		return SelectWeaponFromList(swcs.ttt.WeaponCategories.rifle)
	end
	local function ReplaceSniperRifle(ent)
		return SelectWeaponFromList(swcs.ttt.WeaponCategories.sniperrifle)
	end
	local function ReplacePistol(ent)
		return SelectWeaponFromList(swcs.ttt.WeaponCategories.pistol)
	end
	local function ReplaceMachineGun(ent)
		return SelectWeaponFromList(swcs.ttt.WeaponCategories.machinegun)
	end
	local function ReplaceDeagle(ent)
		return SelectWeaponFromList(swcs.ttt.WeaponCategories.heavy_pistol)
	end

	swcs.ttt.weapon_replace = {
		["weapon_zm_mac10"] = ReplaceSMG,
		["weapon_zm_shotgun"] = ReplaceShotgun,
		["weapon_ttt_m16"] = ReplaceRifle,
		["weapon_zm_rifle"] = ReplaceSniperRifle,
		["weapon_zm_pistol"] = ReplacePistol,
		["weapon_ttt_glock"] = ReplacePistol,
		["weapon_zm_sledge"] = ReplaceMachineGun,
		["weapon_zm_revolver"] = ReplaceDeagle,
		["weapon_zm_molotov"] = function()
			return math.random(0, 1) == 0 and "weapon_swcs_molotov" or "weapon_swcs_incgrenade"
		end,
		["weapon_ttt_smokegrenade"] = "weapon_swcs_smokegrenade",
		["weapon_ttt_confgrenade"] = "weapon_swcs_flashbang", -- not sorry
	}

	function swcs.ttt.ReplaceSingle(ent, newname)
		-- Ammo that has been mapper-placed will not have a pos yet at this point for
		-- reasons that have to do with being really annoying. So don't touch those
		-- so we can replace them later. Grumble grumble.
		if ent:GetPos() == vector_origin then
			return
		end

		ent:SetSolid(SOLID_NONE)

		local rent = ents.Create(newname)
		rent:SetPos(ent:GetPos())
		rent:SetAngles(ent:GetAngles())
		rent:Spawn()

		rent:Activate()
		rent:PhysWake()

		ent:Remove()
	end

	function swcs.ttt.ReplaceWeaponSingle(ent, cls)
		-- Loadout weapons immune
		-- we use a SWEP-set property because at this state all SWEPs identify as weapon_swep
		if ent.AllowDelete == false then
			return
		else
			if cls == nil then cls = ent:GetClass() end

			local rpl = swcs.ttt.weapon_replace[cls]
			if isfunction(rpl) then
				rpl = rpl(ent)
			end

			if rpl then
				swcs.ttt.ReplaceSingle(ent, rpl)
			elseif rpl == false then
				if not ent:GetPos():IsZero() then
					ent:Remove()
				end
			end
		end
	end

	function swcs.ttt.ReplaceWeapons()
		for _, ent in ipairs(ents.FindByClass("weapon_*")) do
			swcs.ttt.ReplaceWeaponSingle(ent)
		end
	end

	hook.Add("OnEntityCreated", "swcs.ttt", function(ent)
		if not ENABLE_WEAPON_REPLACE:GetBool() then return end
		if not ent:IsValid() then return end

		local class = ent:GetClass()
		if class:sub(1, 6) ~= "weapon" then return end
		if weapons.IsBasedOn(class, "weapon_swcs_base") then return end

		timer.Simple(0, function()
			if ent:IsValid() then
				swcs.ttt.ReplaceWeaponSingle(ent, class)
			end
		end)
		return true
	end)

	local function AddTTTSpawnableSWEPs()
		local ActiveList = ents.TTT and ents.TTT.GetSpawnableSWEPs and ents.TTT.GetSpawnableSWEPs() or {}

		-- remove our old weps from current TTT spawnlist
		local new_list = {}
		for k, v in next, ActiveList do
			if swcs.ttt.AllWeapons[v.ClassName] then continue end
			if ENABLE_WEAPON_REPLACE:GetBool() and PREVENT_OTHER_WEAPONS:GetBool() and not swcs.ttt.weapon_replace[v.ClassName] then
				swcs.ttt.ExternalWeapons[v.ClassName] = true
				continue
			end

			new_list[#new_list + 1] = v
		end

		--[[local k, v = nil, nil
		repeat
			local this
			this, v = next(ActiveList, k)

			if v then
				print(v.ClassName)
			 	if swcs.ttt.AllWeapons[v.ClassName] then
			 		print("removing", v.ClassName)
					ActiveList[this] = nil
				elseif ENABLE_WEAPON_REPLACE:GetBool() and not swcs.ttt.weapon_replace[v.ClassName] then
					print("removing external", v.ClassName)
					ActiveList[this] = nil
				else
					k = this
				end
			else
				k = this
			end
		until not k--]]

		-- add our new weps to current TTT spawnlist
		if ENABLE_WEAPON_REPLACE:GetBool() then
			for class, on in next, swcs.ttt.ActiveSpawnList do
				if not on then continue end

				new_list[#new_list + 1] = weapons.Get(class)
			end
		end

		if not ENABLE_WEAPON_REPLACE:GetBool() or not PREVENT_OTHER_WEAPONS:GetBool() then
			local has = {}

			for _, wep in next, ActiveList do
				if not swcs.ttt.ExternalWeapons[wep.ClassName] and not to_disable[wep.ClassName] then continue end
				has[wep.ClassName] = true
			end

			for class in next, swcs.ttt.ExternalWeapons do
				if has[class] then continue end

				new_list[#new_list + 1] = weapons.Get(class)
			end
		end

		table.Empty(ActiveList)
		table.Add(ActiveList, new_list)
	end

	local function SetupWeaponList()
		local weps = swcs.ttt.ActiveSpawnList

		-- migrate
		if file.Exists("swcs_ttt_weaponlist.dat", "DATA") then
			if not file.IsDir("swcs", "DATA") then
				file.CreateDir("swcs")
			end

			local Input = file.Open("swcs_ttt_weaponlist.dat", "rb", "DATA")
			local Output = file.Open("swcs/ttt_weaponlist.dat", "wb", "DATA")
			Output:Write(Input:Read())
			Output:Close()
			Input:Close()

			file.Delete("swcs_ttt_weaponlist.dat")
		end

		if file.Exists("swcs/ttt_weaponlist.dat", "DATA") then
			local File = file.Open("swcs/ttt_weaponlist.dat", "rb", "DATA")

			repeat
				local char = File:Read(1)

				if char == "#" then -- comment
					repeat until File:Read(1) == "\n"
				else -- assume we're in an entry
					File:Skip(-1)
					local strSize = File:ReadByte()
					local weaponClass = File:Read(strSize)
					local bEnabled = File:ReadBool()
					File:Skip(1)

					local wepTable = weapons.Get(weaponClass)

					if not IGNORE_WEAPON_CATEGORY:GetBool() and (wepTable and wepTable.Category ~= "#spawnmenu.category.swcs") then
						weps[weaponClass] = nil
					else
						weps[weaponClass] = bEnabled
					end
				end
			until File:Tell() >= File:Size()

			-- fix for new weapons not being recognized
			for class in next, swcs.ttt.AllWeapons do
				local wep = weapons.Get(class)

				if not wep then
					weps[class] = nil
					continue
				end

				if not IGNORE_WEAPON_CATEGORY:GetBool() and wep.Category ~= "#spawnmenu.category.swcs" then
					weps[class] = nil
					continue
				end

				-- filter items out
				if wep.CanBuy ~= nil or wep._CanBuy ~= nil then
					weps[class] = nil
					continue
				end

				if weps[class] then continue end
				weps[class] = false
			end

			-- fix for old weapons not being removed
			for class in next, weps do
				local wep = weapons.Get(class)
				if not IGNORE_WEAPON_CATEGORY:GetBool() and wep.Category ~= "#spawnmenu.category.swcs" then
					weps[class] = nil
					continue
				end
				if swcs.ttt.AllWeapons[class] then continue end
				weps[class] = nil
			end
		else
			for _, wep in ipairs(weapons.GetList()) do
				if not swcs.ttt.AllWeapons[wep.ClassName] then continue end
				if wep.TTTPreventSpawning then continue end
				if not IGNORE_WEAPON_CATEGORY:GetBool() and wep.Category ~= "#spawnmenu.category.swcs" then continue end

				if wep.AutoSpawnable == false or wep.InLoadoutFor or wep.CanBuy then
					weps[wep.ClassName] = false
				else
					weps[wep.ClassName] = true
				end
			end
		end
	end

	-- swcs.ttt.AllWeapons and swcs.ttt.WeaponCategories are populated
	-- fill out swcs.ttt.ActiveSpawnList
	hook.Add("SWCSTTTWeaponsReady", "swcs.ttt", function()
		local loadout_upvalues = getupvalues(GAMEMODE.PlayerLoadout)
		local glw_upvalues = getupvalues(loadout_upvalues.GetGiveLoadoutWeapons or loadout_upvalues.GiveLoadoutWeapons)
		local GetLoadoutWeapons = glw_upvalues.GetLoadoutWeapons

		local function UpdateMeleeReplacement()
			local KNIFE = weapons.GetStored("weapon_swcs_knife")

			KNIFE.InLoadoutFor = KNIFE.InLoadoutFor or {}

			local bWeaponsReplaced = ENABLE_WEAPON_REPLACE:GetBool()
			local bMeleeReplaced = false

			if bWeaponsReplaced then
				bMeleeReplaced = not DISABLE_REPLACE_CROWBAR:GetBool()
			else
				bMeleeReplaced = ALWAYS_REPLACE_CROWBAR:GetBool()
			end

			if bMeleeReplaced then
				KNIFE.InLoadoutFor = {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE}
				table.insert(GetLoadoutWeapons(ROLE_INNOCENT), 1, "weapon_swcs_knife")
				table.insert(GetLoadoutWeapons(ROLE_TRAITOR), 1, "weapon_swcs_knife")
				table.insert(GetLoadoutWeapons(ROLE_DETECTIVE), 1, "weapon_swcs_knife")
			else
				table.RemoveByValue(GetLoadoutWeapons(ROLE_INNOCENT), "weapon_swcs_knife")
				table.RemoveByValue(GetLoadoutWeapons(ROLE_TRAITOR), "weapon_swcs_knife")
				table.RemoveByValue(GetLoadoutWeapons(ROLE_DETECTIVE), "weapon_swcs_knife")

				table.Empty(KNIFE.InLoadoutFor)
			end
		end

		cvars.AddChangeCallback("swcs_ttt_enable_replace", function(name, old, new)
			local bool = tobool(new)
			local KNIFE = weapons.GetStored("weapon_swcs_knife")

			KNIFE.InLoadoutFor = KNIFE.InLoadoutFor or {}

			if bool then
				if not DISABLE_REPLACE_CROWBAR:GetBool() then
					KNIFE.InLoadoutFor = {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE}
					table.insert(GetLoadoutWeapons(ROLE_INNOCENT), 1, "weapon_swcs_knife")
					table.insert(GetLoadoutWeapons(ROLE_TRAITOR), 1, "weapon_swcs_knife")
					table.insert(GetLoadoutWeapons(ROLE_DETECTIVE), 1, "weapon_swcs_knife")
				end

				for _, wep in ipairs(weapons.GetList()) do
					local bIsGrenade = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base_grenade")
					local bIsSWCSWep = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base")

					if bIsSWCSWep or bIsGrenade then
						if not IGNORE_WEAPON_CATEGORY:GetBool() and wep.Category ~= "#spawnmenu.category.swcs" then continue end

						wep.CanBuy = wep._CanBuy
						wep.AutoSpawnable = wep._AutoSpawnable
					elseif to_disable[wep.ClassName] then
						wep.CanBuy = nil
						wep.AutoSpawnable = false
					end
				end

				if not DISABLE_REPLACE_CROWBAR:GetBool() then
					scripted_ents.GetStored("ttt_knife_proj").t.Model = Model"models/weapons/csgo/w_knife_gg.mdl"
				end
			elseif bool == false then
				if not ALWAYS_REPLACE_CROWBAR:GetBool() then
					table.RemoveByValue(GetLoadoutWeapons(ROLE_INNOCENT), "weapon_swcs_knife")
					table.RemoveByValue(GetLoadoutWeapons(ROLE_TRAITOR), "weapon_swcs_knife")
					table.RemoveByValue(GetLoadoutWeapons(ROLE_DETECTIVE), "weapon_swcs_knife")

					table.Empty(KNIFE.InLoadoutFor)
				end

				for _, wep in ipairs(weapons.GetList()) do
					local bIsGrenade = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base_grenade")
					local bIsSWCSWep = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base")

					if bIsSWCSWep or bIsGrenade then
						if wep.ClassName == "weapon_swcs_knife_gg" and ALWAYS_REPLACE_CROWBAR:GetBool() then continue end
						wep.CanBuy = nil
						wep.AutoSpawnable = false
					elseif to_disable[wep.ClassName] then
						if wep.ClassName == "weapon_ttt_knife" and ALWAYS_REPLACE_CROWBAR:GetBool() then continue end
						wep.CanBuy = wep._CanBuy
						wep.AutoSpawnable = wep._AutoSpawnable
					end
				end

				if not ALWAYS_REPLACE_CROWBAR:GetBool() then
					scripted_ents.GetStored("ttt_knife_proj").t.Model = Model"models/weapons/w_knife_t.mdl"
				end
			end

			AddTTTSpawnableSWEPs()

			-- NB: garrysmod-issues#3740
			net.Start(TAG)
			net.WriteInt(NET_FIX_ITEMS, 4)
			net.Broadcast()
		end, "swcs.ttt")

		cvars.AddChangeCallback("swcs_ttt_always_replace_crowbar", function(name, old, new)
			UpdateMeleeReplacement()

			-- NB: garrysmod-issues#3740
			net.Start(TAG)
			net.WriteInt(NET_FIX_ITEMS, 4)
			net.Broadcast()
		end, "swcs.ttt")

		cvars.AddChangeCallback("swcs_ttt_disable_replace_crowbar", function(name, old, new)
			UpdateMeleeReplacement()
		end, "swcs.ttt")

		local KNIFE = weapons.GetStored("weapon_swcs_knife")
		KNIFE.InLoadoutFor = KNIFE.InLoadoutFor or {}

		local bool

		if ENABLE_WEAPON_REPLACE:GetBool() then
			bool = not DISABLE_REPLACE_CROWBAR:GetBool()
		else
			bool = ALWAYS_REPLACE_CROWBAR:GetBool()
		end

		if bool then
			KNIFE.InLoadoutFor = {ROLE_INNOCENT, ROLE_TRAITOR, ROLE_DETECTIVE}
			table.insert(GetLoadoutWeapons(ROLE_INNOCENT), 1, "weapon_swcs_knife")
			table.insert(GetLoadoutWeapons(ROLE_TRAITOR), 1, "weapon_swcs_knife")
			table.insert(GetLoadoutWeapons(ROLE_DETECTIVE), 1, "weapon_swcs_knife")
		else
			table.RemoveByValue(GetLoadoutWeapons(ROLE_INNOCENT), "weapon_swcs_knife")
			table.RemoveByValue(GetLoadoutWeapons(ROLE_TRAITOR), "weapon_swcs_knife")
			table.RemoveByValue(GetLoadoutWeapons(ROLE_DETECTIVE), "weapon_swcs_knife")

			table.Empty(KNIFE.InLoadoutFor)
		end

		SetupWeaponList()
		cvars.AddChangeCallback("swcs_ttt_ignore_category", function(name, old, new)
			SetupWeaponList()
		end, "swcs.ttt")

		AddTTTSpawnableSWEPs()
		cvars.AddChangeCallback("swcs_ttt_prevent_other_weapons", function(name, old, new)
			AddTTTSpawnableSWEPs()
		end, "swcs.ttt")

		-- ive spent like 3 hours trying to figure out how to add them to TTT2
		-- without doing this and couldnt
		if WEPS.GetWeaponsForSpawnTypes and not WEPS._GetWeaponsForSpawnTypes then
			WEPS._GetWeaponsForSpawnTypes = WEPS.GetWeaponsForSpawnTypes

			WEPS.GetWeaponsForSpawnTypes = function()
				local wepsForSpawns, wepsTable = WEPS._GetWeaponsForSpawnTypes()

				-- add our new weps to current TTT spawnlist
				if ENABLE_WEAPON_REPLACE:GetBool() then
					for class, on in next, swcs.ttt.ActiveSpawnList do
						if not on then continue end

						local wep = weapons.Get(class)
						local spawnType = wep.spawnType

						wepsTable[#wepsTable + 1] = wep

						if not spawnType then continue end

						wepsForSpawns[spawnType] = wepsForSpawns[spawnType] or {}
						wepsForSpawns[spawnType][#wepsForSpawns[spawnType] + 1] = wep
					end
				end

				return wepsForSpawns, wepsTable
			end
		end
	end)

	OnListReceived = function(weps)
		if not file.IsDir("swcs", "DATA") then
			file.CreateDir("swcs")
		end

		local File = file.Open("swcs/ttt_weaponlist.dat", "wb", "DATA")
		File:Write("# This file is generated by SWCS. Do not edit it manually.\n")

		for wep, on in next, weps do
			File:WriteByte(#wep)
			File:Write(wep)
			File:WriteBool(on)
			File:Write("\n")
		end

		File:Close()

		AddTTTSpawnableSWEPs()
	end

	local function GivePreferredKnife(ply)
		local classname = "weapon_swcs_knife"
		if ply:IsBot() then
			classname = table.Random(swcs.ttt.KnifeMap)
		else
			local KNIFE_MODEL = ply:GetInfoNum("swcs_ttt_knife", 0)
			local target_knife = swcs.ttt.KnifeMap[KNIFE_MODEL]
			if KNIFE_MODEL ~= 0 and target_knife then
				classname = target_knife
			end
		end

		ply:Give(classname)
	end

	hook.Add("PlayerLoadout", "swcs.ttt.knife", function(ply)
		if ENABLE_WEAPON_REPLACE:GetBool() then
			if DISABLE_REPLACE_CROWBAR:GetBool() then return end
		else
			if not ALWAYS_REPLACE_CROWBAR:GetBool() then return end
		end

		-- lazy ttt custom roles compat
		timer.Simple(0, function()
			if ply:IsValid() then
				if ply:HasWeapon("weapon_zm_improvised") then
					ply:StripWeapon("weapon_zm_improvised")
					GivePreferredKnife(ply)
				elseif ply:HasWeapon("weapon_swcs_knife") then
					ply:StripWeapon("weapon_swcs_knife")
					GivePreferredKnife(ply)
				end
			end
		end)
	end)
elseif CLIENT then
	local KNIFE_MODEL = CreateClientConVar("swcs_ttt_knife", "0", true, true, "", 0, #swcs.ttt.KnifeMap)

	---@class DFrame
	local Editor = nil

	OnListReceived = function(weps)
		if IsValid(Editor) and Editor.WaitingForList then
			Editor.WaitingForList = false

			for class, on in next, weps do
				---@class Panel should be DListView_Line but that's not defined as extending Panel
				local line

				local wep = weapons.Get(class)
				--local name = wep.PrintName
				--if wep.Category ~= "#spawnmenu.category.swcs" then
				--	name = name .. " [" .. wep.Category .. "]"
				--end

				if on then
					line = Editor.AllowedListPanel:AddLine(wep.PrintName, wep.Category)
				else
					line = Editor.DisallowedListPanel:AddLine(wep.PrintName, wep.Category)
				end

				line.WeaponClass = class
			end
		end
	end

	local function OpenSpawnlistEditor()
		if IsValid(Editor) then
			Editor:Close()
			Editor:Remove()
		end

		Editor = vgui.Create("DFrame")
		--Editor.ActiveList = {}
		--Editor.InactiveList = {}

		Editor:SetTitle("#swcs.ttt_spawnlist_editor.title")
		Editor:SetSize(ScrW() * 0.5, ScrH() * 0.5)
		Editor:Center()
		Editor:MakePopup()

		---@class DButton
		local UploadButton = vgui.Create("DButton", Editor)
		Editor.UploadButton = UploadButton
		UploadButton:Dock(BOTTOM)
		UploadButton:SetText("#swcs.ttt_spawnlist_editor.upload")

		local body = vgui.Create("DHorizontalDivider", Editor)
		body:Dock(FILL)
		body:SetDividerWidth(4)
		body:SetLeftWidth(Editor:GetWide() * 0.5)

		local left, right = vgui.Create("DPanel", body), vgui.Create("DPanel", body)

		body:SetLeft(left)
		body:SetRight(right)

		do -- left side / allowed list
			-- label
			local label = vgui.Create("DLabel", left)
			label:SetText("#swcs.ttt_spawnlist_editor.allowed_title")
			label:SetFont("DermaLarge")
			label:SetDark(true)
			label:SetContentAlignment(5)
			label:DockMargin(0, 4, 0, 4)
			label:Dock(TOP)

			---@class DListView
			local List = vgui.Create("DListView", left)
			Editor.AllowedListPanel = List
			List:Dock(FILL)
			List:AddColumn("#weapon")
			List:AddColumn("#category")

			function List:OnRowRightClick(line, panel)
				local menu = DermaMenu(false, panel)

				local selected = self:GetSelected()
				if #selected > 1 then
					menu:AddOption("#swcs.ttt_spawnlist_editor.remove_selected_multiple", function()
						for _, linePan in ipairs(selected) do
							local oppositeLine = Editor.DisallowedListPanel:AddLine(linePan:GetValue(1), linePan:GetValue(2))
							oppositeLine.WeaponClass = linePan.WeaponClass
							List:RemoveLine(linePan:GetID())
						end
					end):SetIcon("icon16/delete.png")
				else
					menu:AddOption("#swcs.ttt_spawnlist_editor.remove_selected_one", function()
						local oppositeLine = Editor.DisallowedListPanel:AddLine(panel:GetValue(1), panel:GetValue(2))
						oppositeLine.WeaponClass = panel.WeaponClass
						List:RemoveLine(line)
					end):SetIcon("icon16/delete.png")
				end

				menu:Open()
			end
		end

		do -- right side / disallowed list
			-- label
			local label = vgui.Create("DLabel", right)
			label:SetText("#swcs.ttt_spawnlist_editor.disallowed_title")
			label:SetFont("DermaLarge")
			label:SetDark(true)
			label:SetContentAlignment(5)
			label:DockMargin(0, 4, 0, 4)
			label:Dock(TOP)

			local List = vgui.Create("DListView", right)
			Editor.DisallowedListPanel = List
			List:Dock(FILL)
			List:AddColumn("#weapon")
			List:AddColumn("#category")

			function List:OnRowRightClick(line, panel)
				local menu = DermaMenu(false, panel)

				local selected = self:GetSelected()
				if #selected > 1 then
					menu:AddOption("#swcs.ttt_spawnlist_editor.add_selected_multiple", function()
						for _, linePan in ipairs(selected) do
							local oppositeLine = Editor.AllowedListPanel:AddLine(linePan:GetValue(1), linePan:GetValue(2))
							oppositeLine.WeaponClass = linePan.WeaponClass
							List:RemoveLine(linePan:GetID())
						end
					end):SetIcon("icon16/add.png")
				else
					menu:AddOption("#swcs.ttt_spawnlist_editor.add_selected_one", function()
						local oppositeLine = Editor.AllowedListPanel:AddLine(panel:GetValue(1), panel:GetValue(2))
						oppositeLine.WeaponClass = panel.WeaponClass
						List:RemoveLine(line)
					end):SetIcon("icon16/add.png")
				end

				menu:Open()
			end
		end

		function UploadButton:DoClick()
			local SendList = {}

			for _, line in next, Editor.AllowedListPanel:GetLines() do
				SendList[line.WeaponClass] = true
			end
			for _, line in next, Editor.DisallowedListPanel:GetLines() do
				SendList[line.WeaponClass] = false
			end

			net.Start(TAG)
			net.WriteUInt(NET_RECEIVE_LIST, 4)
			net.WriteUInt(table.Count(SendList), 8)

			for wep, on in next, SendList do
				net.WriteString(wep)
				net.WriteBool(on)
			end
			net.SendToServer()
		end

		Editor.WaitingForList = true
		net.Start(TAG)
		net.WriteUInt(NET_REQUEST_LIST, 4)
		net.SendToServer()
	end

	hook.Add("TTTSettingsTabs", "swcs.tab", function(prop)
		local settings = vgui.Create("DPanelList", prop)
		settings:StretchToParent(0, 0, 15, 0)
		settings:EnableVerticalScrollbar()
		settings:SetPadding(10)
		settings:SetSpacing(10)

		prop:AddSheet("SWCS", settings, "icon16/gun.png", false, false, "Configure settings for CS:GO weapons")

		local sv_settings = vgui.Create("DForm", settings)
		do
			sv_settings:SetLabel("#spawnmenu.menu.swcs.sv_settings_name")
			---@class DCheckBox
			local enable_replace = sv_settings:CheckBox("#swcs.ttt_sv_cvar_enable_replace.label", "swcs_ttt_enable_replace")
			enable_replace:SetTooltip("#swcs.ttt_sv_cvar_enable_replace.help")
			---@class DCheckBox
			local disable_replace_crowbar = sv_settings:CheckBox("#swcs.ttt_sv_cvar_disable_replace_crowbar.label", "swcs_ttt_disable_replace_crowbar")
			disable_replace_crowbar:SetTooltip("#swcs.ttt_sv_cvar_disable_replace_crowbar.help")
			---@class DCheckBox
			local always_replace_crowbar = sv_settings:CheckBox("#swcs.ttt_sv_cvar_always_replace_crowbar.label", "swcs_ttt_always_replace_crowbar")
			always_replace_crowbar:SetTooltip("#swcs.ttt_sv_cvar_always_replace_crowbar.help")
			---@class DCheckBox
			local ignore_category = sv_settings:CheckBox("#swcs.ttt_sv_cvar_ignore_category.label", "swcs_ttt_ignore_category")
			ignore_category:SetTooltip("#swcs.ttt_sv_cvar_ignore_category.help")
			---@class DCheckBox
			local prevent_other_weapons = sv_settings:CheckBox("#swcs.ttt_sv_cvar_prevent_others.label", "swcs_ttt_prevent_other_weapons")

			local bEnabled = IsValid(LocalPlayer()) and LocalPlayer():IsAdmin()
			local bIsListenServerHost = IsValid(LocalPlayer()) and LocalPlayer():IsListenServerHost()

			enable_replace:SetEnabled(bEnabled)
			always_replace_crowbar:SetEnabled(bEnabled)
			ignore_category:SetEnabled(bEnabled)
			prevent_other_weapons:SetEnabled(bEnabled)
			disable_replace_crowbar:SetEnabled(bEnabled)

			enable_replace.OnChange = function(self, new)
				if bEnabled and not bIsListenServerHost then
					net.Start(TAG)
					net.WriteUInt(NET_UPDATE_CVAR, 4)
					net.WriteUInt(0, 4)
					net.WriteBool(new)
					net.SendToServer()
				end
			end
			ignore_category.OnChange = function(self, new)
				if bEnabled and not bIsListenServerHost then
					net.Start(TAG)
					net.WriteUInt(NET_UPDATE_CVAR, 4)
					net.WriteUInt(1, 4)
					net.WriteBool(new)
					net.SendToServer()
				end
			end
			always_replace_crowbar.OnChange = function(self, new)
				if bEnabled and not bIsListenServerHost then
					net.Start(TAG)
					net.WriteUInt(NET_UPDATE_CVAR, 4)
					net.WriteUInt(2, 4)
					net.WriteBool(new)
					net.SendToServer()
				end
			end
			prevent_other_weapons.OnChange = function(self, new)
				if bEnabled and not bIsListenServerHost then
					net.Start(TAG)
					net.WriteUInt(NET_UPDATE_CVAR, 4)
					net.WriteUInt(3, 4)
					net.WriteBool(new)
					net.SendToServer()
				end
			end
			disable_replace_crowbar.OnChange = function(self, new)
				if bEnabled and not bIsListenServerHost then
					net.Start(TAG)
					net.WriteUInt(NET_UPDATE_CVAR, 4)
					net.WriteUInt(4, 4)
					net.WriteBool(new)
					net.SendToServer()
				end
			end

			---@class DButton
			local but = sv_settings:Button("#swcs.ttt_spawnlist_editor.open", "")
			but:SetEnabled(bEnabled)
			but.DoClick = function()
				if not IsValid(LocalPlayer()) or not LocalPlayer():IsAdmin() then return end

				OpenSpawnlistEditor()
			end

			settings:AddItem(sv_settings)
		end

		local cl_settings = vgui.Create("DForm", settings)
		do
			cl_settings:SetLabel("#spawnmenu.menu.swcs.cl_settings_name")

			local knife_box = cl_settings:ComboBox("#swcs.ttt_cl_cvar_knife.label", "swcs_ttt_knife")
			for i, knife in pairs(swcs.ttt.KnifeMap) do
				local wep = weapons.Get(knife)
				knife_box:AddChoice(wep and wep.PrintName or knife, i, KNIFE_MODEL:GetInt() == i)
			end

			cl_settings:Help("#swcs.ttt_cl_cvar_knife.help")

			settings:AddItem(cl_settings)
		end
	end)

	-- ttt copypaste
	function RebuildEquipmentCache()
		-- start with all the non-weapon goodies
		local tbl = table.Copy(EquipmentItems)

		-- find buyable weapons to load info from
		for _, wep in pairs(weapons.GetList()) do
			if wep and wep.CanBuy then
				local data = wep.EquipMenuData or {}
				local base = {
					id       = WEPS.GetClass(wep),
					name     = wep.PrintName or "Unnamed",
					limited  = wep.LimitedStock,
					kind     = wep.Kind or WEAPON_NONE,
					slot     = (wep.Slot or 0) + 1,
					material = wep.Icon or "vgui/ttt/icon_id",
					-- the below should be specified in EquipMenuData, in which case
					-- these values are overwritten
					type     = "Type not specified",
					model    = "models/weapons/w_bugbait.mdl",
					desc     = "No description specified.",
				};

				-- Force material to nil so that model key is used when we are
				-- explicitly told to do so (ie. material is false rather than nil).
				if data.modelicon then
					base.material = nil
				end

				table.Merge(base, data)

				-- add this buyable weapon to all relevant equipment tables
				for _, r in pairs(wep.CanBuy) do
					table.insert(tbl[r], base)
				end
			end
		end

		-- mark custom items
		for r, is in pairs(tbl) do
			for _, i in pairs(is) do
				if i and i.id then
					i.custom = not table.HasValue(DefaultEquipment[r], i.id)
				end
			end
		end

		return tbl
	end

	-- prevent knives from bogging down the menu
	hook.Add("TTT2ModifyShopEditorIgnoreEquip", "swcs", function(tbl)
		for _, class in ipairs(swcs.ttt.KnifeMap) do
			tbl[class] = true
		end
	end)

	hook.Add("HUDShouldDraw", "swcs.targetid", function(name)
		if name == "TTTTargetID" then
			---@diagnostic disable-next-line: redundant-parameter
			local trace = LocalPlayer():GetEyeTrace(MASK_SHOT)

			if trace.Entity:IsValid() and swcs.IsLineBlockedBySmoke(trace.StartPos, trace.HitPos, 1) then
				return false
			end
		end
	end)
end

net.Receive(TAG, function(len, ply)
	local what = net.ReadUInt(4)

	if what == NET_REQUEST_LIST and SERVER then
		local to_send = {}
		for class, on in next, swcs.ttt.ActiveSpawnList do
			-- in TTT2, CanBuy exists on all weapons as an empty table
			-- but using weapons.Get adds BaseClass spam which would break count check
			local wep = weapons.GetStored(class)
			if wep.CanBuy and #wep.CanBuy > 0 or wep._CanBuy and #wep._CanBuy > 0 then continue end

			to_send[class] = on
		end

		net.Start(TAG)
		net.WriteUInt(NET_RECEIVE_LIST, 4)
		net.WriteUInt(table.Count(to_send), 8)

		for class, on in next, to_send do
			net.WriteString(class)
			net.WriteBool(on)
		end
		net.Send(ply)
	elseif what == NET_RECEIVE_LIST and (CLIENT or (SERVER and ply:IsAdmin())) then
		local count = net.ReadUInt(8)

		local WepList = swcs.ttt.ActiveSpawnList
		local known = {}
		for i = 1, count do
			local str = net.ReadString()
			local on = net.ReadBool()
			known[str] = true
			WepList[str] = on
		end

		for wep in next, WepList do
			if known[wep] then continue end
			WepList[wep] = nil
		end

		if isfunction(OnListReceived) then
			OnListReceived(WepList)
		end
	elseif what == NET_FIX_ITEMS and CLIENT then -- NB: garrysmod-issues#3740
		local new = ENABLE_WEAPON_REPLACE:GetBool()
		local bool = tobool(new)

		if bool then
			for _, wep in ipairs(weapons.GetList()) do
				local bIsGrenade = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base_grenade")
				local bIsSWCSWep = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base")

				if bIsSWCSWep or bIsGrenade then
					if not IGNORE_WEAPON_CATEGORY:GetBool() and wep.Category ~= "#spawnmenu.category.swcs" then continue end

					wep.CanBuy = wep._CanBuy
					wep.AutoSpawnable = wep._AutoSpawnable
				elseif to_disable[wep.ClassName] then
					wep.CanBuy = nil
					wep.AutoSpawnable = false
				end
			end

			scripted_ents.GetStored("ttt_knife_proj").t.Model = Model"models/weapons/csgo/w_knife_gg.mdl"
		elseif bool == false then
			for _, wep in ipairs(weapons.GetList()) do
				local bIsGrenade = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base_grenade")
				local bIsSWCSWep = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base")

				if bIsSWCSWep or bIsGrenade then
					if wep.ClassName == "weapon_swcs_knife_gg" and ALWAYS_REPLACE_CROWBAR:GetBool() then continue end
					wep.CanBuy = nil
					wep.AutoSpawnable = false
				elseif to_disable[wep.ClassName] then
					if wep.ClassName == "weapon_ttt_knife" and ALWAYS_REPLACE_CROWBAR:GetBool() then continue end
					wep.CanBuy = wep._CanBuy
					wep.AutoSpawnable = wep._AutoSpawnable
				end
			end

			if not ALWAYS_REPLACE_CROWBAR:GetBool() then
				scripted_ents.GetStored("ttt_knife_proj").t.Model = Model"models/weapons/w_knife_t.mdl"
			end
		end

		local Equipment = getupvalues(GetEquipmentForRole).Equipment
		if Equipment ~= nil then
			table.Empty(Equipment)
			table.Add(Equipment, RebuildEquipmentCache())
		end
	elseif what == NET_UPDATE_CVAR and (SERVER and ply:IsAdmin()) then
		local ordinal = net.ReadUInt(4)
		local new = net.ReadBool()

		if not cvar_ordinal[ordinal] then return end

		cvar_ordinal[ordinal]:SetBool(new)
	end
end)

hook.Add("PreGamemodeLoaded", "swcs.ttt_init", function()
	-- add our weps to auto spawn :)
	for _, wep in ipairs(weapons.GetList()) do
		local bIsGrenade = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base_grenade")
		local bIsSWCSWep = weapons.IsBasedOn(wep.ClassName, "weapon_swcs_base")

		if bIsSWCSWep or bIsGrenade then
			wep._CanBuy = wep.CanBuy
			wep._AutoSpawnable = wep.AutoSpawnable

			if not ENABLE_WEAPON_REPLACE:GetBool() and (ALWAYS_REPLACE_CROWBAR:GetBool() and wep.ClassName ~= "weapon_swcs_knife_gg") then
				wep.CanBuy = nil
			end

			if CLIENT then
				local mat = Material("vgui/ttt/" .. wep.ClassName)
				if not mat:IsError() then
					wep.Icon = wep.Icon or ("vgui/ttt/" .. wep.ClassName)
				end
			end

			if not wep.Spawnable then continue end
			if wep.IsKnife then
				wep.Kind = WEAPON_MELEE
				wep.Slot = 0
				continue
			end
			--if t.TTTPreventSpawning then continue end

			local ItemVisuals = util.KeyValuesToTable(wep.ItemDefVisuals or "", true, false)
			local ItemAttributes = util.KeyValuesToTable(wep.ItemDefAttributes or "", true, false)

			local weapon_type = string.lower(ItemVisuals["weapon_type"] or "")

			if weapon_type == "" then continue end
			if wep.TTTIsDeagle then
				weapon_type = "heavy_pistol"
			end

			swcs.ttt.AllWeapons[wep.ClassName] = true

			if wep.AutoSpawnable == false then continue end

			if not (wep.Spawnable and wep.AdminSpawnable) and not wep.InLoadoutFor then
				if not swcs.ttt.WeaponCategories[weapon_type] then
					swcs.ttt.WeaponCategories[weapon_type] = {}
				end

				table.insert(swcs.ttt.WeaponCategories[weapon_type], wep.ClassName)
			end

			local max_prim = tonumber(ItemAttributes["primary reserve ammo max"])
			wep.Primary.ClipMax = max_prim

			if not wep.TTTCustomProps then
				if weapon_type == "pistol" or weapon_type == "heavy_pistol" then
					wep.Kind = WEAPON_PISTOL
					wep.Slot = 1
					wep.spawnType = WEAPON_TYPE_PISTOL

					if weapon_type == "heavy_pistol" then
						wep.Primary.Ammo = "AlyxGun"
						wep.AmmoEnt = "item_ammo_revolver_ttt"
					else
						wep.Primary.Ammo = "pistol"
						wep.AmmoEnt = "item_ammo_pistol_ttt"
					end
				elseif bIsGrenade then
					wep.Kind = WEAPON_NADE
					wep.Slot = 3
					wep.spawnType = WEAPON_TYPE_NADE
					--t.Primary.Ammo = ""
				elseif wep.Base ~= "weapon_swcs_knife" then
					wep.Kind = WEAPON_HEAVY
					wep.Slot = 2
					wep.spawnType = WEAPON_TYPE_HEAVY

					if weapon_type == "shotgun" then
						wep.Primary.Ammo = "Buckshot"
						wep.AmmoEnt = "item_box_buckshot_ttt"
						wep.spawnType = WEAPON_TYPE_SHOTGUN
					elseif weapon_type == "sniperrifle" then
						wep.Primary.Ammo = "357"
						wep.AmmoEnt = "item_ammo_357_ttt"
						wep.spawnType = WEAPON_TYPE_SNIPER
					elseif weapon_type == "submachinegun" then
						wep.Primary.Ammo = "smg1"
						wep.AmmoEnt = "item_ammo_smg1_ttt"
					elseif weapon_type == "machinegun" then
						wep.Primary.Ammo = "AirboatGun"
					else
						wep.Primary.Ammo = "pistol"
						wep.AmmoEnt = "item_ammo_pistol_ttt"
						wep.spawnType = WEAPON_TYPE_PISTOL
					end
				end
			end

			if not ENABLE_WEAPON_REPLACE:GetBool() then
				wep.AutoSpawnable = false
			end
		elseif to_disable[wep.ClassName] then
			Msg("[swcs] ")
			print("obliterated ttt wep", wep.ClassName)
			wep._AutoSpawnable = wep.AutoSpawnable

			if not TTT2 then
				wep._CanBuy = wep.CanBuy
			end

			if ENABLE_WEAPON_REPLACE:GetBool() and not DISABLE_REPLACE_CROWBAR:GetBool() or (ALWAYS_REPLACE_CROWBAR:GetBool() and wep.ClassName == "weapon_ttt_knife") then
				wep.AutoSpawnable = false

				if not TTT2 then
					wep.CanBuy = nil
				end
			end
		end
	end

	local THROWN_KNIFE = scripted_ents.GetStored("ttt_knife_proj").t
	-- FIXME: cvars.AddChangeCallback
	THROWN_KNIFE.Model = (ENABLE_WEAPON_REPLACE:GetBool() or ALWAYS_REPLACE_CROWBAR:GetBool()) and Model("models/weapons/csgo/w_knife_gg.mdl") or Model("models/weapons/w_knife_t.mdl")

	if SERVER then
		function THROWN_KNIFE:BecomeWeapon()
			self.Weaponised = true

			---@class Weapon
			local wep = ents.Create((ENABLE_WEAPON_REPLACE:GetBool() or ALWAYS_REPLACE_CROWBAR:GetBool()) and "weapon_swcs_knife_gg" or "weapon_ttt_knife")
			wep:SetPos(self:GetPos())
			wep:SetAngles(self:GetAngles())
			wep.IsDropped = true

			local prints = self.fingerprints or {}

			SafeRemoveEntity(self)

			wep:Spawn()
			wep.fingerprints = wep.fingerprints or {}
			table.Add(wep.fingerprints, prints)

			return wep
		end
	end

	hook.Run("SWCSTTTWeaponsReady")
end)
