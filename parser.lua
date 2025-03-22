
--mythic+ extension for Details! Damage Meter
local Details = Details
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

local parserFrame = CreateFrame("frame")
parserFrame.isParsing = false

function addon.StartParser()
    print("+ Mythic Dungeon Start")

    --this data need to survive a /reload
    addon.profile.last_run_data.interrupt_cast_overlap = {}
    addon.profile.last_run_data.interrupt_cast_overlap_done = {}

    addon.data.interrupt_cast_overlap = {}
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

    private.log("Parser stopped")
end

function addon.IsParsing()
    return parserFrame.isParsing
end

--functions for events that the addon is interesting in
local parserFunctions = {
    ["SPELL_INTERRUPT"] = function(token, time, sourceGUID, sourceName, sourceFlags)
        --when an interrupt happened
        private.log("Interrupt succeded!", sourceName)
    end,

    ["SPELL_CAST_SUCCESS"] = function(token, time, sourceGUID, sourceName, sourceFlags, targetGUID, targetName, targetFlags, targetRaidFlags, spellId, spellName, spellType, extraSpellID, extraSpellName, extraSchool)
        local interruptSpells = LIB_OPEN_RAID_SPELL_INTERRUPT
        if (interruptSpells[spellId]) then
            addon.profile.last_run_data.interrupt_cast_overlap[targetGUID] = addon.profile.last_run_data.interrupt_cast_overlap[targetGUID] or {}
            ---@type interrupt_overlap
            local spellOverlapData = {
                time = time,
                sourceName = sourceName,
                spellId = spellId,
                targetName = targetName,
                extraSpellID = extraSpellID,
                used = false,
            }
            table.insert(addon.profile.last_run_data.interrupt_cast_overlap[targetGUID], spellOverlapData)

            private.log("Interrupt cast:", sourceName)
        end
    end
}


function parserFrame.OnEvent(self, event, ...)
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, targetGUID, targetName, targetFlags, targetRaidFlags, b2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16 = CombatLogGetCurrentEventInfo()
    if (parserFunctions[event]) then
        parserFunctions[event](event, timestamp, sourceGUID, sourceName, sourceFlags, targetGUID, targetName, targetFlags, targetRaidFlags, b2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16)
    end
end


function addon.CountInterruptOverlaps()
    for _, data in pairs(addon.profile.last_run_data.interrupt_cast_overlap) do
        for i = 1, #data do
            ---@type interrupt_overlap
            local overlapData = data[i]
            if (not overlapData.used) then
                local time = overlapData.time
                local sourceName = overlapData.sourceName
                --local spellId = overlapData.spellId
                --local targetName = overlapData.targetName
                --local extraSpellID = overlapData.extraSpellID

                for j = i+1, #data do
                    ---@type interrupt_overlap
                    local overlapData2 = data[j]
                    if (not overlapData2.used) then
                        local time2 = overlapData2.time
                        local sourceName2 = overlapData2.sourceName
                        --local spellId2 = overlapData2.spellId
                        --local targetName2 = overlapData2.targetName
                        --local extraSpellID2 = overlapData2.extraSpellID

                        if (time2 - time < 1.5) then
                            addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName] = (addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName] or 0) + 1
                            addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName2] = (addon.profile.last_run_data.interrupt_cast_overlap_done[sourceName2] or 0) + 1
                            --print("Overlap: ", sourceName, targetName, C_Spell.GetSpellInfo(spellId).name, sourceName2, targetName2, "with", C_Spell.GetSpellInfo(spellId2).name)

                            private.log("Interrupt overlap found:", sourceName)

                            overlapData.used = true
                            overlapData2.used = true
                        else
                            break
                        end
                    else
                        break
                    end
                end
            end
        end
    end
end
