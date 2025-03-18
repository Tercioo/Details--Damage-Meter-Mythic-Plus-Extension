
--this file is responsable to copy the necessary data from a details! combat into an object that can be used by the addon

--primaryAffix seens to not exists
--local dungeonName, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(challengemodecompletioninfo.mapChallengeModeID)
---@class runinfo : table
---@field completionInfo challengemodecompletioninfo
---@field timeWithoutDeaths number total time in seconds the run took without counting the time lost by player deaths
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

---@class playerinfo : table
---@field name string full name (with realm) if not is a cross realm player
---@field class class the classId (from 1 to 13) gotten from UniClass() thrid return
---@field spec number specialization id
---@field role role name of the role
---@field guid string the player guid