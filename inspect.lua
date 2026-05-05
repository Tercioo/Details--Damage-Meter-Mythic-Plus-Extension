---@type string, private
local tocFileName, private = ...

---@type detailsmythicplus
local addon = private.addon

local issecretvalue = issecretvalue
local InCombatLockdown = InCombatLockdown
local UnitIsPlayer = UnitIsPlayer
local type = type
local UnitGUID = UnitGUID
local UnitIsUnit = UnitIsUnit
local tonumber = tonumber
local string = string
local GetTime = GetTime
local GetAverageItemLevel = GetAverageItemLevel
local C_PaperDollInfo = C_PaperDollInfo

local CACHE_TTL = 30
local INSPECT_REQUEST_COOLDOWN = 1.25
local INSPECT_PENDING_TIMEOUT = 2.0
local InspectCache = {}
local unitNameGuidCache = {}

local inspectQueue = {}

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("INSPECT_READY")

local function safeEquals(a, b)
	if (a == nil or b == nil) then
		return false
	end

	if (issecretvalue(a) or issecretvalue(b)) then
		return false
	end

	return a == b
end

local function RemoveFromQueue(guid)
	for i = #inspectQueue, 1, -1 do
		if safeEquals(inspectQueue[i], guid) then
			table.remove(inspectQueue, i)
		end
	end
end

local function FinishInspectRequest(guid)
	if (not guid) then
		return
	end

	local entry = InspectCache[guid]
	if (entry) then
		entry.pendingUnit = nil
		entry.pendingRequestedAt = nil
	end

	RemoveFromQueue(guid)
end

local function ProcessQueue()
	if (InCombatLockdown()) then
		return
	end

	local currentTime = GetTime()

	for i = 1, #inspectQueue do
		local guid = inspectQueue[i]
		if (issecretvalue(guid)) then
			table.remove(inspectQueue, i)
			return
		end

		local entry = InspectCache[guid]
		if (not entry) then
			table.remove(inspectQueue, i)
			return
		end

		if (entry.pendingRequestedAt and (currentTime - entry.pendingRequestedAt) >= INSPECT_PENDING_TIMEOUT) then
			entry.pendingUnit = nil
			entry.pendingRequestedAt = nil
		end

		if (entry.pendingRequestedAt) then
			return
		end

		local unit = entry.pendingUnit
		if (not unit or issecretvalue(unit)) then
			table.remove(inspectQueue, i)
			return
		end

		local unitGuid = UnitGUID(unit)
		if (issecretvalue(unitGuid) or unitGuid ~= guid) then
			table.remove(inspectQueue, i)
			return
		end

		if (CanInspect(unit)) then
			entry.pendingRequestedAt = currentTime
			NotifyInspect(unit)
		end

		return
	end
end

--- Request the item level for a unit. The callback is invoked with
--- (playerName, ilvl) once the inspect result is available.
--- For the local player or CACHE_TTL cached unit the callback
--- fires synchronously.
---@param unitName string
---@param callback fun(playerName: string, ilvl: number|nil)|nil
addon.RequestUnitInspect = function(unitName, callback)
	if (not unitName or not UnitIsPlayer(unitName)) then
		return
	end

	local guid = UnitGUID(unitName)
	if (type(guid) == "nil" or issecretvalue(guid)) then
		return
	end

	if (not guid) then
		return
	end

	local playerName = private.Details:GetFullName(unitName)
	unitNameGuidCache[playerName] = guid

	local currentTime = GetTime()
	local entry = InspectCache[guid]

	if (UnitIsUnit(unitName, "player")) then
		local _, avgItemLevelEquipped = GetAverageItemLevel()
		local ilvl = avgItemLevelEquipped and tonumber(string.format("%.1f", avgItemLevelEquipped))

		InspectCache[guid] = {
			playerName = playerName,
			last = currentTime,
		}

		if (callback) then
			callback(playerName, ilvl)
		end

		return
	end

	if (entry) then
		if (currentTime - (entry.last or 0)) < CACHE_TTL then
			-- Result is still fresh; fire callback immediately with the cached value.
			if (callback) then
				callback(playerName, entry.cachedIlvl)
			end
			return
		end

		if (currentTime - (entry.requestAt or 0)) < INSPECT_REQUEST_COOLDOWN then
			-- A request was just sent; register the callback to be called when it completes.
			if (callback) then
				entry.callbacks = entry.callbacks or {}
				table.insert(entry.callbacks, callback)
			end
			return
		end
	end

	if (not entry) then
		InspectCache[guid] = {
			playerName = playerName,
		}
		entry = InspectCache[guid]
	end

	-- Reset callbacks for the new request cycle.
	entry.callbacks = callback and { callback } or {}
	entry.requestAt = currentTime

	if (not entry.pendingUnit) then
		entry.pendingUnit = unitName
		local alreadyQueued = false
		for _, queuedGuid in ipairs(inspectQueue) do
			if safeEquals(queuedGuid, guid) then
				alreadyQueued = true
				break
			end
		end

		if (not alreadyQueued) then
			table.insert(inspectQueue, guid)
		end
	end

	ProcessQueue()
end

local HandleInspectReady = function(guid)
	if (issecretvalue(guid)) then
		return
	end

	local entry = InspectCache[guid]
	if (not entry) then
		return
	end

	if (issecretvalue(entry.pendingUnit)) then
		FinishInspectRequest(guid)
		return
	end

	local unitGuid = entry.pendingUnit and UnitGUID(entry.pendingUnit)
	local unit = not issecretvalue(unitGuid) and unitGuid == guid and entry.pendingUnit or nil

	FinishInspectRequest(guid)

	if (not unit or not UnitExists(unit)) then
		ProcessQueue()
		return
	end

	local ilvl = C_PaperDollInfo.GetInspectItemLevel(unit)
	if ilvl then
		ilvl = tonumber(string.format("%.1f", ilvl))
	end

	-- Store just enough to honour CACHE_TTL on future requests; ilvl ownership
	-- is the caller's responsibility via the callback.
	entry.cachedIlvl = ilvl
	entry.last = GetTime()

	local callbacks = entry.callbacks
	entry.callbacks = nil

	if (callbacks) then
		local playerName = entry.playerName
		for _, cb in ipairs(callbacks) do
			cb(playerName, ilvl)
		end
	end

	-- if this is not called it will keep triggering INSPECT_READY events for the last requested unitName
	ClearInspectPlayer()
	ProcessQueue()
end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if (event == "INSPECT_READY") then
		HandleInspectReady(arg1)
	end
end)
