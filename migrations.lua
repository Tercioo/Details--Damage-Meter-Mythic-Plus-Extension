local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon

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
}
