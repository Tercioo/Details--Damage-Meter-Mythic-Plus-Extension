
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
        print("Mythic Plus Overall Ready")
    end

    function addon.OnMythicDungeonStart(...)
        addon.StartParser()
    end

    function addon.OnMythicDungeonEnd(...)
        addon.StopParser()
    end

    function addon.OnEncounterStart(...)
        print("Encounter Start")
    end

    function addon.OnEncounterEnd(...)
        print("Encounter End")
    end

    function addon.OnPlayerEnterCombat(...)
        print("Player Enter")
    end

    function addon.OnPlayerLeaveCombat(...)
        print("Player Leave")
    end

end