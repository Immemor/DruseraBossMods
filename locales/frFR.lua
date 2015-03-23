------------------------------------------------------------------------------
-- Client Lua Script for DruseraBossMods
--
-- Copyright (C) 2015 Thierry carré
--
-- Player Name: 'Immé sama'
-- Guild Name: 'Les Solaris'
-- Server Name: Jabbit(EU)
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Be careful with Apollo editor from carbine, this last don't manage UTF-8.
-- And the game expected UTF-8 string. I recommend Notepad++ for lua or vim.
------------------------------------------------------------------------------

local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local L = GeminiLocale:NewLocale("DruseraBossMods", "frFR")
if not L then return end

------------------------------------------------------------------------------
-- French / Francais.
------------------------------------------------------------------------------

-- Graphic User Interface:
---- Top Menu
L["START_TEST"] = "Début du Test"
L["TOGGLE_ANCHORS"] = "Inverser les Ancres"
L["RESET_ANCHORS"] = "Réinitialiser les Ancres"
---- Left Menu
L["HOME"] = "Accueil"
L["BARS"] = "Barres"
L["SOUNDS"] = "Sons"
L["MARKERS"] = "Marqueurs"
L["BOSSES"] = "Bosses"
---- Bar Customization
L["HIGHLIGHT"] = "Evidence"
L["BAR_CUSTOMIZATION"] = "Personnalisation des Barres"
L["SOUND_CUSTOMIZATION"] = "Personnalisation des sons"
L["INVERSE_SORT"] = "Inverser l'ordre de tri"
L["ALIGN_TO_THE_BOTTOM_FRAME"] = "Aligner sur le bas du cadre"
L["FILL_WITH_COLOR"] = "Remplir avec de la couleur"
L["DISPLAY_TIME"] = "Afficher le temps"
L["BAR_HEIGHT"] = "Hauteur d'une barre"
L["TEXTURE"] = "Texture"
L["THRESHOLD_TO_MOVE_FROM_NORMAL_TO_HIGHLIGHT"] = "Seuil pour basculer de normal à évidence"
L["FONT"] = "Police"
L["MUTE_ALL_SOUND"] = "Couper tous les sons"
L["ENCOUNTER_LOG"] = "Log de la rencontre"


-- For testing.
L["PULL_IN"] = "Pull In"
L["INTERRUPT_THIS_CAST"] = "Coupez ce sort!"
L["THIS_SHOULD_BE_1"] = "Cela devrait être 1"
L["THIS_SHOULD_BE_2"] = "Cela devrait être 2"
L["THIS_SHOULD_BE_3"] = "Cela devrait être 3"
L["THIS_SHOULD_BE_4"] = "Cela devrait être 4"


-- Raid: Genetic Archives
L["GENETIC_ARCHIVE"] = "Archives Génétiques"
L["GENETIC_ARCHIVE_ACT_1"] = "Archives génétiques - Acte 1"
L["GENETIC_ARCHIVE_ACT_2"] = "Archives génétiques - Acte 2"
-- Raid: Datascape
L["DATASCAPE"] = "Datascape"
L["HALLS_OF_THE_INFINITE_MIND"] = "Salles de l'Esprit infini"
L["QUANTUM_VORTEX"] = "Vortex quantique"
------ Encounter: Avatus
L["AVATUS"] = "Avatus"

------- Graphic User Interface
L["HEALTH_BARS"] = "Barres de PV"
L["HIGHLIGHT_TIMERS"] = "Barres en évidence"
L["TIMER_BARS"] = "Barres"
L["HIGHLIGHT_MESSAGES"] = "Messages en évidence"
L["MESSAGES"] = "Messages"
L["WELCOME_IN_DBM"] = "Bienvenu dans DruseraBossMods"
L["ARE_YOU_READY"] = "Es-tu prêt ?"
L["YOU_ARE_DEATH_AGAIN"] = "Tu es mort, encore ..."
L["END_OF_TEST"] = "Fin du test"
