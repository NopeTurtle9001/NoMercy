-- ModuleScript in ServerScriptService
-- BanSystemCore: Secure, group-based ban manager with GitHub-backed ban list.
-- IMPORTANT: Read the CONFIG section to wire your group and GitHub settings.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--========================================
-- CONFIGURATION
--========================================
local Config = {
	-- Admin policy: group-based elevation. Set your group and rank threshold.
	GROUP_ID = 12345678,         -- TODO: Replace with your group ID
	MIN_RANK_FOR_ADMIN = 250,    -- TODO: Replace with your minimum rank for admin access
	CREATOR_IS_ADMIN = true,     -- Also allow the experience owner to act as admin

	-- GitHub repository hosting the ban list file.
	GITHUB_OWNER = "NopeTurtle9001",
	GITHUB_REPO = "NoMercy",
	GITHUB_BRANCH = "main",
	BANLIST_PATH = "banlist.json",

	-- Raw URL (public read) for quick fetches. Note: use /main/, not /refs/heads/main.
	BANLIST_RAW_URL = "https://raw.githubusercontent.com/NopeTurtle9001/NoMercy/main/banlist.json",

	-- GitHub API base path for file read/write (requires token).
	GITHUB_CONTENTS_URL = "https://api.github.com/repos/%s/%s/contents/%s",

	-- Network behavior
	MAX_RETRIES = 3,             -- Retries for transient HTTP failures
	RETRY_BASE_DELAY = 0.5,      -- Seconds; backoff will multiply this

	-- Sanitation
	REASON_MAX_LEN = 140,        -- Keep kick/ban reasons short and safe
}

-- IMPORTANT: Provide your token from a protected source. DO NOT hardcode secrets in code.
-- Replace this function with your secure retrieval (e.g., Roblox-protected store or owner-only path).
local function getGitHubToken()
	 return ReplicatedStorage:FindFirstChild("token")
	--return nil -- TODO: Supply securely. Logs will warn if missing when writes are attempted.
end

--========================================
-- LOGGING HELPERS
--========================================
local function Log(...)
	print("[BanSystemCore]", ...)
end

local function Warn(...)
	warn("[BanSystemCore]", ...)
end

-- Troubleshooting tips:
-- - If you see "[BanSystemCore] HTTP request failed", check your network, URL correctness, and Roblox's HTTP permissions (Game Settings > Security).
-- - If you see "GitHub API failed", verify your token scope (contents:write) and that the repo/branch/path exist.
-- - If you see "Invalid JSON", your banlist.json may be malformed; validate it and ensure UTF-8 without BOM.
-- - If you see "No token provided", ensure getGitHubToken() returns a value only accessible to owner/staff.

