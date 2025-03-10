
--mythic+ extension for Details! Damage Meter
--[[
    This file is responsible for the options windows
]]

---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon

--templates
local options_text_template = detailsFramework:GetTemplate ("font", "OPTIONS_FONT_TEMPLATE")
local options_dropdown_template = detailsFramework:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local options_switch_template = detailsFramework:GetTemplate ("switch", "OPTIONS_CHECKBOX_TEMPLATE")
local options_slider_template = detailsFramework:GetTemplate ("slider", "OPTIONS_SLIDER_TEMPLATE")
local options_button_template = detailsFramework:GetTemplate ("button", "OPTIONS_BUTTON_TEMPLATE")

---@type mythic_plus_options_object
---@diagnostic disable-next-line: missing-fields
local mythicPlusOptions = {}

local optionsTemplate = {
    {type = "label", get = function() return "General Options" end, text_template = detailsFramework:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
    {
        type = "range",
        get = function () return addon.profile.delay_to_open_mythic_plus_breakdown_big_frame end,
        set = function (_, _, value)
            addon.profile.delay_to_open_mythic_plus_breakdown_big_frame = value
            addon.RefreshOpenScoreBoard()
        end,
        min = 0,
        max = 10,
        step = 1,
        name = "Scoreboard open delay",
        desc = "The amount of seconds after which the scoreboard will appear when the mythic plus dungeon completes",
    },
    {
        type = "toggle",
        get = function () return addon.profile.show_column_summary_in_tooltip end,
        set = function (_, _, value)
            addon.profile.show_column_summary_in_tooltip = value
            addon.RefreshOpenScoreBoard()
        end,
        name = "Summary in tooltip",
        desc = "When hovering over a column in the scoreboard it will show a summary of the breakdown",
    },
    {
        type = "toggle",
        get = function () return addon.profile.translit end,
        set = function (_, _, value)
            addon.profile.translit = value
            addon.RefreshOpenScoreBoard()
        end,
        name = "Translit",
        desc = "Translit Cyrillic characters to the latin alphabet",
    },
    {type = "label", get = function() return "Timeline" end, text_template = detailsFramework:GetTemplate ("font", "ORANGE_FONT_TEMPLATE")},
    {
        type = "toggle",
        get = function () return addon.profile.show_remaining_timeline_after_finish end,
        set = function (_, _, value)
            addon.profile.show_remaining_timeline_after_finish = value
            addon.RefreshOpenScoreBoard()
        end,
        name = "Show remaining time",
        desc = "When a key is timed, an extra section will be added showing the time still remaining",
    },
}

local mainFrameName = "DetailsMythicPlusOptionsFrame"

function Details.ShowMythicPlusOptionsWindow()
    mythicPlusOptions.ShowOptions()
end

function mythicPlusOptions.ShowOptions()
    local options = mythicPlusOptions.InitializeOptionsWindow()
    options:Show()
end

function mythicPlusOptions.InitializeOptionsWindow()
    if (_G[mainFrameName]) then
        return _G[mainFrameName]
    end

    local optionsFrame = detailsFramework:CreateSimplePanel(UIParent, 360, 300, "Details! Mythic Plus Options", mainFrameName, {UseScaleBar = false, NoScripts = true, NoTUISpecialFrame = true})
    detailsFramework:MakeDraggable(optionsFrame)
    optionsFrame:SetPoint("center", UIParent, "center", 160, -50)
    detailsFramework:ApplyStandardBackdrop(optionsFrame)
    optionsFrame:SetFrameStrata("HIGH")
    optionsFrame:SetToplevel(true)
    optionsFrame:SetFrameLevel(1000)

    --close button at the top right of the frame
    local closeButton = detailsFramework:CreateCloseButton(optionsFrame, "$parentCloseButton")
    closeButton:SetScript("OnClick", function()
        optionsFrame:Hide()
    end)
    closeButton:SetPoint("topright", optionsFrame, "topright", -5, -5)

    -- detailsFramework:CreateCloseButton looks better
    optionsFrame.Close:Hide()
    optionsFrame.Close = closeButton
    optionsFrame.closeButton = closeButton

    optionsTemplate.always_boxfirst = true
    optionsTemplate.align_as_pairs = true
    optionsTemplate.align_as_pairs_string_space = 180
    optionsTemplate.widget_width = 150

    local canvasFrame = detailsFramework:CreateCanvasScrollBox(optionsFrame, nil, mainFrameName .. "Canvas")
    canvasFrame:SetPoint("topleft", optionsFrame, "topleft", 6, -26)
    canvasFrame:SetPoint("bottomright", optionsFrame, "bottomright", -26, 6)
    optionsFrame.canvasFrame = canvasFrame

    detailsFramework:BuildMenu(canvasFrame, optionsTemplate, 0, 0, optionsFrame:GetWidth(), false, options_text_template, options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template)

    return optionsFrame
end
