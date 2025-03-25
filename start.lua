
local Details = Details
local detailsFramework = DetailsFramework
local _

local CONST_MAX_LOGLINES = 100

---@type string, private
local tocFileName, private = ...

---@type profile
local defaultSettings = {
    when_to_automatically_open_scoreboard = "LOOT_CLOSED",
    delay_to_open_mythic_plus_breakdown_big_frame = 3,
    show_column_summary_in_tooltip = true,
    show_remaining_timeline_after_finish = true,
    show_time_sections = true,
    saved_runs = {},
    saved_runs_limit = 10,
    saved_runs_selected_index = 1,
    scoreboard_scale = 1.0,
    translit = GetLocale() ~= "ruRU",
    logs = {},
    font = {
        row_size = 12,

        regular_color = "white",
        regular_outline = "NONE",

        hover_color = "orange",
        hover_outline = "NONE",

        standout_color = {230/255, 204/255, 128/255},
        standout_outline = "NONE",
    },
    logout_logs = {},
    last_run_data = {},
}

private.addon = detailsFramework:CreateNewAddOn(tocFileName, "Details_MythicPlusDB", defaultSettings)
local addon = private.addon

addon.loot = {}
addon.activityTimeline = {}

function addon.OnLoad(self, profile) --ADDON_LOADED
    --added has been loaded
end

function addon.GetVersionString()
    return C_AddOns.GetAddOnMetadata("Details_MythicPlus", "Version")
end

function addon.GetFullVersionString()
    return Details.GetVersionString() .. " | " .. addon.GetVersionString()
end

function addon.OnInit(self, profile) --PLAYER_LOGIN
    --logout logs register what happened to the addon when the player logged out
    if (not profile.logout_logs) then
        profile.logout_logs = {}
    end
    self:SetLogoutLogTable(profile.logout_logs)

    addon.data = {}

    local detailsEventListener = Details:CreateEventListener()
    addon.detailsEventListener = detailsEventListener

    function private.log(...)
        local str = ""
        for i = 1, select("#", ...) do
            str = str .. tostring(select(i, ...)) .. " "
        end

        --insert year month day and hour min sec into str
        local date = date("%Y-%m-%d %H:%M:%S")
        str = date .. "| " .. str

        table.insert(profile.logs, 1, str)

        --limit to 50 entries, removing the oldest
        table.remove(profile.logs, CONST_MAX_LOGLINES+1)
    end

    --register details! events
    detailsEventListener:RegisterEvent("COMBAT_MYTHICDUNGEON_START")
    detailsEventListener:RegisterEvent("COMBAT_MYTHICDUNGEON_END")
    detailsEventListener:RegisterEvent("COMBAT_MYTHICPLUS_OVERALL_READY")
    detailsEventListener:RegisterEvent("COMBAT_ENCOUNTER_START")
    detailsEventListener:RegisterEvent("COMBAT_ENCOUNTER_END")
    detailsEventListener:RegisterEvent("COMBAT_PLAYER_ENTER")
    detailsEventListener:RegisterEvent("COMBAT_PLAYER_LEAVE")

    addon.InitializeEvents()

    AddonCompartmentFrame:RegisterAddon({
        text = "Mythic+ Scoreboard",
        icon = "4352494",
        notCheckable = true,
        func = Details.OpenMythicPlusBreakdownBigFrame,
        funcOnEnter = function(button)
            MenuUtil.ShowTooltip(button, function(tooltip)
                tooltip:SetText("Open the Details! Mythic+ scoreboard")
            end)
        end,
        funcOnLeave = function(button)
            MenuUtil.HideTooltip(button)
        end,
    })

    -- fix/migrate settings

    -- ensure people don't break the scale
    addon.profile.scoreboard_scale = math.max(0.6, math.min(1.6, addon.profile.scoreboard_scale))

    -- required to create early due to the frame events
    local scoreboard = addon.CreateBigBreakdownFrame()
    scoreboard:SetScale(addon.profile.scoreboard_scale)

    private.log("addon loaded")
end


function addon.ShowLogs()
    --dumpt is a function from details!
    dumpt(addon.profile.logs)
end
