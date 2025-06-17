
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

function addon.LikePlayer(playerLiked)
    if (playerLiked == UnitName("player")) then
        return
    end

    -- todo: addon comms, that will eventually call addon.ProcessLikePlayer(sender, playerLiked)
end


function addon.ProcessLikePlayer(likedBy, playerLiked)
    if (likedBy == playerLiked) then
        return
    end

    local run = addon.Compress.GetLastRun() or addon.Compress.UncompressedRun(1) -- before release remove this line and replace with the one below
    --local run = addon.Compress.GetLastRun()
    --addon.Compress.SetValue(1, "combatData.groupMembers." .. playerLiked .. ".likedBy", {}) -- this line can be used to reset, remove before release
    if (not run or not run.combatData.groupMembers[playerLiked]) then
        return
    end

    if (not run.combatData.groupMembers[playerLiked].likedBy) then
        addon.Compress.SetValue(1, "combatData.groupMembers." .. playerLiked .. ".likedBy", {[likedBy] = true})
    else
        addon.Compress.SetValue(1, "combatData.groupMembers." .. playerLiked .. ".likedBy." .. likedBy, true)
    end

    if (addon.GetSelectedRunIndex() == 1) then
        addon.RefreshOpenScoreBoard()
    end
end
