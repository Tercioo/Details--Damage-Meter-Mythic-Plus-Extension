
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
    if (not playerLiked or whoLiked == playerLiked) then
        return
    end

    local run = addon.Compress.GetLastRun()
    if (not run) then
        return
    end

    if (not run.combatData.groupMembers[playerLiked]) then
        local matched
        for possibleMatch, _ in pairs(run.combatData.groupMembers) do
            if (playerLiked == Ambiguate(possibleMatch, "short") or possibleMatch == Ambiguate(playerLiked, "short")) then
                matched = possibleMatch
                break
            end
        end

        if (matched == nil) then
            return
        end

        playerLiked = matched
    end

    if (not run.combatData.groupMembers[playerLiked].likedBy) then
        addon.Compress.SetValue(1, "combatData.groupMembers." .. playerLiked .. ".likedBy", {[whoLiked] = true})
    else
        addon.Compress.SetValue(1, "combatData.groupMembers." .. playerLiked .. ".likedBy." .. whoLiked, true)
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

    LikePlayer(myName, playerLiked)
    addon.Comm.Send("L", {playerLiked = playerLiked})
end

function addon.ProcessLikePlayer(sender, data)
    LikePlayer(sender, data.playerLiked)
end
