--This Script will make all the children required for PlayerList to even work
local Players = game:GetService("Players")
local FrameToClone = script.Parent.Parent.Parent:FindFirstChild("ExamplePListFrame")
local PListButton = script.Parent.Parent

--Function to remove existing frames from the list
local function removeExistingFrames()
	for _, child in script.Parent:GetChildren() do
		if child:IsA("Frame") and child.Name ~= "Header" then -- Make sure to exclude the header frame
			child:Destroy()
		end
	end
end

--Function to create all the children
function CreatePlayerList()
	removeExistingFrames()
	for i, plr in pairs(Players:GetPlayers()) do
		local userId = plr.UserId
		local PlayerFrame = FrameToClone:Clone()
		PlayerFrame.Parent = script.Parent
		PlayerFrame.Name = userId
		local AvatarIcon = PlayerFrame:FindFirstChild("PlayerProfile")
		AvatarIcon.Image = Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		local TextButton = PlayerFrame:FindFirstChild("ButtonUsedForModeration")
		TextButton.Text = "@"..plr.Name
		PlayerFrame.Visible = true
	end
end

--Function to update the list on player join
local function updatePlayerList()
	CreatePlayerList()
end

--Connect the updatePlayerList function to the Players.PlayerAdded event
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(updatePlayerList)
PListButton.Activated:Connect(updatePlayerList)

--Call the CreatePlayerList function initially
CreatePlayerList()
