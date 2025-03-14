
--functions to handle the loot system
---@type details
local Details = _G.Details
---@type detailsframework
local detailsFramework = _G.DetailsFramework
local addonName, private = ...
---@type detailsmythicplus
local addon = private.addon
local _ = nil
local Translit = LibStub("LibTranslit-1.0")

local CONST_DEBUG_MODE = false
local LOOT_DEBUG_MODE = true

local playerBannerSettings = {
	background_width = 286,
	background_height = 64,
	playername_background_width = 68,
	playername_background_height = 12,
	playername_fontsize = 12,
	playername_fontcolor = {1, 1, 1},
	dungeon_texture_width = 45,
	dungeon_texture_height = 45,
	loot_square_width = 32,
	loot_square_height = 32,
	loot_square_amount = 2,
	trans_anim_duration = 0.5, --time that the translation animation takes to move the banner from right to left
}

---@class loot : table
---@field cache table<string, details_loot_cache[]>
---@field LootFrame lootframe
---@field UpdateUnitLoot fun(scoreboardLine: scoreboard_line)
---@field CreateLootWidgetsInScoreboardLine fun(scoreboardLine: scoreboard_line)

---@class lootframe : frame

--loot namespace
local loot = private.addon.loot

--frame to handle loot events
---@type lootframe
local lootFrame = CreateFrame("frame", "DetailsEndOfMythicLootFrame", UIParent)
lootFrame:RegisterEvent("BOSS_KILL")
private.addon.loot.LootFrame = lootFrame

if (C_EventUtils.IsEventValid("ENCOUNTER_LOOT_RECEIVED")) then
	lootFrame:RegisterEvent("ENCOUNTER_LOOT_RECEIVED")
end

--register the loot players looted at the end of the mythic dungeon
private.addon.loot.cache = {}

---@type scoreboard_line[]
private.addon.loot.scoreboardLineCacheByName = {}

