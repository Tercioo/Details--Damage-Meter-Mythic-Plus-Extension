
--mythic+ extension for Details! Damage Meter
local Details = Details
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...
local addon = private.addon

--localization
local L = detailsFramework.Language.GetLanguageTable(tocFileName)

function addon.InitializeEvents()
    --event listener:
    local detailsEventListener = addon.detailsEventListener

    function detailsEventListener.OnDetailsEvent(contextObject, event, ...)
        private.log(event)
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
        local mythicPlusOverallSegment = Details:GetCurrentCombat()

        local okay, errorText = pcall(function()
            local runInfo = addon.CreateRunInfo(mythicPlusOverallSegment)
            if (runInfo) then
                table.insert(addon.profile.saved_runs, 1, runInfo)
                table.remove(addon.profile.saved_runs, addon.profile.saved_runs_limit+1)
                addon.SetSelectedRunIndex(1)
                addon.profile.has_last_run = true

                if (addon.profile.when_to_automatically_open_scoreboard == "COMBAT_MYTHICPLUS_OVERALL_READY") then
                    addon.OpenScoreBoardAtEnd()
                end
            end
        end)

        if (not okay) then
            private.log("Error on CreateRunInfo(): ", errorText)
        end

        if (not addon.profile.keep_information_for_debugging) then
            addon.profile.last_run_data = {}
        end
    end

    function addon.OnMythicDungeonStart(...)
        if (addon.IsParsing()) then
            -- this function is called after reloading, being called again would reset dungeon info
            -- this change should be removed when COMBAT_MYTHICDUNGEON_START is not being triggered after
            -- reloading in a run, or if it indicates that it is a reload
            return
        end

        addon.profile.has_last_run = false
        addon.profile.is_run_ongoing = true
        addon.profile.last_run_data.reloaded = false
        addon.profile.last_run_data.start_time = time()
        addon.profile.last_run_data.map_id = Details.challengeModeMapId or C_ChallengeMode.GetActiveChallengeMapID()
        addon.profile.last_run_data.incombat_timeline = {time()} --store the first value in the in combat timeline.
        addon.profile.last_run_data.encounter_timeline = {}
        addon.profile.last_run_data.interrupt_spells_cast = {}
        addon.profile.last_run_data.interrupt_cast_overlap_done = {}

        addon.StartParser()
    end

    function addon.OnMythicDungeonEnd(...)
        addon.profile.is_run_ongoing = false
        addon.profile.last_run_data.end_time = time()
        local combatTimeline = addon.profile.last_run_data.incombat_timeline
        local totalTimes = #combatTimeline

        if (totalTimes % 2 == 0) then
            if (combatTimeline[totalTimes -1] == combatTimeline[totalTimes]) then
                --remove this last segment
                table.remove(combatTimeline)
            else
                table.insert(combatTimeline, addon.profile.last_run_data.end_time)
            end
        end

        addon.StopParser()
    end

    function addon.OnEncounterStart(dungeonEncounterId, encounterName, difficultyId, raidSize)
        if (addon.profile.is_run_ongoing) then
            ---@type detailsmythicplus_encounterinfo
            local currentEncounterInfo = {
                dungeonEncounterId = dungeonEncounterId,
                encounterName = encounterName,
                startTime = time(),
                endTime = 0,
                defeated = false,
            }

            table.insert(addon.profile.last_run_data.encounter_timeline, currentEncounterInfo)

            private.log("Encounter started: ", encounterName)
        end
    end

    function addon.OnEncounterEnd(dungeonEncounterId, encounterName, difficultyId, raidSize, endStatus)
        if (addon.profile.is_run_ongoing) then
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
        if (addon.profile.is_run_ongoing) then
            table.insert(addon.profile.last_run_data.incombat_timeline, time())
        end
    end

    function addon.OnPlayerLeaveCombat(...)
        if (addon.profile.is_run_ongoing) then
            table.insert(addon.profile.last_run_data.incombat_timeline, time())
        end
    end

end
