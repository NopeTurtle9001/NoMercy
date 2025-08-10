-- Script in ServerScriptService: BanSystemServer
-- Coordinates player bans using BanSystemCore and RemoteEvents

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HttpService = game:GetService("HttpService")

-- Load BanSystemCore module
local BanSystemCore = require(ServerScriptService:WaitForChild("BanSystemCore"))

--===================================================
-- Remote Event References (client <-> server)
--===================================================
local AdminKickEvent = ReplicatedStorage:WaitForChild("AdminKickEvent", 5)
local BanPlayerEvent = ReplicatedStorage:WaitForChild("BanPlayerEvent", 5)
local clientInitializeEvent = ReplicatedStorage:WaitForChild("BanSystem_ClientInitialize", 5)
local requestPlayerListEvent = ReplicatedStorage:WaitForChild("BanSystem_RequestPlayerList", 5)
local requestBanPlayerEvent = ReplicatedStorage:WaitForChild("BanSystem_RequestBanPlayer", 5)

--===================================================
-- Constants and Ban List Cache
--===================================================
local AUTO_BAN_CHECK_INTERVAL = 180 -- Check every 3 minutes
local currentBanList = {}           -- Cached list from GitHub

--===================================================
-- Kick Handler: Admin action via RemoteEvent
--===================================================
local function onAdminKick(adminPlayer, targetUserId)
	local targetPlayer = Players:GetPlayerByUserId(tonumber(targetUserId))
	if targetPlayer then
		if BanSystemCore.IsAdmin(adminPlayer) then
			targetPlayer:Kick("You have been kicked by an admin.")
			print(("BanSystemServer: Admin %s kicked player %s (%d)"):format(
				adminPlayer.Name, targetPlayer.Name, targetPlayer.UserId))
		else
			warn(("BanSystemServer: Unauthorized kick attempt by %s"):format(adminPlayer.Name))
		end
	else
		warn(("BanSystemServer: No player found with UserId %s for kick."):format(targetUserId))
	end
end

--===================================================
-- Ban Handler: Admin RemoteEvent initiates a full ban
--===================================================
local function onAdminBan(adminPlayer, targetUserId, reason)
	if not targetUserId or not reason then
		warn("BanSystemServer: Missing UserId or reason in ban request.")
		return
	end

	print(("BanSystemServer: Admin %s attempting ban on %s - Reason: %s"):format(
		adminPlayer.Name, targetUserId, reason))

	local success, message = BanSystemCore.BanPlayer(adminPlayer, targetUserId, reason)

	if success then
		print(("BanSystemServer: Ban successful on UserId %s"):format(targetUserId))
	else
		warn(("BanSystemServer: Ban failed - %s"):format(tostring(message)))
		-- Optional: Fire client feedback event here
	end
end

--===================================================
-- Ban Check on Join
--===================================================
Players.PlayerAdded:Connect(function(player)
	-- Step 1: Ban list check
	if BanSystemCore.CheckPlayerAgainstBanList(player, currentBanList) then
		warn(("BanSystemServer: Player %s (%d) matched ban list. Kicking..."):format(
			player.Name, player.UserId))
		player:Kick("You are currently banned from this experience.")
		return
	end

	-- Step 2: Allow character to initialize
	task.wait(1)

	-- Step 3: Inform client about admin status
	local isAdmin = BanSystemCore.IsAdmin(player)
	clientInitializeEvent:FireClient(player, isAdmin)
end)

--===================================================
-- Periodic Ban List Refresh and Recheck
--===================================================
local function AutoBanCheck()
	while true do
		print("BanSystemServer: Starting scheduled ban list refresh...")

		local fetchedList = BanSystemCore.FetchBanList()
		if fetchedList then
			currentBanList = fetchedList
			print("BanSystemServer: Ban list refreshed successfully.")

			for _, player in ipairs(Players:GetPlayers()) do
				if BanSystemCore.CheckPlayerAgainstBanList(player, currentBanList) then
					warn(("BanSystemServer: Player %s (%d) found on ban list. Kicking..."):format(
						player.Name, player.UserId))
					player:Kick("You are currently banned from this experience.")
				end
				task.wait(0.05) -- Minor delay between checks for stability
			end
		else
			warn("BanSystemServer: Failed to refresh ban list. Retaining previous cache.")
			-- Troubleshooting: Check GitHub status, raw URL correctness, and HTTP permissions.
		end

		print("BanSystemServer: Auto-ban cycle complete. Waiting for next interval...")
		task.wait(AUTO_BAN_CHECK_INTERVAL)
	end
end

--===================================================
-- Startup Logic
--===================================================
print("BanSystemServer: Initializing...")

-- Initial ban list fetch
currentBanList = BanSystemCore.FetchBanList() or {}

-- Launch auto-ban loop in parallel
task.spawn(AutoBanCheck)

-- Wire RemoteEvents
AdminKickEvent.OnServerEvent:Connect(onAdminKick)
BanPlayerEvent.OnServerEvent:Connect(onAdminBan)

print("BanSystemServer: Ready.")
