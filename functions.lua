
--mythic+ extension for Details! Damage Meter
local Details = Details
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...

---@type detailsmythicplus
local addon = private.addon

function addon.GetInAndOutOfCombatTimeline()
    local inAndOutCombatTimeline = addon.profile.last_run_data.incombat_timeline
    return inAndOutCombatTimeline
end

--return the run time in seconds of the last run
function addon.GetRunTime()
    local segment = addon.GetMythicPlusOverallSegment()
    if (segment) then
        ---@type mythicdungeoninfo
        local mythicPlusData = segment:GetMythicDungeonInfo()
        if (mythicPlusData and mythicPlusData.TotalTime) then
            return math.floor(mythicPlusData.TotalTime / 1000)
        end
    end

    return 0
end


--get the latest mythic+ overall segment from details!
function addon.GetMythicPlusOverallSegment()
    local mythicPlusOverallSegment = Details:GetCurrentCombat()

	if (mythicPlusOverallSegment:GetCombatType() ~= DETAILS_SEGMENTTYPE_MYTHICDUNGEON_OVERALL) then
		--get a table with all segments
		local segmentsTable = Details:GetCombatSegments()
		for i = 1, #segmentsTable do
			local segment = segmentsTable[i]
			if (segment:GetCombatType() == DETAILS_SEGMENTTYPE_MYTHICDUNGEON_OVERALL) then
				mythicPlusOverallSegment = segment
				break
			end
		end
	end

    return mythicPlusOverallSegment
end

---retrieves the data from the current mythic plus run
---@return mythicdungeoninfo? mythicPlusData a table containing the data from the current mythic plus run.
function addon.GetMythicPlusData()
    local mythicPlusOverallSegment = addon.GetMythicPlusOverallSegment()
    if (mythicPlusOverallSegment) then
        return mythicPlusOverallSegment:GetMythicDungeonInfo()
    end
end

---retrieves the segments of a Mythic+ run that correspond to boss encounters.
---@return table runBossSegments a table containing the segments of the current Mythic+ run that are boss encounters.
function addon.GetRunBossSegments()
    local runBossSegments = {}

    local currentMythicSegment = addon.GetMythicPlusOverallSegment()
    if (currentMythicSegment) then
        ---@type mythicdungeoninfo
        local mythicPlusData = currentMythicSegment:GetMythicDungeonInfo()
        if (mythicPlusData) then
            local runId = mythicPlusData.RunID
            if (runId) then
                local allSegments = Details:GetCombatSegments()
                for i = 1, #allSegments do
                    local mythicBossSegment = allSegments[i]
                    local thisSegmentMythicPlusData = mythicBossSegment:GetMythicDungeonInfo()
                    if (thisSegmentMythicPlusData and thisSegmentMythicPlusData.RunID == runId) then
                        if (mythicBossSegment:GetCombatType() == DETAILS_SEGMENTTYPE_MYTHICDUNGEON_BOSS) then
                            table.insert(runBossSegments, mythicBossSegment)
                        end
                    end
                end
            end
        end
    end

    return runBossSegments
end

---retrieves the start and end time() of a boss encounter segment.
---@param bossSegment combat
---@return number killTime the time() in seconds when the encounter finished.
function addon.GetBossKillTime(bossSegment)
    local mythicPlusData = bossSegment:GetMythicDungeonInfo()
    if (mythicPlusData) then
        return mythicPlusData.EndedAt
    end
    return 0
end