
--this file is responsable to copy the necessary data from a details! combat into an object that can be used by the addon

---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil
local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")

local CONST_MAX_DEATH_EVENTS = 3
local CONST_LAST_RUN_TIMEOUT = 5 * 60

---@alias playername string

--primaryAffix seens to not exists
--local dungeonName, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(challengemodecompletioninfo.mapChallengeModeID)

---runs on details! event COMBAT_MYTHICPLUS_OVERALL_READY
function addon.CreateRunInfo(mythicPlusOverallSegment)
    local completionInfo = C_ChallengeMode.GetChallengeCompletionInfo()
    if (completionInfo.mapChallengeModeID == 0) then
        private.log("Missing completionInfo.mapChallengeModeID, possibly due to and error or reload after the key completed")
        return
    end

    local combatTime = mythicPlusOverallSegment:GetCombatTime()

    --debug
    if (not addon.profile.last_run_data.encounter_timeline) then
        print("Details M+ addon.profile.last_run_data.encounter_timeline is nil")
        private.log("Details M+ addon.profile.last_run_data.encounter_timeline is nil")
    end

    if (not addon.profile.last_run_data.incombat_timeline) then
        print("Details M+ addon.profile.last_run_data.incombat_timeline is nil")
        private.log("Details M+ addon.profile.last_run_data.incombat_timeline is nil")
    end

    addon.profile.last_run_id = addon.profile.last_run_id + 1

    ---@type runinfo
    local runInfo = {
        runId = addon.profile.last_run_id,
        combatId = mythicPlusOverallSegment:GetCombatUID(),
        combatData = {
            groupMembers = {} --done
        },
        completionInfo = { --done
            mapChallengeModeID = completionInfo.mapChallengeModeID,
            level = completionInfo.level,
            time = completionInfo.time,
            onTime = completionInfo.onTime,
            keystoneUpgradeLevels = completionInfo.keystoneUpgradeLevels,
            practiceRun = completionInfo.practiceRun,
            oldOverallDungeonScore = completionInfo.oldOverallDungeonScore,
            newOverallDungeonScore = completionInfo.newOverallDungeonScore,
            isEligibleForScore = completionInfo.isEligibleForScore,
            isMapRecord = completionInfo.isMapRecord,
            isAffixRecord = completionInfo.isAffixRecord,
            members = completionInfo.members,
        },
        encounters = detailsFramework.table.copy({}, addon.profile.last_run_data.encounter_timeline),
        combatTimeline = detailsFramework.table.copy({}, addon.profile.last_run_data.incombat_timeline),
        timeInCombat = combatTime,
        timeWithoutDeaths = 0,
        dungeonName = "", --done
        dungeonId = 0, --done
        instanceId = select(8, GetInstanceInfo()),
        dungeonTexture = 0, --done
        dungeonBackgroundTexture = 0, --done
        timeLimit = 0, --done
        startTime = addon.profile.last_run_data.start_time,
        endTime = time(),
        timeLostToDeaths = addon.profile.last_run_data.time_lost_to_deaths,
        mapId = completionInfo.mapChallengeModeID or addon.profile.last_run_data.map_id,
        reloaded = addon.profile.last_run_data.reloaded,
    }

    local dungeonName, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(runInfo.mapId)
    runInfo.dungeonName = dungeonName
    runInfo.dungeonId = id
    runInfo.mapId = id
    runInfo.timeLimit = timeLimit
    runInfo.dungeonTexture = texture
    runInfo.dungeonBackgroundTexture = backgroundTexture

    local damageContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
    local healingContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_HEAL)
    local utilityContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_MISC)

    for _, actorObject in damageContainer:ListActors() do
        ---@cast actorObject actordamage

        if (actorObject:IsPlayer()) then
            local unitName = actorObject:Name()
            local damageTakenFromSpells = {}
            for i, damageTaken in pairs(mythicPlusOverallSegment:GetDamageTakenBySpells(unitName)) do
                if (i > 7) then
                    break
                end
                table.insert(damageTakenFromSpells, damageTaken)
            end

            ---@type playerinfo
            local playerInfo = {
                name = unitName,
                class = actorObject:Class(),
                spec = actorObject:Spec(),
                role = UnitGroupRolesAssigned(actorObject:Name()),
                guid = actorObject:GetGUID(),
                loot = "",
                score = 0,
                playerOwns = UnitIsUnit(unitName, "player"),
                activityTimeDamage = 0,
                activityTimeHeal = 0,
                scorePrevious = 0,
                totalDeaths = 0,
                totalDamage = actorObject.total,
                totalHeal = 0,
                totalDamageTaken = actorObject.damage_taken,
                totalHealTaken = 0,
                totalDispels = 0,
                totalInterrupts = 0,
                totalInterruptsCasts = 0,
                totalCrowdControlCasts = 0,
                healDoneBySpells = {}, --done
                damageTakenFromSpells = damageTakenFromSpells,
                damageDoneBySpells = {}, --done
                dispelWhat = {}, --done
                interruptWhat = {}, --done
                interruptCastOverlapDone = addon.profile.last_run_data.interrupt_cast_overlap_done[unitName] or 0,
                crowdControlSpells = {}, --done
                ilevel = Details:GetItemLevelFromGuid(actorObject:GetGUID()),
                deathEvents = {}, --information about when the player died
                deathLastHits = {}, --information for the tooltip when the player died
            }

            runInfo.combatData.groupMembers[unitName] = playerInfo

            if (type(actorObject.mrating) == "table") then
                actorObject.mrating = actorObject.mrating.currentSeasonScore
            end
            local score = actorObject.mrating or 0
            playerInfo.score = score
            playerInfo.scorePrevious = Details.PlayerRatings[unitName] or score

            playerInfo.activityTimeDamage = actorObject:Tempo()

            local playerDeaths = mythicPlusOverallSegment:GetPlayerDeaths(unitName)
            playerInfo.totalDeaths = #playerDeaths

            local deathTable = mythicPlusOverallSegment:GetDeaths()
            for i = 1, #deathTable do
                local thisDeathTable = deathTable[i]
                --deathTime is time()
                local playerName, playerClass, deathTime, deathCombatTime, deathTimeString, playerMaxHealth, deathEvents, lastCooldown, spec = Details:UnpackDeathTable(thisDeathTable)
                if (playerName == unitName) then
                    playerInfo.deathEvents[#playerInfo.deathEvents+1] = {
                        type = addon.Enum.ScoreboardEventType.Death,
                        timestamp = thisDeathTable[2],
                        arguments = {}, --playerData = playerInfo, can't assign here as it will save playerInfo twice in the saved variables (or cause a loop)
                    }

                    local countDamageEventsFound = 0

                    ---@type death_last_hits[]
                    local thisDeathLastEvents = {}

                    for j = #deathEvents, 1, -1 do
                        ---@type deathtable
                        local thisEvent = deathEvents[j]
                        local evType, spellId, amount, eventTime, heathPercent, sourceName, absorbed, spellSchool, friendlyFire, overkill, criticalHit, crushing = Details:UnpackDeathEvent(thisEvent)

                        if (evType == true) then --a boolean true means a damage event
                            ---@type death_last_hits
                            local deathLastHit = {
                                spellId = spellId,
                                sourceName = sourceName,
                                totalDamage = amount,
                            }
                            thisDeathLastEvents[#thisDeathLastEvents+1] = deathLastHit
                            countDamageEventsFound = countDamageEventsFound + 1

                            if (countDamageEventsFound == CONST_MAX_DEATH_EVENTS) then
                                break
                            end
                        end
                    end

                    playerInfo.deathLastHits[#playerInfo.deathLastHits+1] = thisDeathLastEvents
                end

            end

            --spell damage done
            local spellsUsed = actorObject:GetActorSpells()
            local temp = {}
            for _, spellTable in pairs(spellsUsed) do
                table.insert(temp, {spellTable.id, spellTable.total})
            end

            table.sort(temp, function(a, b) return a[2] > b[2] end)
            playerInfo.damageDoneBySpells = temp

            --heal
            for _, healActorObject in healingContainer:ListActors() do
                ---@cast actorObject actorheal
                if (healActorObject:Name() == unitName) then
                    playerInfo.totalHeal = healActorObject.total
                    playerInfo.totalHealTaken = healActorObject.healing_taken
                    playerInfo.activityTimeHeal = actorObject:Tempo()

                    --spell heal done
                    local temp = {}
                    local spellsUsedToHeal = healActorObject:GetActorSpells()
                    for _, spellTable in pairs(spellsUsedToHeal) do
                        table.insert(temp, {spellTable.id, spellTable.total})
                    end

                    table.sort(temp, function(a, b) return a[2] > b[2] end)
                    playerInfo.healDoneBySpells = temp
                end
            end

            --utility
            for _, utilityActorObject in utilityContainer:ListActors() do
                ---@cast utilityActorObject actorutility
                if (utilityActorObject:Name() == unitName) then
                    local ccTotal = 0
                    local ccUsed = {}

                    for spellName, casts in pairs(mythicPlusOverallSegment:GetCrowdControlSpells(unitName)) do
                        local spellInfo = C_Spell.GetSpellInfo(spellName)
                        local spellId = spellInfo and spellInfo.spellID or openRaidLib.GetCCSpellIdBySpellName(spellName)
                        if (spellId ~= 197214) then
                            ccUsed[spellName] = casts
                            ccTotal = ccTotal + casts
                        end
                    end

                    playerInfo.totalDispels = utilityActorObject.dispell
                    playerInfo.totalInterrupts = utilityActorObject.interrupt
                    playerInfo.totalInterruptsCasts = mythicPlusOverallSegment:GetInterruptCastAmount(unitName)
                    playerInfo.totalCrowdControlCasts = ccTotal
                    playerInfo.dispelWhat = detailsFramework.table.copy({}, utilityActorObject.dispell_oque or {})
                    playerInfo.interruptWhat = detailsFramework.table.copy({}, utilityActorObject.interrompeu_oque or {})
                    playerInfo.crowdControlSpells = ccUsed
                end
            end
        end
    end

    local compressedOkay, errorText = pcall(function() addon.CompressAndSaveRunInfo(runInfo) end)
    if (not compressedOkay) then
        private.log("Error compressing run info: " .. errorText)
    end

    return runInfo
end



---return an array with all data from the saved runs
---@return runinfo[]
function addon.GetSavedRuns()
    return addon.profile.saved_runs
end

---return the run info for the last run finished before the next one starts
---@return runinfo
function addon.GetLastRun()
    return addon.profile.has_last_run and addon.profile.saved_runs[1] and addon.profile.saved_runs[1].endTime + CONST_LAST_RUN_TIMEOUT > time() and addon.profile.saved_runs[1] or nil
end

---set the index of the latest selected run info
---@param index number
function addon.SetSelectedRunIndex(index)
    addon.profile.saved_runs_selected_index = index
    --call refresh on the score board
    addon.RefreshOpenScoreBoard()
end

---get the index of the latest selected run info
---@return number
function addon.GetSelectedRunIndex()
    return addon.profile.saved_runs_selected_index
end

---return the latest selected run info, return nil if there is no run info data
---@return runinfo?
function addon.GetSelectedRun()
    local savedRuns = addon.GetSavedRuns()
    local selectedRunIndex = addon.GetSelectedRunIndex()
    local runInfo = savedRuns[selectedRunIndex]
    if (runInfo == nil) then
        --if no run is selected, select the first run
        addon.SetSelectedRunIndex(1)
        selectedRunIndex = 1
    end
    return savedRuns[selectedRunIndex]
end

---remove the run info from the saved runs
---@param index number
function addon.RemoveRun(index)
    local currentSelectedIndex = addon.GetSelectedRunIndex()

    table.remove(addon.profile.saved_runs, index)

    if (currentSelectedIndex == index) then
        addon.SetSelectedRunIndex(1)
    elseif (currentSelectedIndex > index) then
        addon.SetSelectedRunIndex(currentSelectedIndex - 1)
    end
end

---return an array with run infos of all runs that match the dungeon name or dungeon id
---@param id string|number dungeon name, dungeon id or map id
---@return runinfo[]
function addon.GetDungeonRunsById(id)
    local runs = {}
    local savedRuns = addon.GetSavedRuns()
    for _, runInfo in ipairs(savedRuns) do
        if (runInfo.dungeonName == id or runInfo.dungeonId == id or runInfo.mapId == id) then
            table.insert(runs, runInfo)
        end
    end
    return runs
end

---return the date when the run ended in format of a string with hour:minute day as number/month as 3letters/year as number
---@param runInfo runinfo
---@return string
function addon.GetRunDate(runInfo)
    return date("%d/%b/%Y", runInfo.endTime)
end

---receives a runInfo, encode it, compress and save it to the saved_runs_compressed
---@param runInfo runinfo
---@return boolean success
function addon.CompressAndSaveRunInfo(runInfo)
    if (not runInfo) then
        private.log("CompressAndSaveRunInfo: runInfo is nil")
        return false
    end

    if (not C_EncodingUtil) then
        private.log("CompressAndSaveRunInfo: C_EncodingUtil is nil")
        return false
    end

    local dataSerialized = C_EncodingUtil.SerializeCBOR(runInfo)
    if (not dataSerialized) then
        private.log("CompressAndSaveRunInfo: C_EncodingUtil.SerializeCBOR failed")
        return false
    end

    local dataCompressed = C_EncodingUtil.CompressString(dataSerialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.OptimizeForSize)
    if (not dataCompressed) then
        private.log("CompressAndSaveRunInfo: C_EncodingUtil.CompressString failed")
        return false
    end

    local dataEncoded = C_EncodingUtil.EncodeBase64(dataCompressed)
    if (not dataEncoded) then
        private.log("CompressAndSaveRunInfo: C_EncodingUtil.EncodeBase64 failed")
        return false
    end

    --save the compressed run info
    table.insert(addon.profile.saved_runs_compressed, 1, dataEncoded)

    ---@type runinfocompressed_header
    local header = {
        dungeonName = runInfo.dungeonName,
        startTime = runInfo.startTime,
        endTime = runInfo.endTime,
        keyLevel = runInfo.completionInfo.level,
        keyUpgradeLevels = runInfo.completionInfo.keystoneUpgradeLevels,
        onTime = runInfo.completionInfo.onTime or false,
        mapId = runInfo.mapId,
        dungeonId = runInfo.dungeonId,
        playerName = UnitName("player"),
        playerClass = select(2, UnitClass("player")),
        runId = runInfo.runId,
        instanceId = runInfo.instanceId,
    }

    table.insert(addon.profile.saved_runs_compressed_headers, 1, header)

    --limit data to 200 entries
    if (#addon.profile.saved_runs_compressed > 200) then
        table.remove(addon.profile.saved_runs_compressed, 201)
    end

    if (#addon.profile.saved_runs_compressed_headers > 200) then
        table.remove(addon.profile.saved_runs_compressed_headers, 201)
    end

    return true
end

---return a table with data to be used in the dropdown menu to select which run to show in the scoreboard
---@param runInfo runinfo
---@return table dropdownData dungeonName, keyLevel, runTime, keyUpgradeLevels, timeString, mapId, dungeonId
function addon.GetDropdownRunDescription(runInfo)
    --Operation: Mechagon - Workshop (2) | 20:10 (+3) | 4 hours ago
    local dungeonName = runInfo.dungeonName
    local runTime = runInfo.endTime - runInfo.startTime
    local secondsAgo = time() - runInfo.endTime

    --if the run time is less than 1 hour, show the time in minutes
    --if the run is less than 24 hours, show the time in hours
    --if the run is more than 24 hours, show the time in days
    --if the run is more than 7 days, show the data using addon.GetRunDate(runInfo)

    local timeString = ""
    if (secondsAgo < 3600) then
        timeString = string.format("%d minutes ago", math.floor(secondsAgo / 60))
    elseif (secondsAgo < 86400) then
        timeString = string.format("%d hours ago", math.floor(secondsAgo / 3600))
    elseif (secondsAgo < 604800) then
        timeString = string.format("%d days ago", math.floor(secondsAgo / 86400))
    else
        timeString = addon.GetRunDate(runInfo)
    end

    local keyLevel = runInfo.completionInfo.level or 0
    local keyUpgradeLevels = runInfo.completionInfo.keystoneUpgradeLevels or 0
    local mapId = runInfo.mapId or 0
    local dungeonId = runInfo.dungeonId or 0
    local onTime = runInfo.completionInfo.onTime or false

    --get the alt name, playerOwns is true when the player itself played the character when doing the run
    local altName = "0" --can't be an empty string due to string.match pattern
    local playerName = UnitName("player")

    for unitName, playerInfo in pairs(runInfo.combatData.groupMembers) do
        ---@cast playerInfo playerinfo
        if (playerInfo.playerOwns and playerInfo.name ~= playerName) then
            altName = playerInfo.name
            altName = detailsFramework:AddClassColorToText(altName, playerInfo.class)
            break
        end
    end

    return {dungeonName, keyLevel, runTime, keyUpgradeLevels, timeString, mapId, dungeonId, onTime and 1 or 0, altName}
end

function addon.FormatRunDescription(runInfo)
    return string.format("%s (%d) - %s", runInfo.dungeonName, runInfo.completionInfo.level, addon.GetRunDate(runInfo))
end

---return a table with subtables of type death_last_hits which tells the last hits that killed the player
---@param runInfo runinfo
---@param unitName playername
---@param deathIndex number
---@return death_last_hits[]|nil
function addon.GetPlayerDeathReason(runInfo, unitName, deathIndex)
    local playerInfo = runInfo.combatData.groupMembers[unitName]
    if (playerInfo) then
        local deathLastHits = playerInfo.deathLastHits[deathIndex]
        if (deathLastHits) then
            return deathLastHits
        end
    end
end

---return the average item level of the 5 players in the run
---@param runInfo runinfo
---@return number
function addon.GetRunAverageItemLevel(runInfo)
    local total = 0
    for _, playerInfo in pairs(runInfo.combatData.groupMembers) do
        total = total + playerInfo.ilevel
    end
    return total / 5
end

---return the average damage per second
---@param runInfo runinfo
---@param timeType combattimetype
---@return number
function addon.GetRunAverageDamagePerSecond(runInfo, timeType)
    local total = 0
    for _, playerInfo in pairs(runInfo.combatData.groupMembers) do
        total = total + playerInfo.totalDamage
    end

    if (addon.Enum.CombatType.RunRime == timeType) then
        return total / (runInfo.endTime - runInfo.startTime)
    elseif (addon.Enum.CombatType.CombatTime == timeType) then
        return total / runInfo.timeInCombat
    end

    --default return as run time
    return total / (runInfo.endTime - runInfo.startTime)
end

---return the average healing per second
---@param runInfo runinfo
---@param timeType combattimetype
function addon.GetRunAverageHealingPerSecond(runInfo, timeType)
    local total = 0
    for _, playerInfo in ipairs(runInfo.combatData.groupMembers) do
        total = total + playerInfo.totalHeal
    end

    if (addon.Enum.CombatType.RunRime == timeType) then
        return total / (runInfo.endTime - runInfo.startTime)
    elseif (addon.Enum.CombatType.CombatTime == timeType) then
        return total / runInfo.timeInCombat
    end

    --default return as run time
    return total / (runInfo.endTime - runInfo.startTime)
end

---return the run info with highest score for a dungeon
---@param id string|number dungeon name, dungeon id or map id
---@return runinfo?
function addon.GetRunInfoForHighestScoreById(id)
    local highestScore = 0
    local highestScoreRun = nil
    for _, runInfo in ipairs(addon.GetSavedRuns()) do
        if (runInfo.dungeonName == id or runInfo.dungeonId == id or runInfo.mapId == id) then
            if (runInfo.completionInfo.newOverallDungeonScore > highestScore) then
                highestScore = runInfo.completionInfo.newOverallDungeonScore
                highestScoreRun = runInfo
            end
        end
    end
    return highestScoreRun
end
