
--mythic+ extension for Details! Damage Meter
--[[
    This file show a frame at the end of a mythic+ run with a breakdown of the players performance.
    It shows the player name, the score, deaths, damage taken, dps, hps, interrupts, dispels and cc casts.
]]

---@type details
---@diagnostic disable-next-line: undefined-field
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil
local Translit = LibStub("LibTranslit-1.0")
local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")

if (not openRaidLib) then
    return
end

--localization
local L = detailsFramework.Language.GetLanguageTable(addonName)

---@class scoreboard_object : table
---@field lines scoreboard_line[]
---@field CreateBigBreakdownFrame fun():scoreboard_mainframe
---@field CreateLineForBigBreakdownFrame fun(parent:scoreboard_mainframe, header:scoreboard_header, index:number):scoreboard_line
---@field CreateActivityPanel fun(parent:scoreboard_mainframe):scoreboard_activityframe
---@field RefreshBigBreakdownFrame fun(mainFrame:scoreboard_mainframe, runData:runinfo):boolean true when it has data, false when it does not and probably should be hidden
---@field SetFontSettings fun() set the default font settings

---@class scoreboard_mainframe : frame
---@field HeaderFrame scoreboard_header
---@field ActivityFrame scoreboard_activityframe
---@field RunInfoDropdown df_dropdown
---@field DungeonNameFontstring fontstring
---@field DungeonBackdropTexture texture
---@field ElapsedTimeText fontstring
---@field OutOfCombatIcon texture
---@field OutOfCombatText fontstring
---@field ItemLevelIcon texture
---@field ItemLevelText fontstring
---@field ReloadedFrame frame
---@field SandTimeIcon texture
---@field StrongArmIcon texture
---@field RatingLabel fontstring
---@field LeftFiligree texture
---@field RightFiligree texture
---@field BottomFiligree texture
---@field YellowSpikeCircle texture
---@field YellowFlash texture
---@field Level fontstring

---@class scoreboard_header : df_headerframe
---@field lines table<number, scoreboard_line>

---@class scoreboard_line : button, df_headerfunctions
---@field playerData scoreboard_playerdata
---@field NextLootSquare number
---@field WaitingForLootLabel loot_dot_animation
---@field LootSquare details_lootsquare
---@field LootSquares details_lootsquare[]
---@field KeystoneDungeonLevel fontstring show the keystone level of the player
---@field KeystoneDungeonLevelBackground texture background texture behind the keystone level text
---@field KeystoneDungeonIcon texture show the keystone dungeon icon the player has
---@field DungeonBorderTexture texture
---@field StopTextDotAnimation fun(self:scoreboard_line)
---@field GetLootSquare fun(self: scoreboard_line):details_lootsquare
---@field ClearLootSquares fun(self: scoreboard_line)
---@field StartTextDotAnimation fun(self:scoreboard_line)


---@class scoreboard_button : df_button
---@field PlayerData scoreboard_playerdata
---@field InterruptCasts fontstring
---@field SetPlayerData fun(self:scoreboard_button, playerData:scoreboard_playerdata)
---@field GetPlayerData fun(self:scoreboard_button):scoreboard_playerdata
---@field HasPlayerData fun(self:scoreboard_button):boolean returns true if data is attached
---@field MarkTop fun(self:scoreboard_button)
---@field OnMouseEnter fun(self:scoreboard_button)|nil
---@field GetActor fun(self:scoreboard_button, actorMainAttribute):actor|nil, combat|nil

---@class scoreboard_playerdata : table
---@field name string
---@field unitName string same as 'name'
---@field class string
---@field spec number
---@field role string
---@field score number
---@field previousScore number
---@field scoreColor table
---@field deaths number
---@field damageTaken number
---@field dps number
---@field hps number
---@field interrupts number
---@field interruptCasts number
---@field dispels number
---@field ccCasts number
---@field unitId string
---@field combatUid number
---@field activityTimeDamage number
---@field activityTimeHeal number
---@field damageTakenFromSpells spell_hit_player[]
---@field loot string|nil
---@field keystoneLevel number
---@field keystoneIcon string|number


---@class timeline_event : table
---@field type string
---@field timestamp number
---@field arguments table

---@type scoreboard_object
---@diagnostic disable-next-line: missing-fields
local mythicPlusBreakdown = {
    lines = {},
}

addon.mythicPlusBreakdown = mythicPlusBreakdown

--main frame settings
local mainFrameName = "DetailsMythicPlusBreakdownFrame"
local mainFrameHeight = 452
--the padding on the left and right side it should keep between the frame itself and the table
local mainFramePaddingHorizontal = 5
--amount of desaturation for the big dungeon image in the background of the main frame
local backdropDungeonTextureDesaturation = 0.5
--offset for the dungeon name y position related to the top of the frame
local dungeonNameY = -12
--where the header is positioned in the Y axis from the top of the frame
local headerY = -65
--width of the run selector at the top right corner
local runSelectorWidth = 250
--the amount of lines to be created to show player data
local lineAmount = 5
local lineOffset = 2
--the height of each line
local lineHeight = 46
--two backdrop colors
local lineColor1 = {1, 1, 1, 0.05}
local lineColor2 = {1, 1, 1, 0.1}
local lineBackdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true}
--position of the activity timeline, it is positioned below the lines
local activityFrameY = headerY - 90 + (lineHeight * lineAmount * -1)
--player keystone icon, keystone text
local keystoneTextureSize = 45 --the icon is a square
local keystoneDefaultTexture = 4352494 --when no keystone is found, this texture is shown
local noKeystoneAlpha = 0.3 --when no keystone is found, decrease the alpha of the icon and text to this value

function addon.OpenMythicPlusBreakdownBigFrame()
    local mainFrame = mythicPlusBreakdown.CreateBigBreakdownFrame()
    if (mainFrame:IsVisible()) then
        return
    end

    local runData = addon.GetSelectedRun()
    if (not runData) then
        print(L["SCOREBOARD_NO_SCORE_AVAILABLE"])
        return
    end

    mythicPlusBreakdown.RefreshBigBreakdownFrame(mainFrame, runData)
    mainFrame:Show()
    mainFrame.YellowSpikeCircle.OnShowAnimation:Play()
end

function addon.RefreshOpenScoreBoard()
    local mainFrame = mythicPlusBreakdown.CreateBigBreakdownFrame()

    if (mainFrame:IsVisible()) then
        --stop all timers running
        for i = 1, #addon.temporaryTimers do
            local thisTimer = addon.temporaryTimers[i]
            if (not thisTimer:IsCancelled()) then
                thisTimer:Cancel()
            end
        end
        table.wipe(addon.temporaryTimers)

        --do the update
        mythicPlusBreakdown.RefreshBigBreakdownFrame(mainFrame, addon.GetSelectedRun())
    end

    return mainFrame
end

function addon.IsScoreboardOpen()
    if (_G[mainFrameName]) then
        return _G[mainFrameName]:IsShown()
    end
    return false
end

function Details.OpenMythicPlusBreakdownBigFrame()
    addon.OpenMythicPlusBreakdownBigFrame()
end

function addon.OpenScoreBoardAtEnd()
    if (not addon.profile.has_last_run) then
        -- workaround for the event not firing if reloaded in-between
        -- this change should be removed when COMBAT_MYTHICPLUS_OVERALL_READY is being triggered in reloaded runs
        addon.OnMythicPlusOverallReady()
    end
    if (not addon.profile.has_last_run) then
        private.log("No last run found while trying to open the scoreboard.")
        return
    end

    private.log("auto opening the mythic+ scoreboard", addon.profile.delay_to_open_mythic_plus_breakdown_big_frame, "seconds")
    detailsFramework.Schedules.After(addon.profile.delay_to_open_mythic_plus_breakdown_big_frame, addon.OpenMythicPlusBreakdownBigFrame)
end

function addon.CreateBigBreakdownFrame()
    return mythicPlusBreakdown.CreateBigBreakdownFrame()
end

local SaveLoot = function(itemLink, unitName)
    local playerName = Ambiguate(unitName, "none")
    local lastRun = addon.GetLastRun()
    if (not lastRun) then
        return
    end

    local itemType = select(6, C_Item.GetItemInfoInstant(itemLink))
    if (itemType ~= Enum.ItemClass.Weapon and itemType ~= Enum.ItemClass.Armor) then
        return
    end

    if (C_Item.IsItemBindToAccountUntilEquip(itemLink)) then
        return
    end

    local effectiveILvl, _, baseItemLevel = C_Item.GetDetailedItemLevelInfo(itemLink)
    local averageItemLevel = addon.GetRunAverageItemLevel(lastRun)
    if (effectiveILvl < averageItemLevel * 0.75 or baseItemLevel < 6) then
        return
    end

    private.log("Loot Received:", playerName, itemLink)
    lastRun.combatData.groupMembers[playerName].loot = itemLink

    addon.RefreshOpenScoreBoard()
end

