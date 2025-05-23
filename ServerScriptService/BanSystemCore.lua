-- ModuleScript in ServerScriptService
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataModel = game:GetService("DataModel")
local DataStores = game:GetService("DataStoreService")
--local experience = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
--local owner = experience.CreatorId
--local ownerType = experience.CreatorType

-- Get the place creator's ID
local CreatorId = game.CreatorId

-- Create a table to store the IDs of the collaborators based on their permissions
local CollaboratorPermissions = {}

-- Get the experience's collaborators
local CollaboratorsFound = nil
--if DataModel.Collaborators == nil then
	--print("Collaborators not found.")
	--CollaboratorsFound = false
--else
	--CollaboratorsFound = true
	--print("Found the game's collaborators: " .. tostring(DataModel.Collaborators))
	--local Collaborators = DataModel.Collaborators


	-- Loop through the collaborators and check their permissions
	--for _, collaborator in pairs(Collaborators) do
		-- Check if the collaborator has edit permissions
		--if collaborator.Permission == Enum.Permission.Edit then
			-- Add the collaborator's ID to the table
			--table.insert(CollaboratorPermissions, collaborator.UserId)
			-- Check if the collaborator has play permissions
		--elseif collaborator.Permission == Enum.Permission.Play then
			-- Add the collaborator's ID to the table
			-- do nothing
		--end
		--table.insert(CollaboratorPermissions, owner)
	--end

	-- Print the table of collaborator IDs
	--print("Collaborator Permissions:")
	--for i, id in pairs(CollaboratorPermissions) do
		--print(i .. ": " .. id)
	--end
--end


-- Print the place creator's ID
print("Place Creator ID: " .. CreatorId)
local BanSystemCore = {}

-- Configuration
-- IMPORTANT: Replace with the RAW URL to your ban list file on GitHub.
-- The file should contain one Roblox UserId per line.
local GITHUB_BANLIST_URL = "https://raw.githubusercontent.com/NopeTurtle9001/NoMercy/refs/heads/main/banlist.json"

-- IMPORTANT: Add the UserIDs of players who should have admin access to the ban panel.
local ADMIN_USER_IDS = {}
if CollaboratorPermissions ~= nil then
	ADMIN_USER_IDS = CollaboratorPermissions
else
	-- do nothing
end

-- IMPORTANT: Replace with your GitHub repo URL if you plan external logging (optional, not implemented here)
local GITHUB_REPO_FOR_LOGGING = "YOUR_GITHUB_REPO_URL_HERE" -- For reference only

-- Automatically include the game creator as an admin
if game.CreatorType == Enum.CreatorType.User then
    table.insert(ADMIN_USER_IDS, game.CreatorId)
end
-- You might want to add group rank checks here as well

-- Check if a player is an admin
function BanSystemCore.IsAdmin(player)
    if not player then return false end

    -- Check explicit admin list
    for _, adminId in ADMIN_USER_IDS do
        if player.UserId == adminId then
            return true
        end
    end

    -- Add group rank checks here if needed
    -- Example:
    -- local GROUP_ID = 12345
    -- local MIN_RANK = 250
    -- if player:GetRankInGroup(GROUP_ID) >= MIN_RANK then
    --     return true
    -- end

    return false
end

