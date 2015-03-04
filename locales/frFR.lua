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

-- For testing.
L["PHASER_COMBO"] = "Combo de phaser"
L["GALERAS"] = "Khamsin"
L["CRIMSON_SPIDERBOT"] = "Arachnobot écarlate"
L["CHECK_POINT"] = "Point de vérification"
L["PULL_IN"] = "Pull In"
L["INTERRUPT_THIS_CAST"] = "Coupez ce sort!"


-- Raid: Genetic Archives
L["GENETIC_ARCHIVE"] = "Archives Génétiques"
L["GENETIC_ARCHIVE_ACT_1"] = "Archives génétiques - Acte 1"
L["GENETIC_ARCHIVE_ACT_2"] = "Archives génétiques - Acte 2"
------ Encounter: Experiment X-89
L["EXPERIMENT_X89"] = "Expérience X-89"
L["RESOUNDING_SHOUT"] = "Hurlement retentissant"
L["REPUGNANT_SPEW"] = "Crachat répugnant"
L["SHATTERING_SHOCKWAVE"] = "Onde de choc dévastatrice"
L["CORRUPTION_GLOBULE"] = "Globule de corruption"
L["STRAIN_BOMB"] = "Bombe de Souillure"
L["MSG_SMALL_BOMB"] = "Petite bombe! Allez au bord!"
L["MSG_BIG_BOMB"] = "Grosse bombe! Sautez!"
------ Encounter: Kuralak the Defiler
L["KURALAK_THE_DEFILER"] = "Kuralak la Profanatrice"
L["CULTIVATE_CORRUPTION"] = "Nourrir la corruption"
L["CHROMOSOME_CORRUPTION"] = "Corruption chromosomique"
L["OUTBREAK"] = "Invasion"
L["VANISH_INTO_DARKNESS"] = "Disparaître dans les ténèbres"
L["DNA_SIPHON"] = "Siphon DNA" -- TODO: Check needed.
------ Encounter: Phage Maw
L["PHAGE_MAW"] = "Phagegueule"
L["DETONATION_BOMB"] = "Bombe à détonateur"
L["DETONATION_BOMBS"] = "Bombes explosives"
L["CRATER"] = "Cratère"
L["AIR_PHASE"] = "phase air"
L["BOMBS"] = "Bombes"
------ Encounter: Prototypes Phagetech
L["PHAGETECH_PROTOTYPES"] = "Prototypes Phagetech"
L["PHAGETECH_COMMANDER"] = "Commandant technophage"
L["PHAGETECH_AUGMENTOR"] = "Augmenteur technophage"
L["PHAGETECH_PROTECTOR"] = "Protecteur technophage"
L["PHAGETECH_FABRICATOR"] = "Fabricant technophage"
L["POWERING_UP"] = "Mise en marche"
L["POWERING_DOWN"] = "Coupure de courant"
L["FORCED_PRODUCTION"] = "Production forcée"
L["DESTRUCTION_PROTOCOL"] = "Protocole de destruction"
L["MALICIOUS_UPLINK"] = "Liaison railleuse"
L["PHAGETECH_BORER"] = "Foreuse technophage"
L["SUMMON_REPAIRBOT"] = "Déployer Bricobot"
L["PULSE_A_TRON_WAVE"] = "Vague pulsatomique"
L["GRAVITATIONAL_SINGULARITY"] = "Singularité gravitationnelle"
L["SUMMON_DESTRUCTOBOT"] = "Déployer Destructobot"
L["TECHNOPHAGE_CATALYST"] = "Catalyse technophage"
------ Encounter: Convergence
L["CONVERGENCE"] = "Convergence"
L["TERAX_BLIGHTWEAVER"] = "Terax Tisserouille"
L["GOLGOX_THE_LIFECRUSHER"] = "Golgox le Fossoyeur"
L["FLESHMONGER_VRATORG"] = "Vratorg le Cannibale"
L["NOXMIND_THE_INSIDIOUS"] = "Toxultime l'Insidieux"
L["ERSOTH_CURSEFORM"] = "Ersoth le Maudisseur"
L["TELEPORT"] = "Se téléporter"
L["STITCHING_STRAIN"] = "Pression de suture"
L["DEMOLISH"] = "Démolir"
L["SCATTER"] = "Disperser"
L["ESSENCE_ROT"] = "Pourriture d'essence"
L["EQUALIZE"] = "équalise"
L["NEXT_CONVERGENCE"] = "Prochaine convergence"
------ Encounter: Dreadphage Ohmna
L["DREADPHAGE_OHMNA"] = "Ohmna la Terriphage"
L["BODY_SLAM"] = "Coup corporel"
L["DEVOUR"] = "Dévorer"
L["GENETIC_TORRENT"] = "Torrent génétique"

