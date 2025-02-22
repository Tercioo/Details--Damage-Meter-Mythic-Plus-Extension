
local Details = Details
local detailsFramework = DetailsFramework
local _

---@type string, private
local tocFileName, private = ...

local defaultSettings = {}

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

    --register details! events
    detailsEventListener:RegisterEvent("COMBAT_MYTHICDUNGEON_START")
    detailsEventListener:RegisterEvent("COMBAT_MYTHICDUNGEON_END")
    detailsEventListener:RegisterEvent("COMBAT_MYTHICPLUS_OVERALL_READY")
    detailsEventListener:RegisterEvent("COMBAT_ENCOUNTER_START")
    detailsEventListener:RegisterEvent("COMBAT_ENCOUNTER_END")
    detailsEventListener:RegisterEvent("COMBAT_PLAYER_ENTER")
    detailsEventListener:RegisterEvent("COMBAT_PLAYER_LEAVE")
end


