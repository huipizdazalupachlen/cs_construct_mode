include("cl_crosshair.lua")

include("shared.lua")

function SWEP:DrawWeaponSelection(x, y, w, h, alpha)
	local selfTable = self:GetTable()
	if not selfTable.SelectIcon then return end

	local Icon = selfTable.SelectIcon
	if selfTable.SelectIconAlt and selfTable.GetWeaponMode(self) == Primary_Mode then
		Icon = selfTable.SelectIconAlt
	end

	surface.SetMaterial(Icon)

	local col = surface.GetDrawColor()
	if col.r == 0 and col.g == 0 and col.b == 0 then
		col.r = 255
		col.g = 255
		col.b = 255
	end

	surface.SetDrawColor(col.r, col.g, col.b, alpha)

	local iMatWidth = Icon:Width() * 0.75
	local iMatHeight = Icon:Height() * 0.75

	local aspectRatio = iMatWidth / iMatHeight
	local inset = 0.75

	local maxWidth = w * inset
	local maxHeight = ScreenScaleH(32) --h * inset
	local iWidth, iHeight

	if (maxWidth / aspectRatio) <= maxHeight then
		iWidth = maxWidth
		iHeight = iWidth / aspectRatio
	else
		iHeight = maxHeight
		iWidth = iHeight * aspectRatio
	end

	local iDrawX = x + (w - iWidth) / 2
	local iDrawY = y + (h - iHeight) / 2

	surface.DrawTexturedRect(iDrawX, iDrawY, iWidth, iHeight)
end

net.Receive("swcs_CallOnClients", function()
	local wep = net.ReadEntity()
	local funcName = net.ReadString()
	local args = net.ReadString()

	if not IsValid(wep) then return end
	local wepTable = wep:GetTable()

	if not wepTable.IsSWCSWeapon then
		ErrorNoHalt(Format("[swcs] Received CallOnClients for %s, but it's not an SWCS weapon!", tostring(wep)))
		return
	end

	local func = wepTable[funcName]
	if not func or not isfunction(func) then
		func = wep[funcName]
	end

	if not func or not isfunction(func) then
		ErrorNoHalt(Format("[swcs] Received CallOnClients for %s, calling unknown function %q!", tostring(wep), func))
		return
	end

	func(wep, args)
end)

SWEP.m_flStatTrakGlowMultiplierIdeal = 0
SWEP.m_flStatTrakGlowMultiplier = 0
function SWEP:UpdateStatTrakGlow(selfTable)
	selfTable = selfTable or self:GetTable()
	--approach the ideal in 2 seconds
	if IsFirstTimePredicted() then
		selfTable.m_flStatTrakGlowMultiplier = swcs.Approach(selfTable.m_flStatTrakGlowMultiplierIdeal, selfTable.m_flStatTrakGlowMultiplier, FrameTime() * 0.5)
	end
end

function SWEP:SetStatTrakGlowMultiplier(flNewIdealGlow)
	self.m_flStatTrakGlowMultiplierIdeal = flNewIdealGlow
end

function SWEP:GetStatTrakGlowMultiplier()
	return self.m_flStatTrakGlowMultiplier
end
