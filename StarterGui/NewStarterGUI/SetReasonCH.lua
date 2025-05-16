local TextButton = script.Parent
local OtherTextButton = script.Parent.Parent:WaitForChild("PredatoryBehaviourButton")
local function onActivated()
	if OtherTextButton.BackgroundColor3 ~= Color3.fromRGB(255,102,102)  then
		TextButton.BackgroundColor3 = Color3.fromRGB(255,102,102) 
		OtherTextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	else
		TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		OtherTextButton.BackgroundColor3 = Color3.fromRGB(255,102,102)
	end
end

TextButton.Activated:Connect(onActivated)
