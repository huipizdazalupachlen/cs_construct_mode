-- material proxies

local function GetMaterialVector(str)
	local x, y, z, w
	local components = 0

	for s in string.gmatch(str, "(%d+%.?%d*)") do
		if not x then
			x = tonumber(s)
		elseif not y then
			y = tonumber(s)
		elseif not z then
			z = tonumber(s)
		elseif not w then
			w = tonumber(s)
		end

		components = components + 1
	end

	return x, y, z, w, components
end

local function GetMaterialVarType(str)
	if string.find(str, "%[") then
		local _, _, _, _, components = GetMaterialVector(str)

		if components == 2 then
			return "vector2"
		elseif components == 3 then
			return "vector3"
		elseif components == 4 then
			return "vector4"
		else
			return "float"
		end
	elseif string.find(str, "%d+%.?%d*") then
		local val = tonumber(string.match(str, "%d+%.?%d*")) or 0

		if math.floor(val) == val then
			return "int"
		else
			return "float"
		end
	else
		--print("UNKNOWN TYPE FOR:", str)
		return "string"
	end
end

local MATERIAL = FindMetaTable("IMaterial")
---@diagnostic disable-next-line: need-check-nil
local MAT_SetFloat = MATERIAL.SetFloat
---@diagnostic disable-next-line: need-check-nil
local MAT_SetInt = MATERIAL.SetInt

local ResultMatProxy
do
	---@diagnostic disable-next-line: need-check-nil
	local MAT_SetVector = MATERIAL.SetVector
	---@diagnostic disable-next-line: need-check-nil
	local MAT_SetVector4D = MATERIAL.SetVector4D

	ResultMatProxy = function(t)
		print("register result matproxy", t.name)

		t.BaseInit = t.init
		t.init = function(self, mat, values)
			self.m_strResultVar = values.resultvar
			self.m_strResultVarType = GetMaterialVarType(mat:GetString(self.m_strResultVar))

			-- Look for array specification...
			if string.find(self.m_strResultVar, "%[") then
				-- strip off the array...
				self.m_ResultVecComp = tonumber(string.match(self.m_strResultVar, "%[(%d*)%]"))
				self.m_strResultVar = string.gsub(self.m_strResultVar, "%[%d*%]", "")

				print("ARRAY COMPONENT", self.name, self.Material, self.m_strResultVar, self.m_ResultVecComp)
			else
				self.m_ResultVecComp = -1
			end

			-- gmod has a bug where multiple of the same matproxy cannot exist in the same material
			-- so we need to use a different resultvar for the second value, and then check for it in the bind function
			self.m_strResultVar2 = values.resultvar2
			if self.m_strResultVar2 then
				self.m_strResultVarType2 = GetMaterialVarType(mat:GetString(self.m_strResultVar2))

				-- Look for array specification...
				if string.find(self.m_strResultVar2, "%[") then
					-- strip off the array...
					self.m_Result2VecComp = tonumber(string.match(self.m_strResultVar2, "%[(%d*)%]"))
					self.m_strResultVar2 = string.gsub(self.m_strResultVar2, "%[%d*%]", "")
				else
					self.m_Result2VecComp = -1
				end
			end

			if isfunction(self.BaseInit) then
				self.BaseInit(self, mat, values)
			end
		end

		t.SetResultValue = function(self, matVarName, value)
			local varType = self.m_strResultVarType

			-- handle t:SetResultVar(value)
			if value == nil and matVarName ~= nil then
				value = matVarName
				matVarName = self.m_strResultVar
				varType = self.m_strResultVarType
			elseif matVarName == self.m_strResultVar2 then
				varType = self.m_strResultVarType2
			end

			--if self.m_ResultVecComp ~= -1 then
			--	print("UNHANDLED ARRAY COMPONENT", self.name, self.Material, varType)
			--	return
			--end

			if varType == "float" then
				MAT_SetFloat(self.Material, matVarName, value)
			elseif varType == "int" then
				MAT_SetInt(self.Material, matVarName, math.floor(value))
			elseif varType == "vector2" then
				if isvector(value) then
					MAT_SetVector(self.Material, matVarName, value)
				else
					MAT_SetVector(self.Material, matVarName, Vector(value, value, 0))
				end
			elseif varType == "vector3" then
				if isvector(value) then
					MAT_SetVector(self.Material, matVarName, value)
				else
					MAT_SetVector(self.Material, matVarName, Vector(value, value, value))
				end
			elseif varType == "vector4" then
				MAT_SetVector4D(self.Material, matVarName, value, value, value, value)
			else
				print("UNHANDLED TYPE", self.name, self.Material, varType, matVarName, value)
			end
		end

		return t
	end
end

