local Players = game:GetService("Players")
local TargetPlayerID = script.Parent.Parent.Parent.Parent.Name
local KickButton = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdminKickEvent = ReplicatedStorage:WaitForChild("AdminKickEvent")

local function kickPlayer(pid)
	print(tonumber(pid))
	AdminKickEvent:FireServer(tonumber(pid))
end
-- kick the player
local function onActivated()
	print("Attempting to kick player.")
	kickPlayer(TargetPlayerID)
end
KickButton.Activated:Connect(onActivated)
