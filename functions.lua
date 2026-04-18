
--mythic+ extension for Details! Damage Meter
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...

---@type detailsmythicplus
local addon = private.addon

--localization
local L = detailsFramework.Language.GetLanguageTable(tocFileName)
local Translit = LibStub("LibTranslit-1.0")

-- required to be called at least once to ensure GetCurrentSeason has a value
C_MythicPlus.RequestMapInfo()
local seasonId = C_MythicPlus.GetCurrentSeason()

function addon.PreparePlayerName(name)
    name = detailsFramework:RemoveRealmName(name)
    return addon.profile.translit and Translit:Transliterate(name, "!") or name
end

function addon.GetCurrentSeasonId()
	return seasonId
end

function addon.ToTimeAgo(header)
	local secondsAgo = time() - header.endTime

    --if the run time is less than 1 hour, show the time in minutes
    --if the run is less than 24 hours, show the time in hours
    --if the run is more than 24 hours, show the time in days
    --if the run is more than 7 days, show the data using addon.GetRunDate(runInfo)

    if (secondsAgo < 3600) then
        return string.format(L["MINUTES_AGO"], math.floor(secondsAgo / 60))
    end

    if (secondsAgo < 86400) then
        return string.format(L["HOURS_AGO"], math.floor(secondsAgo / 3600))
    end

    if (secondsAgo < 604800) then
        return string.format(L["DAYS_AGO"], math.floor(secondsAgo / 86400))
    end

    return addon.GetRunDate(header)
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
            addon.profile.likes_given[playerLiked] = addon.profile.likes_given[playerLiked] or {} --store a list of runIds
            table.insert(addon.profile.likes_given[playerLiked], 1, runHeader.runId) --add the runId where the like was given
        end
    end)

    if (not runOkay) then
        print("Details! M+ Extension error on LikePlayer(): ", errorText)
    end

    if (addon.GetSelectedRunIndex() == 1) then
        addon.RefreshOpenScoreBoard()
    end

    addon.FireEvent("PlayerLiked", DetailsMythicPlus.GetLatestRunId(), playerLiked)
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
    if (sender == UnitName("player")) then
        return
    end

    LikePlayer(sender, data.playerLiked)
end
