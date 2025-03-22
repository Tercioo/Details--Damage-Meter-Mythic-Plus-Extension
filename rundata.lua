
--this file is responsable to copy the necessary data from a details! combat into an object that can be used by the addon

---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil

---@alias playername string

--primaryAffix seens to not exists
--local dungeonName, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(challengemodecompletioninfo.mapChallengeModeID)
---@class runinfo : table
---@field combatId number the dungeon overall data unique combat id from details!
---@field combatdata combatdata stores the required combat data for the score board, hence the scoreboard can function even if the combat isn't available in details!
---@field completionInfo challengemodecompletioninfo
---@field timeWithoutDeaths number total time in seconds the run took without counting the time lost by player deaths
---@field timeInCombat number total time in seconds the run took in combat
---@field dungeonName string the name of the dungeon
---@field dungeonId number former DungeonID, this is the id from C_ChallengeMode.GetMapUIInfo
---@field dungeonTexture number gotten from the the 4th result of C_ChallengeMode.GetMapUIInfo
---@field dungeonBackgroundTexture number gotten from the the 5th result of C_ChallengeMode.GetMapUIInfo
---@field timeLimit number the time limit for the run in seconds
---@field startTime number the time() when the run started
---@field endTime number the time() when the run ended
---@field mapId number completionInfo.mapChallengeModeID or Details.challengeModeMapId or C_ChallengeMode.GetActiveChallengeMapID()

---@class challengemodecompletioninfo : table store the data from the GetChallengeCompletionInfo() plus some extra data
---@field mapChallengeModeID number the map id
---@field level number the keystone level
---@field time number seconds+milliseconds, could be nil if the run doesn't completes, need to be divided by 1000 to get the seconds
---@field onTime boolean true if the run finished on time
---@field keystoneUpgradeLevels number how many levels the keystone was upgraded (only possible if onTime is true)
---@field practiceRun boolean true if the run was a practice run
---@field oldOverallDungeonScore number the old score
---@field newOverallDungeonScore number the new score
---@field isEligibleForScore boolean true if the run is eligible for score
---@field isMapRecord boolean true if the run is a record for the map
---@field isAffixRecord boolean true if the run is a record for the affix
---@field members challengemodeplayerinfo[]> the players in the group

---@class challengemodeplayerinfo : table
---@field name string
---@field memberGUID string

---@class playerinfo : table information about a player from details!
---@field name string full name (with realm) if not is a cross realm player
---@field class class the classId (from 1 to 13) gotten from UniClass() thrid return
---@field spec number specialization id
---@field role role name of the role
---@field guid string the player guid
---@field score number mythic+ score
---@field totalDeaths number total deaths
---@field totalDamage number total damage done
---@field totalHeal number total damage done
---@field totalDamageTaken number total damage taken
---@field totalHealTaken number total damage taken
---@field totalDispels number total dispels
---@field totalInterrupts number total of sucessful interrupts
---@field totalInterruptsCasts number total amount of casts of interrupt spells
---@field totalCrowdControlCasts number total amount of casts of crowd control spells
---@field healDoneBySpells table<spellid, number>[] heal done by spells, a table with indexed subtables where the first index is the spellid and the second is the total heal done by that spell
---@field damageDoneBySpells table<spellid, number>[] damage done by spells, a table with indexed subtables where the first index is the spellid and the second is the total damage done by that spell
---@field damageTakenFromSpells table<spellid, number> damage taken from spells
---@field dispelWhat table<spellid, number> which debuffs the player dispelled
---@field interruptWhat table<spellid, number> which spells the player interrupted
---@field crowdControlSpells table<spellid, number> which spells the player casted that are crowd control

---@class combatdata : table
---@field groupMembers table<playername, playerinfo>

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





