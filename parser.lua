
--mythic+ extension for Details! Damage Meter
local Details = Details
---@type detailsframework
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...

---@type detailsmythicplus
local addon = private.addon

---@class interrupt_overlap : table
---@field time number
---@field sourceName string
---@field spellId number
---@field targetName string
---@field extraSpellID number
---@field used boolean
---@field interrupted boolean

--localization
local L = detailsFramework.Language.GetLanguageTable(tocFileName)

local parserFrame = CreateFrame("frame")
parserFrame.isParsing = false

function addon.StartParser()
    --this data need to survive a /reload
    addon.profile.last_run_data.interrupt_spells_cast = {}
    addon.profile.last_run_data.interrupt_cast_overlap_done = {}

    parserFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    parserFrame:SetScript("OnEvent", parserFrame.OnEvent)
    parserFrame.isParsing = true

    private.log("Parser stared")
end

function addon.StopParser()
    parserFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    addon.CountInterruptOverlaps()
    parserFrame.isParsing = false

    private.log("Parser stopped")
end

function addon.IsParsing()
    return parserFrame.isParsing
end

--functions for events that the addon is interesting in
local parserFunctions = {
    ["SPELL_INTERRUPT"] =       function(token, time, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, targetGUID, targetName, targetFlags, targetRaidFlags, spellId, spellName, spellType, extraSpellID, extraSpellName, extraSchool)
        --get the list of interrupt attempts by this player
        ---@type table<guid, interrupt_overlap[]>
        local interruptCastsOnTarget = addon.profile.last_run_data.interrupt_spells_cast[targetGUID]
        if (interruptCastsOnTarget) then
            --iterate among interrupt attempts on this target and find the one that matches the time of the interrupt and the source name
            for i = #interruptCastsOnTarget, 1, -1 do
                ---@type interrupt_overlap
                local interruptAttempt = interruptCastsOnTarget[i]

                if (interruptAttempt.sourceName == sourceName) then
                    if (detailsFramework.Math.IsNearlyEqual(time, interruptAttempt.time, 0.1)) then
                        --mark as a success interrupt
                        interruptAttempt.interrupted = true
                        private.log("Interrupt success:", sourceName, "on", targetGUID)
                        break
                    end
                end
            end
        else
            private.log("No interrupts casts on target", targetGUID)
        end
    end,

    ["SPELL_CAST_SUCCESS"] =    function(token, time, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, targetGUID, targetName, targetFlags, targetRaidFlags, spellId, spellName, spellType, extraSpellID, extraSpellName, extraSchool)
        local interruptSpells = LIB_OPEN_RAID_SPELL_INTERRUPT
        --check if this is an interrupt spell
        if (interruptSpells[spellId]) then
            addon.profile.last_run_data.interrupt_spells_cast[targetGUID] = addon.profile.last_run_data.interrupt_spells_cast[targetGUID] or {}
            ---@type interrupt_overlap
            local spellOverlapData = {
                time = time,
                sourceName = sourceName,
                spellId = spellId,
                targetName = targetName,
                extraSpellID = extraSpellID,
                used = false,
                interrupted = false,
            }
            --store the interrupt attempt in a table
            table.insert(addon.profile.last_run_data.interrupt_spells_cast[targetGUID], spellOverlapData)

            private.log("Interrupt cast:", sourceName, "on", targetGUID)
        end
    end
}


function parserFrame.OnEvent(self, event, ...)
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, targetGUID, targetName, targetFlags, targetRaidFlags, b2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16 = CombatLogGetCurrentEventInfo()
    if (parserFunctions[event]) then
        parserFunctions[event](event, timestamp, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, targetGUID, targetName, targetFlags, targetRaidFlags, b2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16)
    end
end


function addon.CountInterruptOverlaps()
    for targetGUID, interruptCastsOnTarget in pairs(addon.profile.last_run_data.interrupt_spells_cast) do

        --store clusters of interrupts that was attempted on the same target within 1.5 seconds
        --this is a table of tables, where each table is a cluster of interrupts
        local interruptClusters = {}

        private.log("CountInterruptOverlaps() cluster created for", targetGUID, "Interrupts on this target:", #interruptCastsOnTarget)

        --find interrupt casts casted on the same target within 1.5 seconds of each other
        local index = 1
        while (index < #interruptCastsOnTarget) do
            ---@type interrupt_overlap
            local interruptAttempt = interruptCastsOnTarget[index]
            local thisCluster = {interruptAttempt}
            local lastIndex = index

            for j = index+1, #interruptCastsOnTarget do --from the next interrupt to the end of the table
                lastIndex = j
                ---@type interrupt_overlap
                local nextInterruptAttempt = interruptCastsOnTarget[j]
                if (detailsFramework.Math.IsNearlyEqual(interruptAttempt.time, nextInterruptAttempt.time, 1.5)) then
                    table.insert(thisCluster, nextInterruptAttempt)
                else
                    break
                end
            end

            index = lastIndex

            if (#thisCluster > 1) then
                --add the cluster to the list of clusters
                table.insert(interruptClusters, thisCluster)
            end
        end

        private.log("Interrupts clusters found on this target:", #interruptClusters)

        for index, thisCluster in ipairs(interruptClusters) do
            --iterate among the cluster and add a overlap if those interrupts without success
            private.log("This cluster size:", #thisCluster)

            for i = 1, #thisCluster do
                ---@type interrupt_overlap
                local interruptAttempt = thisCluster[i]

                if (not interruptAttempt.interrupted) then
                    local sourceName = interruptAttempt.sourceName
                    addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName] = (addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName] or 0) + 1
                    private.log("Added an overlap for player:", sourceName, "total overlaps:", addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName])
                else
                    private.log("This player interrupted the spell:", interruptAttempt.sourceName)
                end
            end
        end
    end
end
