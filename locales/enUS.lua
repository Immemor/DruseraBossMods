------------------------------------------------------------------------------
-- Client Lua Script for DruseraBossMods
--
-- Copyright (C) 2015 Thierry carré
--
-- Player Name: 'Immé sama'
-- Guild Name: 'Les Solaris'
-- Server Name: Jabbit(EU)
------------------------------------------------------------------------------

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local L = GeminiLocale:NewLocale("DruseraBossMods", "enUS")
if not L then return end

------------------------------------------------------------------------------
-- English.
------------------------------------------------------------------------------

-- Graphic User Interface:
---- Top Menu
L["START_TEST"] = "Start Test"
L["TOGGLE_ANCHORS"] = "Toggle Anchors"
L["RESET_ANCHORS"] = "Reset Anchors"
---- Left Menu
L["HOME"] = "Home"
L["BARS"] = "Bars"
L["SOUNDS"] = "Sounds"
L["MARKERS"] = "Markers"
L["BOSSES"] = "Bosses"
---- Bar Customization
L["HIGHLIGHT"] = "Highlight"
L["BAR_CUSTOMIZATION"] = "Bar Customization"
L["SOUND_CUSTOMIZATION"] = "Sound Customization"
L["INVERSE_SORT"] = "Invert sort"
L["ALIGN_TO_THE_BOTTOM_FRAME"] = "Align to the bottom's frame"
L["FILL_WITH_COLOR"] = "Fill with color"
L["DISPLAY_TIME"] = "Display time"
L["BAR_HEIGHT"] = "Bar's height"
L["TEXTURE"] = "Texture"
L["THRESHOLD_TO_MOVE_FROM_NORMAL_TO_HIGHLIGHT"] = "Threshold to move from normal to highlight"
L["FONT"] = "Font"
L["MUTE_ALL_SOUND"] = "Mute all sounds"
L["ENCOUNTER_LOG"] = "Encounter's log"


-- For testing.
L["PULL_IN"] = "Pull In"
L["INTERRUPT_THIS_CAST"] = "Interrupt this cast!"
L["THIS_SHOULD_BE_1"] = "This should be 1"
L["THIS_SHOULD_BE_2"] = "This should be 2"
L["THIS_SHOULD_BE_3"] = "This should be 3"
L["THIS_SHOULD_BE_4"] = "This should be 4"

-- Raid: Genetic Archives
L["GENETIC_ARCHIVE"] = "Genetic Archives"
L["GENETIC_ARCHIVE_ACT_1"] = "Genetic Archives - Act 1"
L["GENETIC_ARCHIVE_ACT_2"] = "Genetic Archives - Act 2"
-- Raid: Datascape
L["DATASCAPE"] = "Datascape"
L["HALLS_OF_THE_INFINITE_MIND"] = "Halls of the Infinite Mind"
L["QUANTUM_VORTEX"] = "Quantum vortex"
------ Encounter: Avatus
L["AVATUS"] = "Avatus"

------- Graphic User Interface
L["HEALTH_BARS"] = "Health bars"
L["HIGHLIGHT_TIMERS"] = "Highlight Timers"
L["TIMER_BARS"] = "Timers"
L["HIGHLIGHT_MESSAGES"] = "Highlight Messages"
L["MESSAGES"] = "Messages"
L["ARE_YOU_READY"] = "Are you ready ?"
L["WELCOME_IN_DBM"] = "Welcome in DruseraBossMods"
L["YOU_ARE_DEATH_AGAIN"] = "You are death, again ..."
L["END_OF_TEST"] = "End of test"
