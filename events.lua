
--mythic+ extension for Details! Damage Meter
local Details = Details
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...
local addon = private.addon

function addon.InitializeEvents()
    --event listener:
    local detailsEventListener = addon.detailsEventListener

    function detailsEventListener.OnDetailsEvent(contextObject, event, ...)
        if (event == "COMBAT_MYTHICDUNGEON_START") then
            addon.OnMythicDungeonStart(...)
        elseif (event == "COMBAT_MYTHICDUNGEON_END") then
            addon.OnMythicDungeonEnd(...)
        elseif (event == "COMBAT_MYTHICPLUS_OVERALL_READY") then
            addon.OnMythicPlusOverallReady(...)
        elseif (event == "COMBAT_ENCOUNTER_START") then
            addon.OnEncounterStart(...)
        elseif (event == "COMBAT_ENCOUNTER_END") then
            addon.OnEncounterEnd(...)
        elseif (event == "COMBAT_PLAYER_ENTER") then
            addon.OnPlayerEnterCombat(...)
        elseif (event == "COMBAT_PLAYER_LEAVE") then
            addon.OnPlayerLeaveCombat(...)
        end
    end

    function addon.OnMythicPlusOverallReady(...)
        private.addon.mythicPlusBreakdown.MythicPlusOverallSegmentReady()
    end

    function addon.OnMythicDungeonStart(...)
        addon.profile.last_run_data.start_time = time()
        --store the first value in the in combat timeline.
        addon.profile.last_run_data.incombat_timeline = {{time = time(), in_combat = false}}
        addon.profile.last_run_data.boss_timeline = {} --todo(tercio): need to insert the bosses here
        addon.StartParser()
    end

    function addon.OnMythicDungeonEnd(...)
        addon.StopParser()
    end

    function addon.OnEncounterStart(...)
    end

    function addon.OnEncounterEnd(...)
    end

    ---@class scoreboard_incombat_timeline_step : table
    ---@field time number epoch time of when the player entered or left combat
    ---@field in_combat boolean whether the player is in combat or not

    function addon.OnPlayerEnterCombat(...)
        local incombatTimeline = addon.profile.last_run_data.incombat_timeline
        table.insert(incombatTimeline, {time = time(), in_combat = true})
    end

    function addon.OnPlayerLeaveCombat(...)
        local incombatTimeline = addon.profile.last_run_data.incombat_timeline
        table.insert(incombatTimeline, {time = time(), in_combat = false})
    end

end
