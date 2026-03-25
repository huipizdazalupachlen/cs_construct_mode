-- skins and whatnot
AddCSLuaFile()

local TAG = "swcs_econ"

swcs.econ = swcs.econ or {}

local ECON_INC_STATTRAK = 0
local ECON_SEND_INVENTORY = 1
local ECON_UPDATE_ITEM = 2
local ECON_SEND_ITEM = 3

swcs.econ._EconItem = swcs.econ._EconItem or {}
local EconItem = swcs.econ._EconItem
EconItem.__index = EconItem
EconItem.__tostring = function(self)
	return Format(
		"EconItem[%s (%s%s)]", self.classname,
		#self.strCustomName > 0 and Format("\"%s\" ", self.strCustomName) or "",
		self.bHasStatTrak and Format("StatTrak %i", self.iStatTrakScore) or ""
	)
end
EconItem.__eq = function(a, b)
	return a.classname == b.classname and a.bHasStatTrak == b.bHasStatTrak and a.iStatTrakScore == b.iStatTrakScore and a.strCustomName == b.strCustomName
end

function swcs.econ.EconItem(classname, bHasStatTrak, iStatTrakScore, strCustomName)
	if not classname then return end
	if not weapons.IsBasedOn(classname, "weapon_swcs_base") then return end

	if bHasStatTrak == nil then
		bHasStatTrak = false
	end
	if iStatTrakScore == nil then
		iStatTrakScore = 0
	end
	if strCustomName == nil then
		strCustomName = ""
	end

	return setmetatable({
		classname = classname,
		bHasStatTrak = bHasStatTrak,
		iStatTrakScore = iStatTrakScore,
		strCustomName = strCustomName,
	}, EconItem)
end

function swcs.econ.GetInventory(ply)
	return swcs.econ.Inventory[ply]
end

swcs.econ.Inventory = swcs.econ.Inventory or setmetatable({}, {__mode = "k"})

if SERVER then
	util.AddNetworkString(TAG)

	hook.Add("OnNPCKilled", TAG .. ".stattrak", function(npc, attacker, inflictor)
		if not (attacker and attacker:IsValid() and attacker:IsPlayer()) then return end
		if not (inflictor:IsValid() and inflictor:IsWeapon() and inflictor.IsSWCSWeapon) then return end
		if inflictor:GetOriginalOwnerSteamID() ~= attacker:SteamID() then return end

		local inventory = swcs.econ.Inventory[attacker]
		if not inventory then return end

		local classname = inflictor:GetClass()
		local econitem = inventory[classname]
		if not (econitem and econitem.bHasStatTrak) then return end

		local wepItem = inflictor.m_econItem
		if wepItem == econitem then
			econitem.iStatTrakScore = econitem.iStatTrakScore + 1
			wepItem.iStatTrakScore = econitem.iStatTrakScore

			net.Start(TAG)
			net.WriteUInt(ECON_INC_STATTRAK, 3)
			net.WriteString(classname)
			net.Send(attacker)
		end
	end)
	hook.Add("PlayerDeath", TAG .. ".stattrak", function(ply, inflictor, attacker)
		if not attacker:IsPlayer() then return end
		if not (inflictor:IsValid() and inflictor:IsWeapon() and inflictor.IsSWCSWeapon) then return end
		if inflictor:GetOriginalOwnerSteamID() ~= attacker:SteamID() then return end

		local inventory = swcs.econ.Inventory[attacker]
		if not inventory then return end

		local classname = inflictor:GetClass()
		local econitem = inventory[classname]
		if not (econitem and econitem.bHasStatTrak) then return end

		local wepItem = inflictor.m_econItem
		if wepItem == econitem then
			econitem.iStatTrakScore = econitem.iStatTrakScore + 1
			inflictor.m_econItem.iStatTrakScore = econitem.iStatTrakScore

			net.Start(TAG)
			net.WriteUInt(ECON_INC_STATTRAK, 3)
			net.WriteString(classname)
			net.Send(attacker)
		end
	end)

	net.Receive(TAG, function(len, ply)
		local Type = net.ReadUInt(3)

		if Type == ECON_SEND_INVENTORY then
			local count = net.ReadUInt(9)

			local plyInventory = {}

			for i = 0, count do
				local class = net.ReadString()
				local bHasStatTrak, iStatTrakScore = net.ReadBool(), 0
				if bHasStatTrak then
					iStatTrakScore = net.ReadUInt(32)
				end
				local strCustomName = net.ReadString()

				if not weapons.IsBasedOn(class, "weapon_swcs_base") then continue end

				plyInventory[class] = swcs.econ.EconItem(class, bHasStatTrak, iStatTrakScore, strCustomName)
			end

			swcs.econ.Inventory[ply] = plyInventory
		elseif Type == ECON_UPDATE_ITEM then
			local count = net.ReadUInt(9)

			if not swcs.econ.Inventory[ply] then
				swcs.econ.Inventory[ply] = {}
			end

			for i = 1, count do
				local classname = net.ReadString()
				local bHasStatTrak = net.ReadBool()
				local strCustomName = net.ReadString()

				if not weapons.IsBasedOn(classname, "weapon_swcs_base") then continue end

				local econitem = swcs.econ.Inventory[ply][classname]
				if not econitem then
					swcs.econ.Inventory[ply][classname] = swcs.econ.EconItem(classname, bHasStatTrak, 0, strCustomName)
				else
					econitem.bHasStatTrak = bHasStatTrak
					econitem.strCustomName = strCustomName
				end
			end
		end
	end)
