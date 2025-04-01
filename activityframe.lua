
---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil
local Translit = LibStub("LibTranslit-1.0")

--localization
local L = detailsFramework.Language.GetLanguageTable(addonName)

local activity = private.addon.activityTimeline

activity.markers = {}
activity.timeSections = {}
activity.maxEvents = 256

function activity.UpdateTimeSections(activityFrame, totalRuntime, multiplier)
    for i = 1, #activity.timeSections do
        activity.timeSections[i]:Hide()
    end

    if (not addon.profile.show_time_sections) then
        return
    end

    -- aim to have 4~6 section markers
    local length = 300
    local step = 300

    for _ = 1, 10 do
        local division = totalRuntime / length
        if (division < 4) then
            if (length > step) then
                length = length - step
            end
            break
        else
            length = length + step
        end
    end

    for i = 1, math.ceil(totalRuntime / length) do
        local section = activity.timeSections[i]
        if (not section) then
            section = addon.CreateTimeSection(activityFrame, i)
            activity.timeSections[i] = section
        end

        local time = (i - 1) * length

        section:Show()
        section:ClearAllPoints()
        section:SetPoint("topleft", activityFrame, "bottomleft", time * multiplier, 0)
        section:SetFrameLevel(5000 + i)
        section.TimeText:SetText(detailsFramework:IntegerToTimer(time))
    end
end

---boss widgets showing the kill time of each boss
---@param runData runinfo
function activity.UpdateBossWidgets(activityFrame, runData, multiplier)
    for i = 1, #activityFrame.bossWidgets do
        activityFrame.bossWidgets[i]:Hide()
    end

    local bossWidgetIndex = 1
    for i = 1, #runData.encounters do
        local encounter = runData.encounters[i]
        if (encounter.defeated) then
            local bossWidget = activityFrame.bossWidgets[bossWidgetIndex]
            if (not bossWidget) then
                bossWidget = addon.CreateBossPortraitTexture(activityFrame, bossWidgetIndex)
                activityFrame.bossWidgets[bossWidgetIndex] = bossWidget
            end
            bossWidgetIndex = bossWidgetIndex + 1

            local killTimeRelativeToStart = encounter.endTime - runData.startTime
            local xPosition = killTimeRelativeToStart * multiplier

            bossWidget:Show()
            bossWidget:ClearAllPoints()
            bossWidget:SetPoint("bottomright", activityFrame, "bottomleft", xPosition, 4)
            bossWidget:SetFrameLevel(5000 + i)

            bossWidget.TimeText:SetText(detailsFramework:IntegerToTimer(killTimeRelativeToStart))
            local encounterInfo = Details:GetEncounterInfo(encounter.dungeonEncounterId)
            if (encounterInfo and encounterInfo.creatureIcon) then
                bossWidget.AvatarTexture:SetTexture(encounterInfo.creatureIcon)
                bossWidget.AvatarTexture:SetSize(64, 32)
                bossWidget.AvatarTexture:SetAlpha(1)
            else
                -- the following 3 lines and the SetSize/SetAlpha above can be removed when a proper fallback image is available
                bossWidget.AvatarTexture:SetAtlas("BossBanner-SkullCircle")
                bossWidget.AvatarTexture:SetSize(36, 36)
                bossWidget.AvatarTexture:SetAlpha(0.6)
            end
        end
    end
end

function activity.UpdateBloodlustWidgets(activityFrame, runData, multiplier)
    -- todo: implement into runData
end

--return a texture to be used as a segment of the activity bar
function activity.GetSegmentTexture(activityFrame)
    local currentIndex = activityFrame.nextTextureIndex
    activityFrame.nextTextureIndex = currentIndex + 1

    if (activityFrame.segmentTextures[currentIndex]) then
        return activityFrame.segmentTextures[currentIndex]
    end

    local texture = activityFrame:CreateTexture("$parentSegmentTexture" .. currentIndex, "artwork")
    texture:SetColorTexture(1, 1, 1, 0.5)
    texture:SetHeight(4)
    texture:ClearAllPoints()

    activityFrame.segmentTextures[currentIndex] = texture

    return texture
end

--reset the next index of texture to use and hide all existing textures
function activity.ResetSegmentTextures(activityFrame)
    activityFrame.nextTextureIndex = 1
    --iterate among all textures and hide them
    for i = 1, #activityFrame.segmentTextures do
        activityFrame.segmentTextures[i]:Hide()
    end
end

