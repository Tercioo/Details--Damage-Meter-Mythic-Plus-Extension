
--functions to handle the slash commands
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

addon.commands = {
    [""] = {L["COMMAND_OPEN_OPTIONS"], function ()
        print(string.format(L["COMMAND_OPEN_OPTIONS_PRINT"], "/sb help"))
        addon.ShowMythicPlusOptionsWindow()
    end},
    help = {L["COMMAND_HELP"], function ()
        print(L["COMMAND_HELP_PRINT"])
        local sb = WrapTextInColorCode("/sb ", "0000ccff")
        for name, command in pairs(addon.commands) do
            print(sb .. (name and WrapTextInColorCode(name .. " ", "001eff00") or "") .. command[1])
        end
    end},
    version = {L["COMMAND_SHOW_VERSION"], function ()
        Details.ShowCopyValueFrame(addon.GetFullVersionString())
    end},
    open = {L["COMMAND_OPEN_SCOREBOARD"], function ()
        addon.OpenMythicPlusBreakdownBigFrame()
    end},
    logs = {L["COMMAND_OPEN_LOGS"], function ()
        addon.ShowLogs()
    end},
    history = {L["COMMAND_LIST_RUN_HISTORY"], function ()
        local runs = addon.GetSavedRuns()
        local total = #runs
        if (total == 0) then
            print(L["COMMAND_LIST_RUN_HISTORY_NO_RUNS"])
        end
        for i = total, 1, -1 do
            local runInfo = runs[i]
            print(i .. ". " .. addon.FormatRunDescription(runInfo))
        end
    end},
    ["history-clear"] = {L["COMMAND_CLEAR_RUN_HISTORY"], function ()
        local total = #addon.GetSavedRuns()
        print(string.format(L["COMMAND_CLEAR_RUN_HISTORY_DONE"], WrapTextInColorCode(total, "0000ff00")))
        for i = total, 1, -1 do
            addon.RemoveRun(i)
        end
    end},
}

SLASH_SCORE1, SLASH_SCORE2, SLASH_SCORE3 = "/scoreboard", "/score", "/sb"
function SlashCmdList.SCORE(msg)
    local command, rest = msg:match("^(%S*)%s*(.-)$")
    command = string.lower(command)

    if (addon.commands[command]) then
        addon.commands[command][2](rest)
    end
end
