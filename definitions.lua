
---@class private : table
---@field addon detailsmythicplus

---@class detailsmythicplus : table
---@field detailsEventListener table
---@field InitializeEvents fun() run on PLAYER_LOGIN, create the function to listen to details events
---@field OnMythicDungeonStart fun(...) run on COMBAT_MYTHICDUNGEON_START
---@field OnMythicDungeonEnd fun(...) run on COMBAT_MYTHICDUNGEON_END
---@field OnMythicPlusOverallReady fun(...) run on COMBAT_MYTHICPLUS_OVERALL_READY
---@field OnEncounterStart fun(...) run on COMBAT_ENCOUNTER_START
---@field OnEncounterEnd fun(...) run on COMBAT_ENCOUNTER_END
---@field OnPlayerEnterCombat fun(...) run on COMBAT_PLAYER_ENTER
---@field OnPlayerLeaveCombat fun(...) run on COMBAT_PLAYER_LEAVE
---@field StartParser fun() start the combatlog parser
---@field StopParser fun() stop the combatlog parser
---@field OpenMythicPlusBreakdownBigFrame fun() open the mythic plus breakdown big frame