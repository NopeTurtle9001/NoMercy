--This Script will handle searching for players
local Players = game:GetService("Players")

local TextBox = script.Parent



local function onTextChanged()
	local text = TextBox.Text
	--Get all player frames in plist scrolling frame
	local PlayerList = script.Parent.Parent
	for _, child in PlayerList:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "Header" then
			-- Get the ButtonForModeration 
			local ButtonForMod = child:FindFirstChild("ButtonUsedForModeration")
			if string.find(text, ButtonForMod.Text) then
				child.Visible = true
			else
				child.Visible = false
			end
		end
	end
	if text == " " or "" then
		-- Handle the case where the text is empty
		text = "Enter Name Here"
		for _, child in PlayerList:GetChildren() do
			-- Make all children visible
			if not child:IsA("Frame") or child:IsA("UIListLayout") then
				-- Do nothing
			else
				child.Visible = true
			end
		end
	end
end

TextBox:GetPropertyChangedSignal("Text"):Connect(onTextChanged)
