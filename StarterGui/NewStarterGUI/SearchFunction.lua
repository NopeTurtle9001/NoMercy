--This Script will handle searching for players
local Players = game:GetService("Players")

local TextBox = script.Parent



local function onTextChanged()
	local text = TextBox.Text
	--Get all player frames in plist scrolling frame
	local PlayerList = script.Parent.Parent
	for _, child in PlayerList:GetChildren() do
		if child:IsA("Frame") and not (child:IsA("UIListLayout") or child:IsA("LocalScript") or child:IsA("TextBox")) then
			-- Get the ButtonForModeration 
			local ButtonForMod = child:FindFirstChild("ButtonUsedForModeration")
			if string.find(text, ButtonForMod.Text) then
				print("Showing child named: "..child.Name)
				child.Visible = true
			else
				print("Hiding child named: "..child.Name)
				child.Visible = false
			end
		end
	end
	if text == " " or text == "" or text == "Enter Name Here" then
		-- Handle the case where the text is empty
		for _, child in PlayerList:GetChildren() do
			-- Make all children visible
			if child:IsA("UIListLayout") or child:IsA("LocalScript") or child:IsA("TextBox") then
				-- Do nothing
			else
				child.Visible = true
				print("Showing all children")
			end
		end
	end
end

TextBox:GetPropertyChangedSignal("Text"):Connect(onTextChanged)
