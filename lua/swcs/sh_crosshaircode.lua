-- based on https://github.com/akiver/csgo-sharecode

AddCSLuaFile()

AddCSLuaFile("external/bigint.lua")

local bigint = include("external/bigint.lua")

local CODE_PATTERN = "^CSGO%-(%w%w%w%w%w)%-(%w%w%w%w%w)%-(%w%w%w%w%w)%-(%w%w%w%w%w)%-(%w%w%w%w%w)"

local ALPHABET = "ABCDEFGHJKLMNOPQRSTUVWXYZabcdefhijkmnopqrstuvwxyz23456789"

local gap = GetConVar("swcs_crosshairgap")
local outline = GetConVar("swcs_crosshair_outlinethickness")
local red = GetConVar("swcs_crosshaircolor_r")
local green = GetConVar("swcs_crosshaircolor_g")
local blue = GetConVar("swcs_crosshaircolor_b")
local alpha = GetConVar("swcs_crosshairalpha")
local splitDistance = GetConVar("swcs_crosshair_dynamic_splitdist")
local followRecoil = GetConVar("swcs_crosshair_recoil")
local fixedGap = GetConVar("swcs_crosshair_fixedgap")
local color = GetConVar("swcs_crosshaircolor")
local outlineEnabled = GetConVar("swcs_crosshair_drawoutline")
local innerSplitAlpha = GetConVar("swcs_crosshair_dynamic_splitalpha_innermod")
local outerSplitAlpha = GetConVar("swcs_crosshair_dynamic_splitalpha_outermod")
local splitSizeRatio = GetConVar("swcs_crosshair_dynamic_maxdist_splitratio")
local thickness = GetConVar("swcs_crosshairthickness")
local centerDotEnabled = GetConVar("swcs_crosshairdot")
local deployedWeaponGapEnabled = GetConVar("swcs_crosshairgap_useweaponvalue")
local alphaEnabled = GetConVar("swcs_crosshairusealpha")
local tStyleEnabled = GetConVar("swcs_crosshair_t")
local style = GetConVar("swcs_crosshairstyle")
local length = GetConVar("swcs_crosshairsize")

local function sumArray(arr)
	local ret = 0

	for _, v in ipairs(arr) do
		ret = ret + v
	end

	return ret
end

local function StringToBytes(str)
	local bytes = {}

	for i = 1, #str, 2 do
		table.insert(bytes, tonumber(string.sub(str, i, i + 1), 16))
	end

	return bytes
end

