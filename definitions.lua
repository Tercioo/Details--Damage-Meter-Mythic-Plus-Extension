
--mythic+ extension for Details! Damage Meter
---@class private : table
---@field addon detailsmythicplus
---@field log fun(...) log a message to the addon logs

---@class profile : table
---@field auto_open_mythic_plus_breakdown_big_frame boolean if true, the panel will open after x seconds after the m+ overall segment is ready.
---@field delay_to_open_mythic_plus_breakdown_big_frame number seconds to wait to open the big frame panel
---@field show_column_summary_in_tooltip boolean whether or not to show the summary in a tooltip when hovering over the column
---@field show_remaining_timeline_after_finish boolean whether or not to render the remaining time in a bar in a keystone after completing
---@field translit boolean translit cyrillic
---@field last_run_data detailsmythicplus_rundata store the data from the last run
---@field font fontsettings font settings
---@field logs string[] logs of the addon
---@field logout_logs string[]

---@class fontsettings : table
---@field row_size number
---@field regular_color any
---@field regular_outline string
---@field hover_color any
---@field hover_outline string
---@field standout_color any
---@field standout_outline string

---@class detailsmythicplus_rundata : table
---@field start_time number
---@field end_time number
---@field incombat_timeline detailsmythicplus_combatstep[] first table tells the group left table, second when entered in combat, third when left combat, and so on
---@field encounter_timeline detailsmythicplus_encounterinfo[] store the data from encounter_start and encounter_end events, one sub table per boss attempt
---@field interrupt_overlaps table<string, number> count the interrupt overlaps for each player

---@class detailsmythicplus_combatstep : table a table with the time and if the group was in combat or not, sub table of 'incombat_timeline'
---@field time number time() of when the player entered or left combat
---@field in_combat boolean whether the player is in combat or not

---@class detailsmythicplus_encounterinfo : table
---@field dungeonEncounterId number encounter id given from the encounter_start event
---@field encounterName string localized name of the encounter
---@field difficultyId number difficulty id of the encounter
---@field raidSize number number of players in the group
---@field startTime number time() of when the encounter started
---@field endTime number time() of when the encounter ended (if the encounter did not ended yet, this value is zero)
---@field defeated boolean true if the boss has been killed

---@class detailsmythicplus : table
---@field profile profile store the profile settings
---@field detailsEventListener table register and listen to Details! events
---@field data table store data from the current mythic plus run
---@field mythicPlusBreakdown details_mythicplus_breakdown
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
---@field IsParsing fun():boolean whether or parsing at the moment
---@field OpenMythicPlusBreakdownBigFrame fun() open the mythic plus breakdown big frame
---@field RefreshOpenScoreBoard fun() Refreshes the score board, but only if it's visible
---@field MythicPlusOverallSegmentReady fun() executed after the run is done and details! has the m+ overall segment
---@field CountInterruptOverlaps fun() executed after the run is done, count the interrupt overlaps for each player
---@field GetInAndOutOfCombatTimeline fun() : detailsmythicplus_combatstep[] return the in and out of combat timeline
---@field GetRunTime fun() : number return the run time of the last run
---@field GetMythicPlusOverallSegment fun() : combat return the latest mythic+ overall segment from details!
---@field GetRunBossSegments fun() : combat[] retrieves the segments of a Mythic+ run that correspond to boss encounters.
---@field GetMythicPlusData fun() : mythicdungeoninfo? retrieves the data from the current mythic plus run

