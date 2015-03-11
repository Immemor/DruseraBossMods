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
L["PHASER_COMBO"] = "Phaser Combo"
L["GALERAS"] = "Galeras"
L["CRIMSON_SPIDERBOT"] = "Crimson Spiderbot"
L["CHECK_POINT"] = "Check Point"
L["PULL_IN"] = "Pull In"
L["INTERRUPT_THIS_CAST"] = "Interrupt this cast!"


-- Raid: Genetic Archives
L["GENETIC_ARCHIVE"] = "Genetic Archives"
L["GENETIC_ARCHIVE_ACT_1"] = "Genetic Archives - Act 1"
L["GENETIC_ARCHIVE_ACT_2"] = "Genetic Archives - Act 2"
------ Encounter: Experiment X-89
L["EXPERIMENT_X89"] = "Experiment X-89"
L["RESOUNDING_SHOUT"] = "Resounding Shout"
L["REPUGNANT_SPEW"] = "Repugnant Spew"
L["SHATTERING_SHOCKWAVE"] = "Shattering Shockwave"
L["CORRUPTION_GLOBULE"] = "Corruption Globule"
L["STRAIN_BOMB"] = "Strain Bomb"
L["MSG_SMALL_BOMB"] = "Small bomb! Go to the edge!"
L["MSG_BIG_BOMB"] = "BIG bomb! Jump down!"
------ Encounter: Kuralak the Defiler
L["KURALAK_THE_DEFILER"] = "Kuralak the Defiler"
L["CULTIVATE_CORRUPTION"] = "Cultivate Corruption"
L["CHROMOSOME_CORRUPTION"] = "Chromosome Corruption"
L["OUTBREAK"] = "Outbreak"
L["VANISH_INTO_DARKNESS"] = "Vanish into Darkness"
L["DNA_SIPHON"] = "DNA Siphon"
------ Encounter: Phage Maw
L["PHAGE_MAW"] = "Phage Maw"
L["DETONATION_BOMB"] = "Detonation Bomb"
L["DETONATION_BOMBS"] = "Detonation Bombs"
L["CRATER"] = "Crater"
L["AIR_PHASE"] = "Air phase"
L["BOMBS"] = "Bombs"
------ Encounter: Prototypes Phagetech
L["PHAGETECH_PROTOTYPES"] = "Phagetech Prototypes"
L["PHAGETECH_COMMANDER"] = "Phagetech Commander"
L["PHAGETECH_AUGMENTOR"] = "Phagetech Augmentor"
L["PHAGETECH_PROTECTOR"] = "Phagetech Protector"
L["PHAGETECH_FABRICATOR"] = "Phagetech Fabricator"
L["POWERING_UP"] = "Powering Up"
L["POWERING_DOWN"] = "Powering Down"
L["FORCED_PRODUCTION"] = "Forced Production"
L["DESTRUCTION_PROTOCOL"] = "Destruction Protocol"
L["MALICIOUS_UPLINK"] = "Malicious Uplink"
L["PHAGETECH_BORER"] = "Phagetech Borer"
L["SUMMON_REPAIRBOT"] = "Summon Repairbot"
L["PULSE_A_TRON_WAVE"] = "Pulse-A-Tron Wave"
L["GRAVITATIONAL_SINGULARITY"] = "Gravitational Singularity"
L["SUMMON_DESTRUCTOBOT"] = "Summon Destructobot"
L["TECHNOPHAGE_CATALYST"] = "Technophage Catalyst"
------ Encounter: Convergence
L["CONVERGENCE"] = "Convergence"
L["TERAX_BLIGHTWEAVER"] = "Terax Blightweaver"
L["GOLGOX_THE_LIFECRUSHER"] = "Golgox the Lifecrusher"
L["FLESHMONGER_VRATORG"] = "Fleshmonger Vratorg"
L["NOXMIND_THE_INSIDIOUS"] = "Noxmind the Insidious"
L["ERSOTH_CURSEFORM"] = "Ersoth Curseform"
L["TELEPORT"] = "Teleport"
L["STITCHING_STRAIN"] = "Stitching Strain"
L["DEMOLISH"] = "Demolish"
L["SCATTER"] = "Scatter"
L["ESSENCE_ROT"] = "Essence Rot"
L["EQUALIZE"] = "équalise"
L["NEXT_CONVERGENCE"] = "Next convergence"
------ Encounter: Dreadphage Ohmna
L["DREADPHAGE_OHMNA"] = "Dreadphage Ohmna"
L["BODY_SLAM"] = "Body Slam"
L["DEVOUR"] = "Devour"
L["GENETIC_TORRENT"] = "Genetic Torrent"

