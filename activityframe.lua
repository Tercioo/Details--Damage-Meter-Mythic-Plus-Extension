
---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil
local Translit = LibStub("LibTranslit-1.0")

local activity = private.addon.activityTimeline

---boss widgets showing the kill time of each boss
function activity.UpdateBossWidgets(activityFrame, start, multiplier)
    for i = 1, #activityFrame.bossWidgets do
        activityFrame.bossWidgets[i]:Hide()
    end

    local allBossesSegments = addon.GetRunBossSegments()
    local bossWidgetIndex = 1

    for i = 1, #allBossesSegments do
        local bossSegment = allBossesSegments[i]
        local bossSegmentTexture = bossSegment:GetMythicDungeonInfo()
        local bossSegmentTime = bossSegment:GetCombatTime()
        local killTime = addon.GetBossKillTime(bossSegment)

        if (killTime > 0) then
            local bossWidget = activityFrame.bossWidgets[bossWidgetIndex]
            if (not bossWidget) then
                bossWidget = addon.CreateBossPortraitTexture(activityFrame, bossWidgetIndex)
                activityFrame.bossWidgets[bossWidgetIndex] = bossWidget
            end
            bossWidgetIndex = bossWidgetIndex + 1

            local killTimeRelativeToStart = killTime - start
            local xPosition = killTimeRelativeToStart * multiplier

            bossWidget:SetPoint("bottomright", activityFrame, "bottomleft", xPosition, 4)
            bossWidget:SetFrameLevel(10000 + i)

            bossWidget.TimeText:SetText(detailsFramework:IntegerToTimer(killTimeRelativeToStart))

            --local bossInfo = bossSegment:GetBossInfo()
            --if (bossInfo and bossInfo.bossimage) then
            if (bossSegment:GetBossImage()) then
                bossWidget.AvatarTexture:SetTexture(bossSegment:GetBossImage())
            else
                --local bossAvatar = Details:GetBossPortrait(nil, nil, bossTable[2].name, bossTable[2].ej_instance_id)
                --bossWidget.AvatarTexture:SetTexture(bossAvatar)
            end
        end
    end
end

function activity.UpdateBloodlustWidgets(activityFrame, start, multiplier)
    local bloodlustUsage = addon.GetBloodlustUsage()
    if (bloodlustUsage) then
        for i = 1, #bloodlustUsage do
            local timeOfUsage = bloodlustUsage[i]
        end
    end
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

function activity.RenderDeathMarker(self, event, marker)
    local preferUp = false
    local playerPortrait = marker.subFrames.playerPortrait
    ---@cast playerPortrait playerportrait
    if (not marker.subFrames.playerPortrait) then
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

        marker.subFrames.playerPortrait = playerPortrait
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

    detailsFramework:SetFontSize(marker.timestampLabel, 12)
    detailsFramework:SetFontColor(marker.timestampLabel, 1, 0, 0)

    return {
        preferUp = preferUp,
        forceDirection = nil,
    }
end

function activity.RenderKeyFinishedMarker(self, event, marker)
    local icon = marker.subFrames.icon
    if (not icon) then
        icon = marker:CreateTexture("$parentIcon", "artwork")
        marker.subFrames.icon = icon
    end

    detailsFramework:SetFontSize(marker.timestampLabel, 12)
    if (event.arguments.onTime) then
        icon:SetAtlas("gficon-chest-evergreen-greatvault-collect")
        detailsFramework:SetFontColor(marker.timestampLabel, 0.2, 0.8, 0.2)
    else
        icon:SetAtlas("gficon-chest-evergreen-greatvault-complete")
        detailsFramework:SetFontColor(marker.timestampLabel, 0.8, 0.2, 0.2)
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