--========================================
-- BASE64 ENCODER/DECODER
-- (Roblox environment does not always provide Base64 helpers)
--========================================
local base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(str)
	local bytes = {string.byte(str, 1, #str)}
	local encoded = {}

	for i = 1, #bytes, 3 do
		local b1 = bytes[i] or 0
		local b2 = bytes[i + 1] or 0
		local b3 = bytes[i + 2] or 0

		local n = b1 * 65536 + b2 * 256 + b3

		local c1 = math.floor(n / 262144) % 64
		local c2 = math.floor(n / 4096) % 64
		local c3 = math.floor(n / 64) % 64
		local c4 = n % 64

		local pad2 = (i + 1) > #bytes
		local pad1 = (i + 2) > #bytes

		table.insert(encoded, base64Chars:sub(c1 + 1, c1 + 1))
		table.insert(encoded, base64Chars:sub(c2 + 1, c2 + 1))
		table.insert(encoded, pad1 and "=" or base64Chars:sub(c3 + 1, c3 + 1))
		table.insert(encoded, pad2 and "=" or base64Chars:sub(c4 + 1, c4 + 1))
	end

	return table.concat(encoded)
end

local base64DecodeLookup = {}
for i = 1, #base64Chars do
	base64DecodeLookup[base64Chars:sub(i, i)] = i - 1
end

local function Base64Decode(data)
	-- Remove any whitespace / line breaks often present in API responses
	data = data:gsub("%s+", "")
	local bytes = {}
	local i = 1

	while i <= #data do
		local c1 = base64DecodeLookup[data:sub(i, i)] or 0
		local c2 = base64DecodeLookup[data:sub(i + 1, i + 1)] or 0
		local c3char = data:sub(i + 2, i + 2)
		local c4char = data:sub(i + 3, i + 3)
		local c3 = (c3char == "=") and 0 or (base64DecodeLookup[c3char] or 0)
		local c4 = (c4char == "=") and 0 or (base64DecodeLookup[c4char] or 0)

		local n = (c1 * 262144) + (c2 * 4096) + (c3 * 64) + c4

		local b1 = math.floor(n / 65536) % 256
		local b2 = math.floor(n / 256) % 256
		local b3 = n % 256

		table.insert(bytes, string.char(b1))
		if c3char ~= "=" then table.insert(bytes, string.char(b2)) end
		if c4char ~= "=" then table.insert(bytes, string.char(b3)) end

		i = i + 4
	end

	return table.concat(bytes)
end

--========================================
-- REQUEST HELPER (with retries and fallback)
--========================================
local function httpRequest(method, url, headers, body)
	headers = headers or {}
	local attempt = 0
	local delayBase = Config.RETRY_BASE_DELAY

	while attempt < Config.MAX_RETRIES do
		attempt += 1

		-- Preferred path: RequestAsync (supports headers and bodies properly)
		local ok, res = pcall(function()
			return HttpService:RequestAsync({
				Url = url,
				Method = method,
				Headers = headers,
				Body = body,
			})
		end)

		if ok and res and res.Success then
			return res
		end

		-- Fallback path for environments with RequestAsync inconsistencies:
		-- Only safe for simple GET without headers/body.
		if (not ok or (res and not res.Success)) and method == "GET" and (not headers or next(headers) == nil) and (not body) then
			local ok2, bodyText = pcall(function()
				return HttpService:GetAsync(url)
			end)
			if ok2 and bodyText then
				return { Success = true, Body = bodyText, StatusCode = 200, StatusMessage = "OK" }
			end
		end

		-- On failure, log once and backoff
		if attempt == 1 then
			Warn(("HTTP request failed (attempt %d): %s %s"):format(
				attempt,
				tostring(res and (res.StatusCode .. " " .. (res.StatusMessage or "")) or "pcall error"),
				url
				))
			-- Troubleshooting: Check URL correctness, Roblox HTTP permissions, and that remote service is reachable.
		end

		task.wait(delayBase * attempt) -- Exponential-ish backoff
	end

	return nil
end

--========================================
-- ADMIN CHECK
--========================================
local function IsAdmin(player)
	if not player then return false end

	-- Group-based check
	local rank = 0
	local ok, err = pcall(function()
		rank = player:GetRankInGroup(Config.GROUP_ID)
	end)
	if ok and rank >= Config.MIN_RANK_FOR_ADMIN then
		return true
	end
	-- Troubleshooting: If rank lookups fail, ensure the group ID is correct and group visibility allows rank checks.

	-- Optional creator fallback
	if Config.CREATOR_IS_ADMIN and game.CreatorType == Enum.CreatorType.User then
		if player.UserId == game.CreatorId then
			return true
		end
	end

	return false
end

--========================================
-- SANITIZATION
--========================================
local function sanitizeReason(reason)
	if type(reason) ~= "string" then
		reason = tostring(reason or "")
	end
	-- Strip control chars (keep printable ASCII). Replace line breaks/tabs with spaces.
	reason = reason:gsub("[\r\n\t]", " ")
	reason = reason:gsub("[^\032-\126]", "")
	if #reason > Config.REASON_MAX_LEN then
		reason = string.sub(reason, 1, Config.REASON_MAX_LEN)
	end
	return reason
end

--========================================
-- BANLIST FETCH (RAW -> public read, fast)
--========================================
local function FetchBanListFromRaw()
	local res = httpRequest("GET", Config.BANLIST_RAW_URL, nil, nil)
	if not res then
		Warn("Unable to fetch ban list (raw). Falling back to last-known cache if available.")
		return nil
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(res.Body)
	end)
	if not ok or type(data) ~= "table" then
		Warn("Invalid JSON when decoding ban list from raw URL. Validate banlist.json formatting.")
		return nil
	end

	-- Count entries for log visibility
	local count = 0
	for _ in pairs(data) do count += 1 end
	Log(("Fetched ban list (raw) with %d entries."):format(count))

	return data
end

--========================================
-- GITHUB CONTENTS API (read for SHA/content; write for updates)
--========================================
local function buildContentsUrl()
	return string.format(
		Config.GITHUB_CONTENTS_URL,
		Config.GITHUB_OWNER,
		Config.GITHUB_REPO,
		Config.BANLIST_PATH
	)
end

local function fetchFileForWrite(token)
	local headers = {
		["Authorization"] = "token " .. token,
		["User-Agent"] = "roblox-ban-system",
		["Accept"] = "application/vnd.github+json",
	}
	local res = httpRequest("GET", buildContentsUrl(), headers, nil)
	if not res then
		Warn("GitHub API failed to fetch file for write (no response). Check token, repo path, or network.")
		return nil
	end

	local ok, json = pcall(function()
		return HttpService:JSONDecode(res.Body)
	end)
	if not ok or type(json) ~= "table" then
		Warn("GitHub API returned non-JSON or unexpected JSON. Check permissions or path.")
		return nil
	end

	-- json.content is base64-encoded; json.sha is required for PUT updates
	if not json.sha then
		Warn("GitHub API response missing SHA. Ensure the file exists and token has contents:read.")
		return nil
	end

	local contentStr = ""
	if type(json.content) == "string" then
		contentStr = Base64Decode(json.content)
	else
		Warn("GitHub API response missing 'content' (file may be binary or unavailable). Proceeding with empty content.")
	end

	return {
		sha = json.sha,
		content = contentStr,
	}
end

local function putFile(token, message, newContentStr, sha)
	local headers = {
		["Authorization"] = "token " .. token,
		["User-Agent"] = "roblox-ban-system",
		["Accept"] = "application/vnd.github+json",
		["Content-Type"] = "application/json",
	}

	local bodyTable = {
		message = message,
		content = Base64Encode(newContentStr), -- GitHub requires base64 content
		sha = sha,                             -- Required to update existing files
		branch = Config.GITHUB_BRANCH,
	}
	local body = HttpService:JSONEncode(bodyTable)

	local res = httpRequest("PUT", buildContentsUrl(), headers, body)
	if not res then
		Warn("GitHub API failed to PUT file (no response). Check token scope (contents:write) and branch protection.")
		return false
	end

	-- Expect 200 (update) or 201 (create)
	if res.StatusCode ~= 200 and res.StatusCode ~= 201 then
		Warn(("GitHub PUT unexpected status %s: %s"):format(tostring(res.StatusCode), tostring(res.StatusMessage)))
		-- Troubleshooting: If you see 409, the SHA is outdated. Re-fetch the file and retry the PUT.
		return false
	end

	return true
end

--========================================
-- PUBLIC MODULE API
--========================================
local BanSystemCore = {}

-- Returns: table mapping string UserId -> reason (string), or nil on failure
function BanSystemCore.FetchBanList()
	return FetchBanListFromRaw()
end

-- Returns true if the player is banned (based on provided banList map)
function BanSystemCore.CheckPlayerAgainstBanList(player, banList)
	if not player or not banList then return false end
	return banList[tostring(player.UserId)] ~= nil
end

-- Optional helper: get the ban reason for a player (or nil)
function BanSystemCore.GetBanReason(player, banList)
	if not player or not banList then return nil end
	return banList[tostring(player.UserId)]
end

-- Admin check using group roles and optional creator fallback
function BanSystemCore.IsAdmin(player)
	return IsAdmin(player)
end

-- Append/update a ban entry in GitHub and attempt Roblox ban
-- Returns (success:boolean, message:string)
function BanSystemCore.BanPlayer(adminPlayer, targetUserId, reason)
	-- Authorization
	if not IsAdmin(adminPlayer) then
		Warn(("Unauthorized ban attempt by %s (%d)"):format(adminPlayer and adminPlayer.Name or "?", adminPlayer and adminPlayer.UserId or -1))
		return false, "Unauthorized"
	end

	-- Validate inputs
	if not targetUserId or tonumber(targetUserId) == nil then
		return false, "Missing or invalid target UserId"
	end
	reason = sanitizeReason(reason or "")
	if reason == "" then
		return false, "Missing reason"
	end

	local token = getGitHubToken()
	if not token then
		Warn("No token provided for GitHub write. Configure getGitHubToken() to return a secure token.")
		-- You can still proceed to ban in Roblox without writing to GitHub, if desired.
	end

	local targetPlayer = Players:GetPlayerByUserId(tonumber(targetUserId))

	Log(string.format("Admin '%s' (%d) initiating ban for UserID %s. Reason: %s",
		adminPlayer.Name, adminPlayer.UserId, tostring(targetUserId), reason))

	-- 1) Update GitHub banlist (if token available)
	if token then
		local file = fetchFileForWrite(token)
		if not file then
			Warn("Failed to fetch banlist.json from GitHub for update. Ban will continue in-game; sync later.")
		else
			-- Parse existing JSON (map: string UserId -> reason)
			local data = {}
			if file.content and #file.content > 0 then
				local ok, parsed = pcall(function() return HttpService:JSONDecode(file.content) end)
				if ok and typeof(parsed) == "table" then
					data = parsed
				else
					Warn("Existing banlist.json invalid JSON; starting from a new map for this update.")
				end
			end

			-- Merge/update entry
			data[tostring(targetUserId)] = reason

			-- Encode and PUT with SHA
			local newContentStr = HttpService:JSONEncode(data)
			local okPut = putFile(token, "Update banlist.json", newContentStr, file.sha)
			if not okPut then
				Warn("Failed to write updated banlist.json to GitHub. Check logs above for HTTP status or SHA conflicts.")
				-- Troubleshooting: If 409 Conflict occurs, re-run: fetchFileForWrite() then putFile() again.
			else
				Log("banlist.json successfully updated on GitHub.")
			end
		end
	end

	-- 2) Roblox-side ban
	local success, banErr = pcall(function()
		-- Requires: Game published + Game Settings > Security > Allow HTTP + API Services enabled.
		Players:BanAsync(tonumber(targetUserId), reason)
	end)

	if success then
		Log(("Successfully banned UserID %s"):format(tostring(targetUserId)))
		if targetPlayer then
			targetPlayer:Kick("You have been banned from this experience. Reason: " .. reason)
		end
		return true, "Banned"
	else
		local errStr = tostring(banErr)
		Warn(("Failed to ban UserID %s - %s"):format(tostring(targetUserId), errStr))
		-- Troubleshooting common cases:
		-- - "Cannot ban user from unpublished game": Publish the game.
		-- - "API Services not enabled": Enable in Game Settings > Security.
		-- - "User is already banned": No action needed; update reason in GitHub if desired.
		if string.find(errStr, "unpublished") then
			return false, "Ban API requires the game to be published."
		elseif string.find(errStr, "API Services") then
			return false, "Enable 'Studio Access to API Services' in Game Settings > Security."
		elseif string.find(errStr, "already banned") then
			return false, "User is already banned."
		end
		return false, "Failed to ban user: " .. errStr
	end
end

return BanSystemCore
