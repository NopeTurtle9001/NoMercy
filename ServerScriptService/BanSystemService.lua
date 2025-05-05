  -- Script in ServerScriptService
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService") -- Needed for BanSystemCore

local BanSystemCore = require(ServerScriptService.BanSystemCore)

-- Remote Events
local clientInitializeEvent = ReplicatedStorage:WaitForChild("BanSystem_ClientInitialize")
local requestPlayerListEvent = ReplicatedStorage:WaitForChild("BanSystem_RequestPlayerList")
local requestBanPlayerEvent = ReplicatedStorage:WaitForChild("BanSystem_RequestBanPlayer")
local updateAdminPlayerListEvent = ReplicatedStorage:WaitForChild("BanSystem_UpdateAdminPlayerList")

local currentBanList = {}
local AUTO_BAN_CHECK_INTERVAL = 20
	--3 * 60 * 60 -- 3 hours in seconds

-- Function to get player data for admin panel
local function GetPlayerDataForAdmin()
    local playerData = {}
    for _, player in Players:GetPlayers() do
        table.insert(playerData, {Name = player.Name, UserId = player.UserId})
    end
    return playerData
end

-- Function to update all admins
local function UpdateAdmins()
    local admins = {}
    for _, player in Players:GetPlayers() do
        if BanSystemCore.IsAdmin(player) then
            table.insert(admins, player)
        end
    end

    if #admins > 0 then
        local playerData = GetPlayerDataForAdmin()
        for _, adminPlayer in admins do
            updateAdminPlayerListEvent:FireClient(adminPlayer, playerData)
        end
    end
end

-- Player Added Logic
Players.PlayerAdded:Connect(function(player)
    -- Initial check against the current ban list
	if BanSystemCore.CheckPlayerAgainstBanList(player, currentBanList) then
        warn("BanSystemServer: Kicking player on ban list:", player.Name, player.UserId)
        player:Kick("You are currently banned from this experience.")
        return -- Stop further processing for this player
    end

    -- Wait a moment for character etc.
    task.wait(1)

    -- Send initialization info to the client
    local isAdmin = BanSystemCore.IsAdmin(player)
    clientInitializeEvent:FireClient(player, isAdmin)

    -- Update player lists for admins
    UpdateAdmins()
end)

-- Player Removing Logic
Players.PlayerRemoving:Connect(function(player)
    -- Use task.defer to allow PlayerRemoving signals to finish before updating
    task.defer(UpdateAdmins)
end)

-- Handle Client Request for Player List
requestPlayerListEvent.OnServerEvent:Connect(function(player)
    if BanSystemCore.IsAdmin(player) then
        local playerData = GetPlayerDataForAdmin()
        -- Send the list back to the requesting admin only
        updateAdminPlayerListEvent:FireClient(player, playerData)
    else
        warn("BanSystemServer: Non-admin player requested player list:", player.Name)
    end
end)

-- Handle Client Request to Ban Player
requestBanPlayerEvent.OnServerEvent:Connect(function(player, targetUserId, reason)
    if not targetUserId or not reason then return end

    local success, message = BanSystemCore.BanPlayer(player, targetUserId, reason)
    if not success then
        warn("BanSystemServer: Ban failed - ", message)
        -- Optionally notify the admin player of the failure via another remote event
    else
        -- Ban successful, lists will update automatically via PlayerRemoving
        print("BanSystemServer: Ban initiated successfully by", player.Name)
    end
end)

-- Auto-Ban Check Loop
local function AutoBanCheck()
    while true do
        print("BanSystemServer: Starting periodic auto-ban check...")
        local fetchedList = BanSystemCore.FetchBanListFromGitHub()
        if fetchedList then
            currentBanList = fetchedList
            print("BanSystemServer: Updated local ban list.")

            for _, player in Players:GetPlayers() do
                if BanSystemCore.CheckPlayerAgainstBanList(player, currentBanList) then
                     warn("BanSystemServer: Kicking player found during periodic check:", player.Name, player.UserId)
                     player:Kick("You have been identified on the ban list.")
                end
                task.wait() -- Yield between checks
            end
        else
            warn("BanSystemServer: Skipping auto-ban checks as ban list fetch failed.")
        end

        print("BanSystemServer: Auto-ban check finished. Waiting for next interval.")
        task.wait(AUTO_BAN_CHECK_INTERVAL)
    end
end

-- Initial fetch
currentBanList = BanSystemCore.FetchBanListFromGitHub() or {}

-- Start the auto-ban check loop in a separate thread
task.spawn(AutoBanCheck)

print("BanSystemServer: Initialized.")


