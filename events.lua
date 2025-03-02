
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
        addon.profile.last_run_data.encounter_timeline = {} --todo(tercio): need to insert the bosses here
        addon.StartParser()
    end

    function addon.OnMythicDungeonEnd(...)
        addon.profile.last_run_data.end_time = time()
        addon.StopParser()
    end

    function addon.OnEncounterStart(dungeonEncounterId, encounterName, difficultyId, raidSize)
        if (addon.IsParsing()) then
            ---@type detailsmythicplus_encounterinfo
            local currentEncounterInfo = {
                dungeonEncounterId = dungeonEncounterId,
                encounterName = encounterName,
                difficultyId = difficultyId,
                raidSize = raidSize,
                startTime = time(),
                endTime = 0,
                defeated = false,
            }

            table.insert(addon.profile.last_run_data.encounter_timeline, currentEncounterInfo)

            private.log("Encounter started: ", encounterName)
        end
    end

    function addon.OnEncounterEnd(dungeonEncounterId, encounterName, difficultyId, raidSize, endStatus)
        if (addon.IsParsing()) then
            ---@type detailsmythicplus_encounterinfo
            local currentEncounterInfo = addon.profile.last_run_data.encounter_timeline[#addon.profile.last_run_data.encounter_timeline]

            --if the current encounter is nil, then we did miss the encounter start event
            if (not currentEncounterInfo) then
                return
            end

            currentEncounterInfo.endTime = time()
            currentEncounterInfo.defeated = endStatus == 1

            private.log("Encounter ended: ", encounterName, " defeated: ", endStatus == 1)
        end
    end

    function addon.OnPlayerEnterCombat(...)
        if (addon.IsParsing()) then
            local incombatTimeline = addon.profile.last_run_data.incombat_timeline
            table.insert(incombatTimeline, {time = time(), in_combat = true})

            private.log("Entered in combat: ", time())
        end
    end

    function addon.OnPlayerLeaveCombat(...)
        if (addon.IsParsing()) then
            local incombatTimeline = addon.profile.last_run_data.incombat_timeline
            table.insert(incombatTimeline, {time = time(), in_combat = false})

            private.log("Left combat: ", time())
        end
    end

end
