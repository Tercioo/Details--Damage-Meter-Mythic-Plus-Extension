
--mythic+ extension for Details! Damage Meter
--last run: the most recent mythic+ run finished


---@class private : table
---@field addon detailsmythicplus
---@field log fun(...) log a message to the addon logs

---@class combattimetype : table
---@field RunRime number
---@field CombatTime number

---@class scoreboard_eventtype : table
---@field EncounterStart scoreboard_eventtypes
---@field EncounterEnd scoreboard_eventtypes
---@field Death scoreboard_eventtypes
---@field KeyFinished scoreboard_eventtypes

---@alias scoreboard_eventtypes
---| "EncounterStart"
---| "EncounterEnd"
---| "Death"
---| "KeyFinished"

---@class enum : table
---@field CombatType combattimetype
---@field ScoreboardEventType scoreboard_eventtype

---@class profile : table
---@field saved_runs runinfo[] store the saved runs
---@field saved_runs_limit number limit of saved runs
---@field saved_runs_selected_index number index of the selected run
---@field when_to_automatically_open_scoreboard string which method to use to automatically open? can be LOOT_CLOSED or COMBAT_MYTHICPLUS_OVERALL_READY
---@field delay_to_open_mythic_plus_breakdown_big_frame number seconds to wait to open the big frame panel
---@field show_column_summary_in_tooltip boolean whether or not to show the summary in a tooltip when hovering over the column
---@field show_remaining_timeline_after_finish boolean whether or not to render the remaining time in a bar in a keystone after completing
---@field show_time_sections boolean whether or not to render sections of time on the timeline
---@field scoreboard_scale number indicates the scale of the scoreboard window
---@field translit boolean translit cyrillic
---@field last_run_data detailsmythicplus_run_data store the data from the last run
---@field font fontsettings font settings
---@field logs string[] logs of the addon
---@field logout_logs string[]

---@class detailsmythicplus : table
---@field profile profile store the profile settings
---@field detailsEventListener table register and listen to Details! events
---@field loot loot
---@field data table store data from the current mythic plus run
---@field Enum enum
---@field selectedRunInfo runinfo currently run info in use (showing the data in the scoreboard), if any
---@field mythicPlusBreakdown details_mythicplus_breakdown
---@field activityTimeline activitytimeline namespace for functions related to the activity timeline
---@field ActivityFrame scoreboard_activityframe frame where the widgets for the activity timeline are parented to
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
---@field CreateRunInfo fun(segment:combat) : runinfo create a run info from the mythic+ overall segment
---@field OpenMythicPlusBreakdownBigFrame fun() open the mythic plus breakdown big frame
---@field RefreshOpenScoreBoard fun():scoreboard_mainframe Refreshes the score board, but only if it's visible
---@field OpenScoreBoardAtEnd fun() Opens the scoreboard with the configured delay, at the end of a run
---@field CountInterruptOverlaps fun() executed after the run is done, count the interrupt overlaps for each player
---@field CreateBossPortraitTexture fun(parent:frame, index:number) : bosswidget create a boss portrait texture widget
---@field CreateTimeSection fun(parent:frame, index:number) : timesection create a time section label
---@field IsScoreboardOpen fun() : boolean whether or not the scoreboard is shown in the screen
---@field GetVersionString fun() : string the version info of just this addon
---@field GetFullVersionString fun() : string the version info of details and this addon
---@field GetBloodlustUsage fun() : number[]? retrieves the time() in seconds when the player received bloodlust buff.
---@field GetSavedRuns fun() : runinfo[] return an array with all data from the saved runs
---@field GetLastRun fun() : runinfo return the run info for the last run finished
---@field GetDungeonRunsById fun(id:string|number) : runinfo[] return an array with run infos of all runs that match the dungeon name or dungeon id
---@field GetRunDate fun(runInfo:runinfo) : string return the date when the run ended in format of a string with hour:minute day as number/month as 3letters/year as number
---@field FormatRunDescription fun(runInfo:runinfo) : string returns the run description in a single string
---@field GetRunAverageItemLevel fun(runInfo:runinfo) : number return the average item level of the 5 players in the run
---@field GetRunAverageDamagePerSecond fun(runInfo:runinfo, timeType:combattimetype) : number return the average damage per second
---@field GetRunAverageHealingPerSecond fun(runInfo:runinfo, timeType:combattimetype) : number return the average healing per second
---@field GetRunInfoForHighestScoreById fun(id:string|number) : runinfo? return the runinfo with the highest score of all runs that match the dungeon name or dungeon id, nil if no dungeon found
---@field SetSelectedRunIndex fun(index:number) set the selected run index
---@field GetSelectedRunIndex fun() : number get the selected run index
---@field GetSelectedRun fun() : runinfo return the latest selected run info, return nil if there is no run info data
---@field RemoveRun fun(index:number) remove the run info from the saved runs
---@field GetDropdownRunDescription fun(runInfo:runinfo) : table indexed table containing: [1] dungeonName, [2] keyLevel, [3] runTime, [4] keyUpgradeLevels, [5] timeString, [6] onTime [7] mapId [8] dungeonId


