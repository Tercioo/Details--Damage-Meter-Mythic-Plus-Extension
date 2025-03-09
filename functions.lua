
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
