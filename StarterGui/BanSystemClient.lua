-- LocalScript inside BanSystemUI (ScreenGui)
-- IMPORTANT: This script assumes a ScreenGui named "BanSystemUI" exists in StarterGui
-- and contains the necessary UI elements (AdminPanel, PlayerInfoPanel, etc.) created manually.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local BanSystemUI = PlayerGui:WaitForChild("BanSystemUI") -- Waits for the ScreenGui

-- UI Elements (Ensure these names match your manually created UI)
local AdminPanel = BanSystemUI:WaitForChild("AdminPanel")
local PlayerInfoPanel = BanSystemUI:WaitForChild("PlayerInfoPanel")
local PlayerListFrame = AdminPanel:WaitForChild("PlayerList") -- Assuming ScrollingFrame is named PlayerList
local ControlsFrame = AdminPanel:WaitForChild("ControlsFrame") -- Assuming Frame containing controls
local SelectedPlayerLabel = ControlsFrame:WaitForChild("SelectedPlayerLabel")
local ShowBanPopupButton = ControlsFrame:WaitForChild("ShowBanPopupButton")
local BanReasonPopup = AdminPanel:WaitForChild("BanReasonPopup") -- Assuming Frame for popup
local BanTargetLabel = BanReasonPopup:WaitForChild("BanTargetLabel")
--local ReasonDropdown = BanReasonPopup:WaitForChild("ReasonDropdown")
local ConfirmBanButton = BanReasonPopup:WaitForChild("ConfirmBanButton")
local InfoTextLabel = PlayerInfoPanel:WaitForChild("InfoText") -- Assuming TextLabel in PlayerInfoPanel

-- Remote Events
local clientInitializeEvent = ReplicatedStorage:WaitForChild("BanSystem_ClientInitialize")
local requestPlayerListEvent = ReplicatedStorage:WaitForChild("BanSystem_RequestPlayerList")
local requestBanPlayerEvent = ReplicatedStorage:WaitForChild("BanSystem_RequestBanPlayer")
local updateAdminPlayerListEvent = ReplicatedStorage:WaitForChild("BanSystem_UpdateAdminPlayerList")

local isAdmin = false
local selectedUserId = nil
local selectedPlayerName = nil



-- Create a new UIListLayout object
local ReasonDropdown = Instance.new("UIListLayout")
ReasonDropdown.Parent = BanReasonPopup

-- Set the UIListLayout properties
ReasonDropdown.FillDirection = Enum.FillDirection.Vertical
ReasonDropdown.SortOrder = Enum.SortOrder.Name

-- Add items to the UIListLayout
local reasons = {"Cheating/Exploiting", "Predatory/Unhealthy Behavior"}
for i, reason in pairs(reasons) do
	local item = Instance.new("TextButton")
	item.Name = reason
	item.Text = reason
	item.LayoutOrder = i
	item.Parent = ReasonDropdown
end
-- Set the SortOrder to LayoutOrder
ReasonDropdown.SortOrder = Enum.SortOrder.LayoutOrder

-- Sort the items in descending order (higher values first)
for i, child in pairs(ReasonDropdown:GetChildren()) do
	child.LayoutOrder = -i
end

-- Update the list layout to apply the custom sorting
ReasonDropdown:ApplyLayout()
-- Initialize the selected item
local selectedReason = reasons[1]
--ReasonDropdown.SortOrder = game:GetService("ReplicatedStorage"):WaitForChild("ReasonTemplate")

-- Function to update the selected item
-- Connect the UIListLayout Selected property to the updateSelectedReason function
local function updateSelectedReason(button)
	if button then
		updateSelectedReason(button.Name)
	end
end

local function onMouseClick(input)
	local mouse = input.KeyCode
	if mouse == Enum.UserInputType.MouseButton1 then
		local button = game.Players.LocalPlayer:GetMouse().Target
		for _, child in pairs(ReasonDropdown:GetChildren()) do
			if child:IsA("TextButton") and child == button then
				updateSelectedReason(child)
				return
			end
		end
	end
end