matproxy.Add(ResultMatProxy{
	name = "IronSightAmount",
	init = function(self, mat, values)
		self.m_bInvert = tobool(values.invert or 0)
	end,
	bind = function(self, mat, ent)
		local var = 0

		if ent:IsValid() then
			local owner = ent:GetOwner()

			if IsValid(owner) then
				local wep = owner:GetActiveWeapon()

				if wep:IsValid() then
					local iron = wep.GetIronSightController and wep:GetIronSightController() or NULL

					if iron:IsValid() and iron.GetIronSightAmount then
						var = iron:GetIronSightAmount()
					end
				end
			end
		end

		if self.m_bInvert then
			var = 1 - var
		end

		self:SetResultValue(var)
	end,
})

local SWITCH_CrosshairColor = {
	[0] = Color(250, 50, 50),
	Color(50, 250, 50),
	Color(250, 250, 50),
	Color(50, 50, 250),
	Color(50, 250, 250),
	function(settings)
		return Color(
			settings.red,
			settings.green,
			settings.blue
		)
	end,
}

local swcs_crosshair_use_spectator = GetConVar"swcs_crosshair_use_spectator"
matproxy.Add(ResultMatProxy{
	name = "CrossHairColor",
	bind = function(self, mat, ent)
		---@class Entity
		local viewEnt = GetViewEntity()
		local bLocalPlayer = false

		if not viewEnt:IsValid() then
			bLocalPlayer = true
			viewEnt = LocalPlayer()
		elseif viewEnt == LocalPlayer() then
			local target = viewEnt:GetObserverTarget()

			if target:IsValid() and target:IsPlayer() and viewEnt:GetObserverMode() == OBS_MODE_IN_EYE then
				viewEnt = target
			else
				bLocalPlayer = true
			end
		end

		local code, settings = "", nil

		if viewEnt:IsPlayer() then
			if bLocalPlayer or not swcs_crosshair_use_spectator:GetBool() then
				code = viewEnt.swcs_CrosshairCode
				if not code then
					code = swcs.EncodeCrosshairCode()
					viewEnt.swcs_CrosshairCode = code
				end
			else
				code = viewEnt:GetNWString("swcs.crosshair_code", "")
			end
		end

		if code ~= "" then
			if code ~= self.m_strCurrentCrosshairCode then
				self.m_strCurrentCrosshairCode = code
				self.m_tCurrentCrosshairSettings = nil
			end

			if not self.m_tCurrentCrosshairSettings then
				self.m_tCurrentCrosshairSettings = swcs.DecodeCrosshairCode(code)
			end
		end

		settings = self.m_tCurrentCrosshairSettings

		---@type function|Color
		local col = SWITCH_CrosshairColor[1] -- trusty green
		if settings and SWITCH_CrosshairColor[settings.color] then
			col = SWITCH_CrosshairColor[settings.color]

			if isfunction(col) then
				col = col(settings)
			end
		end

		self:SetResultValue(Vector(
			math.Remap(col.r, 0, 255, 0, 3),
			math.Remap(col.g, 0, 255, 0, 3),
			math.Remap(col.b, 0, 255, 0, 3))
		)
	end,
})

-- in all valve games since l4d1, but not gmod
matproxy.Add(ResultMatProxy{
	name = "ConVar",
	init = function(self, mat, values)
		self.m_strConVar = values.convar
	end,
	bind = function(self, mat, ent)
		if not self.m_ConVar then
			self.m_ConVar = GetConVar(self.m_strConVar)
			--mat:SetInt(self.m_strResultVar, 1)
			return
		end

		local strVal = self.m_ConVar:GetString()

		local num = tonumber(strVal)
		if num then
			if math.floor(num) == num then
				MAT_SetInt(mat, self.m_strResultVar, num)
			else
				MAT_SetFloat(mat, self.m_strResultVar, num)
			end
		else
			--
		end
	end,
})

local function WepHelper(proxy, ent)
	local wep = ent.m_Weapon
	if wep and wep:IsValid() then
		return wep
	end

	-- StatTrak modules are children of their accompanying viewmodels
	local vm = ent:GetParent()

	if not (vm:IsValid() and vm:GetClass():find("viewmodel")) then return NULL end

	return vm:GetInternalVariable("m_hWeapon")
end