-- Raid: Datascape
L["DATASCAPE"] = "Datascape"
L["HALLS_OF_THE_INFINITE_MIND"] = "Salles de l'Esprit infini"
L["QUANTUM_VORTEX"] = "Vortex quantique"
------ Encounter: System Daemon
L["SYSTEM_DAEMON"] = "Système Daemon"
L["NULL_SYSTEM_DAEMON"] = "Daemon 1.0"
L["BINARY_SYSTEM_DAEMON"] = "Daemon 2.0"
L["DEFRAGMENTATION_UNIT"] = "Unité de défragmentation"
L["RADIATION_DISPERSION_UNIT"] = "Unité de dispersion de radiations"
L["PURGE"] = "Purge"
L["DISCONNECT"] = "Déconnecté"
L["SOUTH_DAEMON"] = "Sud Daemon"
L["NORTH_DAEMON"] = "Nord Daemon"
L["INVALID_ACCESS_DETECTED"] = "ACCÈS NON AUTORISÉ DÉTECTÉ."
L["INITIALIZING_LOWER_GENERATOR_ROOMS"] = "INITIALISATION DES SALLES DU GÉNÉRATEUR INFÉRIEUR."
L["COMMENCING_ENHANCEMENT_SEQUENCE"] = "ACTIVATION DE LA SÉQUENCE D'AMÉLIORATION."
L["NEXT_ADD_WAVE"] = "Prochaine vague d'add"
L["NEXT_DISCONNECT"] = "Prochaine déconnexion"
L["NORTH_PURGE_NEXT"] = "[NORD] Prochaine Purge"
L["SOUTH_PURGE_NEXT"] = "[SUD] Prochaine Purge"
L["PROBE_1"] = "Sonde 1"
L["PROBE_2"] = "Sonde 2"
L["PROBE_3"] = "Sonde 3"
------ Encounter: (MiniBoss) Bio-Enhanced Broodmother
L["BIO_ENHANCED_BROODMOTHER"] = "Mère de couvée augmentée"
L["AUGMENTED_VENOM"] = "Bio-soie augmentée"
------ Encounter: (MiniBoss) Fully-Optimized Canimid
L["FULLY_OPTIMIZED_CANIMID"] = "Canimide entièrement optimisé"
L["UNDERMINE"] = "Ébranler"
L["TERRAFORMATION"] = "Terra-forme"
------ Encounter: (MiniBoss) Logic Guided Rockslide
L["LOGIC_GUIDED_ROCKSLIDE"] = "Éboulement guidé par la logique"
------ Encounter: Gloomclaw
L["GLOOMCLAW"] = "Serrenox"
L["CORRUPTED_RAVAGER"] = "Ravageur corrompu"
L["EMPOWERED_RAVAGER"] = "Ravageur renforcé"
L["STRAIN_PARASITE"] = "Parasite de la Souillure"
L["GLOOMCLAW_SKURGE"] = "Skurge serrenox"
L["CORRUPTED_FRAZ"] = "Friz corrumpu"
L["RUPTURE"] = "Rupture"
L["ADDS_WAVE"] = "Vague d'adds"
L["DATACHRON_GLOOMCLAW_IS_REDUCED"] = "Serrenox a été affaibli !"
L["DATACHRON_GLOOMCLAW_IS_PUSHED_BACK"] = "Serrenox est repoussé par la purification des essences !"
L["DATACHRON_GLOOMCLAW_IS_MOVING_FORWARD"] = "Serrenox s'approche pour corrompre davantage d'essences !"
L["GLOOMCLAW_IS_PUSHED_BACK"] = "Serrenox est repoussé"
L["GLOOMCLAW_IS_MOVING_FORWARD"] = "Serrenox s'approche"
L["CORRUPTING_RAYS"] = "Rayons de corruption"
L["INTERRUPT_CORRUPTING_RAYS"] = "Coupez: Rayons Corrompus !"
------ Encounter: Maelstrom Authority
L["MAELSTROM_AUTHORITY"] = "Contrôleur du Maelstrom"
L["THE_PLATFORM_SHAKES"] = "La plateforme tremble !"
L["NEXT_PLATFORM_SHAKES"] = "Prochain tremblement de plateforme"
------ Encounter: Volatility Lattice
L["VOLATILITY_LATTICE"] = "Volatility Lattice"
------ Encounter: Limbo Infomatrix
L["LIMBO_INFOMATRIX"] = "Limbo Infomatrix"
------ Encounter: Avatus
L["AVATUS"] = "Avatus"


------- Graphic User Interface
L["HEALTH_BARS"] = "Barres de PV"
L["HIGHLIGHT_TIMERS"] = "Barres en évidence"
L["TIMER_BARS"] = "Barres"
L["HIGHLIGHT_MESSAGES"] = "Messages en évidence"
L["MESSAGES"] = "Messages"
L["THIS_SHOULD_BE_1"] = "Cela devrait être 1"
L["THIS_SHOULD_BE_2"] = "Cela devrait être 2"
L["THIS_SHOULD_BE_3"] = "Cela devrait être 3"
L["THIS_SHOULD_BE_4"] = "Cela devrait être 4"
L["WELCOME_IN_DBM"] = "Bienvenu dans DruseraBossMods"
L["ARE_YOU_READY"] = "Es-tu prêt ?"
L["YOU_ARE_DEATH_AGAIN"] = "Tu es mort, encore ..."
L["END_OF_TEST"] = "Fin du test"
