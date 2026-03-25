AddCSLuaFile()

function SWEP:GetSpreadOffset(rand, iSpreadIndex)
	local flTheta, flCurveDensity

	local iSeed = tonumber(self.ItemAttributes["spread seed"])

	if not iSeed or self:GetBullets() <= 1 or iSpreadIndex >= 64 then
		flCurveDensity = rand:RandomFloat()
		flTheta = rand:RandomFloat(0, math.pi * 2)
	else
		local data = self.m_SpreadData[iSpreadIndex]

		flTheta = data.m_flTheta
		flCurveDensity = data.m_flCurveDensity
	end

	return flTheta, flCurveDensity
end

function SWEP:GenerateSpreadTable(data)
	local iBulletsInShot = self:GetBullets()

	if iBulletsInShot <= 1 then
		return
	end

	iBulletsInShot = math.min(iBulletsInShot, 64)

	local iSeed = tonumber(self.ItemAttributes["spread seed"])
	--if not iSeed then
	-- gen new seed based on CRC of weapon name
	--iSeed = tonumber(util.CRC(self:GetClass()))
	--end

	local flBulletFrac = 1 / iBulletsInShot

	local rand = UniformRandomStream(iSeed)

	local i, iCurBullet, v21, v34 = 64, 0, 0, 0

	repeat
		v21 = 0
		if iCurBullet < iBulletsInShot then
			v21 = iCurBullet
		end

		local flRawRandomA = rand:RandomFloat(0, 2 * math.pi)
		v34 = v21 + 1

		local flTheta = flRawRandomA

		local flRawRandomB = rand:RandomFloat(v21 * flBulletFrac, (v21 + 1) * flBulletFrac)
		local flCurveDensity
		if flRawRandomB >= 0.0 then
			flCurveDensity = math.min(flRawRandomB, 1)
		else
			flCurveDensity = 0
		end

		iCurBullet = v34

		table.insert(data, #data, {
			m_flTheta = flTheta,
			m_flCurveDensity = flCurveDensity,
		})

		i = i - 1
	until i == 0
end
