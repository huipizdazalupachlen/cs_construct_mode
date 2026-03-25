-- defusing hud
do
	local prevVal = false

	local FRAME
	local function CreatePopup()
		---@class EditablePanel
		FRAME = vgui.Create("EditablePanel")
		FRAME:SetSize(200, 50)
		--FRAME:ShowCloseButton(false)
		--FRAME:SetTitle("DEFUSING")
		FRAME:CenterVertical(0.6)
		FRAME:CenterHorizontal(0.5)
		--FRAME:Center()
		--FRAME:MakePopup()
		FRAME:ParentToHUD()

		FRAME.Progress = vgui.Create("DProgress", FRAME)
		FRAME.Progress:Dock(FILL)

		FRAME.Label = vgui.Create("DLabel", FRAME)
		FRAME.Label:Dock(TOP)
		FRAME.Label:SetText("Defuse Time: 00:10")
	end

	hook.Add("Think", "swcs.defusing_hud", function()
		local ply = LocalPlayer()
		local curVal = ply:GetNWBool("m_bIsDefusing", false)

		if prevVal ~= curVal then
			local bStarted = not prevVal

			if bStarted then
				if not IsValid(FRAME) then
					CreatePopup()
				else
					FRAME:SetVisible(true)
				end
			elseif FRAME:IsValid() then
				FRAME:SetVisible(false)
			end

			prevVal = curVal
		end

		if IsValid(FRAME) and curVal then
			local flLength = ply:GetNWFloat("m_flSWCSDefuseLength", 0)
			local flEndTime = ply:GetNWFloat("m_flDefuseCountDown", 0)

			local flTimeLeft = math.max(flEndTime - CurTime(), 0)

			local strTime = string.FormattedTime(flTimeLeft, "%02i:%02i")
			FRAME.Progress:SetFraction(flTimeLeft / flLength)
			FRAME.Label:SetText(Format("Defuse Time: %s", strTime))
		end
	end)
end
