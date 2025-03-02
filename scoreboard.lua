
--mythic+ extension for Details! Damage Meter
--[[
    This file show a frame at the end of a mythic+ run with a breakdown of the players performance.
    It shows the player name, the score, deaths, damage taken, dps, hps, interrupts, dispels and cc casts.
]]

---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil

---@class scoreboard_object : table
---@field lines scoreboard_line[]
---@field CreateBigBreakdownFrame fun():scoreboard_mainframe
---@field CreateLineForBigBreakdownFrame fun(parent:scoreboard_mainframe, header:scoreboard_header, index:number):scoreboard_line
---@field CreateActivityPanel fun(parent:scoreboard_mainframe):scoreboard_activityframe
---@field RefreshBigBreakdownFrame fun()
---@field MythicPlusOverallSegmentReady fun() executed when details! send the event COMBAT_MYTHICPLUS_OVERALL_READY
---@field SetFontSettings fun() set the default font settings

---@class scoreboard_mainframe : frame
---@field HeaderFrame scoreboard_header
---@field ActivityFrame scoreboard_activityframe
---@field DungeonNameFontstring fontstring
---@field DungeonBackdropTexture texture
---@field ElapsedTimeIcon texture
---@field ElapsedTimeText fontstring
---@field OutOfCombatIcon texture
---@field OutOfCombatText fontstring
---@field SandTimeIcon texture
---@field KeylevelText fontstring
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

---@class scoreboard_button : df_button
---@field PlayerData table
---@field SetPlayerData fun(self:scoreboard_button, playerData:scoreboard_playerdata)
---@field GetPlayerData fun(self:scoreboard_button):scoreboard_playerdata
---@field MarkTop fun(self:scoreboard_button)
---@field OnMouseEnter fun(self:scoreboard_button)|nil
---@field GetActor fun(self:scoreboard_button, actorMainAttribute):actor|nil, combat|nil

---@class scoreboard_playerdata : table
---@field name string
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

---@class scoreboard_activityframe : frame
---@field InCombatTexture texture
---@field OutOfCombatTexture texture
---@field BackgroundTexture texture
---@field SetActivity fun(self: scoreboard_activityframe, inCombat: number, outOfCombat: number)

---@type scoreboard_object
---@diagnostic disable-next-line: missing-fields
local mythicPlusBreakdown = {
    lines = {},
}

private.addon.mythicPlusBreakdown = mythicPlusBreakdown

local GetItemInfo = GetItemInfo or C_Item.GetItemInfo
local GetItemIcon = GetItemIcon or C_Item.GetItemIcon
local GetDetailedItemLevelInfo = GetDetailedItemLevelInfo or C_Item.GetDetailedItemLevelInfo

local Loc = _G.LibStub("AceLocale-3.0"):GetLocale("Details")

--local mythicDungeonCharts = Details222.MythicPlus.Charts.Listener
--local mythicDungeonFrames = Details222.MythicPlus.Frames

local CONST_DEBUG_MODE = false
local LOOT_DEBUG_MODE = false

--main frame settings
local mainFrameName = "DetailsMythicPlusBreakdownFrame"
local mainFrameHeight = 420
--the padding on the left and right side it should keep between the frame itself and the table
local mainFramePaddingHorizontal = 5
--offset for the dungeon name y position related to the top of the frame
local dungeonNameY = -10
--where the header is positioned in the Y axis from the top of the frame
local headerY = -55
--the amount of lines to be created to show player data
local lineAmount = 5
local lineOffset = 2
--the height of each line
local lineHeight = 46
--two backdrop colors
local lineColor1 = {1, 1, 1, 0.05}
local lineColor2 = {1, 1, 1, 0.1}
local lineBackdrop = {bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true}

local activityFrameY = headerY - 45 + (lineHeight * lineAmount * -1)

---store spell names of interrupt spells
---the table is filled when the main frame is created
---@type table<string, boolean>
local interruptSpellNameCache = {}

function addon.OpenMythicPlusBreakdownBigFrame()
    if (not _G[mainFrameName]) then
        mythicPlusBreakdown.CreateBigBreakdownFrame()
    end

    local mainFrame = _G[mainFrameName]
    mainFrame:Show()

    mythicPlusBreakdown.RefreshBigBreakdownFrame()

    mainFrame.YellowSpikeCircle.OnShowAnimation:Play()