function private.addon.loot.UpdateUnitLoot(scoreboardLine) --player banner will be replaced by the line that shows player information, class: scoreboard_line
	---currently being called after a updatPlayerBanner()
	---@cast scoreboardLine scoreboard_line
	local unitId = scoreboardLine.unitId
	local unitName = scoreboardLine.unitName

	local timeNow = GetTime()
	local lootCache = private.addon.loot.cache[unitName]
	if (not lootCache) then
		return
	end

	---@type details_loot_cache[]
	local lootCandidates = {}

	if (#lootCache > 0) then
		scoreboardLine:StopTextDotAnimation()
	end

	if (lootCache) then
		local lootCacheSize = #lootCache
		if (lootCacheSize > 0) then
			local lootIndex = 1
			for i = lootCacheSize, 1, -1 do
				---@type details_loot_cache
				local lootInfo = lootCache[i]
				if (timeNow - lootInfo.time < 10) then
					lootCandidates[lootIndex] = lootInfo
					lootIndex = lootIndex + 1
				end
				table.remove(lootCache, i)

				if (LOOT_DEBUG_MODE) then
					if (UnitIsUnit("player", unitId)) then
						Details:Msg("Loot ENTRY REMOVED:", unitName, GetTime())
					end
				end
			end
		end
	end

	for i = 1, #lootCandidates do
		local lootInfo = lootCandidates[i]
		local itemLink = lootInfo.itemLink
		local effectiveILvl = lootInfo.effectiveILvl
		local itemQuality = lootInfo.itemQuality
		local itemID = lootInfo.itemID

		local lootSquare = scoreboardLine:GetLootSquare() --internally controls the loot square index
		lootSquare.itemLink = itemLink --will error if this the thrid lootSquare (creates only 2 per banner)

		local rarityColor = --[[GLOBAL]] ITEM_QUALITY_COLORS[itemQuality]
		lootSquare.LootIcon:SetTexture(C_Item.GetItemIconByID(itemID))
		lootSquare.LootIconBorder:SetVertexColor(rarityColor.r, rarityColor.g, rarityColor.b, 1)
		lootSquare.LootItemLevel:SetText(effectiveILvl or "0")

		--update size
		lootSquare.LootIcon:SetSize(playerBannerSettings.loot_square_width, playerBannerSettings.loot_square_height)
		lootSquare.LootIconBorder:SetSize(playerBannerSettings.loot_square_width, playerBannerSettings.loot_square_height)

		lootSquare:Show()

		if (LOOT_DEBUG_MODE) then
			if (UnitIsUnit("player", unitId)) then
				Details:Msg("Loot DISPLAYED:", unitName, GetTime())
			end
		end
	end
end

lootFrame:SetScript("OnEvent", function(self, event, ...)
	if (event == "BOSS_KILL") then
		local encounterID, name = ...;

	elseif (event == "ENCOUNTER_LOOT_RECEIVED") then
		local lootEncounterId, itemID, itemLink, quantity, unitName, className = ...

		unitName = Ambiguate(unitName, "none")

		local _, instanceType = GetInstanceInfo()
		if (instanceType == "party" or CONST_DEBUG_MODE) then
			local effectiveILvl, nop, baseItemLevel = GetDetailedItemLevelInfo(itemLink)

			local bIsAccountBound = C_Item.IsItemBindToAccountUntilEquip(itemLink)

			local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
			itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
			expacID, setID, isCraftingReagent = GetItemInfo(itemLink)

			if (addon.IsScoreboardOpen()) then
				local scoreboardLine = private.addon.loot.scoreboardLineCacheByName[unitName]
				if (scoreboardLine) then
					scoreboardLine:StopTextDotAnimation()
				end
			end

			--if (Details.debug) then
			--	Details222.DebugMsg("Loot Received:", unitName, itemLink, effectiveILvl, itemQuality, baseItemLevel, "itemType:", itemType, "itemSubType:", itemSubType, "itemEquipLoc:", itemEquipLoc)
			--end

			if (effectiveILvl > 480 and baseItemLevel > 5 and not bIsAccountBound) then --avoid showing loot that isn't items
				private.addon.loot.cache[unitName] = private.addon.loot.cache[unitName] or {}
				---@type details_loot_cache
				local lootCacheTable = {
					playerName = unitName,
					itemLink = itemLink,
					effectiveILvl = effectiveILvl,
					itemQuality = itemQuality, --this is a number
					itemID = itemID,
					time = GetTime()
				}
				table.insert(private.addon.loot.cache[unitName], lootCacheTable)

				if (LOOT_DEBUG_MODE) then
					Details:Msg("Loot ADDED:", unitName, itemLink, effectiveILvl, itemQuality, baseItemLevel)
				end

				--check if the end of mythic plus frame is opened and call a function to update the loot frame of the player
				if (addon.IsScoreboardOpen()) then
					C_Timer.After(1.5, function()
						local scoreboardLine = private.addon.loot.scoreboardLineCacheByName[unitName]
						if (scoreboardLine) then
							private.addon.loot.UpdateUnitLoot(scoreboardLine)
						end
					end)
				end
			else
				if (LOOT_DEBUG_MODE) then
					Details:Msg("Loot SKIPPED:", unitName, itemLink, effectiveILvl, itemQuality, baseItemLevel, bIsAccountBound)
				end
			end
		end
	end
end)

---@param scoreboardLine scoreboard_line
---@param name string
---@param parent frame
---@param lootIndex number
local createLootSquare = function(scoreboardLine, name, parent, lootIndex)
	---@type details_lootsquare
	local lootSquare = CreateFrame("frame", scoreboardLine:GetName() .. "LootSquare" .. lootIndex, parent)
	lootSquare:SetSize(46, 46)
	lootSquare:SetFrameLevel(parent:GetFrameLevel()+10)
	lootSquare:Hide()

	lootSquare:SetScript("OnEnter", function(self)
		if (self.itemLink) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
			GameTooltip:SetHyperlink(lootSquare.itemLink)
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

	local shadowTexture = scoreboardLine:CreateTexture("$parentShadowTexture", "artwork")
	shadowTexture:SetTexture([[Interface\AddOns\Details\images\end_of_mplus_banner_mask.png]])
	shadowTexture:SetTexCoord(441/512, 511/512, 81/512, 151/512)
	shadowTexture:SetSize(32, 32)
	shadowTexture:SetVertexColor(0.05, 0.05, 0.05, 0.6)
	shadowTexture:SetPoint("center", lootSquare, "center", 0, 0)
	lootSquare.ShadowTexture = shadowTexture

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
	lootItemLevel:SetPoint("bottom", lootSquare, "bottom", 0, -4)
	lootItemLevel:SetTextColor(1, 1, 1)
	detailsFramework:SetFontSize(lootItemLevel, 11)
	lootSquare.LootItemLevel = lootItemLevel

	local lootItemLevelBackgroundTexture = lootSquare:CreateTexture("$parentItemLevelBackgroundTexture", "artwork", nil, 6)
	lootItemLevelBackgroundTexture:SetTexture([[Interface\Cooldown\LoC-ShadowBG]])
	lootItemLevelBackgroundTexture:SetPoint("bottomleft", lootSquare, "bottomleft", -7, -3)
	lootItemLevelBackgroundTexture:SetPoint("bottomright", lootSquare, "bottomright", 7, -15)
	lootItemLevelBackgroundTexture:SetHeight(10)
	lootSquare.LootItemLevelBackgroundTexture = lootItemLevelBackgroundTexture

	return lootSquare
end


---@param line scoreboard_line
---@return frame
function addon.loot.CreateLootWidgetsInScoreboardLine(line)
    local lootAnchor = CreateFrame("frame", nil, line)
    --waiting for loot animation

	---@class loot_dot_animation : df_label
	---@field dotsTimer timer

	---@type loot_dot_animation
	local waitingForLootDotsAnimationLabel = detailsFramework:CreateLabel(lootAnchor, "...", 20, "silver") --~dots
	waitingForLootDotsAnimationLabel:SetDrawLayer("overlay", 6)
	waitingForLootDotsAnimationLabel:SetAlpha(0.5)
	waitingForLootDotsAnimationLabel:Hide()
	line.WaitingForLootLabel = waitingForLootDotsAnimationLabel

	--make a text dot animation, which will show no dots at start and then "." then ".." then "..." and back to "" and so on
	function line:StartTextDotAnimation()
		--update the Waiting for Loot labels
		local dotsString = self.WaitingForLootLabel
		dotsString:Show()

		local dotsCount = 0
		local maxDots = 3
		local maxLoops = 200

		local dotsTimer = C_Timer.NewTicker(0.5+RandomFloatInRange(-0.003, 0.003), function()
			dotsCount = dotsCount + 1

			if (dotsCount > maxDots) then
				dotsCount = 0
			end

			local dotsText = ""
			for i = 1, dotsCount do
				dotsText = dotsText .. "."
			end

			dotsString:SetText(dotsText)
		end, maxLoops)

		dotsString.dotsTimer = dotsTimer
	end

	function line:StopTextDotAnimation()
		local dotsString = self.WaitingForLootLabel
		dotsString:Hide()
		if (dotsString.dotsTimer) then
			dotsString.dotsTimer:Cancel()
		end
	end

    line.LootSquares = {}
    line.NextLootSquare = 1

	for i = 1, 2 do
		local lootSquare = createLootSquare(line, "", lootAnchor, i)
		if (i == 1) then
			lootSquare:SetPoint("right", lootAnchor, "left", 0, 0)
		else
			lootSquare:SetPoint("right", line.LootSquares[i-1], "left", -2, 0)
		end
		line.LootSquares[i] = lootSquare
		line["lootSquare" .. i] = lootSquare
	end

	function line:ClearLootSquares()
		line.NextLootSquare = 1

		for _, lootSquare in ipairs(self.LootSquares) do
			lootSquare:Hide()
			lootSquare.itemLink = nil
			lootSquare.LootIcon:SetTexture([[Interface\ICONS\INV_Misc_QuestionMark]])
			lootSquare.LootItemLevel:SetText("")
		end
	end

	function line:GetLootSquare()
		local lootSquareIdx = line.NextLootSquare
		line.NextLootSquare = lootSquareIdx + 1
		local lootSquare = line.LootSquares[lootSquareIdx]
		lootSquare:Show()
		return lootSquare
	end

	return lootAnchor
end