game:GetService("UserInputService").InputBegan:Connect(onMouseClick)


-- Function to update the player list UI
local function UpdatePlayerListUI(playerData)
	if not isAdmin then return end
	if not PlayerListFrame:IsA("ScrollingFrame") then
		warn("BanSystemClient: PlayerListFrame is not a ScrollingFrame!")
		return
	end

	-- Ensure UIListLayout exists
	local listLayout = PlayerListFrame:FindFirstChildWhichIsA("UIListLayout")
	if not listLayout then
		warn("BanSystemClient: PlayerListFrame needs a UIListLayout inside.")
		-- Optionally create one if missing
		listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 2)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
		listLayout.Parent = PlayerListFrame
	end

	-- Clear existing player buttons
	for _, child in PlayerListFrame:GetChildren() do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local canvasHeight = 0
	local layoutOrder = 0

	-- Create buttons for each player
	for _, data in playerData do
		if data.UserId == LocalPlayer.UserId then continue end -- Don't list self

		local playerButton = Instance.new("TextButton")
		playerButton.Name = tostring(data.UserId)
		playerButton.Text = data.Name .. " (" .. data.UserId .. ")"
		playerButton.Size = UDim2.new(1, 0, 0, 30) -- Fixed height
		playerButton.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
		playerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		playerButton.Font = Enum.Font.SourceSans
		playerButton.TextSize = 14
		playerButton.LayoutOrder = layoutOrder
		playerButton.Parent = PlayerListFrame

		canvasHeight = canvasHeight + playerButton.AbsoluteSize.Y + listLayout.Padding.Offset
		layoutOrder = layoutOrder + 1

		-- Handle selection
		playerButton.MouseButton1Click:Connect(function()
			selectedUserId = data.UserId
			selectedPlayerName = data.Name
			SelectedPlayerLabel.Text = "Selected: " .. data.Name
			ShowBanPopupButton.Visible = true -- Show ban button
			BanReasonPopup.Visible = false -- Hide popup if switching selection

			-- Highlight selected button (optional)
			for _, btn in PlayerListFrame:GetChildren() do
				if btn:IsA("TextButton") then
					btn.BackgroundColor3 = Color3.fromRGB(70, 70, 90) -- Reset others
				end
			end
			playerButton.BackgroundColor3 = Color3.fromRGB(100, 100, 130) -- Highlight
		end)

		continue
	end

	-- Update scroll frame canvas size
	PlayerListFrame.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
end

-- ...

ShowBanPopupButton.MouseButton1Click:Connect(function()
	if isAdmin and selectedUserId and selectedPlayerName and selectedPlayerName ~= "" then
		BanTargetLabel.Text = "Banning: " .. selectedPlayerName
		-- Reset dropdown selection
		if ReasonDropdown then
			local reasons = ReasonDropdown:GetChildren()
			for i, reason in pairs(reasons) do
				if reason:IsA("TextLabel") then
					reason.Selected = true
				else
					reason.Selected = false
				end
			end
		end
		BanReasonPopup.Visible = true
	else
		-- If no player is selected, ensure popup is hidden
		BanReasonPopup.Visible = false
	end
end)

-- Handle Confirm Ban Button Click (for Admins)
ConfirmBanButton.MouseButton1Click:Connect(function()
	if isAdmin and selectedUserId then
		local selectedReason = nil
		if ReasonDropdown:IsA("Dropdown") then
			selectedReason = ReasonDropdown.SelectedOption -- Get selected text
		end

		if selectedReason and selectedReason ~= "" then
			print(string.format("BanSystemClient: Requesting ban for %d, Reason: %s", selectedUserId, selectedReason))
			requestBanPlayerEvent:FireServer(selectedUserId, selectedReason)
			-- Hide popup and reset selection
			BanReasonPopup.Visible = false
			selectedUserId = nil
			selectedPlayerName = nil
			SelectedPlayerLabel.Text = "Selected: None"
			ShowBanPopupButton.Visible = false
		else
			warn("BanSystemClient: No reason selected or Dropdown issue.")
		end
	end
end)

print("BanSystemClient Loaded.")