-- Raid: Datascape
L["DATASCAPE"] = "Datascape"
L["HALLS_OF_THE_INFINITE_MIND"] = "Halls of the Infinite Mind"
L["QUANTUM_VORTEX"] = "Quantum vortex"
------ Encounter: System Daemon
L["SYSTEM_DAEMON"] = "System Daemon"
L["NULL_SYSTEM_DAEMON"] = "Null System Daemon"
L["BINARY_SYSTEM_DAEMON"] = "Binary System Daemon"
L["DEFRAGMENTATION_UNIT"] = "Defragmentation Unit"
L["RADIATION_DISPERSION_UNIT"] = "Radiation Dispersion Unit"
L["PURGE"] = "Purge"
L["DISCONNECT"] = "Disconnect"
L["SOUTH_DAEMON"] = "South Daemon"
L["NORTH_DAEMON"] = "North Daemon"
L["INVALID_ACCESS_DETECTED"] = "INVALID ACCESS DETECTED."
L["INITIALIZING_LOWER_GENERATOR_ROOMS"] = "INITIALIZING LOWER GENERATOR ROOMS."
L["COMMENCING_ENHANCEMENT_SEQUENCE"] = "COMMENCING ENHANCEMENT SEQUENCE."
L["NEXT_ADD_WAVE"] = "Next Add Wave"
L["NEXT_DISCONNECT"] = "Next Disconnect"
L["NORTH_PURGE_NEXT"] = "[NORTH] Purge Next"
L["SOUTH_PURGE_NEXT"] = "[SOUTH] Purge Next"
L["PROBE_1"] = "Probe 1"
L["PROBE_2"] = "Probe 2"
L["PROBE_3"] = "Probe 3"
------ Encounter: (MiniBoss) Bio-Enhanced Broodmother
L["BIO_ENHANCED_BROODMOTHER"] = "Bio-Enhanced Broodmother"
L["AUGMENTED_BIO_WEB"] = "Augmented Bio-Web"
------ Encounter: (MiniBoss) Fully-Optimized Canimid
L["FULLY_OPTIMIZED_CANIMID"] = "Fully-Optimized Canimid"
L["UNDERMINE"] = "Undermine"
L["TERRAFORMATION"] = "Terra-forme" --<< XXX: check.
------ Encounter: (MiniBoss) Logic Guided Rockslide
L["LOGIC_GUIDED_ROCKSLIDE"] = "Logic Guided Rockslide"
------ Encounter: Gloomclaw
L["GLOOMCLAW"] = "Gloomclaw"
L["CORRUPTED_RAVAGER"] = "Corrupted Ravager"
L["EMPOWERED_RAVAGER"] = "Empowered Ravager"
L["STRAIN_PARASITE"] = "Strain Parasite"
L["GLOOMCLAW_SKURGE"] = "Gloomclaw Skurge"
L["CORRUPTED_FRAZ"] = "Corrupted Fraz"
L["RUPTURE"] = "Rupture"
L["ADDS_WAVE"] = "Adds wave"
L["DATACHRON_GLOOMCLAW_IS_REDUCED"] = "Gloomclaw is reduced to a weakened state!"
L["DATACHRON_GLOOMCLAW_IS_PUSHED_BACK"] = "Gloomclaw is pushed back by the purification of the essences!"
L["DATACHRON_GLOOMCLAW_IS_MOVING_FORWARD"] = "Gloomclaw is moving forward to corrupt more essences!"
L["GLOOMCLAW_IS_PUSHED_BACK"] = "Glooclaw is pushed back"
L["GLOOMCLAW_IS_MOVING_FORWARD"] = "Glooclaw is moving forward"
L["CORRUPTING_RAYS"] = "Corrupting Rays"
L["INTERRUPT_CORRUPTING_RAYS"] = "Interrupt: Corrupting Rays !"
------ Encounter: Maelstrom Authority
L["MAELSTROM_AUTHORITY"] = "Maelstrom Authority"
L["THE_PLATFORM_SHAKES"] = "The platform shakes !"
L["NEXT_PLATFORM_SHAKES"] = "Next platform shakes"
------ Encounter: Volatility Lattice
L["VOLATILITY_LATTICE"] = "Volatility Lattice"
------ Encounter: Limbo Infomatrix
L["LIMBO_INFOMATRIX"] = "Limbo Infomatrix"
L["KEEPER_OF_SANDS"] = "Keeper Of Sands"
L["INFOMATRIX_ANTLION"] = "Infomatrix Antlion"
L["CAST_EXHAUST"] = "Exhaust"
L["MSG_WARNING_KNOCKBACK"] = "Warning: Knock-Back"
------ Encounter: Avatus
L["AVATUS"] = "Avatus"


------- Graphic User Interface
L["HEALTH_BARS"] = "Health bars"
L["HIGHLIGHT_TIMERS"] = "Highlight Timers"
L["TIMER_BARS"] = "Timers"
L["HIGHLIGHT_MESSAGES"] = "Highlight Messages"
L["MESSAGES"] = "Messages"
L["THIS_SHOULD_BE_1"] = "This should be 1"
L["THIS_SHOULD_BE_2"] = "This should be 2"
L["THIS_SHOULD_BE_3"] = "This should be 3"
L["THIS_SHOULD_BE_4"] = "This should be 4"
L["ARE_YOU_READY"] = "Are you ready ?"
L["WELCOME_IN_DBM"] = "Welcome in DruseraBossMods"
L["YOU_ARE_DEATH_AGAIN"] = "You are death, again ..."
L["END_OF_TEST"] = "End of test"
