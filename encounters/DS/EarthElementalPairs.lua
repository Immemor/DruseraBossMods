------------------------------------------------------------------------------
-- Client Lua Script for DruseraBossMods
--
-- Copyright (C) 2015 Thierry carré
--
-- Player Name: 'Immé sama'
-- Guild Name: 'Les Solaris'
-- Server Name: Jabbit(EU)
------------------------------------------------------------------------------

require "Apollo"
require "GameLib"

local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("EARTH_ELEMENTAL_PAIRS")

local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Megalith.
------------------------------------------------------------------------------
local Megalith = {}

function Megalith:OnStartCombat()
end

------------------------------------------------------------------------------
-- Pyrobane.
------------------------------------------------------------------------------
local Pyrobane = {}

function Pyrobane:OnStartCombat()
end

------------------------------------------------------------------------------
-- Mnemesis.
------------------------------------------------------------------------------
local Mnemesis = {}

function Mnemesis:OnStartCombat()
end

------------------------------------------------------------------------------
-- Aileron.
------------------------------------------------------------------------------
local Aileron = {}

function Aileron:OnStartCombat()
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, nil)
  self:RegisterTriggerNames({"MEGALITH", "PYROBANE", "MNEMESIS", "AILERON"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    MEGALITH = Megalith,
    PYROBANE = Pyrobane,
    MNEMESIS = Mnemesis,
    AILERON = Aileron,
  })
  self:RegisterEnglishLocale({
    ["EARTH_ELEMENTAL_PAIRS"] = "Earth Elemental Pairs",
    ["MEGALITH"] = "Megalith",
    ["PYROBANE"] = "Pyrobane",
    ["MNEMESIS"] = "Mnemesis",
    ["AILERON"] = "Aileron",
  })
  self:RegisterFrenchLocale({
    ["EARTH_ELEMENTAL_PAIRS"] = "Pairs Elémentaire de Terre",
    ["MEGALITH"] = "Megalith", -- TOCHECK
    ["PYROBANE"] = "Pyromagnus",
    ["MNEMESIS"] = "Mnemesis", -- TOCHECK
    ["AILERON"] = "Ventemort", -- TOCHECK
  })
end

function ENCOUNTER:OnEnable()
  self:ActivateDetection(true)
end
