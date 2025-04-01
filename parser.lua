
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

    addon.data.interrupt_spells_cast = {}
    addon.data.interrupt_cast_overlap_done = {}
    addon.profile.last_run_data.run_start = time()

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
                        break
                    end
                end
            end
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

            private.log("Interrupt cast:", sourceName)
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

        for i = 1, #interruptCastsOnTarget do
            ---@type interrupt_overlap
            local interruptAttempt = interruptCastsOnTarget[i]
            interruptClusters[interruptAttempt] = {interruptAttempt}

            for j = i+1, #interruptCastsOnTarget do
                ---@type interrupt_overlap
                local nextInterruptAttempt = interruptCastsOnTarget[j]
                if (detailsFramework.Math.IsNearlyEqual(interruptAttempt.time, nextInterruptAttempt.time, 1.5)) then
                    --add to the cluster
                    table.insert(interruptClusters[interruptAttempt], nextInterruptAttempt)
                else
                    i = i + #interruptClusters[interruptAttempt] - 1
                    break
                end
            end
        end

        for index, clusterOfInterrupts in ipairs(interruptClusters) do
            --check if the cluster has more than 1 interrupt attempt
            if (#clusterOfInterrupts > 1) then
                --iterate among the cluster and add a overlap if those interrupts without success
                for i = 1, #clusterOfInterrupts do
                    ---@type interrupt_overlap
                    local interruptAttempt = clusterOfInterrupts[i]
                    if (not interruptAttempt.interrupted) then
                        local sourceName = interruptAttempt.sourceName
                        addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName] = (addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName] or 0) + 1
                    end
                end
            end
        end
    end
end