end

function Details.OpenMythicPlusBreakdownBigFrame()
    addon.OpenMythicPlusBreakdownBigFrame()
end

function mythicPlusBreakdown.MythicPlusOverallSegmentReady()
    if (addon.profile.auto_open_mythic_plus_breakdown_big_frame) then
        private.log("auto opening the mythic+ breakdown big frame after", addon.profile.delay_to_open_mythic_plus_breakdown_big_frame, "seconds")
        detailsFramework.Schedules.After(addon.profile.delay_to_open_mythic_plus_breakdown_big_frame, addon.OpenMythicPlusBreakdownBigFrame)
    end
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
    closeButton:SetScript("OnClick", function()
        readyFrame:Hide()
    end)
    closeButton:SetPoint("topright", readyFrame, "topright", -5, -5)

    mythicPlusBreakdown.CreateActivityPanel(readyFrame)

    --dungeon name at the top of the frame
    local dungeonNameFontstring = readyFrame:CreateFontString("$parentTitle", "overlay", "GameFontNormalLarge")
    dungeonNameFontstring:SetPoint("top", readyFrame, "top", 0, dungeonNameY)
    DetailsFramework:SetFontSize(dungeonNameFontstring, 20)
    readyFrame.DungeonNameFontstring = dungeonNameFontstring

    local runTimeFontstring = readyFrame:CreateFontString("$parentRunTime", "overlay", "GameFontNormal")
    runTimeFontstring:SetPoint("top", dungeonNameFontstring, "bottom", 0, -5)
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
        {text = "Player Name", width = 110},
        {text = "M+ Score", width = 90},
        {text = "Deaths", width = 80},
        {text = "Damage Taken", width = 100},
        {text = "DPS", width = 100},
        {text = "HPS", width = 100},
        {text = "Interrupts", width = 100},
        {text = "Dispels", width = 80},
        {text = "CC Casts", width = 80},
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
		local textColor = {1, 0.8196, 0, 1}
		local textSize = 12

		--clock texture and icon to show the total time elapsed
		local elapsedTimeIcon = readyFrame:CreateTexture("$parentClockIcon", "artwork", nil, 2)
		elapsedTimeIcon:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
		elapsedTimeIcon:SetTexCoord(172/512, 235/512, 84/512, 147/512)
		readyFrame.ElapsedTimeIcon = elapsedTimeIcon

		--another clock texture and icon to show the wasted time (time out of combat)
		local outOfCombatIcon = readyFrame:CreateTexture("$parentClockIcon2", "artwork", nil, 2)
		outOfCombatIcon:SetTexture([[Interface\AddOns\Details\images\end_of_mplus.png]], nil, nil, "TRILINEAR")
		outOfCombatIcon:SetTexCoord(172/512, 235/512, 84/512, 147/512)
		outOfCombatIcon:SetVertexColor(detailsFramework:ParseColors("orangered"))
		readyFrame.OutOfCombatIcon = outOfCombatIcon

		local outOfCombatText = readyFrame:CreateFontString("$parentClockText2", "artwork", "GameFontNormal")
		outOfCombatText:SetTextColor(1, 1, 1)
		detailsFramework:SetFontSize(outOfCombatText, 11)
		detailsFramework:SetFontColor(outOfCombatText, "orangered")
		outOfCombatText:SetText("00:00")
		outOfCombatText:SetPoint("left", outOfCombatIcon, "right", 6, -3)
		readyFrame.OutOfCombatText = outOfCombatText

        local buttonSize = 24

        readyFrame.ElapsedTimeIcon:SetSize(buttonSize, buttonSize)
        readyFrame.OutOfCombatIcon:SetSize(buttonSize, buttonSize)
        readyFrame.ElapsedTimeIcon:SetPoint("bottomleft", headerFrame, "topleft", 20, 12)
        readyFrame.OutOfCombatIcon:SetPoint("left", readyFrame.ElapsedTimeIcon, "right", 120, 0)
    end

    --create 6 rows to show data of the player, it only require 5 lines, the last one can be used on exception cases.
    for i = 1, lineAmount do
        mythicPlusBreakdown.CreateLineForBigBreakdownFrame(readyFrame, headerFrame, i)
    end

    return readyFrame
