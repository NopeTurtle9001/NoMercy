--This Script will handle searching for players
local Players = game:GetService("Players")

local TextBox = script.Parent



local function onTextChanged()
	local text = TextBox.Text
	--Get all player frames in plist scrolling frame
	local PlayerList = script.Parent.Parent
	for _, child in PlayerList:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "Header" and not (child:IsA("UIListLayout") or child:IsA("LocalScript") or child:IsA("TextBox")) then
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
			if child:IsA("UIListLayout") or child:IsA("LocalScript") or child:IsA("TextBox") then
				-- Do nothing
			else
				child.Visible = true
			end
		end
	end
end

TextBox:GetPropertyChangedSignal("Text"):Connect(onTextChanged)
