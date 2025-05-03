local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon

local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")

addon.Migrations = {
    function ()
        -- structure was changed to use just numbers instead of a table with extra info
        for _, run in pairs(addon.profile.saved_runs) do
            for i, timeline in pairs(run.combatTimeline) do
                run.combatTimeline[i] = timeline.time
            end
        end
    end,

    function ()
        -- structure was changed to only store the last 7
        for _, run in pairs(addon.profile.saved_runs) do
            for _, damageTakenList in pairs(run.combatData.groupMembers) do
                local newDamageTakeFromSpells = {}
                for i, damageTaken in pairs(damageTakenList.damageTakenFromSpells) do
                    if (i > 7) then
                        break
                    end
                    newDamageTakeFromSpells[i] = damageTaken
                end
                damageTakenList.damageTakenFromSpells = newDamageTakeFromSpells
            end
        end
    end,

    function ()
        -- runId was introduced so external addons can link info to our runs without having to save it in this addon
        for _, run in pairs(addon.profile.saved_runs) do
            if (run.runId == nil) then
                addon.profile.last_run_id = addon.profile.last_run_id + 1
                run.runId = addon.profile.last_run_id
            end
        end
    end,

    function ()
        -- Sundering is not a CC in 99.99% of the PvE scenarios, especially in M+. For now we remove the data from
        -- existing runs
        for _, run in pairs(addon.profile.saved_runs) do
            for _, playerInfo in pairs(run.combatData.groupMembers) do
                local ccTotal = 0
                local ccUsed = {}

                for spellName, casts in pairs(playerInfo.crowdControlSpells) do
                    local spellInfo = C_Spell.GetSpellInfo(spellName)
                    local spellId = spellInfo and spellInfo.spellID or openRaidLib.GetCCSpellIdBySpellName(spellName)
                    if (spellId ~= 197214) then
                        ccUsed[spellName] = casts
                        ccTotal = ccTotal + casts
                    end
                end

                playerInfo.totalCrowdControlCasts = ccTotal
                playerInfo.crowdControlSpells = ccUsed
            end
        end
    end,

    function ()
        -- Some spell data contains invalid values, we can't reconstruct this
        for _, run in pairs(addon.profile.saved_runs) do
            for _, playerInfo in pairs(run.combatData.groupMembers) do
                for _, spellData in pairs(playerInfo.damageDoneBySpells) do
                    if (type(spellData) == "number") then
                        playerInfo.damageDoneBySpells = {}
                    end

                    break
                end
            end
        end
    end
}
