
--functions to handle the slash commands
---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil

addon.commands = {
    [""] = {"Open the options", function ()
        print("Opening Details! Mythic+ scoreboard options, for more information use /sb help")
        addon.ShowMythicPlusOptionsWindow()
    end},
    help = {"Shows this list of commands", function ()
        print("available commands:")
        local sb = WrapTextInColorCode("/sb ", "0000ccff")
        for name, command in pairs(addon.commands) do
            print(sb .. (name and WrapTextInColorCode(name .. " ", "001eff00") or "") .. command[1])
        end
    end},
    version = {"Show the version", function ()
        Details.ShowCopyValueFrame(addon.GetFullVersionString())
    end},
    open = {"Open the scoreboard", function ()
        addon.OpenMythicPlusBreakdownBigFrame()
    end},
    logs = {"Show recent logs", function ()
        addon.ShowLogs()
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