else
	swcs.econ._PrevInventory = swcs.econ._PrevInventory or {}

	net.Receive(TAG, function(len)
		local Type = net.ReadUInt(3)

		local ply = LocalPlayer()
		local plyInventory = swcs.econ.GetInventory(ply)
		if not plyInventory then
			plyInventory = {}
			swcs.econ.Inventory[ply] = plyInventory
		end

		if Type == ECON_INC_STATTRAK then
			local classname = net.ReadString()
			if not classname then return end

			local econitem = plyInventory[classname]
			if not (econitem and econitem.bHasStatTrak) then return end

			local wep = ply:GetWeapon(classname)
			local wepItem = wep.m_econItem
			if wepItem == econitem then
				econitem.iStatTrakScore = (econitem.iStatTrakScore or 0) + 1
				wepItem.iStatTrakScore = econitem.iStatTrakScore
			end

			if swcs.econ._PrevInventory and swcs.econ._PrevInventory[classname] then
				swcs.econ._PrevInventory[classname].iStatTrakScore = econitem.iStatTrakScore
			end
		elseif Type == ECON_SEND_ITEM then
			---@class Entity
			local wep = net.ReadEntity()
			if not wep:IsValid() then return end

			local bHasStatTrak, iScore = net.ReadBool(), 0
			if bHasStatTrak then
				iScore = net.ReadUInt(32)
			end

			local strCustomName = net.ReadString()

			wep.m_econItem = swcs.econ.EconItem(wep:GetClass(), bHasStatTrak, iScore, strCustomName)
		end
	end)

	-- forward expandable :)
	local SAVE_VALS = {
		{name = "bHasStatTrak",   type = "bool",   default = false},
		{name = "iStatTrakScore", type = "int",    default = 0},
		{name = "strCustomName",  type = "string", default = ""},
	}
	local WRITE_VAL = {
		["string"] = function(file, val)
			local iLen = #val

			file:WriteByte(iLen)
			if iLen > 0 then
				file:Write(val)
			end
		end,
		["bool"] = function(file, val)
			file:WriteBool(val)
		end,
		["int"] = function(file, val)
			file:WriteULong(val)
		end,
		["float"] = function(file, val)
			file:WriteFloat(val)
		end,
	}
	local READ_VAL = {
		["string"] = function(file)
			local iLen = file:ReadByte()
			if iLen == 0 then
				return ""
			else
				return file:Read(iLen)
			end
		end,
		["bool"] = function(file)
			return file:ReadBool()
		end,
		["int"] = function(file)
			return file:ReadULong()
		end,
		["float"] = function(file)
			return file:ReadFloat()
		end,
	}

	function swcs.econ._LoadInventory1(File)
		if not File then
			File = file.Open("swcs/inventory.dat", "rb", "DATA")
			if not File then return false end

			if File:Read(9) ~= "SWCSECON1" then
				File:Close()
				return false
			end
		end

		File:Skip(1) -- skip newline

		repeat
			local char = File:Read(1)

			if char == "#" then -- comment
				repeat until File:Read(1) == "\n"
			else -- assume we're in an entry
				File:Skip(-1)

				local class = File:Read(File:ReadByte())

				local SWEP = weapons.Get(class)
				if SWEP and SWEP.IsSWCSWeapon then -- and able to stat-trak
					swcs.econ.Inventory[class] = {
						bHasStatTrak = File:ReadBool(),
						iStatTrakScore = File:ReadULong(),
					}
				end
			end
		until File:Tell() >= File:Size()

		File:Close()
		swcs.econ._PrevInventory = table.Copy(swcs.econ.Inventory)

		return true
	end

	function swcs.econ.LoadInventory()
		local File = file.Open("swcs/inventory.dat", "rb", "DATA")
		if not File then return false end

		local header = File:Read(9)

		if header == "SWCSECON1" then
			local success = swcs.econ._LoadInventory1(File)
			if success then
				swcs.econ.SaveInventory()
			end
			return success
		end

		if header ~= "SWCSECON2" then
			File:Close()
			return false
		end

		local iNumKnownVarsLength = #SAVE_VALS

		-- read how many vars the file knows about
		local iNumFileVars = File:ReadULong()

		local ply = LocalPlayer()

		local plyInventory = swcs.econ.GetInventory(ply)
		if not plyInventory then
			plyInventory = {}
			swcs.econ.Inventory[ply] = plyInventory
		end

		repeat
			local class = READ_VAL["string"](File)

			-- how many bytes the variables take up
			local iVarsLength = File:ReadULong()
			local iCursor = File:Tell()

			if not weapons.IsBasedOn(class, "weapon_swcs_base") then -- bad
				File:Seek(iCursor + iVarsLength)
			else
				-- read vars
				local Vars = {}
				for i = 1, math.min(iNumKnownVarsLength, iNumFileVars) do
					local v = SAVE_VALS[i]

					Vars[v.name] = READ_VAL[v.type](File)
				end

				-- skip ahead past vars we don't know how to read ?!
				if iNumFileVars > iNumKnownVarsLength then
					File:Seek(iCursor + iVarsLength)
				end

				local econitem = swcs.econ.EconItem(class, Vars.bHasStatTrak, Vars.iStatTrakScore, Vars.strCustomName)
				plyInventory[class] = econitem
			end
		until File:Tell() >= File:Size()

		File:Close()
		swcs.econ._PrevInventory = table.Copy(plyInventory)

		return true
	end

	function swcs.econ.SaveInventory()
		if not file.IsDir("swcs", "DATA") then
			file.CreateDir("swcs")
		end

		local ply = LocalPlayer()
		if not ply:IsValid() then return false end

		local plyInventory = swcs.econ.GetInventory(ply)
		if table.IsEmpty(plyInventory) then return false end

		local File = file.Open("swcs/inventory.dat", "wb", "DATA")
		if not File then return false end

		-- header
		File:Write("SWCSECON2")

		-- write how many vars we know about; i plan to add to the list sequentially
		local iNumVars = #SAVE_VALS
		File:WriteULong(iNumVars)

		-- write the inventory
		for class, item in next, plyInventory do
			local SWEP = weapons.Get(class)
			if not (SWEP and SWEP.IsSWCSWeapon) then continue end -- and able to stat-trak

			WRITE_VAL.string(File, class)

			-- write how long in bytes the var entries are
			local iCursor = File:Tell()
			File:WriteULong(0) -- placeholder

			-- write each var sequentially in the order they were added :)
			for _, type in ipairs(SAVE_VALS) do
				local val = item[type.name]
				WRITE_VAL[type.type](File, val ~= nil and val or type.default)
			end

			-- calc length of vars
			local iEnd = File:Tell()
			local iLength = iEnd - iCursor - 4

			-- rewind to fill in the length
			File:Seek(iCursor)
			File:WriteULong(iLength)
			File:Seek(iEnd)
		end

		File:Close()
		return true
	end

	function swcs.econ.UpdateInventory()
		if not swcs.econ._PrevInventory then return end

		local updatedItems = {}
		local count = 0

		local ply = LocalPlayer()
		if not ply:IsValid() then return end

		local plyInventory = swcs.econ.GetInventory(ply)
		if not plyInventory then return end

		local iCurrentCount = table.Count(plyInventory)
		local iPrevCount = table.Count(swcs.econ._PrevInventory)

		-- add new items into the list
		if iCurrentCount > iPrevCount then
			for class, item in next, plyInventory do
				if not swcs.econ._PrevInventory[class] then
					updatedItems[item] = true
					count = count + 1
				end
			end
		end

		-- check for updated items
		for class, item in next, plyInventory do
			local prevItem = swcs.econ._PrevInventory[class]
			if not prevItem then continue end

			if item ~= prevItem then
				updatedItems[item] = true
				count = count + 1
			end
		end

		if count == 0 then return end

		-- send it off
		net.Start(TAG)
		net.WriteUInt(ECON_UPDATE_ITEM, 3)
		net.WriteUInt(count, 9)

		for item in next, updatedItems do
			net.WriteString(item.classname)
			net.WriteBool(item.bHasStatTrak)
			net.WriteString(item.strCustomName)

			if item.strCustomName and #item.strCustomName > 0 then
				item.strFilteredName = util.FilterText(item.strCustomName, TEXT_FILTER_NAME)
			end
		end
		net.SendToServer()

		swcs.econ._PrevInventory = table.Copy(plyInventory)
	end

	-- look into CEconItemView::CreateCustomWeaponMaterials()
	local genned_mats = {}
	function swcs.econ.GenerateEconTexture(params)
		if SERVER then return end

		local basetexture = params.basetexture
		local flWearValue = params.wearvalue
		local normalmap = params.normal

		local filename = string.GetFileFromFilename(basetexture)
		if not filename then error("bad texture path", 2) end

		local hash = util.CRC(Format("%s_%f", filename, flWearValue))
		local mat_name = Format("swcs_%s_%x", filename, hash)

		local mat = genned_mats[mat_name]
		if not mat or mat:IsError() then
			mat = CreateMaterial(mat_name, "VertexLitGeneric", {
				["$basetexture"] = basetexture,
				["$bumpmap"] = normalmap,
			})
		else
			mat:SetTexture("$basetexture", basetexture)

			if normalmap then
				mat:SetTexture("$bumpmap", normalmap)
			end

			local tex = mat:GetTexture("$basetexture")
			if tex then
				tex:Download()
			end
		end

		genned_mats[mat_name] = mat

		return mat_name, mat
	end

	hook.Add("InitPostEntity", TAG, function()
		local plyInventory = {}
		swcs.econ.Inventory[LocalPlayer()] = plyInventory

		if swcs.econ.LoadInventory() then
			net.Start(TAG)
			net.WriteUInt(ECON_SEND_INVENTORY, 3)

			net.WriteUInt(math.min(table.Count(plyInventory) - 1, 511), 9) -- limit to 512 items

			for class, item in next, plyInventory do
				net.WriteString(class)
				net.WriteBool(item.bHasStatTrak)
				if item.bHasStatTrak then
					net.WriteUInt(item.iStatTrakScore, 32)
				end
				net.WriteString(item.strCustomName)
			end
			net.SendToServer()
		end
	end)
	hook.Add("ShutDown", TAG, swcs.econ.SaveInventory)
	timer.Create(TAG, 60, 0, swcs.econ.SaveInventory)
end
