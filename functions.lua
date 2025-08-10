
--mythic+ extension for Details! Damage Meter
local Details = Details
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...

---@type detailsmythicplus
local addon = private.addon

--localization
local L = detailsFramework.Language.GetLanguageTable(tocFileName)
local Translit = LibStub("LibTranslit-1.0")

function addon.PreparePlayerName(name)
    name = detailsFramework:RemoveRealmName(name)
    return addon.profile.translit and Translit:Transliterate(name, "!") or name
end

local LikePlayer = function (whoLiked, playerLiked)
    if (not playerLiked) then
        return
    end

    playerLiked = Ambiguate(playerLiked, "none")
    if (playerLiked == whoLiked) then
        return
    end

    local run, runHeader = addon.Compress.GetLastRun()
    if (not run or not runHeader) then
        return
    end

    if (not run.combatData.groupMembers[playerLiked]) then
        private.log("unable to match gg from " .. whoLiked .. " for " .. playerLiked .. " to a player in the group")
        return
    end

    if (not run.combatData.groupMembers[playerLiked].likedBy) then
        addon.Compress.SetValue(1, "combatData.groupMembers." .. playerLiked .. ".likedBy", {[whoLiked] = true})
    else
        addon.Compress.SetValue(1, "combatData.groupMembers." .. playerLiked .. ".likedBy." .. whoLiked, true)
    end

    runHeader.likesGiven[whoLiked] = runHeader.likesGiven[whoLiked] or {}
    runHeader.likesGiven[whoLiked][playerLiked] = true

    local runOkay, errorText = pcall(function() --don't stop the flow if new code gives errors
        if (UnitIsUnit(whoLiked, "player")) then
            addon.profile.likesGiven[playerLiked] = addon.profile.likesGiven[playerLiked] or {0, {}} --[1] amount of likes given, [2] runIds where the likes were given
            local likesGiven = addon.profile.likesGiven[playerLiked]
            likesGiven[1] = likesGiven[1] + 1 --increment the amount of likes given
            table.insert(likesGiven[2], runHeader.runId) --add the runId where the like was given
        end
    end)

    if (not runOkay) then
        print("Details! M+ Extension error on LikePlayer(): ", errorText)
    end

    if (addon.GetSelectedRunIndex() == 1) then
        addon.RefreshOpenScoreBoard()
    end
end

function addon.LikePlayer(playerLiked)
    local myName = UnitName("player")
    if (playerLiked == myName) then
        return
    end

    if (not playerLiked:match("%-")) then
        playerLiked = playerLiked .. "-" .. GetRealmName("player")
    end

    LikePlayer(myName, playerLiked)
    addon.Comm.Send("L", {playerLiked = playerLiked})
end

function addon.ProcessLikePlayer(sender, data)
    LikePlayer(sender, data.playerLiked)
end

function DetailsMythicPlus.GetAmountOfLikesGivenByPlayerSelf(targetPlayerName)
    --get all stored runs
    local allRuns = addon.Compress.GetSavedRuns()
    if (not allRuns) then
        return 0
    end

    ---@type table<number, number[]>
    local likesGivenToTargetPlayer = addon.profile.likesGiven[targetPlayerName]
    if (likesGivenToTargetPlayer) then
        local amountOfLikes = likesGivenToTargetPlayer[1]
        local runIds = likesGivenToTargetPlayer[2]
        return amountOfLikes, runIds
    end

    return 0, {}
end