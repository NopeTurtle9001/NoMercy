local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local TargetPlayerID = script.Parent.Parent.Parent.Parent.Name
local BanConfirmButton = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BanPlayerEvent = ReplicatedStorage:WaitForChild("BanPlayerEvent")
local reasons = BanConfirmButton.Parent:GetChildren()
local banreason = ""
--Check which one the admin clicked
function DetermineReason()
	for i, reason in reasons do
		--compare name
		if reason.Name == "CheatingReasonButton" and reason.BackgroundColor == Color3.fromRGB(255,102,102) then
			banreason = "Cheating/Exploiting"
		else
			banreason = "PredatoryBehaviour"
		end
	end
end

local function BanPlayer(pid)
	DetermineReason()
	-- make case to check if banreason is false and end safely
	print(tonumber(pid))
	BanPlayerEvent:FireServer(LocalPlayer, tonumber(pid), banreason)
	
end
-- kick the player
local function onActivated()
	print("Attempting to Ban player.")
	BanPlayer(TargetPlayerID)
end
BanConfirmButton.Activated:Connect(onActivated)