function activity.RenderDeathMarker(frame, event, marker)
    local preferUp = false
    local playerPortrait = marker.SubFrames.playerPortrait
    ---@cast playerPortrait playerportrait
    if (not marker.SubFrames.playerPortrait) then
        --player portrait
        playerPortrait = Details:CreatePlayerPortrait(marker, "$parentPortrait")
        ---@cast playerPortrait playerportrait
        playerPortrait:ClearAllPoints()
        playerPortrait:SetPoint("center", marker, "center", 0, 0)
        playerPortrait.Portrait:SetSize(32, 32)
        playerPortrait:SetSize(32, 32)
        playerPortrait.RoleIcon:SetSize(18, 18)
        playerPortrait.RoleIcon:ClearAllPoints()
        playerPortrait.RoleIcon:SetPoint("bottomleft", playerPortrait.Portrait, "bottomright", -9, -2)

        playerPortrait.Portrait:SetDesaturated(true)
        playerPortrait.RoleIcon:SetDesaturated(true)

        marker.SubFrames.playerPortrait = playerPortrait
    end

    SetPortraitTexture(playerPortrait.Portrait, event.arguments.playerData.unitId)
    local portraitTexture = playerPortrait.Portrait:GetTexture()
    if (not portraitTexture) then
        local class = event.arguments.playerData.class
        playerPortrait.Portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        playerPortrait.Portrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
    end

    local role = event.arguments.playerData.role
    if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
        playerPortrait.RoleIcon:SetAtlas(GetMicroIconForRole(role), TextureKitConstants.IgnoreAtlasSize)
        playerPortrait.RoleIcon:Show()
    else
        playerPortrait.RoleIcon:Hide()
    end

    playerPortrait:SetFrameLevel(playerPortrait:GetParent():GetFrameLevel() - 2)
    playerPortrait:Show()
    playerPortrait.Portrait:Show()

    detailsFramework:SetFontSize(marker.TimestampLabel, 12)
    detailsFramework:SetFontColor(marker.TimestampLabel, 1, 0, 0)

    return {
        preferUp = preferUp,
        forceDirection = nil,
    }
end

function activity.RenderKeyFinishedMarker(frame, event, marker)
    local icon = marker.SubFrames.icon
    if (not icon) then
        icon = marker:CreateTexture("$parentIcon", "artwork")
        marker.SubFrames.icon = icon
    end

    detailsFramework:SetFontSize(marker.TimestampLabel, 12)
    if (event.arguments.onTime) then
        icon:SetAtlas("gficon-chest-evergreen-greatvault-collect")
        detailsFramework:SetFontColor(marker.TimestampLabel, 0.2, 0.8, 0.2)
    else
        icon:SetAtlas("gficon-chest-evergreen-greatvault-complete")
        detailsFramework:SetFontColor(marker.TimestampLabel, 0.8, 0.2, 0.2)
    end

    icon:SetSize(257*0.2, 226*0.2)
    icon:ClearAllPoints()
    icon:SetPoint("center", marker, "center", 0, 5)
    icon:Show()

    return {
        preferUp = nil,
        forceDirection = "up",
    }
end

function activity.PrepareEventFrames(frame, events)
    local i = 0
    local eventCount = #events
    local markerCount = #activity.markers
    local function iterator()
        i = i + 1
        if (i > eventCount or i > activity.maxEvents) then
            -- hide all other markers and frames
            if (i <= markerCount) then
                for j = i, markerCount do
                    activity.markers[j]:Hide()
                    for _, subFrame in pairs(activity.markers[j].SubFrames) do
                        subFrame:Hide()
                    end
                end
            end
            return
        end

        ---@type activitytimeline_marker
        local marker = activity.markers[i]
        if (not activity.markers[i]) then
            local frameLevel = 10 + 5 * i
            activity.markers[i] = CreateFrame("frame", "$parentEventMarker" .. i, frame, "BackdropTemplate")
            marker = activity.markers[i]
            marker:SetFrameLevel(frameLevel)
            marker.SubFrames = {} -- used to track sub frames that can then all be hidden
            marker:EnableMouse(true)
            marker:SetSize(32, 32)
            marker:SetScript("OnEnter", function (self)
                self.originalFrameLevel = self:GetFrameLevel()
                self:SetFrameLevel(self.originalFrameLevel + 6000)
                self.TimestampLabel:Show()
                self.TimestampBackground:Show()
            end)
            marker:SetScript("OnLeave", function (self)
                self:SetFrameLevel(self.originalFrameLevel)
                self.TimestampLabel:Hide()
                self.TimestampBackground:Hide()
            end)

            local timestampLabel = marker:CreateFontString("$parentTimestampLabel", "overlay", "GameFontNormal")
            timestampLabel:SetJustifyH("center")
            timestampLabel:Hide()
            marker.TimestampLabel = timestampLabel

            local timestampBackground = detailsFramework:CreateImage(marker, "", 30, 12, "artwork")
            timestampBackground:SetColorTexture(0, 0, 0, 0.4)
            timestampBackground:SetPoint("topleft", timestampLabel, "topleft", -2, 2)
            timestampBackground:SetPoint("bottomright", timestampLabel, "bottomright", 2, -2)
            timestampBackground:Hide()
            marker.TimestampBackground = timestampBackground

            local line = marker:CreateTexture("$parentMarkerLineTexture", "border")
            line:SetColorTexture(1, 1, 1, 0.5)
            line:SetWidth(1)
            marker.LineTexture = line
        end

        marker:ClearAllPoints()
        marker:Hide()
        for _, subFrame in pairs(marker.SubFrames) do
            subFrame:Hide()
        end

        return events[i], marker
    end

    return iterator
end