local function BytesToHex(bytes)
	local ret = {"0x"}

	for _, v in ipairs(bytes) do
		ret[#ret + 1] = bit.tohex(v, 2)
	end

	return table.concat(ret, "")
end

local function BytesToShareCode(bytes)
	local hex = BytesToHex(bytes)

	local total = bigint(hex)

	local chars = {}
	local rem

	for _ = 1, 25 do
		rem = tonumber(total:Mod(#ALPHABET):ToDec())
		chars[#chars + 1] = ALPHABET[rem + 1]
		total = total:Div(#ALPHABET)
	end

	chars = table.concat(chars, "")

	return string.format("CSGO-%s-%s-%s-%s-%s",
		string.sub(chars, 1, 5),
		string.sub(chars, 6, 10),
		string.sub(chars, 11, 15),
		string.sub(chars, 16, 20),
		string.sub(chars, 21, 25))
end

function swcs.EncodeCrosshairCode()
	local bytes = {
		0,
		1,
		bit.band(gap:GetInt() * 10, 0xff),
		outline:GetFloat() * 2,
		red:GetInt(),
		green:GetInt(),
		blue:GetInt(),
		alpha:GetInt(),
		bit.bor(bit.lshift(followRecoil:GetBool() and 1 or 0, 7),
			bit.band(splitDistance:GetInt(), 7)),
		bit.band(fixedGap:GetInt() * 10, 0xff),
		bit.bor(bit.band(color:GetInt(), 7), bit.lshift(outlineEnabled:GetBool() and 1 or 0, 3), bit.lshift(innerSplitAlpha:GetFloat() * 10, 4)),
		bit.bor(outerSplitAlpha:GetFloat() * 10, bit.lshift(splitSizeRatio:GetFloat() * 10, 4)),
		thickness:GetFloat() * 10,
		bit.bor(bit.lshift(style:GetInt(), 1),
			bit.lshift(centerDotEnabled:GetBool() and 1 or 0, 4),
			bit.lshift(deployedWeaponGapEnabled:GetBool() and 1 or 0, 5),
			bit.lshift(alphaEnabled:GetBool() and 1 or 0, 6),
			bit.lshift(tStyleEnabled:GetBool() and 1 or 0, 7)),
		length:GetFloat() * 10,
		0,
		0,
		0,
	}
	bytes[1] = bit.band(sumArray(bytes), 0xff)

	return BytesToShareCode(bytes)
end

local function ShareCodeToBytes(code)
	if not string.find(code, CODE_PATTERN) then
		return
	end

	code = string.gsub(string.sub(code, 6), "-", "")
	local chars = table.Reverse(string.Split(code, ""))

	local big = bigint(0)
	for i = 1, #chars do
		local iFind = string.find(ALPHABET, chars[i]) - 1
		big = big:Mul(#ALPHABET):Add(iFind)
	end

	local str = string.gsub(big:ToHex(), "0x", "")
	if #str < 36 then
		str = string.rep("0", 36 - #str) .. str
	end
	return StringToBytes(str)
end

local function uint8ToInt8(number)
	if number > 127 then
		return -127 + (number % 128) - 1
	end

	return bit.rshift(bit.lshift(number, 24), 24)
end

function swcs.DecodeCrosshairCode(code)
	local bytes = ShareCodeToBytes(code)

	if not bytes then return end

	local copy = table.Copy(bytes)
	table.remove(copy, 1)
	local size = sumArray(copy) % 256

	if size ~= bytes[1] then return end

	return {
		gap = uint8ToInt8(bytes[3]) / 10,
		outline = bytes[4] / 2,
		red = bytes[5],
		green = bytes[6],
		blue = bytes[7],
		alpha = bytes[8],
		splitDistance = bit.band(bytes[9], 7),
		followRecoil = bit.band(bit.rshift(bytes[9], 4), 8) == 8,
		fixedCrosshairGap = uint8ToInt8(bytes[10]) / 10,
		color = bit.band(bytes[11], 7),
		outlineEnabled = bit.band(bytes[11], 8) == 8,
		innerSplitAlpha = bit.rshift(bytes[11], 4) / 10,
		outerSplitAlpha = bit.band(bytes[12], 0xf) / 10,
		splitSizeRatio = bit.rshift(bytes[12], 4) / 10,
		thickness = bytes[13] / 10,
		centerDotEnabled = bit.band(bit.rshift(bytes[14], 4), 1) == 1,
		deployedWeaponGapEnabled = bit.band(bit.rshift(bytes[14], 4), 2) == 2,
		alphaEnabled = bit.band(bit.rshift(bytes[14], 4), 4) == 4,
		tStyleEnabled = bit.band(bit.rshift(bytes[14], 4), 8) == 8,
		style = bit.rshift(bit.band(bytes[14], 0xf), 1),
		length = bytes[15] / 10,
	}
end

local TAG = "swcs_crosshair"
if CLIENT then
	function swcs.ApplyCrosshairCode(code)
		local settings = swcs.DecodeCrosshairCode(code)
		if not settings then return false end

		gap:SetInt(settings.gap)
		outline:SetFloat(settings.outline)
		red:SetInt(settings.red)
		green:SetInt(settings.green)
		blue:SetInt(settings.blue)
		alpha:SetInt(settings.alpha)
		splitDistance:SetInt(settings.splitDistance)
		followRecoil:SetBool(settings.followRecoil)
		fixedGap:SetInt(settings.fixedCrosshairGap)
		color:SetInt(settings.color)
		outlineEnabled:SetBool(settings.outlineEnabled)
		innerSplitAlpha:SetFloat(settings.innerSplitAlpha)
		outerSplitAlpha:SetFloat(settings.outerSplitAlpha)
		splitSizeRatio:SetFloat(settings.splitSizeRatio)
		thickness:SetFloat(settings.thickness)
		centerDotEnabled:SetBool(settings.centerDotEnabled)
		deployedWeaponGapEnabled:SetBool(settings.deployedWeaponGapEnabled)
		alphaEnabled:SetBool(settings.alphaEnabled)
		tStyleEnabled:SetBool(settings.tStyleEnabled)
		style:SetInt(settings.style)
		length:SetFloat(settings.length)

		return true
	end

	local function cvarChangeCallback(name, old, new)
		if not timer.Exists("swcs.crosshair_update") then
			timer.Create("swcs.crosshair_update", 0.1, 1, function()
				local code = swcs.EncodeCrosshairCode()

				net.Start(TAG)
				net.WriteString(code)
				net.SendToServer()

				LocalPlayer().swcs_CrosshairCode = code
			end)
		else
			timer.Adjust("swcs.crosshair_update", 0.1)
		end
	end
	local function addCallback(cvar)
		cvars.RemoveChangeCallback(cvar, "swcs.crosshair")
		cvars.AddChangeCallback(cvar, cvarChangeCallback, "swcs.crosshair")
	end

	addCallback("swcs_crosshairgap")
	addCallback("swcs_crosshair_outlinethickness")
	addCallback("swcs_crosshaircolor_r")
	addCallback("swcs_crosshaircolor_g")
	addCallback("swcs_crosshaircolor_b")
	addCallback("swcs_crosshairalpha")
	addCallback("swcs_crosshair_dynamic_splitdist")
	addCallback("swcs_crosshair_recoil")
	addCallback("swcs_crosshair_fixedgap")
	addCallback("swcs_crosshaircolor")
	addCallback("swcs_crosshair_drawoutline")
	addCallback("swcs_crosshair_dynamic_splitalpha_innermod")
	addCallback("swcs_crosshair_dynamic_splitalpha_outermod")
	addCallback("swcs_crosshair_dynamic_maxdist_splitratio")
	addCallback("swcs_crosshairthickness")
	addCallback("swcs_crosshairdot")
	addCallback("swcs_crosshairgap_useweaponvalue")
	addCallback("swcs_crosshairusealpha")
	addCallback("swcs_crosshair_t")
	addCallback("swcs_crosshairstyle")
	addCallback("swcs_crosshairsize")

	net.Receive(TAG, function(len)
		local code = swcs.EncodeCrosshairCode()

		net.Start(TAG)
		net.WriteString(code)
		net.SendToServer()
	end)
else
	util.AddNetworkString(TAG)

	-- homonovus CSGO-FjpNP-to8qv-dqM9i-RVFqT-mwCND
	-- Freemann CSGO-eGLDR-6PXWk-3K5ix-nVaMd-J6BxH

	-- leme CSGO-qXfFL-7ArHT-keLeO-2qjUj-ekrqK broken??
	-- https://discord.com/channels/1138420436397473852/1138420509491605534/1462371347228528845

	local CodeReceiveCallbackList = {}
	net.Receive(TAG, function(len, ply)
		local code = net.ReadString()

		local settings = swcs.DecodeCrosshairCode(code)
		if not settings then return end

		ply:SetNWString("swcs.crosshair_code", code)
		ply.swcs_CrosshairCode = code

		local callback = CodeReceiveCallbackList[ply]
		CodeReceiveCallbackList[ply] = nil

		if isfunction(callback) then
			callback(code)
		end
	end)

	function swcs.RequestCrosshairCode(ply, callback)
		if not (isentity(ply) and ply:IsValid() and ply:IsPlayer()) then return end

		if ply:IsBot() then
			ply:SetNWString("swcs.crosshair_code", "CSGO-Odxy9-hom66-FfRDk-yN3Ed-ehj9Q")
			if isfunction(callback) then
				callback("CSGO-Odxy9-hom66-FfRDk-yN3Ed-ehj9Q")
			end
		else
			CodeReceiveCallbackList[ply] = callback
			net.Start(TAG)
			net.Send(ply)
		end
	end
end
