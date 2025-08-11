
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon


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