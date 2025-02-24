
--mythic+ extension for Details! Damage Meter
local Details = Details
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...

---@type detailsmythicplus
local addon = private.addon

local parserFrame = CreateFrame("frame")

function addon.StartParser()
    print("+ Mythic Dungeon Start")

    addon.data.interrupt_cast_overlap = {}

    parserFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    parserFrame:SetScript("OnEvent", parserFrame.OnEvent)
end

function addon.StopParser()
    print("- Mythic Dungeon Stopped")
    parserFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

--functions for events that the addon is interesting in
local parserFunctions = {
    ["SPELL_INTERRUPT"] = function()
        --when an interrupt happened
    end,

    ["SPELL_CAST_SUCCESS"] = function(token, time, sourceGUID, sourceName, sourceFlags, targetGUID, targetName, targetFlags, targetRaidFlags, spellId, spellName, spellType)

    end
}


function parserFrame.OnEvent(self, event, ...)
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, targetGUID, targetName, targetFlags, targetRaidFlags, b2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16 = CombatLogGetCurrentEventInfo()
    if (parserFunctions[event]) then
        parserFunctions[event](event, timestamp, sourceGUID, sourceName, sourceFlags, targetGUID, targetName, targetFlags, targetRaidFlags, b2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16)
    end
end