-- Fetch the ban list from GitHub
function BanSystemCore.FetchBanListFromGitHub()
    if GITHUB_BANLIST_URL == "YOUR_RAW_GITHUB_CONTENT_URL_HERE" or GITHUB_BANLIST_URL == "" then
        warn("BanSystemCore: GitHub Ban List URL not configured.")
        return nil
    end

    local success, result = pcall(function()
        -- Use RequestAsync for more control and header setting if needed in future
        local response = HttpService:RequestAsync({
            Url = GITHUB_BANLIST_URL,
            Method = "GET"
        })
        if response.Success then
            return response.Body
        else
            warn("BanSystemCore: HTTP request failed: ", response.StatusCode, response.StatusMessage)
            return nil
        end
    end)

    if not success then
        warn("BanSystemCore: Error during HTTP request - ", result)
        return nil
    end

    if not result then
        -- Previous warning from pcall already indicated the issue
        return nil
	end

    -- Assuming ban list is plain text, one UserId per line
	local json = game:GetService("HttpService"):JSONDecode(game.HttpService:GetAsync(GITHUB_BANLIST_URL))
	local banList = {}
	for id, reason in pairs(json) do
		banList[tonumber(id)] = reason
	end

	--for id, reason in pairs(json) do
		--print("ID:", id)
		--print("Reason:", reason)
		--print()
	--end
	print("BanSystemCore: Fetched ban list with", #banList, "entries.")
	for id, _ in pairs(banList) do
		print(id)  -- print the ID
	end
	return banList
end

-- Check if a player's ID is in the provided ban list table
function BanSystemCore.CheckPlayerAgainstBanList(player, banList)
	return (banList[player.UserId] == true) and (player.UserId ~= nil)
end
function DoBan (MESSAGE, PlayerID, Reason)
	local owner = "NopeTurtle9001"
	local repo = "NoMercy"
	local path = "banlist.json"
	local branch = "main"
	local token = "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"
	local sha = ""
	local message = MESSAGE
	local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, path)
	local response = HttpService:GetAsync(url)
	local existing_json = response:JsonDecode()
	local existing_data = existing_json.content
	local data_store_name = "banlist"
	local scope = "global"
	local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	
	local headerS = {
		["Authorization"] = "token " .. token,
		["User-Agent"] = "lua-http"
	}
	--body of the request
	local bdata = HttpService:GetAsync(url,true, headerS)
	--get sha now
	sha = bdata.sha
	
	
	
	
	--encode base 64 all github content must be encoded before committing
	local function encode64(str)
		local encoded = ""
		local bytes = {str:byte(1, #str)}

		for i = 1, #bytes, 3 do
			local b1, b2, b3 = bytes[i] or 0, bytes[i+1] or 0, bytes[i+2] or 0
			local num = (b1 * 65536) + (b2 * 256) + b3  -- Simulating bitwise shifts using multiplication

			local c1 = math.floor(num / 262144) % 64
			local c2 = math.floor(num / 4096) % 64
			local c3 = math.floor(num / 64) % 64
			local c4 = num % 64

			encoded = encoded 
				.. base64Chars:sub(c1 + 1, c1 + 1)
				.. base64Chars:sub(c2 + 1, c2 + 1)
				.. (#bytes - i < 2 and "=" or base64Chars:sub(c3 + 1, c3 + 1))
				.. (#bytes - i < 1 and "=" or base64Chars:sub(c4 + 1, c4 + 1))
		end

		return encoded
	end
	
	-- Commit changes
	local function commit_changes()	
		local new_line = {
			["id"] = PlayerID,
			["reason"] = Reason
		}
		local updated_data = {
			["banlist"] = {}
		}
		for k, v in pairs(existing_data) do
			table.insert(updated_data["banlist"], v)
		end
		table.insert(updated_data["banlist"], new_line)
		local new_json = {
			["content"] = HttpService:JsonEncode(updated_data)
			--["sha"] = existing_json.sha
		}
		local headers = {
			["Authorization"] = "token " .. token,
			["User-Agent"] = "lua-http",
			["Content-Type"] = "application/json"
		}
		local body = HttpService:JSONEncode({
			message = message,
			content = new_json,
			sha = sha,
			branch = branch
		})
		local body = HttpService:JSONEncode({
			message = message,
			content = encode64(new_json),
			sha = sha,
			branch = branch
		})
		local patch_request = {
			["method"] = "PUT",
			["url"] = url,
			["headers"] = headers,
			["body"] = body
		}

		local response = HttpService:RequestAsync(patch_request)
	end
end

-- Ban a player (requires admin privileges)
function BanSystemCore.BanPlayer(adminPlayer, targetUserId, reason)
    if not BanSystemCore.IsAdmin(adminPlayer) then
        warn("BanSystemCore: Unauthorized ban attempt by", adminPlayer.Name, "(", adminPlayer.UserId, ")")
        return false, "Unauthorized"
    end

    if not targetUserId or not reason or reason == "" then
        return false, "Missing target UserId or reason"
    end

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)

    -- Log the ban attempt (Simulated - replace with actual logging/GitHub interaction via external service if needed)
    print(string.format("BanSystemCore: Admin '%s' (%d) initiating ban for UserID %d. Reason: %s", adminPlayer.Name, adminPlayer.UserId, targetUserId, reason))
	-- Placeholder for where you might send data to an external service to log to GitHub
	DoBan("Update banlist.json",targetUserId,reason)
    -- print("BanSystemCore: Data would be appended to GitHub via external service using URL:", GITHUB_REPO_FOR_LOGGING)
    -- Perform the ban using Roblox API
    local success, banResult = pcall(function()
        -- NOTE: BanUserAsync requires specific permissions enabled in Game Settings > Security > Allow API Services
        -- It also requires the game to be published.
        Players:BanAsync(targetUserId, reason)
    end)

    if success then
        print("BanSystemCore: Successfully banned UserID", targetUserId)
        -- Kick the player if they are still in the server after the ban
        if targetPlayer then
            targetPlayer:Kick("You have been banned from this experience. Reason: " .. reason)
        end
        return true
    else
        warn("BanSystemCore: Failed to ban UserID", targetUserId, "-", banResult)
        -- Provide more specific feedback if possible
        if string.find(banResult, "Cannot ban user from unpublished game") then
             return false, "Ban API requires the game to be published."
        elseif string.find(banResult, "API Services not enabled") then
             return false, "Ban API requires 'Enable Studio Access to API Services' in Game Settings > Security."
        elseif string.find(banResult, "User is already banned") then
             return false, "User is already banned."
        end
        return false, "Failed to ban user: " .. banResult
    end
end
return BanSystemCore

-- ModuleScript in ServerScriptService
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local DataModel = game:GetService("DataModel")
local DataStores = game:GetService("DataStoreService")
--local experience = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
--local owner = experience.CreatorId
--local ownerType = experience.CreatorType

-- Get the place creator's ID
local CreatorId = game.CreatorId

-- Create a table to store the IDs of the collaborators based on their permissions
local CollaboratorPermissions = {}

-- Get the experience's collaborators
local CollaboratorsFound = nil
--if DataModel.Collaborators == nil then
	--print("Collaborators not found.")
	--CollaboratorsFound = false
--else
	--CollaboratorsFound = true
	--print("Found the game's collaborators: " .. tostring(DataModel.Collaborators))
	--local Collaborators = DataModel.Collaborators


	-- Loop through the collaborators and check their permissions
	--for _, collaborator in pairs(Collaborators) do
		-- Check if the collaborator has edit permissions
		--if collaborator.Permission == Enum.Permission.Edit then
			-- Add the collaborator's ID to the table
			--table.insert(CollaboratorPermissions, collaborator.UserId)
			-- Check if the collaborator has play permissions
		--elseif collaborator.Permission == Enum.Permission.Play then
			-- Add the collaborator's ID to the table
			-- do nothing
		--end
		--table.insert(CollaboratorPermissions, owner)
	--end

	-- Print the table of collaborator IDs
	--print("Collaborator Permissions:")
	--for i, id in pairs(CollaboratorPermissions) do
		--print(i .. ": " .. id)
	--end
--end


-- Print the place creator's ID
print("Place Creator ID: " .. CreatorId)
local BanSystemCore = {}

-- Configuration
-- IMPORTANT: Replace with the RAW URL to your ban list file on GitHub.
-- The file should contain one Roblox UserId per line.
local GITHUB_BANLIST_URL = "https://raw.githubusercontent.com/NopeTurtle9001/NoMercy/refs/heads/main/banlist.json"

-- IMPORTANT: Add the UserIDs of players who should have admin access to the ban panel.
local ADMIN_USER_IDS = {}
if CollaboratorPermissions ~= nil then
	ADMIN_USER_IDS = CollaboratorPermissions
else
	-- do nothing
end

-- IMPORTANT: Replace with your GitHub repo URL if you plan external logging (optional, not implemented here)
local GITHUB_REPO_FOR_LOGGING = "YOUR_GITHUB_REPO_URL_HERE" -- For reference only

-- Automatically include the game creator as an admin
if game.CreatorType == Enum.CreatorType.User then
    table.insert(ADMIN_USER_IDS, game.CreatorId)
end
-- You might want to add group rank checks here as well

-- Check if a player is an admin
function BanSystemCore.IsAdmin(player)
    if not player then return false end

    -- Check explicit admin list
    for _, adminId in ADMIN_USER_IDS do
        if player.UserId == adminId then
            return true
        end
    end

    -- Add group rank checks here if needed
    -- Example:
    -- local GROUP_ID = 12345
    -- local MIN_RANK = 250
    -- if player:GetRankInGroup(GROUP_ID) >= MIN_RANK then
    --     return true
    -- end

    return false
end

-- Fetch the ban list from GitHub
function BanSystemCore.FetchBanListFromGitHub()
    if GITHUB_BANLIST_URL == "YOUR_RAW_GITHUB_CONTENT_URL_HERE" or GITHUB_BANLIST_URL == "" then
        warn("BanSystemCore: GitHub Ban List URL not configured.")
        return nil
    end

    local success, result = pcall(function()
        -- Use RequestAsync for more control and header setting if needed in future
        local response = HttpService:RequestAsync({
            Url = GITHUB_BANLIST_URL,
            Method = "GET"
        })
        if response.Success then
            return response.Body
        else
            warn("BanSystemCore: HTTP request failed: ", response.StatusCode, response.StatusMessage)
            return nil
        end
    end)

    if not success then
        warn("BanSystemCore: Error during HTTP request - ", result)
        return nil
    end

    if not result then
        -- Previous warning from pcall already indicated the issue
        return nil
	end

    -- Assuming ban list is plain text, one UserId per line
	local json = game:GetService("HttpService"):JSONDecode(game.HttpService:GetAsync(GITHUB_BANLIST_URL))
	local banList = {}
	for id, reason in pairs(json) do
		banList[tonumber(id)] = reason
	end

	--for id, reason in pairs(json) do
		--print("ID:", id)
		--print("Reason:", reason)
		--print()
	--end
	print("BanSystemCore: Fetched ban list with", #banList, "entries.")
	for id, _ in pairs(banList) do
		print(id)  -- print the ID
	end
	return banList
end

-- Check if a player's ID is in the provided ban list table
function BanSystemCore.CheckPlayerAgainstBanList(player, banList)
	return (banList[player.UserId] == true) and (player.UserId ~= nil)
end
function DoBan (MESSAGE, PlayerID, Reason)
	local owner = "NopeTurtle9001"
	local repo = "NoMercy"
	local path = "banlist.json"
	local branch = "main"
	local token = "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"
	local sha = ""
	local message = MESSAGE
	local url = string.format("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, path)
	local response = HttpService:GetAsync(url)
	local existing_json = response:JsonDecode()
	local existing_data = existing_json.content
	local data_store_name = "banlist"
	local scope = "global"
	local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	
	local headerS = {
		["Authorization"] = "token " .. token,
		["User-Agent"] = "lua-http"
	}
	--body of the request
	local bdata = HttpService:GetAsync(url,true, headerS)
	--get sha now
	sha = bdata.sha
	
	
	
	
	--encode base 64 all github content must be encoded before committing
	local function encode64(str)
		local encoded = ""
		local bytes = {str:byte(1, #str)}

		for i = 1, #bytes, 3 do
			local b1, b2, b3 = bytes[i] or 0, bytes[i+1] or 0, bytes[i+2] or 0
			local num = (b1 * 65536) + (b2 * 256) + b3  -- Simulating bitwise shifts using multiplication

			local c1 = math.floor(num / 262144) % 64
			local c2 = math.floor(num / 4096) % 64
			local c3 = math.floor(num / 64) % 64
			local c4 = num % 64

			encoded = encoded 
				.. base64Chars:sub(c1 + 1, c1 + 1)
				.. base64Chars:sub(c2 + 1, c2 + 1)
				.. (#bytes - i < 2 and "=" or base64Chars:sub(c3 + 1, c3 + 1))
				.. (#bytes - i < 1 and "=" or base64Chars:sub(c4 + 1, c4 + 1))
		end

		return encoded
	end
	
	-- Commit changes
	local function commit_changes()	
		local new_line = {
			["id"] = PlayerID,
			["reason"] = Reason
		}
		local updated_data = {
			["banlist"] = {}
		}
		for k, v in pairs(existing_data) do
			table.insert(updated_data["banlist"], v)
		end
		table.insert(updated_data["banlist"], new_line)
		local new_json = {
			["content"] = HttpService:JsonEncode(updated_data)
			--["sha"] = existing_json.sha
		}
		local headers = {
			["Authorization"] = "token " .. token,
			["User-Agent"] = "lua-http",
			["Content-Type"] = "application/json"
		}
		local body = HttpService:JSONEncode({
			message = message,
			content = new_json,
			sha = sha,
			branch = branch
		})
		local body = HttpService:JSONEncode({
			message = message,
			content = encode64(new_json),
			sha = sha,
			branch = branch
		})
		local patch_request = {
			["method"] = "PUT",
			["url"] = url,
			["headers"] = headers,
			["body"] = body
		}

		local response = HttpService:RequestAsync(patch_request)
	end
end

-- Ban a player (requires admin privileges)
function BanSystemCore.BanPlayer(adminPlayer, targetUserId, reason)
    if not BanSystemCore.IsAdmin(adminPlayer) then
        warn("BanSystemCore: Unauthorized ban attempt by", adminPlayer.Name, "(", adminPlayer.UserId, ")")
        return false, "Unauthorized"
    end

    if not targetUserId or not reason or reason == "" then
        return false, "Missing target UserId or reason"
    end

    local targetPlayer = Players:GetPlayerByUserId(targetUserId)

    -- Log the ban attempt (Simulated - replace with actual logging/GitHub interaction via external service if needed)
    print(string.format("BanSystemCore: Admin '%s' (%d) initiating ban for UserID %d. Reason: %s", adminPlayer.Name, adminPlayer.UserId, targetUserId, reason))
	-- Placeholder for where you might send data to an external service to log to GitHub
	DoBan("Update banlist.json",targetUserId,reason)
    -- print("BanSystemCore: Data would be appended to GitHub via external service using URL:", GITHUB_REPO_FOR_LOGGING)
    -- Perform the ban using Roblox API
    local success, banResult = pcall(function()
        -- NOTE: BanUserAsync requires specific permissions enabled in Game Settings > Security > Allow API Services
        -- It also requires the game to be published.
        Players:BanAsync(targetUserId, reason)
    end)

    if success then
        print("BanSystemCore: Successfully banned UserID", targetUserId)
        -- Kick the player if they are still in the server after the ban
        if targetPlayer then
            targetPlayer:Kick("You have been banned from this experience. Reason: " .. reason)
        end
        return true
    else
        warn("BanSystemCore: Failed to ban UserID", targetUserId, "-", banResult)
        -- Provide more specific feedback if possible
        if string.find(banResult, "Cannot ban user from unpublished game") then
             return false, "Ban API requires the game to be published."
        elseif string.find(banResult, "API Services not enabled") then
             return false, "Ban API requires 'Enable Studio Access to API Services' in Game Settings > Security."
        elseif string.find(banResult, "User is already banned") then
             return false, "User is already banned."
        end
        return false, "Failed to ban user: " .. banResult
    end
end
return BanSystemCore
