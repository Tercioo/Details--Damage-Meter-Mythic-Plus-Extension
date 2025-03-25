
--this file is responsable to copy the necessary data from a details! combat into an object that can be used by the addon

---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil

--localization
local L = detailsFramework.Language.GetLanguageTable(addonName)

---@alias playername string

--primaryAffix seens to not exists
--local dungeonName, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(challengemodecompletioninfo.mapChallengeModeID)

---runs on details! event COMBAT_MYTHICPLUS_OVERALL_READY
function addon.CreateRunInfo(mythicPlusOverallSegment)

    local completionInfo = C_ChallengeMode.GetChallengeCompletionInfo()
    local combatTime = mythicPlusOverallSegment:GetCombatTime()

    ---@type runinfo
    local runInfo = {
        combatId = mythicPlusOverallSegment:GetCombatUID(),
        combatdata = {
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
        dungeonTexture = 0, --done
        dungeonBackgroundTexture = 0, --done
        timeLimit = 0, --done
        startTime = addon.profile.last_run_data.start_time,
        endTime = time(),
        mapId = 0, --done
    }

    if (completionInfo.mapChallengeModeID == nil) then
        runInfo.mapId = Details.challengeModeMapId
    end

    if (runInfo.mapId == nil) then
        runInfo.mapId = C_ChallengeMode.GetActiveChallengeMapID()
    end

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
            local playerName = actorObject:Name()

            ---@type playerinfo
            local playerInfo = {
                name = playerName,
                class = actorObject:Class(),
                spec = actorObject:Spec(),
                role = UnitGroupRolesAssigned(actorObject:Name()),
                guid = actorObject:GetGUID(),
                score = 0,
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
                damageTakenFromSpells  = mythicPlusOverallSegment:GetDamageTakenBySpells(playerName),
                damageDoneBySpells  = {}, --done
                dispelWhat  = {}, --done
                interruptWhat = {}, --done
                crowdControlSpells = {}, --done
                ilevel = Details:GetItemLevelFromGuid(actorObject:GetGUID()),
            }

            runInfo.combatdata.groupMembers[playerName] = playerInfo

            local playerDeaths = mythicPlusOverallSegment:GetPlayerDeaths(playerName)
            playerInfo.totalDeaths = #playerDeaths

            --spell damage done
            local spellsUsed = actorObject:GetActorSpells()
            local temp = {}
            for _, spellTable in ipairs(spellsUsed) do
                table.insert(temp, spellTable.id, spellTable.total)
            end

            table.sort(temp, function(a, b) return a[2] > b[2] end)
            playerInfo.damageDoneBySpells = temp

            --heal
            for _, healActorObject in healingContainer:ListActors() do
                ---@cast actorObject actorheal
                if (healActorObject:Name() == playerName) then
                    playerInfo.totalHeal = healActorObject.total
                    playerInfo.totalHealTaken = healActorObject.healing_taken

                    --spell heal done
                    local temp = {}
                    local spellsUsedToHeal = healActorObject:GetActorSpells()
                    for _, spellTable in ipairs(spellsUsedToHeal) do
                        table.insert(temp, spellTable.id, spellTable.total)
                    end

                    table.sort(temp, function(a, b) return a[2] > b[2] end)
                    playerInfo.healDoneBySpells = temp
                end
            end

            --utility
            for _, utilityActorObject in utilityContainer:ListActors() do
                ---@cast utilityActorObject actorutility
                if (utilityActorObject:Name() == playerName) then
                    playerInfo.totalDispels = utilityActorObject.dispell
                    playerInfo.totalInterrupts = utilityActorObject.interrupt
                    playerInfo.totalInterruptsCasts = mythicPlusOverallSegment:GetInterruptCastAmount(playerName)
                    playerInfo.totalCrowdControlCasts = mythicPlusOverallSegment:GetCCCastAmount(playerName)
                    playerInfo.dispelWhat = detailsFramework.table.copy({}, utilityActorObject.dispell_oque)
                    playerInfo.interruptWhat = detailsFramework.table.copy({}, utilityActorObject.interrompeu_oque)
                    playerInfo.crowdControlSpells = mythicPlusOverallSegment:GetCrowdControlSpells(playerName)
                end
            end
        end
    end

    return runInfo
end

---return an array with all data from the saved runs
---@return runinfo[]
function addon.GetSavedRuns()
    return addon.profile.saved_runs
end

---return the run info for the last run finished
---@return runinfo
function addon.GetLastRun()
    return addon.profile.saved_runs[1]
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
    return date("%H:%M %d/%b/%Y", runInfo.endTime)
end

---return the average item level of the 5 players in the run
---@param runInfo runinfo
---@return number
function addon.GetRunAverageItemLevel(runInfo)
    local total = 0
    for _, playerInfo in ipairs(runInfo.combatdata.groupMembers) do
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
    for _, playerInfo in ipairs(runInfo.combatdata.groupMembers) do
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
    for _, playerInfo in ipairs(runInfo.combatdata.groupMembers) do
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