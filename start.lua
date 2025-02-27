
local Details = Details
local detailsFramework = DetailsFramework
local _

local CONST_MAX_LOGLINES = 50

---@type string, private
local tocFileName, private = ...

---@type profile
local defaultSettings = {
    auto_open_mythic_plus_breakdown_big_frame = true,
    delay_to_open_mythic_plus_breakdown_big_frame = 5,
    logs = {},
    font = {
        regular_size = 12,
        regular_color = "white",
        regular_outline = "NONE",

        hover_size = 12,
        hover_color = "orange",
        hover_outline = "NONE",

        standout_size = 12,
        standout_color = {230/255, 204/255, 128/255},
        standout_outline = "NONE",
    },
    logout_logs = {},
}

private.addon = detailsFramework:CreateNewAddOn(tocFileName, "Details_MythicPlusDB", defaultSettings)

function private.addon.OnLoad(self, profile) --ADDON_LOADED
    --added has been loaded
end

function private.addon.OnInit(self, profile) --PLAYER_LOGIN
    --logout logs register what happened to the addon when the player logged out
    if (not profile.logout_logs) then
        profile.logout_logs = {}
    end
    self:SetLogoutLogTable(profile.logout_logs)

    local detailsEventListener = Details:CreateEventListener()
    private.addon.detailsEventListener = detailsEventListener

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

    private.addon.InitializeEvents()

    private.log("addon loaded")
end

--functions exposed to global namespace
--[[GLOBAL]] DetailsMythicPlusAddon = {}

function DetailsMythicPlusAddon.ShowLogs()
    --dumpt is a function from details!
    dumpt(private.addon.profile.logs)
end