--[[
	StatTrakDigit
	{
		resultVar		"$frame"
		resultVar2		"$bumpframe"
		trimzeros		0
		displayDigit	0
	}
]]
matproxy.Add(ResultMatProxy{
	name = "SWCS_StatTrakDigit",
	init = function(self, mat, values)
		self.m_bTrimZeros = tobool(values.trimzeros or 0)
		self.m_iDisplayDigit = math.floor(tonumber(values.displaydigit) or 0)
	end,
	ScoreHelper = function(self, wep)
		--local plyInventory = swcs.econ.GetInventory(wep:GetOwner())
		--if not plyInventory then return false, 0 end
		--
		--local econitem = plyInventory[wep:GetClass()]
		local econitem = wep.m_econItem
		if not (econitem and econitem.bHasStatTrak) then return false, 0 end

		return true, econitem.iStatTrakScore
	end,
	WepHelper = WepHelper,
	bind = function(self, mat, ent)
		if not ent:IsValid() then return end

		local bHasScoreToDisplay, iScore = false, 0

		local wep = self:WepHelper(ent)
		if wep:IsValid() then
			bHasScoreToDisplay, iScore = self:ScoreHelper(wep)
		end

		if not bHasScoreToDisplay then
			-- Force flashing numbers
			self:SetResultValue(math.floor(math.fmod(CurTime(), 10.0)))

			if self.m_strResultVar2 then
				self:SetResultValue(self.m_strResultVar2, math.floor(math.fmod(CurTime(), 10.0)))
			end
			return
		end

		local iDesiredDigit = self.m_iDisplayDigit
		-- trim preceding zeros
		if self.m_bTrimZeros and math.pow(10, iDesiredDigit) > iScore then
			self:SetResultValue(10) --assumed blank framegrenades

			if self.m_strResultVar2 then
				self:SetResultValue(self.m_strResultVar2, 10)
			end

			return
		end

		-- get the [0-9] value of the digit we want
		local iDigitCount = math.min(iDesiredDigit, 10)
		for i = 1, iDigitCount do
			iScore = iScore / 10
		end
		iScore = iScore % 10

		self:SetResultValue(iScore)
		if self.m_strResultVar2 then
			self:SetResultValue(self.m_strResultVar2, iScore)
		end
	end,
})

--[[
	StatTrakIllum
	{
		resultVar	$color
		minVal		0.5
		maxVal		1.5
	}
]]
matproxy.Add(ResultMatProxy{
	name = "SWCS_StatTrakIllum",
	init = function(self, mat, values)
		self.m_flMinVal = tonumber(values.minval) or 0.5
		self.m_flMaxVal = tonumber(values.maxval) or 1
	end,
	WepHelper = WepHelper,
	bind = function(self, mat, ent)
		if not ent:IsValid() then return end

		local wep = self:WepHelper(ent)
		if not wep:IsValid() then return end

		--local plyInventory = swcs.econ.GetInventory(wep:GetOwner())
		--if not plyInventory then return end
		--
		--local econitem = plyInventory[wep:GetClass()]
		local econitem = wep.m_econItem
		if not (econitem and econitem.bHasStatTrak) then return end

		local comp = Lerp(wep:GetStatTrakGlowMultiplier(), self.m_flMinVal, self.m_flMaxVal)
		self:SetResultValue(comp)
	end,
})

--[[
	WeaponLabelText
	{
		displayDigit		0
	}
]]
local NUM_UID_CHARS = 20
local matrix = Matrix({
	{1, 0, 0, 0},
	{0, 1, 0, 0},
	{0, 0, 1, 0},
	{0, 0, 0, 1},
})

local MATRIX = FindMetaTable("VMatrix")
---@diagnostic disable-next-line: need-check-nil
local M_SetField = MATRIX.SetField
---@diagnostic disable-next-line: need-check-nil
local MAT_SetMatrix = MATERIAL.SetMatrix
matproxy.Add({
	name = "SWCS_WeaponLabelText",
	init = function(self, mat, values)
		self.m_iDisplayDigit = math.floor(tonumber(values.displaydigit) or 0)
	end,
	WepHelper = WepHelper,
	bind = function(self, mat, ent)
		if not ent:IsValid() then return end

		local wep = self:WepHelper(ent)
		if not wep:IsValid() then return end

		--local plyInventory = swcs.econ.GetInventory(wep:GetOwner())
		--if not plyInventory then return end
		--
		--local econitem = plyInventory[wep:GetClass()]
		local econitem = wep.m_econItem
		if not (econitem and econitem.strCustomName and #econitem.strCustomName > 0) then return end

		-- get the digit index we need to display
		local nCharIndex = 0
		local nDigit = self.m_iDisplayDigit

		-- center the text within NUM_UID_CHARS
		if not econitem.strFilteredName then
			econitem.strFilteredName = util.FilterText(econitem.strCustomName, TEXT_FILTER_NAME)
		end
		local strName = econitem.strFilteredName
		local nStrLen = #strName

		local nPrependSpaces = math.floor((NUM_UID_CHARS - nStrLen) / 2)
		nDigit = nDigit - nPrependSpaces

		if nDigit >= 0 and nDigit < nStrLen then
			nCharIndex = string.byte(string.sub(strName, nDigit + 1, nDigit + 1)) - 32
		end

		local nIndexHoriz = math.fmod(nCharIndex, 12)
		local nIndexVertical = math.floor(nCharIndex / 12)

		local flOffsetX = 0.083333 * nIndexHoriz
		local flOffsetY = 0.125 * nIndexVertical

		M_SetField(matrix, 1, 4, flOffsetX)
		M_SetField(matrix, 2, 4, flOffsetY)
		MAT_SetMatrix(mat, "$basetexturetransform", matrix)
	end,
})