end

--this function get the overall mythic+ segment created after a mythic+ run has finished
--then it fill the lines with data from the overall segment
function mythicPlusBreakdown.RefreshBigBreakdownFrame()
    ---@type scoreboard_mainframe
    local mainFrame = _G[mainFrameName]
    local headerFrame = mainFrame.HeaderFrame
    local lines = headerFrame.lines

    mythicPlusBreakdown.SetFontSettings()

    local mythicPlusOverallSegment = Details:GetCurrentCombat()

	if (mythicPlusOverallSegment:GetCombatType() ~= DETAILS_SEGMENTTYPE_MYTHICDUNGEON_OVERALL) then
		--get a table with all segments
		local segmentsTable = Details:GetCombatSegments()
		for i = 1, #segmentsTable do
			local segment = segmentsTable[i]
			if (segment:GetCombatType() == DETAILS_SEGMENTTYPE_MYTHICDUNGEON_OVERALL) then
				mythicPlusOverallSegment = segment
				break
			end
		end
	end

	if (mythicPlusOverallSegment:GetCombatType() ~= DETAILS_SEGMENTTYPE_MYTHICDUNGEON_OVERALL) then
        --no mythic+ segment found
        --mainFrame:Hide()
        return
    end

    --local mythicPlusOverallSegment = Details:GetOverallCombat()
    local combatTime = mythicPlusOverallSegment:GetCombatTime()

    local damageContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_DAMAGE)
    local healingContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_HEAL)
    local utilityContainer = mythicPlusOverallSegment:GetContainer(DETAILS_ATTRIBUTE_MISC)

    local data = {}

    do --code for filling the 5 player lines
        for actorIndex, actorObject in damageContainer:ListActors() do
            ---@cast actorObject actor
            if (actorObject:IsGroupPlayer()) then
                local unitId
                for i = 1, #Details.PartyUnits do
                    if (Details:GetFullName(Details.PartyUnits[i]) == actorObject.nome) then
                        unitId = Details.PartyUnits[i]
                    end
                end
                unitId = unitId or actorObject.nome

                if (type(actorObject.mrating) == "table") then
                    actorObject.mrating = actorObject.mrating.currentSeasonScore
                end

                local rating = actorObject.mrating or 0
                local ratingColor = C_ChallengeMode.GetDungeonScoreRarityColor(rating)
                if (not ratingColor) then
                    ratingColor = _G["HIGHLIGHT_FONT_COLOR"]
                end

                local deathAmount = 0
                local deathTable = mythicPlusOverallSegment:GetDeaths()
                for i = 1, #deathTable do
                    local thisDeathTable = deathTable[i]
                    local playerName = thisDeathTable[3]
                    if (playerName == actorObject.nome) then
                        deathAmount = deathAmount + 1
                    end
                end

                ---@cast actorObject actordamage

                ---@type scoreboard_playerdata
                local thisPlayerData = {
                    name = actorObject.nome,
                    class = actorObject.classe,
                    spec = actorObject.spec,
                    role = actorObject.role or UnitGroupRolesAssigned(unitId),
                    score = rating,
                    previousScore = Details.PlayerRatings[Details:GetFullName(unitId)] or rating,
                    scoreColor = ratingColor,
                    deaths = deathAmount,
                    damageTaken = actorObject.damage_taken,
                    dps = actorObject.total / combatTime,
                    activityTimeDamage = actorObject:Tempo(),
                    activityTimeHeal = 0, --place holder for now, is setted when iterating the healingContainer
                    hps = 0,
                    interrupts = 0,
                    interruptCasts = mythicPlusOverallSegment:GetInterruptCastAmount(actorObject.nome),
                    dispels = 0,
                    ccCasts = mythicPlusOverallSegment:GetCCCastAmount(actorObject.nome),
                    unitId = unitId,
                    combatUid = mythicPlusOverallSegment:GetCombatUID(),
                }

                if (thisPlayerData.role == "NONE") then
                    thisPlayerData.role = "DAMAGER"
                end

                data[#data+1] = thisPlayerData
            end
        end

        for actorIndex, actorObject in healingContainer:ListActors() do
            local playerData
            for i = 1, #data do
                if (data[i].name == actorObject.nome) then
                    playerData = data[i]
                    break
                end
            end

            if (playerData) then
                ---@cast actorObject actorheal
                playerData.hps = actorObject.total / combatTime
                playerData.activityTimeHeal = actorObject:Tempo()
            end
        end

        for actorIndex, actorObject in utilityContainer:ListActors() do
            local playerData
            for i = 1, #data do
                if (data[i].name == actorObject.nome) then
                    playerData = data[i]
                    break
                end
            end

            if (playerData) then
                ---@cast actorObject actorutility
                playerData.interrupts = actorObject.interrupt or 0
                playerData.dispels = actorObject.dispell or 0
            end
        end

        table.sort(data, function(t1, t2) return t1.role > t2.role end)

        for i = 1, lineAmount do
            lines[i]:Hide()
        end

        local topScores = {
            [6] = {key = "damageTaken", line = 0, best = 0},
            [7] = {key = "dps", line = 0, best = 0},
            [8] = {key = "hps", line = 0, best = 0},
            [9] = {key = "interrupts", line = 0, best = 0},
            [10] = {key = "dispels", line = 0, best = 0},
            [11] = {key = "ccCasts", line = 0, best = 0},
        }

        for i = 1, lineAmount do
            local line = lines[i]
            local frames = line:GetFramesFromHeaderAlignment()
            local playerData = data[i]

            --(re)set the line contents
            for j = 1, #frames do
                local frame = frames[j]

                if (frame:GetObjectType() == "FontString" or frame:GetObjectType() == "Button") then
                    frame:SetText("")
                elseif (frame:GetObjectType() == "Texture") then
                    frame:SetTexture(nil)
                end

                if (playerData and frame.SetPlayerData) then
                    frame:SetPlayerData(playerData)
                end
            end

            if (playerData) then
                line:Show()
                --dumpt(playerData)
                local playerPortrait = frames[1]
                local specIcon = frames[2]

                -- manually setting the textures, buttons are set through SetPlayerData
                if (GetUnitName("player", true) == playerData.name) then
                    playerRating = playerData.score
                end

                SetPortraitTexture(playerPortrait.Portrait, playerData.unitId)
                local portraitTexture = playerPortrait.Portrait:GetTexture()
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
                    if (value.best < playerData[value.key]) then
                        value.best = playerData[value.key]
                        value.line = i
                    end
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

    local mythicPlusData = mythicPlusOverallSegment:GetMythicDungeonInfo()
    --dumpt(mythicPlusData)

    if (mythicPlusData) then
        local runTime = mythicPlusData.RunTime
        if (runTime) then
            local notInCombat = runTime - combatTime

            mainFrame.ActivityFrame:SetActivity(combatTime, notInCombat)

            mainFrame.ElapsedTimeText:SetText(detailsFramework:IntegerToTimer(runTime))
            mainFrame.OutOfCombatText:SetText("Not in Combat: " .. detailsFramework:IntegerToTimer(notInCombat))
            mainFrame.Level:SetText(mythicPlusData.Level) --the level in the big circle at the top
            mainFrame.DungeonNameFontstring:SetText(mythicPlusData.DungeonName)
        else
            mainFrame.ElapsedTimeText:SetText("00:00")
            mainFrame.OutOfCombatText:SetText("00:00")
            mainFrame.Level:SetText("0")
            mainFrame.DungeonNameFontstring:SetText("Unknown Dungeon")
        end
    end

    ---@type details_instanceinfo
	local instanceInfo = mythicPlusData and Details:GetInstanceInfo(mythicPlusData.MapID) or Details:GetInstanceInfo(Details:GetCurrentCombat().mapId)
    if (instanceInfo) then
        mainFrame.DungeonBackdropTexture:SetTexture(instanceInfo.iconLore)
    else
        mainFrame.DungeonBackdropTexture:SetTexture(mythicPlusOverallSegment.is_mythic_dungeon.DungeonTexture)
    end

    mainFrame.DungeonBackdropTexture:SetTexCoord(35/512, 291/512, 49/512, 289/512)

end

local function OpenLineBreakdown(self, mainAttribute, subAttribute)
    local playerData = self.MyObject:GetPlayerData()
    if (not playerData or not playerData.name or not playerData.combatUid) then
        return
    end

    Details:OpenSpecificBreakdownWindow(Details:GetCombatByUID(playerData.combatUid), playerData.name, mainAttribute, subAttribute)
end

local showTargetsTooltip = function(self, playerObject, title)
    local targets = playerObject.targets
    local text = ""
    if (targets) then
        local targetList = {}
        for targetName, amount in pairs(targets) do
            targetList[#targetList+1] = {targetName, amount}
        end
        table.sort(targetList, function(t1, t2) return t1[2] > t2[2] end)

        for i = 1, math.min(#targetList, 7) do
            local targetName = targetList[i][1]
            local amount = targetList[i][2]
            text = text .. targetName .. ": " .. amount .. "\n"
        end
    end

    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:SetText(detailsFramework:RemoveRealmName(playerObject:Name()) .. title)
    GameTooltip:AddLine(text, 1, 1, 1, true)
    GameTooltip:Show()
end

---@param self df_blizzbutton
---@param button scoreboard_button
local function OnEnterLineBreakdownButton(self, button)
    local text = button.button.text
    text.originalColor = {text:GetTextColor()}
    detailsFramework:SetFontSize(text, addon.profile.font.row_size)
    detailsFramework:SetFontColor(text, addon.profile.font.hover_color)
    detailsFramework:SetFontOutline(text, addon.profile.font.hover_outline)

    if (button.OnMouseEnter and addon.profile.show_column_summary_in_tooltip) then
        button.OnMouseEnter(self, button)
    end
end

local function OnLeaveLineBreakdownButton(self)
    local text = self.MyObject.button.text
    detailsFramework:SetFontSize(text, addon.profile.font.row_size)
    detailsFramework:SetFontOutline(text, addon.profile.font.regular_outline)
    detailsFramework:SetFontColor(text, text.originalColor)
    GameTooltip:Hide()
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
        onSetPlayerData(self, playerData)
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
        self:SetText(detailsFramework:RemoveRealmName(playerData.name))
    end)

    local playerScore = CreateBreakdownLabel(line, function(self, playerData)
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

    local playerDeaths = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(playerData.deaths)
    end)

    local playerDamageTaken = CreateBreakdownButton(
        line,
        -- onclick
        function (self)
            OpenLineBreakdown(self, DETAILS_ATTRIBUTE_DAMAGE, DETAILS_SUBATTRIBUTE_DAMAGETAKEN)
        end,
        -- onSetPlayerData
        function(self, playerData)
            self:SetText(Details:Format(math.floor(playerData.damageTaken)))
        end,
        -- onMouseEnter
        function (self, button)
            -- this one does not work yet

            ---@type actordamage|combat
            local actor, combat = button:GetActor(DETAILS_ATTRIBUTE_DAMAGE)

            --indexed table with subtable with [1] spellId [2] amount
            ---@type table<number, table<number, number>>
            local spellsThatHitThisPlayer = {}

            for damagerName in pairs (actor.damage_from) do
                local damagerObject = combat:GetActor(DETAILS_ATTRIBUTE_DAMAGE, damagerName)
                if (damagerObject) then
                    for spellId, spellTable in pairs(damagerObject:GetSpellList()) do
                        if (spellTable.targets and spellTable.targets[playerName]) then
                            local amount = spellTable.targets[playerName]
                            if (amount > 0) then
                                spellsThatHitThisPlayer[#spellsThatHitThisPlayer+1] = {spellId, amount}
                            end
                        end
                    end
                end
            end

            table.sort(spellsThatHitThisPlayer, function(t1, t2) return t1[2] > t2[2] end)
            for i = 1, math.min(#spells, 7) do
                local spellId = spells[i][1]
                local amount = spells[i][2]
                text = text .. spellId .. ": " .. amount .. "\n"
            end

            GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(detailsFramework:RemoveRealmName(playerObject:Name()) .. " - Damage Taken")
            GameTooltip:AddLine(text, 1, 1, 1, true)
            GameTooltip:Show()
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
            self:SetText(Details:Format(math.floor(playerData.dps)))
        end,
        function (self, button)
            local actor = button:GetActor(DETAILS_ATTRIBUTE_DAMAGE)
            if (actor) then
                showTargetsTooltip(self, actor, " - Damage Done")
            end
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
            self:SetText(Details:Format(math.floor(playerData.hps)))
        end,
        -- onMouseEnter
        function (self, button)
            local actor = button:GetActor(DETAILS_ATTRIBUTE_HEAL)
            if (actor) then
                showTargetsTooltip(self, actor, " - Healing Done")
            end
        end
    )

    local playerInterrupts = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(math.floor(playerData.interrupts))
        self.InterruptCasts:SetText("/ " .. math.floor(playerData.interruptCasts))
    end)

    playerInterrupts.InterruptCasts = CreateBreakdownLabel(line)

    local playerDispels = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(math.floor(playerData.dispels))
    end)

    local playerCcCasts = CreateBreakdownLabel(line, function(self, playerData)
        self:SetText(math.floor(playerData.ccCasts))
    end)

    --local playerEmptyField = CreateBreakdownLabel(line)

    --add each widget create to the header alignment
    line:AddFrameToHeaderAlignment(playerPortrait)
    line:AddFrameToHeaderAlignment(specIcon)
    line:AddFrameToHeaderAlignment(playerName)
    line:AddFrameToHeaderAlignment(playerScore)
    line:AddFrameToHeaderAlignment(playerDeaths)
    line:AddFrameToHeaderAlignment(playerDamageTaken)
    line:AddFrameToHeaderAlignment(playerDps)
    line:AddFrameToHeaderAlignment(playerHps)
    line:AddFrameToHeaderAlignment(playerInterrupts)
    line:AddFrameToHeaderAlignment(playerDispels)
    line:AddFrameToHeaderAlignment(playerCcCasts)
    --line:AddFrameToHeaderAlignment(playerEmptyField)

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

    activityFrame:SetHeight(4)
    activityFrame:SetPoint("topleft", mainFrame, "topleft", lineOffset, activityFrameY)
    activityFrame:SetPoint("topright", mainFrame, "topright", -lineOffset - 1, activityFrameY)

    local backgroundTexture = activityFrame:CreateTexture("$parentBackgroundTexture", "border")
    backgroundTexture:SetColorTexture(0, 0, 0, 0.834)
    backgroundTexture:SetAllPoints()

    local incombatTexture = activityFrame:CreateTexture("$parentInCombatTexture", "artwork")
    incombatTexture:SetColorTexture(0, 1, 0, 0.734)
    incombatTexture:SetPoint("left", activityFrame, "left", 0, 0)

    local outOfCombatTexture = activityFrame:CreateTexture("$parentOutOfCombatTexture", "artwork")
    outOfCombatTexture:SetColorTexture(1, 0, 0, 0.734)

    --members
    activityFrame.InCombatTexture = incombatTexture
    activityFrame.OutOfCombatTexture = outOfCombatTexture
    activityFrame.BackgroundTexture = backgroundTexture

    --functions
    activityFrame.SetActivity = function(self, inCombat, outOfCombat)
        local total = inCombat + outOfCombat
        local inCombatWidth = (inCombat / total) * self:GetWidth()
        local outOfCombatWidth = (outOfCombat / total) * self:GetWidth()

        --inCombatTimeline is a table with 'scoreboard_incombat_timeline_step' subtable that tells when the group entered or left combat
        ---@type scoreboard_incombat_timeline_step[]
        local inCombatTimeline = addon.profile.last_run_data.incombat_timeline
        --todo(tercio): use the timeline to show when the group entered or left combat with small chunks for textures
        --todo(tercio): show players activityTime some place in the mainFrame

        self.InCombatTexture:SetWidth(inCombatWidth)
        self.OutOfCombatTexture:SetWidth(outOfCombatWidth)
        self.OutOfCombatTexture:SetPoint("left", self.InCombatTexture, "right", 0, 0)
    end

    return activityFrame
end