---@class runinfo : table
---@field combatId number the dungeon overall data unique combat id from details!
---@field combatData combatdata stores the required combat data for the score board, hence the scoreboard can function even if the combat isn't available in details!
---@field encounters detailsmythicplus_encounterinfo[] the encounters timeline
---@field combatTimeline detailsmythicplus_combatstep[] the combat timeline
---@field completionInfo challengemodecompletioninfo
---@field timeWithoutDeaths number total time in seconds the run took without counting the time lost by player deaths
---@field timeInCombat number total time in seconds the run took in combat
---@field dungeonName string the name of the dungeon
---@field dungeonId number former DungeonID, this is the id from C_ChallengeMode.GetMapUIInfo
---@field dungeonTexture number gotten from the the 4th result of C_ChallengeMode.GetMapUIInfo
---@field dungeonBackgroundTexture number gotten from the the 5th result of C_ChallengeMode.GetMapUIInfo
---@field timeLimit number the time limit for the run in seconds
---@field startTime number the time() when the run started
---@field endTime number the time() when the run ended
---@field mapId number completionInfo.mapChallengeModeID or Details.challengeModeMapId or C_ChallengeMode.GetActiveChallengeMapID()

---@class challengemodecompletioninfo : table store the data from the GetChallengeCompletionInfo() plus some extra data
---@field mapChallengeModeID number the map id
---@field level number the keystone level
---@field time number seconds+milliseconds, could be nil if the run doesn't completes, need to be divided by 1000 to get the seconds
---@field onTime boolean true if the run finished on time
---@field keystoneUpgradeLevels number how many levels the keystone was upgraded (only possible if onTime is true)
---@field practiceRun boolean true if the run was a practice run
---@field oldOverallDungeonScore number the old score
---@field newOverallDungeonScore number the new score
---@field isEligibleForScore boolean true if the run is eligible for score
---@field isMapRecord boolean true if the run is a record for the map
---@field isAffixRecord boolean true if the run is a record for the affix
---@field members challengemodeplayerinfo[]> the players in the group

---@class challengemodeplayerinfo : table
---@field name string
---@field memberGUID string

---@class playerinfo : table information about a player from details!
---@field name string full name (with realm) if not is a cross realm player
---@field class class the classId (from 1 to 13) gotten from UniClass() thrid return
---@field spec number specialization id
---@field role role name of the role
---@field guid string the player guid
---@field activityTimeDamage number the time in seconds the player was in combat
---@field activityTimeHeal number the time in seconds the player was in combat
---@field score number mythic+ score
---@field scorePrevious number mythic+ score the player had at the start of the run
---@field ilevel number the average item level of the player
---@field loot string item link of the loot the player received
---@field deathEvents timeline_event[]
---@field totalDeaths number total deaths
---@field totalDamage number total damage done
---@field totalHeal number total damage done
---@field totalDamageTaken number total damage taken
---@field totalHealTaken number total damage taken
---@field totalDispels number total dispels
---@field totalInterrupts number total of sucessful interrupts
---@field totalInterruptsCasts number total amount of casts of interrupt spells
---@field totalCrowdControlCasts number total amount of casts of crowd control spells
---@field healDoneBySpells table<spellid, number>[] heal done by spells, a table with indexed subtables where the first index is the spellid and the second is the total heal done by that spell
---@field damageDoneBySpells table<spellid, number>[] damage done by spells, a table with indexed subtables where the first index is the spellid and the second is the total damage done by that spell
---@field damageTakenFromSpells spell_hit_player[] damage taken from spells
---@field dispelWhat table<spellid, number> which debuffs the player dispelled
---@field interruptWhat table<spellid, number> which spells the player interrupted
---@field interruptCastOverlapDone number how many times the player attempted to interrupt a spell with another player
---@field crowdControlSpells table<spellname, number> which spells the player casted that are crowd control

---@class combatdata : table
---@field groupMembers table<playername, playerinfo>

---@class fontsettings : table
---@field row_size number
---@field regular_color any
---@field regular_outline string
---@field hover_color any
---@field hover_outline string
---@field standout_color any
---@field standout_outline string

---@class detailsmythicplus_run_data : table
---@field map_id number
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

---@class activitytimeline_marker : frame
---@field SubFrames frame[]
---@field TimestampLabel frame
---@field TimestampBackground df_image
---@field LineTexture frame

---@class activitytimeline_marker_data : table
---@field forceDirection string|nil up or down
---@field preferUp boolean|nil when true it will initially try to render above the timeline

---@class activitytimeline : table
---@field markers activitytimeline_marker[]
---@field maxEvents number
---@field UpdateBossWidgets fun(self:scoreboard_activityframe, runData:runinfo, multiplier:number) update the boss widgets showing the kill time of each boss
---@field UpdateBloodlustWidgets fun(self:scoreboard_activityframe, runData:runinfo, multiplier:number) update the bloodlust widgets showing the time of bloodlust usage
---@field ResetSegmentTextures fun(self:scoreboard_activityframe) reset the next index of texture to use and hide all existing textures
---@field GetSegmentTexture fun(self:scoreboard_activityframe) : texture return a texture to be used as a segment of the activity bar
---@field RenderKeyFinishedMarker fun(frame:scoreboard_activityframe, event:timeline_event, marker:activitytimeline_marker) : activitytimeline_marker_data
---@field RenderDeathMarker fun(frame:scoreboard_activityframe, event:timeline_event, marker:activitytimeline_marker) : activitytimeline_marker_data
---@field PrepareEventFrames fun(frame:scoreboard_activityframe, events:timeline_event[]) : timeline_event, activitytimeline_marker

---@class scoreboard_activityframe : frame
---@field nextTextureIndex number
---@field segmentTextures texture[]
---@field bossWidgets bosswidget[]
---@field InCombatTexture texture
---@field OutOfCombatTexture texture
---@field BackgroundTexture texture
---@field SetActivity fun(self: scoreboard_activityframe, events: timeline_event[], runData: runinfo)
