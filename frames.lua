
--functions to create frames, use to keep clean the main files
---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil
local Translit = LibStub("LibTranslit-1.0")

---@class bosswidget : frame
---@field AvatarTexture texture
---@field TimeText fontstring
---@field VerticalLine texture

---@param parent frame
---@param index number
---@return bosswidget
function addon.CreateBossPortraitTexture(parent, index)
    local newBossWidget = CreateFrame("frame", "$parentBossWidget" .. index, parent, "BackdropTemplate")
    newBossWidget:SetSize(64, 32)
    newBossWidget:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
    newBossWidget:SetBackdropColor(0, 0, 0, 0.1)
    newBossWidget:SetBackdropBorderColor(0, 0, 0, 0)

    local bossAvatar = detailsFramework:CreateImage(newBossWidget, "", 64, 32, "border")
    bossAvatar:SetPoint("bottomleft", newBossWidget, "bottomleft", 0, 0)
    bossAvatar:SetScale(1.0)
    newBossWidget.AvatarTexture = bossAvatar

    local timeText = detailsFramework:CreateLabel(newBossWidget)
    timeText:SetPoint("bottomright", newBossWidget, "bottomright", 0, 0)
    newBossWidget.TimeText = timeText

    local verticalLine = detailsFramework:CreateImage(newBossWidget, "", 1, 25, "overlay")
    verticalLine:SetColorTexture(1, 1, 1, 0.3)
    verticalLine:SetPoint("bottomleft", newBossWidget, "bottomright", 0, 0)
    verticalLine:SetPoint("topleft", timeText, "topright", 0, 0)
    newBossWidget.VerticalLine = verticalLine

    local timeBackground = detailsFramework:CreateImage(newBossWidget, "", 30, 12, "artwork")
    timeBackground:SetColorTexture(0, 0, 0, 0.8)
    timeBackground:SetPoint("topleft", timeText, "topleft", -2, 2)
    timeBackground:SetPoint("bottomright", timeText, "bottomright", 2, 0)

    return newBossWidget
end