function mythicPlusBreakdown.CreateBigBreakdownFrame()
    --quick exit if the frame already exists
    if (_G[mainFrameName]) then
        return _G[mainFrameName]
    end

    ---@type scoreboard_mainframe
    local readyFrame = CreateFrame("frame", mainFrameName, UIParent, "BackdropTemplate")
    readyFrame:SetHeight(mainFrameHeight)
    readyFrame:SetPoint("center", UIParent, "center", 0, 0)
    readyFrame:SetFrameStrata("HIGH")
    readyFrame:EnableMouse(true)
    readyFrame:SetMovable(true)
    readyFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    readyFrame:SetScript("OnEvent", function (self, event, ...)
        if (event == "LOOT_CLOSED") then
            self:UnregisterEvent("LOOT_CLOSED")
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
            if (addon.profile.when_to_automatically_open_scoreboard == "LOOT_CLOSED") then
                addon.OpenScoreBoardAtEnd()
            elseif (addon.profile.when_to_automatically_open_scoreboard == "COMBAT_MYTHICPLUS_OVERALL_READY" and not addon.profile.has_last_run) then
                -- fallback to open the scoreboard after looting because the ready event wasn't fired
                -- this change should be removed when COMBAT_MYTHICPLUS_OVERALL_READY is being triggered in reloaded runs
                addon.OpenScoreBoardAtEnd()
            end
        elseif (event == "CHALLENGE_MODE_COMPLETED") then
            self:RegisterEvent("LOOT_CLOSED")
            self:RegisterEvent("PLAYER_ENTERING_WORLD")
            self:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")
            self:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
        elseif (event == "PLAYER_ENTERING_WORLD") then
            local isLogin, isReload = ...
            if (not isLogin and not isReload) then
                self:UnregisterEvent("LOOT_CLOSED")
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
                self:UnregisterEvent("ENCOUNTER_LOOT_RECEIVED")
                self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
            end
        elseif (event == "ENCOUNTER_LOOT_RECEIVED") then
            local _, _, itemLink, _, unitName = ...
            SaveLoot(itemLink, unitName)
        end
    end)

    table.insert(UISpecialFrames, mainFrameName)

    readyFrame:SetBackdropColor(.1, .1, .1, 0)
    readyFrame:SetBackdropBorderColor(.1, .1, .1, 0)
    detailsFramework:AddRoundedCornersToFrame(readyFrame, Details.PlayerBreakdown.RoundedCornerPreset)

    local backgroundDungeonTexture = readyFrame:CreateTexture("$parentDungeonBackdropTexture", "background")
    backgroundDungeonTexture:SetPoint("topleft", readyFrame, "topleft", 3, -3)
    backgroundDungeonTexture:SetPoint("bottomright", readyFrame, "bottomright", -3, 3)
    readyFrame.DungeonBackdropTexture = backgroundDungeonTexture

    detailsFramework:MakeDraggable(readyFrame)

    --close button at the top right of the frame
    local closeButton = detailsFramework:CreateCloseButton(readyFrame, "$parentCloseButton")
    closeButton:SetScript("OnClick", function() readyFrame:Hide() end)
    closeButton:SetPoint("topright", readyFrame, "topright", -4, -7)

    local configButton = detailsFramework:CreateButton(readyFrame, addon.ShowMythicPlusOptionsWindow, 32, 32, "")
    configButton:SetAlpha(0.823)
    configButton:SetSize(closeButton:GetSize())
    configButton:ClearAllPoints()
    configButton:SetPoint("right", closeButton, "left", -3, 0)

    --dropdown to select the runInfo to show
    local buildRunInfoList = function()
        ---@type dropdownoption[]
        local runInfoList = {}
        local savedRuns = addon.GetSavedRuns()
        --get the current run showing
        local selectedRunIndex = addon.GetSelectedRunIndex()

        for i = 1, #savedRuns do
            local runInfo = savedRuns[i]

            --runInfo.mapId, runInfo.dungeonId, runInfo.completionInfo.mapChallengeModeID
            --are the same and doesn't work with Details:GetInstanceInfo()

            ---@type details_instanceinfo
            local instanceInfo = Details:GetInstanceInfo(runInfo.instanceId or runInfo.dungeonName)
            --print(runInfo.mapId, runInfo.dungeonId, runInfo.completionInfo.mapChallengeModeID)

            ---@type dropdownoption
            local option = {
                label = table.concat(addon.GetDropdownRunDescription(runInfo), "@"),
                value = i,
                onclick = function()
                    addon.SetSelectedRunIndex(i)
                end,
                icon = instanceInfo and instanceInfo.iconLore or [[Interface\AddOns\Details_MythicPlus\Assets\Images\sandglass_icon.png]],
                iconsize = {18, 18},
                texcoord = instanceInfo and instanceInfo.iconLore and {35/512, 291/512, 49/512, 289/512} or {0, 1, 0, 1},
                iconcolor = {1, 1, 1, 0.7},
            }

            if (i == selectedRunIndex) then
                option.statusbar = [[Interface\AddOns\Details\images\bar_serenity]]
                option.statusbarcolor = {0.4, 0.4, 0, 0.5}
                option.color = "yellow"

            end
            runInfoList[#runInfoList+1] = option
        end
        return runInfoList
    end

    local runInfoDropdown = detailsFramework:CreateDropDown(readyFrame, buildRunInfoList, addon.GetSelectedRunIndex(), runSelectorWidth, 20, "selectRunInfoDropdown", "DetailsMythicPlusRunSelectorDropdown", detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE"))
    runInfoDropdown:SetPoint("right", configButton, "left", -3, 0)
    readyFrame.RunInfoDropdown = runInfoDropdown
    runInfoDropdown:UseSimpleHeader(true)

    runInfoDropdown.OnCreateOptionFrame = function(dropdown, optionFrame, optionTable)
        if (not optionFrame.label2) then
            optionFrame.label2 = optionFrame:CreateFontString(nil, "overlay", "GameFontNormal")
            optionFrame.label3 = optionFrame:CreateFontString(nil, "overlay", "GameFontNormal")
            optionFrame.label4 = optionFrame:CreateFontString(nil, "overlay", "GameFontNormal")
            optionFrame.label5 = optionFrame:CreateFontString(nil, "overlay", "GameFontNormal")

            optionFrame.label2:SetPoint("left", optionFrame, "left", 220, 0)
            optionFrame.label3:SetPoint("left", optionFrame, "left", 250, 0)
            optionFrame.label4:SetPoint("left", optionFrame, "left", 295, 0)
            optionFrame.label5:SetPoint("left", optionFrame, "left", 325, 0)

            local fontFace, fontSize, fontFlags = optionFrame.label:GetFont()
            optionFrame.label2:SetFont(fontFace, fontSize, fontFlags)
            optionFrame.label3:SetFont(fontFace, fontSize, fontFlags)
            optionFrame.label4:SetFont(fontFace, fontSize, fontFlags)
            optionFrame.label5:SetFont(fontFace, fontSize, fontFlags)
            optionFrame.label2:SetTextColor(optionFrame.label:GetTextColor())
            optionFrame.label3:SetTextColor(optionFrame.label:GetTextColor())
            optionFrame.label4:SetTextColor(optionFrame.label:GetTextColor())
            optionFrame.label5:SetTextColor(optionFrame.label:GetTextColor())
        end
    end

    runInfoDropdown.OnUpdateOptionFrame = function(dropdown, optionFrame, optionTable)
        ---@type fontstring
        local label1 = optionFrame.label
        local text = label1:GetText()

        local dungeonName, keyLevel, runTime, keyUpgradeLevels, timeString, mapId, dungeonId, onTime = text:match("(.-)@(%d+)@(%d+)@(%d+)@(.+)@(%d+)@(%d+)@(%d+)")

        label1:SetText(dungeonName)
        optionFrame.label2:SetText(keyLevel)
        optionFrame.label3:SetText(detailsFramework:IntegerToTimer(runTime))

        if (tonumber(keyUpgradeLevels) > 0) then
            optionFrame.label4:SetText("+" .. keyUpgradeLevels)
        else
            optionFrame.label4:SetText("")
        end

        optionFrame.label5:SetText(timeString)
    end

    hooksecurefunc(runInfoDropdown, "Selected", function(self, thisOption)
        local dungeonName, keyLevel, runTime, keyUpgradeLevels, timeString, mapId, dungeonId, onTime = thisOption.label:match("(.-)@(%d+)@(%d+)@(%d+)@(.+)@(%d+)@(%d+)@(%d+)")

        onTime = "1" and true or false

        dungeonId = tonumber(dungeonId)

        if (dungeonId == 370) then
            dungeonName = dungeonName:gsub("^.+%-", "")
        end

        --limit dungeon name to 22 letters
        local resizedDungeonName = dungeonName:sub(1, 22)

        self.label:SetText(resizedDungeonName .. " +" .. keyLevel .. " (" .. timeString .. ")")
    end)
    --DropDownMetaFunctions:Selected(thisOption)

    runInfoDropdown.widget:HookScript("OnMouseDown", function(self)

    end)

    local normalTexture = configButton:CreateTexture(nil, "overlay")
    normalTexture:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
    normalTexture:SetTexCoord(79/512, 113/512, 0/512, 36/512)
    normalTexture:SetDesaturated(true)

    local pushedTexture = configButton:CreateTexture(nil, "overlay")
    pushedTexture:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
    pushedTexture:SetTexCoord(114/512, 148/512, 0/512, 36/512)
    pushedTexture:SetDesaturated(true)

    local highlightTexture = configButton:CreateTexture(nil, "highlight")
    highlightTexture:SetTexture([[Interface\BUTTONS\redbutton2x]], nil, nil, "TRILINEAR")
    highlightTexture:SetTexCoord(116/256, 150/256, 0, 39/128)
    highlightTexture:SetDesaturated(true)

    configButton:SetTexture(normalTexture, highlightTexture, pushedTexture, normalTexture)
    configButton.widget:GetNormalTexture():Show()

    mythicPlusBreakdown.CreateActivityPanel(readyFrame)

    --dungeon name at the top of the frame
    local dungeonNameFontstring = readyFrame:CreateFontString("$parentTitle", "overlay", "GameFontNormalLarge")
    dungeonNameFontstring:SetPoint("top", readyFrame, "top", 0, dungeonNameY)
    DetailsFramework:SetFontSize(dungeonNameFontstring, 20)
    readyFrame.DungeonNameFontstring = dungeonNameFontstring

    local runTimeFontstring = readyFrame:CreateFontString("$parentRunTime", "overlay", "GameFontNormal")
    runTimeFontstring:SetPoint("top", dungeonNameFontstring, "bottom", 0, -8)
    DetailsFramework:SetFontSize(runTimeFontstring, 16)
    runTimeFontstring:SetText("00:00")
    readyFrame.ElapsedTimeText = runTimeFontstring

    do --create the orange circle with spikes and the level text
        local topFrame = CreateFrame("frame", "$parentTopFrame", readyFrame, "BackdropTemplate")
        topFrame:SetPoint("topleft", readyFrame, "topleft", 0, 0)
        topFrame:SetPoint("topright", readyFrame, "topright", 0, 0)
        topFrame:SetHeight(1)
        topFrame:SetFrameLevel(readyFrame:GetFrameLevel() - 1)

        --use the same textures from the original end of dungeon panel
        local spikes = topFrame:CreateTexture("$parentSkullCircle", "overlay")
        spikes:SetSize(100, 100)
        spikes:SetPoint("center", readyFrame, "top", 0, 27)
        spikes:SetAtlas("ChallengeMode-SpikeyStar")
        spikes:SetAlpha(1)
        spikes:SetIgnoreParentAlpha(true)
        readyFrame.YellowSpikeCircle = spikes

        local yellowFlash = topFrame:CreateTexture("$parentYellowFlash", "artwork")
        yellowFlash:SetSize(120, 120)
        yellowFlash:SetPoint("center", readyFrame, "top", 0, 27)
        yellowFlash:SetAtlas("BossBanner-RedFlash")
        yellowFlash:SetAlpha(0)
        yellowFlash:SetBlendMode("ADD")
        yellowFlash:SetIgnoreParentAlpha(true)
        readyFrame.YellowFlash = yellowFlash

        readyFrame.Level = topFrame:CreateFontString("$parentLevelText", "overlay", "GameFontNormalWTF2Outline")
        readyFrame.Level:SetPoint("center", readyFrame.YellowSpikeCircle, "center", 0, 0)
        readyFrame.Level:SetText("12")

        --create the animation for the yellow flash
        local flashAnimHub = detailsFramework:CreateAnimationHub(yellowFlash, function() yellowFlash:SetAlpha(0) end, function() yellowFlash:SetAlpha(0) end)
        local flashAnim1 = detailsFramework:CreateAnimation(flashAnimHub, "Alpha", 1, 0.5, 0, 1)
        local flashAnim2 = detailsFramework:CreateAnimation(flashAnimHub, "Alpha", 2, 0.5, 1, 0)

        --create the animation for the yellow spike circle
        local spikeCircleAnimHub = detailsFramework:CreateAnimationHub(spikes, function() spikes:SetAlpha(0); spikes:SetScale(1) end, function() flashAnimHub:Play(); spikes:SetSize(100, 100); spikes:SetScale(1); spikes:SetAlpha(1) end)
        local alphaAnim1 = detailsFramework:CreateAnimation(spikeCircleAnimHub, "Alpha", 1, 0.2960000038147, 0, 1)
        local scaleAnim1 = detailsFramework:CreateAnimation(spikeCircleAnimHub, "Scale", 1, 0.21599999070168, 5, 5, 1, 1, "center", 0, 0)
        readyFrame.YellowSpikeCircle.OnShowAnimation = spikeCircleAnimHub

        readyFrame.LeftFiligree = topFrame:CreateTexture("$parentLeftFiligree", "artwork")
        readyFrame.LeftFiligree:SetAtlas("BossBanner-LeftFillagree")
        readyFrame.LeftFiligree:SetSize(72, 43)
        readyFrame.LeftFiligree:SetPoint("bottom", readyFrame, "top", -50, -2)

        readyFrame.RightFiligree = topFrame:CreateTexture("$parentRightFiligree", "artwork")
        readyFrame.RightFiligree:SetAtlas("BossBanner-RightFillagree")
        readyFrame.RightFiligree:SetSize(72, 43)
        readyFrame.RightFiligree:SetPoint("bottom", readyFrame, "top", 50, -2)

        --create the bottom filligree using BossBanner-BottomFillagree atlas
        readyFrame.BottomFiligree = topFrame:CreateTexture("$parentBottomFiligree", "artwork")
        readyFrame.BottomFiligree:SetAtlas("BossBanner-BottomFillagree")
        readyFrame.BottomFiligree:SetSize(66, 28)
        readyFrame.BottomFiligree:SetPoint("bottom", readyFrame, "bottom", 0, -19)

    end

    --header frame
    local headerTable = {
        {text = "", width = 60}, --player portrait
        {text = "", width = 25}, --spec icon
        {text = L["SCOREBOARD_TITLE_PLAYER_NAME"], width = 110},
        {text = L["SCOREBOARD_TITLE_KEYSTONE"], width = 60},
        {text = L["SCOREBOARD_TITLE_SCORE"], width = 90},
        {text = L["SCOREBOARD_TITLE_LOOT"], width = 80},
        {text = L["SCOREBOARD_TITLE_DEATHS"], width = 80},
        {text = L["SCOREBOARD_TITLE_DAMAGE_TAKEN"], width = 100},
        {text = L["SCOREBOARD_TITLE_DPS"], width = 100},
        {text = L["SCOREBOARD_TITLE_HPS"], width = 100},
        {text = L["SCOREBOARD_TITLE_INTERRUPTS"], width = 100},
        {text = L["SCOREBOARD_TITLE_DISPELS"], width = 80},
        {text = L["SCOREBOARD_TITLE_CC_CASTS"], width = 80},
        --{text = "", width = 250},
    }
    local headerOptions = {
        padding = 2,
    }

    ---@type scoreboard_header
    local headerFrame = detailsFramework:CreateHeader(readyFrame, headerTable, headerOptions)
    headerFrame:SetPoint("topleft", readyFrame, "topleft", 5, headerY)
    headerFrame.lines = {}
    readyFrame.HeaderFrame = headerFrame

    readyFrame:SetWidth(headerFrame:GetWidth() + mainFramePaddingHorizontal * 2)

    do --mythic+ run data
        --clock texture and icon to show the wasted time (time out of combat)
        local outOfCombatIcon = readyFrame:CreateTexture("$parentOutOfCombatIcon", "artwork", nil, 2)
        outOfCombatIcon:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
        outOfCombatIcon:SetTexCoord(172/512, 235/512, 84/512, 147/512)
        outOfCombatIcon:SetVertexColor(detailsFramework:ParseColors("silver"))
        outOfCombatIcon:SetSize(24, 24)
        --outOfCombatIcon:SetPoint("bottomleft", headerFrame, "topleft", 20, 12)
        outOfCombatIcon:SetPoint("topleft", readyFrame, "topleft", 5, -5)
        readyFrame.OutOfCombatIcon = outOfCombatIcon

        local outOfCombatText = readyFrame:CreateFontString("$parentOutOfCombatText", "artwork", "GameFontNormal")
        detailsFramework:SetFontSize(outOfCombatText, 11)
        detailsFramework:SetFontColor(outOfCombatText, "silver")
        outOfCombatText:SetText("00:00")
        outOfCombatText:SetPoint("left", outOfCombatIcon, "right", 6, -3)
        readyFrame.OutOfCombatText = outOfCombatText

        local itemLevelIcon = readyFrame:CreateTexture("$parentItemLevelIcon", "artwork", nil, 2)
        itemLevelIcon:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
        itemLevelIcon:SetPoint("left", outOfCombatIcon, "right", 260, 0)
        do
            local left, right, top, bottom = 79, 131, 229, 271
            itemLevelIcon:SetTexCoord(left/512, right/512, top/512, bottom/512)
            itemLevelIcon:SetSize(right - left, bottom - top)
            itemLevelIcon:SetScale(0.5)
            itemLevelIcon:SetAlpha(0.834)
            itemLevelIcon:SetVertexColor(0.9, 0.9, 0.9)
        end

        local itemLevelText = readyFrame:CreateFontString("$parentItemLevelText", "artwork", "GameFontNormal")
        detailsFramework:SetFontSize(itemLevelText, 11)
        detailsFramework:SetFontColor(itemLevelText, "silver")
        itemLevelText:SetText("0.0")
        itemLevelText:SetPoint("left", itemLevelIcon, "right", 6, -3)
        readyFrame.ItemLevelText = itemLevelText

        local reloadedFrame = CreateFrame("frame", "$parentReloadedFrame", headerFrame, "BackdropTemplate")
        reloadedFrame:SetScript("OnEnter", function(self)
            GameCooltip:Preset(2)
            GameCooltip:SetOwner(self, "bottom", "top", 0, -4)
            GameCooltip:AddLine(L["SCOREBOARD_RELOADED_TOOLTIP"])
            GameCooltip:Show()
        end)
        reloadedFrame:SetScript("OnLeave", function()
            GameCooltip:Hide()
        end)
        readyFrame.ReloadedFrame = reloadedFrame

        local reloadedText = reloadedFrame:CreateFontString("$parentReloadedText", "artwork", "GameFontNormal")
        detailsFramework:SetFontSize(reloadedText, 11)
        detailsFramework:SetFontColor(reloadedText, "orange")
        reloadedText:SetText(L["SCOREBOARD_RELOADED_WARNING"])

        local reloadedIcon = reloadedFrame:CreateTexture("$parentReloadedIcon", "artwork", nil, 2)
        reloadedIcon:SetAtlas("Professions_Icon_Warning")
        reloadedIcon:SetSize(20, 15)

        reloadedText:SetPoint("bottomright", headerFrame, "bottomright", -4, 25)
        reloadedIcon:SetPoint("bottomright", reloadedText, "bottomleft", -2, 0)
        reloadedFrame:SetPoint("bottomright", reloadedText, "bottomright", 5, -5)
        reloadedFrame:SetPoint("topleft", reloadedIcon, "topleft", -5, 5)

        reloadedFrame.ReloadedText = reloadedText
        reloadedFrame.ReloadedIcon = reloadedIcon
    end

    --create 6 rows to show data of the player, it only require 5 lines, the last one can be used on exception cases.
    for i = 1, lineAmount do
        mythicPlusBreakdown.CreateLineForBigBreakdownFrame(readyFrame, headerFrame, i)
    end

    return readyFrame
end

--this function get the overall mythic+ segment created after a mythic+ run has finished
--then it fill the lines with data from the overall segment
---@param mainFrame scoreboard_mainframe
---@param runData runinfo
function mythicPlusBreakdown.RefreshBigBreakdownFrame(mainFrame, runData)
    local headerFrame = mainFrame.HeaderFrame
    local lines = headerFrame.lines

    mainFrame.RunInfoDropdown:Select(addon.GetSelectedRunIndex(), nil, nil, false)
    mythicPlusBreakdown.SetFontSettings()

    if (runData.reloaded) then
        mainFrame.ReloadedFrame:Show()
    else
        mainFrame.ReloadedFrame:Hide()
    end

    if (#addon.GetSavedRuns() > 1) then
        mainFrame.RunInfoDropdown:Show()
    else
        mainFrame.RunInfoDropdown:Hide()
    end

    local combatTime = runData.timeInCombat

    ---@type scoreboard_playerdata[]
    local data = {}
    ---@type timeline_event[]
    local events = {}

    local runPlayerData = runData.combatData.groupMembers

    do --code for filling the 5 player lines
        for playerName, playerInfo in pairs(runPlayerData) do
            local unitId
            for i = 1, #Details.PartyUnits do
                if (Details:GetFullName(Details.PartyUnits[i]) == playerName) then
                    unitId = Details.PartyUnits[i]
                end
            end
            unitId = unitId or playerName

            local score = playerInfo.score or 0
            local ratingColor = C_ChallengeMode.GetDungeonScoreRarityColor(score)
            if (not ratingColor) then
                ratingColor = _G["HIGHLIGHT_FONT_COLOR"]
            end

            ---@type scoreboard_playerdata
            local thisPlayerData = {
                name = playerName,
                unitName = playerName,
                class = playerInfo.class,
                spec = playerInfo.spec,
                role = playerInfo.role or UnitGroupRolesAssigned(unitId),
                score = score,
                unitId = unitId,
                previousScore = playerInfo.scorePrevious or score or 0,
                scoreColor = ratingColor,
                damageTaken = playerInfo.totalDamageTaken or 0,
                damageTakenFromSpells = playerInfo.damageTakenFromSpells,
                dps = playerInfo.totalDamage / combatTime,
                hps = playerInfo.totalHeal / combatTime,
                activityTimeDamage = playerInfo.activityTimeDamage or combatTime,
                activityTimeHeal = playerInfo.activityTimeHeal or combatTime,
                interrupts = playerInfo.totalInterrupts or 0,
                interruptCastOverlapDone = playerInfo.interruptCastOverlapDone or 0,
                interruptCasts = playerInfo.totalInterruptsCasts or 0,
                dispels = playerInfo.totalDispels or 0,
                ccCasts = playerInfo.totalCrowdControlCasts,
                ccSpellsUsed = playerInfo.crowdControlSpells,
                deaths = playerInfo.totalDeaths,
                combatUid = runData.combatId,
                loot = playerInfo.loot,
                keystoneLevel = 0,
                keystoneIcon = keystoneDefaultTexture,
            }

            if (thisPlayerData.role == "NONE") then
                thisPlayerData.role = "DAMAGER"
            end

            local playerKeystoneInfo = openRaidLib.GetKeystoneInfo(unitId)
            if (playerKeystoneInfo) then
                thisPlayerData.keystoneLevel = playerKeystoneInfo.level or thisPlayerData.keystoneLevel --default zero

                ---@type details_instanceinfo
                local instanceInfo = Details:GetInstanceInfo(playerKeystoneInfo.mapID)

                if (instanceInfo) then
                    thisPlayerData.keystoneIcon = instanceInfo.iconLore
                end
            end

            --to render the event for deaths, it is required 'playerInfo' into the playerInfo.deathEvents[x].arguments.'playerData' field
            --as the scoreboard cannot change the database (in this case assigning thisPlayerData to playerInfo.deathEvents[x].arguments.'playerData')
            --we need to copy the deathEvents table and assign the playerData to each event
            local deathEventsTableCopy = detailsFramework.table.copy({}, playerInfo.deathEvents)
            for i = 1, #deathEventsTableCopy do
                local thisDeathEventCopied = deathEventsTableCopy[i]
                thisDeathEventCopied.arguments.playerData = thisPlayerData
                thisDeathEventCopied.arguments.index = i
            end
            detailsFramework.table.append(events, deathEventsTableCopy)

            data[#data+1] = thisPlayerData
        end

        table.sort(data, function(t1, t2) return t1.role > t2.role end)

        for i = 1, lineAmount do
            lines[i]:Hide()
        end

        local topScores = {
            [8] = {key = "damageTaken", line = nil, best = nil, highest = false},
            [9] = {key = "dps", line = nil, best = nil, highest = true},
            [10] = {key = "hps", line = nil, best = nil, highest = true},
            [11] = {key = "interrupts", line = nil, best = nil, highest = true},
            [12] = {key = "dispels", line = nil, best = nil, highest = true},
            [13] = {key = "ccCasts", line = nil, best = nil, highest = true},
        }

        for i = 1, lineAmount do
            local scoreboardLine = lines[i]
            local frames = scoreboardLine:GetFramesFromHeaderAlignment()
            ---@type scoreboard_playerdata
            local playerData = data[i]

            --(re)set the line contents
            for j = 1, #frames do
                local frame = frames[j]

                if (frame:GetObjectType() == "FontString" or frame:GetObjectType() == "Button") then
                    frame:SetText("")
                elseif (frame:GetObjectType() == "Texture") then
                    frame:SetTexture(nil)
                end

                if (frame.SetPlayerData) then
                    frame:SetPlayerData(playerData)
                end
            end

            if (playerData) then
                scoreboardLine:Show()
                local playerPortrait = frames[1]
                local specIcon = frames[2]

                SetPortraitTexture(playerPortrait.Portrait, playerData.unitId)
                local portraitTexture = playerPortrait.Portrait:GetTexture()
                playerPortrait.Portrait:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
                if (not portraitTexture) then
                    local class = playerData.class
                    playerPortrait.Portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
                    playerPortrait.Portrait:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class]))
                end

                local role = playerData.role
                if (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
                    playerPortrait.RoleIcon:SetAtlas(GetMicroIconForRole(role), TextureKitConstants.IgnoreAtlasSize)
                    playerPortrait.RoleIcon:Show()
                else
                    playerPortrait.RoleIcon:Hide()
                end

                specIcon:SetTexture(select(4, GetSpecializationInfoByID(playerData.spec)))

                for _, value in pairs(topScores) do
                    if (value.line == nil or (value.highest and value.best < playerData[value.key]) or (not value.highest and value.best > playerData[value.key])) then
                        value.best = playerData[value.key]
                        value.line = i
                    end
                end

                --safe run for feature in test
                local okay, errorText = pcall(function()
                    --keystone texture and level
                    local keystoneTexture = scoreboardLine.KeystoneDungeonIcon
                    local keystoneLevel = scoreboardLine.KeystoneDungeonLevel
                    local keystoneLevelBackground = scoreboardLine.KeystoneDungeonLevelBackground

                    keystoneTexture:SetTexture(playerData.keystoneIcon)
                    if (playerData.keystoneIcon ~= keystoneDefaultTexture) then
                        keystoneTexture:SetTexCoord(36/512, 375/512, 50/512, 290/512)
                        keystoneTexture:SetAlpha(1)
                        keystoneTexture:SetDesaturated(false)
                        keystoneTexture:SetTexture(playerData.keystoneIcon)
                        keystoneLevel:SetAlpha(1)
                        keystoneLevelBackground:SetAlpha(1)
                    else
                        keystoneTexture:SetTexCoord(0, 1, 0, 1)
                        keystoneTexture:SetAlpha(noKeystoneAlpha)
                        keystoneTexture:SetDesaturated(true)
                        keystoneTexture:SetTexture(keystoneDefaultTexture)
                        keystoneLevel:SetAlpha(noKeystoneAlpha)
                        keystoneLevelBackground:SetAlpha(noKeystoneAlpha)
                    end

                    keystoneLevel:SetText(playerData.keystoneLevel)

                    --the scoreboard open after the local player open the loot cache.
                    --as consequence, the addon doesn't know if other players has opened as well.
                    --if a player loots the first keystone, the scoreboard won't know about it, so schedule updates to verify that.

                    local didPrintLog = false
                    ---@param thisPlayerData scoreboard_playerdata
                    local looperCallback = function(thisPlayerData)
                        local playerName = thisPlayerData.name
                        if (UnitExists(playerName)) then
                            local unitKeystoneInfo = openRaidLib.GetKeystoneInfo(playerName)
                            if (unitKeystoneInfo) then
                                keystoneTexture:SetTexCoord(36/512, 375/512, 50/512, 290/512)
                                keystoneTexture:SetAlpha(1)
                                keystoneTexture:SetDesaturated(false)
                                keystoneTexture:SetTexture(playerData.keystoneIcon)
                                keystoneLevel:SetAlpha(1)
                                keystoneLevelBackground:SetAlpha(1)
                                keystoneLevel:SetText(playerData.keystoneLevel)

                                --log (debug)
                                if (not didPrintLog) then
                                    private.log("Keystone Update Okay, Name:", playerName or "ERROR", "keystoneLevel:", playerData.keystoneLevel or "ERROR", "keystoneIcon:", playerData.keystoneIcon or "ERROR")
                                    didPrintLog = true
                                end
                            end
                        end
                    end

                    local loopAmount = 30
                    local looperEndCallback = function()end
                    local checkPointCallback = function() return mainFrame:IsShown() end --if the scoreboard is hidden, interrupt the loop
                    local keystoneUpdateSchedule = detailsFramework.Schedules.NewLooper(1, looperCallback, loopAmount, looperEndCallback, checkPointCallback, playerData)
                    --add to the timer list to be stopped when a scoreboard update is triggered
                    addon.temporaryTimers[#addon.temporaryTimers + 1] = keystoneUpdateSchedule
                end)

                if (not okay) then
                    print("|cFFFFFF00Details Mythic+ Key Stone Update ERROR:|r ", errorText)
                end
            end
        end

        for frameId, value in pairs(topScores) do
            if (value.best > 0) then
                local frames = lines[value.line] and lines[value.line]:GetFramesFromHeaderAlignment() or {}
                if (frames[frameId] and frames[frameId].MarkTop) then
                    frames[frameId]:MarkTop()
                end
            end
        end
    end


    local runTime = runData.completionInfo.time
    if (runTime) then --runTime can be nil if the run is not completed
        runTime = runData.completionInfo.time / 1000
        local notInCombat = runTime - combatTime

        if (runData.endTime) then
            events[#events+1] = {
                type = addon.Enum.ScoreboardEventType.KeyFinished,
                timestamp = runData.endTime,
                arguments = {
                    onTime = runData.completionInfo.onTime,
                    keystoneLevelsUpgrade = runData.completionInfo.keystoneUpgradeLevels,
                },
            }
        end

        table.sort(events, function(t1, t2) return t1.timestamp < t2.timestamp end)
        local flooredRunTime = math.floor(runTime)

        mainFrame.ActivityFrame:SetActivity(events, runData)

        local timeLimitToCompletion = runData.timeLimit

        --mainFrame.ItemLevelText:SetText(runData.completionInfo.itemLevel or 0.0)
        --get the item level of all player in the run and sum all of them, and then divide by the total of players found, item level is stored here: runInfo.combatData.groupMembers[unitName].ilevel
        local totalItemLevel = 0
        local totalPlayers = 0
        for playerName, playerInfo in pairs(runData.combatData.groupMembers) do
            if (playerInfo.ilevel) then
                totalItemLevel = totalItemLevel + playerInfo.ilevel
                totalPlayers = totalPlayers + 1
            end
        end
        if (totalPlayers > 0) then
            mainFrame.ItemLevelText:SetText(math.floor(totalItemLevel / totalPlayers))
        else
            mainFrame.ItemLevelText:SetText("0.0")
        end

        if (detailsFramework.Math.IsNearlyEqual(timeLimitToCompletion, flooredRunTime, 2)) then
            mainFrame.ElapsedTimeText:SetText(detailsFramework:IntegerToTimer(flooredRunTime) .. WrapTextInColorCode("." .. math.floor((runTime - flooredRunTime) * 1000), "FFBA8E23"))
        else
            mainFrame.ElapsedTimeText:SetText(detailsFramework:IntegerToTimer(flooredRunTime))
        end

        mainFrame.OutOfCombatText:SetText(L["SCOREBOARD_NOT_IN_COMBAT_LABEL"] .. ": " .. detailsFramework:IntegerToTimer(notInCombat))
        mainFrame.Level:SetText(runData.completionInfo.level) --the level in the big circle at the top
        if (runData.completionInfo.onTime) then
            mainFrame.DungeonNameFontstring:SetText(runData.dungeonName .. " +" .. runData.completionInfo.keystoneUpgradeLevels)
        else
            mainFrame.DungeonNameFontstring:SetText(runData.dungeonName)
        end
    else
        mainFrame.ElapsedTimeText:SetText("00:00")
        mainFrame.OutOfCombatText:SetText("00:00")
        mainFrame.Level:SetText("0")
        mainFrame.DungeonNameFontstring:SetText(L["SCOREBOARD_UNKNOWN_DUNGEON_LABEL"])
    end

    ---@type details_instanceinfo
    local instanceInfo = runData and Details:GetInstanceInfo(runData.mapId)
    if (instanceInfo) then
        mainFrame.DungeonBackdropTexture:SetTexture(instanceInfo.iconLore)
    else
        mainFrame.DungeonBackdropTexture:SetTexture(runData.dungeonBackgroundTexture)
    end

    mainFrame.DungeonBackdropTexture:SetDesaturation(backdropDungeonTextureDesaturation)
    mainFrame.DungeonBackdropTexture:SetTexCoord(35/512, 291/512, 49/512, 289/512)

    return true
end

local function OpenLineBreakdown(self, mainAttribute, subAttribute)
    local playerData = self.MyObject:GetPlayerData()
    if (not playerData or not playerData.name or not playerData.combatUid) then
        return
    end

    local combat = Details:GetCombatByUID(playerData.combatUid)
    if (not combat) then
        return
    end

    Details:OpenSpecificBreakdownWindow(combat, playerData.name, mainAttribute, subAttribute)
end

local function DoPlayerTooltip(playerData, owner, renderContent, rightHeaderColumn, r, g, b)
    GameCooltip:Preset(2)

    local classColor = RAID_CLASS_COLORS[playerData.class]
    GameCooltip:AddLine(addon.PreparePlayerName(playerData.name), rightHeaderColumn, nil, classColor.r, classColor.g, classColor.b, 1, r, g, b, 1)
    GameCooltip:AddLine("")
    renderContent()
    GameCooltip:SetOwner(owner)
    GameCooltip:SetOption("LeftPadding", -3)
    GameCooltip:SetOption("RightPadding", 2)
    GameCooltip:SetOption("LinePadding", -2)
    GameCooltip:SetOption("LineYOffset", 0)
    GameCooltip:SetOption("TextSize", Details.tooltip.fontsize)
    GameCooltip:SetOption("TextFont",  Details.tooltip.fontface)
    GameCooltip:SetOption("FixedWidth", false)
    GameCooltip:Show()
end

local spellNumberListCooltip = function(self, playerData, actor, rightColumnDescription)
    if (not actor) then
        return
    end

    ---@class spell_id_amount_table : table
    ---@field spellId number
    ---@field amount number
    ---
    ---@type spell_id_amount_table[]
    local spellIdAmount = {}

    for spellId, spellTable in pairs(actor:GetSpellList()) do
        if (spellTable.total > 0) then
            spellIdAmount[#spellIdAmount +1] = {
                spellId = spellId,
                amount = spellTable.total,
            }
        end
    end

    table.sort(spellIdAmount, function(t1, t2) return t1.amount > t2.amount end)

    DoPlayerTooltip(playerData, self, function ()
        for i = 1, math.min(#spellIdAmount, 7) do
            local spellId = spellIdAmount[i].spellId
            local amount = spellIdAmount[i].amount

            local spellName, _, spellIcon = Details.GetSpellInfo(spellId)
            if (spellName and spellIcon) then
                GameCooltip:AddLine(spellName, Details:Format(amount))
                GameCooltip:AddIcon(spellIcon, 1, 1, 18, 18, 0.1, 0.9, 0.1, 0.9)
                Details:AddTooltipBackgroundStatusbar(nil, 100, false, {0.1, 0.1, 0.1, 0.2})
            end
        end

        if (Details:GetCombatByUID(playerData.combatUid)) then
            GameCooltip:AddLine("")
            GameCooltip:AddLine(L["SCOREBOARD_TOOLTIP_OPEN_BREAKDOWN"], nil, nil, 1, 1, 1, 1, nil, nil, nil, nil)
        end
    end, rightColumnDescription)
end

---@param self scoreboard_button
local showCrowdControlTooltip = function(self)
    local playerData = self:GetPlayerData()
    if (playerData.ccCasts == 0) then
        return
    end

    DoPlayerTooltip(playerData, self.widget, function ()
        for spellName, totalUses in pairs(playerData.ccSpellsUsed) do
            local ccText = totalUses
            if (addon.profile.show_cc_cast_tooltip_percentage) then
                ccText =  ccText .. " (" .. math.floor(totalUses / playerData.ccCasts * 100) .. "%)"
            end
            GameCooltip:AddLine(spellName, ccText)
            Details:AddTooltipBackgroundStatusbar(nil, 100, false, {0.1, 0.1, 0.1, 0.2})

            local spellInfo = C_Spell.GetSpellInfo(spellName)
            -- details alpha (13509) feature detection
            if (not spellInfo and openRaidLib.GetCCSpellIdBySpellName) then
                local spellId = openRaidLib.GetCCSpellIdBySpellName(spellName)
                if (spellId) then
                    spellInfo = C_Spell.GetSpellInfo(spellId)
                end
            end
            -- set icon width to 0.00001 as workaround to ensure row height is consistent
            GameCooltip:AddIcon(spellInfo and spellInfo.iconID or 134400, 1, 1, spellInfo and 18 or 0.00001, 18, 0.1, 0.9, 0.1, 0.9)
        end
    end, L["SCOREBOARD_TOOLTIP_CC_CAST_HEADER"])
end

---@param self df_blizzbutton
---@param button scoreboard_button
local function OnEnterLineBreakdownButton(self, button)
    local text = button.button.text
    text.originalColor = {text:GetTextColor()}
    detailsFramework:SetFontSize(text, addon.profile.font.row_size)
    detailsFramework:SetFontColor(text, addon.profile.font.hover_color)
    detailsFramework:SetFontOutline(text, addon.profile.font.hover_outline)

    if (button.OnMouseEnter and addon.profile.show_column_summary_in_tooltip and button:HasPlayerData()) then
        button.OnMouseEnter(self, button)
    end
end

local function OnLeaveLineBreakdownButton(self)
    local text = self.MyObject.button.text
    detailsFramework:SetFontSize(text, addon.profile.font.row_size)
    detailsFramework:SetFontOutline(text, addon.profile.font.regular_outline)
    detailsFramework:SetFontColor(text, text.originalColor)
    GameTooltip:Hide()
    GameCooltip:Hide()
end

function mythicPlusBreakdown.SetFontSettings()
    for i = 1, #mythicPlusBreakdown.lines do
        local line = mythicPlusBreakdown.lines[i]

        ---@type fontstring[]
        local regions = {line:GetRegions()}
        for j = 1, #regions do
            local region = regions[j]
            if (region:GetObjectType() == "FontString") then
                detailsFramework:SetFontSize(region, addon.profile.font.row_size)
                detailsFramework:SetFontColor(region, addon.profile.font.regular_color)
                detailsFramework:SetFontOutline(region, addon.profile.font.regular_outline)
            end
        end

        --include framework buttons
        ---@type df_blizzbutton[]
        local children = {line:GetChildren()}
        for j = 1, #children do
            local blizzButton = children[j]
            if (blizzButton:GetObjectType() == "Button" and blizzButton.MyObject) then --.MyObject is a button from the framework
                local buttonObject = blizzButton.MyObject
                buttonObject:SetFontSize(addon.profile.font.row_size)
                buttonObject:SetTextColor(addon.profile.font.regular_color)
                detailsFramework:SetFontOutline(buttonObject.button.text, addon.profile.font.regular_outline)
            end
        end
    end
end

local function CreateBreakdownButton(line, onClick, onSetPlayerData, onMouseEnter)
    ---@type scoreboard_button
    local button = detailsFramework:CreateButton(line, onClick, 80, 22, nil, nil, nil, nil, nil, nil, nil, nil, {font = "GameFontNormal", size = 12})

    button:SetHook("OnEnter", OnEnterLineBreakdownButton)
    button:SetHook("OnLeave", OnLeaveLineBreakdownButton)
    button.button.text:ClearAllPoints()
    button.button.text:SetPoint("left", button.button, "left")
    button.button.text.originalColor = {button.button.text:GetTextColor()}

    button.OnMouseEnter = onMouseEnter

    function button.SetPlayerData(self, playerData)
        self.PlayerData = playerData
        if (playerData ~= nil) then
            onSetPlayerData(self, playerData)
        end
    end

    function button.HasPlayerData(self)
        return self.PlayerData ~= nil
    end

    function button.GetPlayerData(self)
        return self.PlayerData
    end

    function button.GetActor(self, actorMainAttribute)
        local playerData = self:GetPlayerData()
        if (not playerData) then
            return
        end

        local combat = Details:GetCombatByUID(playerData.combatUid)
        if (not combat) then
            return
        end

        return combat:GetActor(actorMainAttribute, playerData.name), combat
    end

    function button.MarkTop(self)
        detailsFramework:SetFontSize(self.button.text, addon.profile.font.row_size)
        detailsFramework:SetFontColor(self.button.text, addon.profile.font.standout_color)
        detailsFramework:SetFontOutline(self.button.text, addon.profile.font.standout_outline)
    end

    return button
end

local function CreateBreakdownLabel(line, onSetPlayerData)
    local label = line:CreateFontString(nil, "overlay", "GameFontNormal")

    function label.SetPlayerData(self, playerData)
        self.PlayerData = playerData
        if (onSetPlayerData) then
            detailsFramework:SetFontSize(self, addon.profile.font.row_size)
            detailsFramework:SetFontColor(self, addon.profile.font.regular_color)
            detailsFramework:SetFontOutline(self, addon.profile.font.regular_outline)
            onSetPlayerData(self, playerData)
        end
    end
    function label.GetPlayerData(self)
        return self.PlayerData
    end
    function label.MarkTop(self)
        detailsFramework:SetFontSize(self, addon.profile.font.row_size)
        detailsFramework:SetFontColor(self, addon.profile.font.standout_color)
        detailsFramework:SetFontOutline(self, addon.profile.font.standout_outline)
    end

    return label
end

---@param scoreboardLine scoreboard_line
local CreateLootSquare = function(scoreboardLine)
    ---@type details_lootsquare
    local lootSquare = CreateFrame("frame", "$parentLootSquare", scoreboardLine)
    lootSquare:SetSize(46, 46)
    lootSquare:SetFrameLevel(scoreboardLine:GetFrameLevel()+10)
    lootSquare:Hide()

    function lootSquare.SetPlayerData(self, playerData)
        self:Hide()
        if (not playerData.loot or playerData.loot == "") then
            return
        end

        local item = Item:CreateFromItemLink(playerData.loot)
        item:ContinueOnItemLoad(function()
            local r, g, b = C_Item.GetItemQualityColor(item:GetItemQuality())
            self.itemLink = playerData.loot
            self.LootIcon:SetTexture(item:GetItemIcon())
            self.LootIconBorder:SetVertexColor(r, g, b, 1)
            self.LootItemLevel:SetText(item:GetCurrentItemLevel())

            --update size
            self.LootIcon:SetSize(32, 32)
            self.LootIconBorder:SetSize(32, 32)
            self:Show()
        end)
    end

    lootSquare:SetScript("OnEnter", function(self)
        if (self.itemLink) then
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()

            self:SetScript("OnUpdate", function()
                if (IsShiftKeyDown()) then
                    GameTooltip_ShowCompareItem()
                else
                    GameTooltip_HideShoppingTooltips(GameTooltip)
                end
            end)
        end
    end)

    lootSquare:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", nil)
    end)

    local lootIcon = lootSquare:CreateTexture("$parentLootIcon", "artwork")
    lootIcon:SetSize(46, 46)
    lootIcon:SetPoint("center", lootSquare, "center", 0, 0)
    lootIcon:SetTexture([[Interface\ICONS\INV_Misc_QuestionMark]])
    lootSquare.LootIcon = lootIcon

    local lootIconBorder = lootSquare:CreateTexture("$parentLootSquareBorder", "overlay")
    lootIconBorder:SetTexture([[Interface\COMMON\WhiteIconFrame]])
    lootIconBorder:SetTexCoord(0, 1, 0, 1)
    lootIconBorder:SetSize(46, 46)
    lootIconBorder:SetPoint("center", lootIcon, "center", 0, 0)
    lootSquare.LootIconBorder = lootIconBorder

    local lootItemLevel = lootSquare:CreateFontString("$parentLootItemLevel", "overlay", "GameFontNormal")
    lootItemLevel:SetPoint("bottom", lootSquare, "bottom", 0, 0)
    lootItemLevel:SetTextColor(1, 1, 1)
    detailsFramework:SetFontSize(lootItemLevel, 11)
    lootSquare.LootItemLevel = lootItemLevel

    local lootItemLevelBackgroundTexture = lootSquare:CreateTexture("$parentItemLevelBackgroundTexture", "artwork")
    lootItemLevelBackgroundTexture:SetTexture([[Interface\Cooldown\LoC-ShadowBG]])
    lootItemLevelBackgroundTexture:SetPoint("bottomleft", lootSquare, "bottomleft", -7, 1)
    lootItemLevelBackgroundTexture:SetPoint("bottomright", lootSquare, "bottomright", 7, -11)
    lootItemLevelBackgroundTexture:SetHeight(10)
    lootSquare.LootItemLevelBackgroundTexture = lootItemLevelBackgroundTexture

    return lootSquare
end

--search tags: ~create ~line
function mythicPlusBreakdown.CreateLineForBigBreakdownFrame(mainFrame, headerFrame, index)
    ---@type scoreboard_line
    local line = CreateFrame("button", "$parentLine" .. index, mainFrame, "BackdropTemplate")
    detailsFramework:Mixin(line, detailsFramework.HeaderFunctions)
    mythicPlusBreakdown.lines[#mythicPlusBreakdown.lines+1] = line

    local yPosition = -((index-1)*(lineHeight+1)) - 1
    line:SetPoint("topleft", headerFrame, "bottomleft", lineOffset, yPosition)
    line:SetPoint("topright", headerFrame, "bottomright", -lineOffset - 1, yPosition)
    line:SetHeight(lineHeight)

    line:SetBackdrop(lineBackdrop)
    if (index % 2 == 0) then
        line:SetBackdropColor(unpack(lineColor1))
    else
        line:SetBackdropColor(unpack(lineColor2))
    end

    --player portrait
    local playerPortrait = Details:CreatePlayerPortrait(line, "$parentPortrait")
    ---@cast playerPortrait playerportrait
    playerPortrait.Portrait:SetSize(lineHeight-2, lineHeight-2)
    playerPortrait:SetSize(lineHeight-2, lineHeight-2)
    playerPortrait.RoleIcon:SetSize(18, 18)
    playerPortrait.RoleIcon:ClearAllPoints()
    playerPortrait.RoleIcon:SetPoint("bottomleft", playerPortrait.Portrait, "bottomright", -9, -2)

    --texture to show the specialization of the player
    local specIcon = line:CreateTexture(nil, "overlay")
    specIcon:SetSize(20, 20)

    local playerName = CreateBreakdownLabel(line, function(self, playerData)
        local classColor = RAID_CLASS_COLORS[playerData.class]
        self:SetTextColor(classColor.r, classColor.g, classColor.b)
        self:SetText(addon.PreparePlayerName(playerData.name))
    end)

    local keystoneDungeonIconTexture = line:CreateTexture("$parentDungeonIconTexture", "artwork")
    keystoneDungeonIconTexture:SetTexCoord(36/512, 375/512, 50/512, 290/512)
    keystoneDungeonIconTexture:SetSize(keystoneTextureSize, keystoneTextureSize)
    keystoneDungeonIconTexture:SetAlpha(0.932)
    detailsFramework:SetMask(keystoneDungeonIconTexture, [[Interface\FrameGeneral\UIFrameIconMask]])
    line.KeystoneDungeonIcon = keystoneDungeonIconTexture

    local keystoneDungeonBorderTexture = line:CreateTexture("$parentDungeonIconBorderTexture", "border")
    keystoneDungeonBorderTexture:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
    keystoneDungeonBorderTexture:SetTexCoord(441/512, 511/512, 81/512, 151/512)
    keystoneDungeonBorderTexture:SetDrawLayer("border", 0)
    keystoneDungeonBorderTexture:SetSize(keystoneTextureSize+2, keystoneTextureSize+2)
    keystoneDungeonBorderTexture:SetPoint("center", keystoneDungeonIconTexture, "center", 0, 0)
    keystoneDungeonBorderTexture:SetAlpha(1)
    keystoneDungeonBorderTexture:SetVertexColor(0, 0, 0, 0.3)
    line.DungeonBorderTexture = keystoneDungeonBorderTexture

    local keystoneDungeonLevelFontstring = line:CreateFontString("$parentDungeonLevelFontstring", "overlay", "GameFontNormal")
    keystoneDungeonLevelFontstring:SetPoint("bottom", keystoneDungeonIconTexture, "bottom", 0, -2)
    detailsFramework:SetFontSize(keystoneDungeonLevelFontstring, 15)
    line.KeystoneDungeonLevel = keystoneDungeonLevelFontstring

	local keystoneDungeonLevelBackgroundTexture = line:CreateTexture("$parentDungeonLevelBackgroundTexture", "artwork", nil, 6)
	keystoneDungeonLevelBackgroundTexture:SetTexture([[Interface\Cooldown\LoC-ShadowBG]])
	keystoneDungeonLevelBackgroundTexture:SetPoint("bottomleft", line.KeystoneDungeonIcon, "bottomleft", -10, -2)
	keystoneDungeonLevelBackgroundTexture:SetPoint("bottomright", line.KeystoneDungeonIcon, "bottomright", 10, -15)
	keystoneDungeonLevelBackgroundTexture:SetHeight(12)
	line.KeystoneDungeonLevelBackground = keystoneDungeonLevelBackgroundTexture

    local playerScore = CreateBreakdownLabel(line, function(self, playerData)
        ---@cast playerData scoreboard_playerdata
        self:SetText(playerData.score)
        local gainedScore = playerData.score - playerData.previousScore
        local text = ""
        if (gainedScore >= 1) then
            local textToFormat = "%d (+%d)"
            text = textToFormat:format(playerData.score, gainedScore)
        else
            local textToFormat = "%d"
            text = textToFormat:format(playerData.score)
        end
        self:SetText(text)
        self:SetTextColor(playerData.scoreColor.r, playerData.scoreColor.g, playerData.scoreColor.b)
    end)

    local lootAnchor = CreateLootSquare(line)

    local playerDeaths = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(playerData.deaths)
    end)

    local playerDamageTaken = CreateBreakdownButton(
        line,
        -- onclick
        ---@param self scoreboard_button
        function (self)
            OpenLineBreakdown(self, DETAILS_ATTRIBUTE_DAMAGE, DETAILS_SUBATTRIBUTE_DAMAGETAKEN)
        end,
        -- onSetPlayerData
        ---@param self scoreboard_button
        ---@param playerData scoreboard_playerdata
        function(self, playerData)
            self:SetText(Details:Format(math.floor(playerData.damageTaken)))
        end,
        -- onMouseEnter
        ---@param self frame
        ---@param button scoreboard_button
        function (self, button)
            local playerData = button:GetPlayerData()
            DoPlayerTooltip(playerData, self, function ()
                ---@class spell_hit_player : table
                ---@field spellId number
                ---@field amount number
                ---@field damagerName string
                ---
                ---@type spell_hit_player[]
                local spellsThatHitThisPlayer = playerData.damageTakenFromSpells

                for _, spellData in pairs(spellsThatHitThisPlayer) do
                    local spellId = spellData.spellId
                    local amount = spellData.amount
                    local sourceName = spellData.damagerName

                    local spellName, _, spellIcon = Details.GetSpellInfo(spellId)
                    if (spellName and spellIcon) then
                        local spellAmount = Details:Format(amount)
                        GameCooltip:AddLine(spellName .. " (" .. sourceName .. ")", spellAmount)
                        GameCooltip:AddIcon(spellIcon, 1, 1, 18, 18, 0.1, 0.9, 0.1, 0.9)
                        Details:AddTooltipBackgroundStatusbar(nil, 100, false, {0.1, 0.1, 0.1, 0.2})
                    end
                end

                if (Details:GetCombatByUID(playerData.combatUid)) then
                    GameCooltip:AddLine("")
                    GameCooltip:AddLine(L["SCOREBOARD_TOOLTIP_OPEN_BREAKDOWN"], nil, nil, 1, 1, 1, 1, nil, nil, nil, nil)
                end
            end, L["SCOREBOARD_TOOLTIP_DAMAGE_TAKEN_HEADER"])
        end
    )

    local playerDps = CreateBreakdownButton(
        line,
        -- onclick
        function (self)
            OpenLineBreakdown(self, DETAILS_ATTRIBUTE_DAMAGE, DETAILS_SUBATTRIBUTE_DPS)
        end,
        -- onSetPlayerData
        function(self, playerData)
            ---@cast playerData scoreboard_playerdata
            self:SetText(Details:Format(math.floor(playerData.dps)))
        end,
        function (self, button)
            spellNumberListCooltip(self, button:GetPlayerData(), button:GetActor(DETAILS_ATTRIBUTE_DAMAGE), L["SCOREBOARD_TOOLTIP_DAMAGE_DONE_HEADER"])
        end
    )

    local playerHps = CreateBreakdownButton(
        line,
        -- onclick
        function (self)
            OpenLineBreakdown(self, DETAILS_ATTRIBUTE_HEAL, DETAILS_SUBATTRIBUTE_HPS)
        end,
        -- onSetPlayerData
        function(self, playerData)
            ---@cast playerData scoreboard_playerdata
            self:SetText(Details:Format(math.floor(playerData.hps)))
        end,
        -- onMouseEnter
        function (self, button)
            spellNumberListCooltip(self, button:GetPlayerData(), button:GetActor(DETAILS_ATTRIBUTE_HEAL), L["SCOREBOARD_TOOLTIP_HEALING_DONE_HEADER"])
        end
    )

    local playerInterrupts = CreateBreakdownButton(
        line,
        -- onclick
        function (self) end,
        -- onSetPlayerData
        function(self, playerData)
            ---@cast playerData scoreboard_playerdata
            self:SetText(math.floor(playerData.interrupts))
            self.InterruptCasts:SetText("/ " .. math.floor(playerData.interruptCasts))
        end,
        -- onMouseEnter
        function (self, button)
            local playerData = button:GetPlayerData()
            local interrupts = math.floor(playerData.interrupts)
            local overlaps = playerData.interruptCastOverlapDone or 0
            local casts = math.floor(playerData.interruptCasts)
            if (casts == 0) then
                return
            end

            local missed = casts - overlaps - interrupts
            local interruptText = interrupts
            local overlapText = overlaps
            local missedText = missed
            if (addon.profile.show_interrupt_tooltip_percentage) then
                if (interrupts > 0) then
                    interruptText = interruptText .. " (" .. (math.floor((interrupts / casts) * 100)) .. "%)"
                end
                if (overlaps > 0) then
                    overlapText = overlapText .. " (" .. (math.floor((overlaps / casts) * 100)) .. "%)"
                end
                if (missed > 0) then
                    missedText = missedText .. " (" .. (math.floor((missed / casts) * 100)) .. "%)"
                end
            end

            local ttLines = {
                {L["SCOREBOARD_TOOLTIP_INTERRUPT_SUCCESS_LABEL"], interruptText},
                {L["SCOREBOARD_TOOLTIP_INTERRUPT_OVERLAP_LABEL"], overlapText},
                {L["SCOREBOARD_TOOLTIP_INTERRUPT_MISSED_LABEL"], missedText},
            }

            DoPlayerTooltip(playerData, self, function ()
                for _, ttLine in pairs(ttLines) do
                    GameCooltip:AddLine(ttLine[1], ttLine[2])
                    -- set icon width to 0.00001 as workaround to ensure row height is consistent
                    GameCooltip:AddIcon(134400, 1, 1, 0.00001, 18, 0.1, 0.9, 0.1, 0.9)
                    Details:AddTooltipBackgroundStatusbar(nil, 100, false, {0.1, 0.1, 0.1, 0.2})
                end
            end, L["SCOREBOARD_TOOLTIP_INTERRUPTS_HEADER"])
        end
    )

    playerInterrupts.InterruptCasts = CreateBreakdownLabel(line)

    local playerDispels = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(math.floor(playerData.dispels))
    end)

    local playerCrowdControlCasts = CreateBreakdownButton(
        line,
        -- onclick
        function (self) end,
        -- onSetPlayerData
        function(self, playerData)
            ---@cast playerData scoreboard_playerdata
            self:SetText(math.floor(playerData.ccCasts))
        end,
        -- onMouseEnter
        function (self, button)
            showCrowdControlTooltip(button)
        end
    )

    --add each widget create to the header alignment
    line:AddFrameToHeaderAlignment(playerPortrait)
    line:AddFrameToHeaderAlignment(specIcon)
    line:AddFrameToHeaderAlignment(playerName)
    line:AddFrameToHeaderAlignment(keystoneDungeonIconTexture)
    line:AddFrameToHeaderAlignment(playerScore)
    line:AddFrameToHeaderAlignment(lootAnchor)
    line:AddFrameToHeaderAlignment(playerDeaths)
    line:AddFrameToHeaderAlignment(playerDamageTaken)
    line:AddFrameToHeaderAlignment(playerDps)
    line:AddFrameToHeaderAlignment(playerHps)
    line:AddFrameToHeaderAlignment(playerInterrupts)
    line:AddFrameToHeaderAlignment(playerDispels)
    line:AddFrameToHeaderAlignment(playerCrowdControlCasts)

    line:AlignWithHeader(headerFrame, "left")

    --set the point of the interrupt casts
    local a, b, c, d, e = playerInterrupts:GetPoint(1)
    playerInterrupts.InterruptCasts:SetPoint(a, b, c, d + 20, e)

    headerFrame.lines[index] = line

    return line
end

function mythicPlusBreakdown.CreateActivityPanel(mainFrame)
    ---@type scoreboard_activityframe
    local activityFrame = CreateFrame("frame", "$parentActivityFrame", mainFrame)
    mainFrame.ActivityFrame = activityFrame
    addon.ActivityFrame = activityFrame

    activityFrame:SetHeight(4)
    activityFrame:SetPoint("topleft", mainFrame, "topleft", lineOffset * 2, activityFrameY)
    activityFrame:SetPoint("topright", mainFrame, "topright", -lineOffset * 2 - 1, activityFrameY)

    local backgroundTexture = activityFrame:CreateTexture("$parentBackgroundTexture", "border")
    backgroundTexture:SetColorTexture(0, 0, 0, 0.834)
    backgroundTexture:SetAllPoints()
    activityFrame.BackgroundTexture = backgroundTexture

    activityFrame.segmentTextures = {}
    activityFrame.nextTextureIndex = 1

    activityFrame.bossWidgets = {}


    --todo(tercio): show players activityTime some place in the mainFrame

    --functions
    ---@param runData runinfo
    activityFrame.SetActivity = function(self, events, runData)
        --reset the segment textures
        addon.activityTimeline.ResetSegmentTextures(self)

        ---@type table<string, table<number, number, number, number>>
        local eventColors = {
            fallback = {0.6, 0.6, 0.6, 0.5},
            enter_combat = {0.1, 0.7, 0.1, 0.5},
            leave_combat = {0.7, 0.1, 0.1, 0.5},
        }

        ---@type number[]
        local combatTimeline = runData.combatTimeline
        local timestamps = {}
        local last
        for i = 1, #combatTimeline do
            local timestamp = combatTimeline[i]
            if (timestamp >= runData.startTime) then
                last = {
                    time = timestamp - runData.startTime,
                    event = i % 2 == 0 and "enter_combat" or "leave_combat"
                }

                table.insert(timestamps, last)
            end
        end

        if (last == nil) then
            return
        end

        last.time = math.max(last.time, runData.endTime - runData.startTime)
        if (addon.profile.show_remaining_timeline_after_finish and runData.timeLimit and last.time < runData.timeLimit) then
            last = {
                time = runData.timeLimit,
                event = "time_limit",
            }

            timestamps[#timestamps+1] = last
        end

        local width = self:GetWidth()
        local multiplier = width / last.time

        addon.activityTimeline.UpdateBossWidgets(self, runData, multiplier)
        addon.activityTimeline.UpdateBloodlustWidgets(self, runData, multiplier)
        addon.activityTimeline.UpdateTimeSections(self, last.time, multiplier)

        for i = 1, #timestamps do
            local step = timestamps[i]
            local nextStep = timestamps[i+1]
            if (nextStep == nil) then
                break
            end

            local thisStepTexture = addon.activityTimeline.GetSegmentTexture(self)

            thisStepTexture:SetWidth((nextStep.time - step.time) * multiplier)
            thisStepTexture:SetPoint("left", activityFrame, "left", step.time * multiplier, 0)
            thisStepTexture:Show()

            if (nextStep.event == "time_limit") then
                thisStepTexture:SetColorTexture(unpack(eventColors.fallback))
            else
                thisStepTexture:SetColorTexture(unpack(eventColors[step.event] or eventColors.fallback))
            end
        end

        ---@class playerportrait : frame
        ---@field Portrait texture
        ---@field RoleIcon texture

        local reservedUntil = -100
        local up = true
        for event, marker in addon.activityTimeline.PrepareEventFrames(self, events) do
            local relativeTimestamp = event.timestamp - runData.startTime
            local pointOnBar = relativeTimestamp * multiplier

            detailsFramework:SetFontColor(marker.TimestampLabel, 1, 1, 1)
            detailsFramework:SetFontSize(marker.TimestampLabel, 12)
            marker.TimestampLabel:SetText(detailsFramework:IntegerToTimer(relativeTimestamp))

            ---@type activitytimeline_marker_data
            local markerData = {}
            if (event.type == addon.Enum.ScoreboardEventType.Death) then
                markerData = addon.activityTimeline.RenderDeathMarker(self, event, marker, runData)

            elseif (event.type == addon.Enum.ScoreboardEventType.KeyFinished) then
                markerData = addon.activityTimeline.RenderKeyFinishedMarker(self, event, marker)
            end

            local offset = marker:GetWidth() * 0.4
            local before = pointOnBar - offset
            local after = pointOnBar + offset

            if (markerData.forceDirection) then
                up = markerData.forceDirection == "up" and true or false
            elseif (before < reservedUntil) then
                up = not up
            else
                up = markerData.preferUp and true or false
            end

            if (after > reservedUntil) then
                reservedUntil = after
            end

            marker:Show()
            marker:ClearAllPoints()
            marker.TimestampLabel:ClearAllPoints()
            marker.LineTexture:ClearAllPoints()
            if (up) then
                marker:SetPoint("bottom", activityFrame, "topleft", pointOnBar, 15)
                marker.LineTexture:SetPoint("top", marker, "bottom", 0, 0)
                marker.LineTexture:SetPoint("bottom", activityFrame, "top", 0, 0)
                marker.TimestampLabel:SetPoint("bottom", marker, "top", 0, 3)
            else
                marker:SetPoint("top", activityFrame, "bottomleft", pointOnBar, -15)
                marker.LineTexture:SetPoint("top", marker, "top", 0, 0)
                marker.LineTexture:SetPoint("bottom", activityFrame, "bottom", 0, 0)
                marker.TimestampLabel:SetPoint("top", marker, "bottom", 0, -3)
            end
        end

    end

    return activityFrame
end
