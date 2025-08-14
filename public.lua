
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon

---@type detailsframework
local detailsFramework = DetailsFramework

---@param targetPlayerName string
---@return number amountOfLike amount of likes given by the player to the target player
function DetailsMythicPlus.GetAmountOfLikesGivenByPlayerSelf(targetPlayerName)
    --get all stored runs
    local allRuns = addon.Compress.GetSavedRuns()
    if (not allRuns) then
        return 0
    end

    ---@type table<number, number[]>
    local likesGivenToTargetPlayer = addon.profile.likes_given[targetPlayerName]
    if (likesGivenToTargetPlayer) then
        return #likesGivenToTargetPlayer
    end

    return 0
end

---@param targetPlayerName string
---@return number[] runIds
function DetailsMythicPlus.GetRunIdLikesGivenByPlayerSelf(targetPlayerName)
    --get all stored runs
    local allRuns = addon.Compress.GetSavedRuns()
    if (not allRuns) then
        return {}
    end

    ---@type table<number, number[]>
    local likesGivenToTargetPlayer = addon.profile.likes_given[targetPlayerName]
    if (likesGivenToTargetPlayer) then
        local repeated = {}
        for i = #likesGivenToTargetPlayer, 1, -1 do
            if (repeated[likesGivenToTargetPlayer[i]]) then
                table.remove(likesGivenToTargetPlayer, i)
            else
                repeated[likesGivenToTargetPlayer[i]] = true
            end
        end
        return likesGivenToTargetPlayer
    end

    return {}
end

function DetailsMythicPlus.Open(runId)
    addon.OpenScoreboardFrame()
    local runIndex = addon.GetRunIndexById(runId)
    if (runIndex) then
        addon.SetSelectedRunIndex(runIndex)
    end
end

---return the simple title for the given runId
---@param runId number
---@return string
function DetailsMythicPlus.GetSimpleDescription(runId)
    local runHeader = addon.Compress.GetRunHeaderById(runId)
    if (runHeader) then
        --{dungeonName, keyLevel, runTime, keyUpgradeLevels, timeString, mapId, dungeonId, onTime and 1 or 0, altName}
        local descriptionTable = addon.Compress.GetDropdownRunDescription(runHeader)
        local dungeonName = descriptionTable[1]

        local dungeonNameAcronym = detailsFramework.string.Acronym(dungeonName)
        local onTimeColor = descriptionTable[8] == 1 and "FFA8E7A8" or "FFD69A9A"
        local when = runHeader.endTime
        local whenString = when and detailsFramework.string.FormatDateByLocale(when) or ""

        local simpleTitle = string.format("%s +%d, |c%s%s|r (" .. whenString .. ")", dungeonNameAcronym, descriptionTable[2], onTimeColor, detailsFramework:IntegerToTimer(descriptionTable[3]))

        return simpleTitle
    end
    return ""
end

---return the runId of the latest run
---@return number?
function DetailsMythicPlus.GetLatestRunId()
    local headers = addon.Compress.GetHeaders()
    if (#headers > 0) then
        return headers[1].runId
    end
    return nil
end