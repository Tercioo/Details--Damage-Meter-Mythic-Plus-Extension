
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
    print("+ Mythic Dungeon Start")

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

function addon.GetLastRunStart()
    return addon.profile.last_run_data.run_start or time() --retuning time() here result in an empty timeline (all black), it fails in the "if (last == nil) then" check
end

function addon.StopParser()
    print("- Mythic Dungeon Stopped")
    parserFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    addon.CountInterruptOverlaps()
    parserFrame.isParsing = false
    addon.loot.cache = {}

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

        --[=[
        --doesn't work as intended, as value1 and value2 are marked as used, a third attempt wouldn't count
        for i = 1, #interruptCastsOnTarget do
            ---@type interrupt_overlap
            local player1InterruptAttempt = interruptCastsOnTarget[i]

            if (not player1InterruptAttempt.used) then
                local time = player1InterruptAttempt.time
                local sourceName = player1InterruptAttempt.sourceName
                local player1Interrupted = player1InterruptAttempt.interrupted

                for j = i+1, #interruptCastsOnTarget do
                    ---@type interrupt_overlap
                    local player2InterruptAttempt = interruptCastsOnTarget[j]
                    if (not player2InterruptAttempt.used) then
                        local time2 = player2InterruptAttempt.time
                        local sourceName2 = player2InterruptAttempt.sourceName
                        local player2Interrupted = player2InterruptAttempt.interrupted

                        if (time2 - time < 1.5) then
                            --add the overlap if the interrupt attempt fail to interrupt
                            if (not player1Interrupted) then
                                addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName] = (addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName] or 0) + 1
                            end
                            if (not player2Interrupted) then
                                addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName2] = (addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName2] or 0) + 1
                            end

                            --print("Overlap: ", sourceName, targetName, C_Spell.GetSpellInfo(spellId).name, sourceName2, targetName2, "with", C_Spell.GetSpellInfo(spellId2).name)
                            private.log("Interrupt overlap found:", sourceName)

                            player1InterruptAttempt.used = true
                            player2InterruptAttempt.used = true
                        else
                            break
                        end
                    else
                        break
                    end
                end
            end
        end
        --]=]
    end
end
