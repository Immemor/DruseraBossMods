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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("LIFE_ELEMENTAL_PAIRS")

local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Visceralus.
------------------------------------------------------------------------------
local Visceralus = {}

function Visceralus:OnStartCombat()
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
  self:RegisterTriggerNames({"VISCERALUS"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    VISCERALUS = Visceralus,
    PYROBANE = Pyrobane,
    MNEMESIS = Mnemesis,
    AILERON = Aileron,
  })
  self:RegisterEnglishLocale({
    ["LIFE_ELEMENTAL_PAIRS"] = "Life Elemental Pairs",
    ["VISCERALUS"] = "Visceralus",
    ["PYROBANE"] = "Pyrobane",
    ["MNEMESIS"] = "Mnemesis",
    ["AILERON"] = "Aileron",
  })
  self:RegisterFrenchLocale({
    ["LIFE_ELEMENTAL_PAIRS"] = "Pairs Elémentaire de Vie",
    ["VISCERALUS"] = "Visceralus", -- TOCHECK
    ["PYROBANE"] = "Pyromagnus",
    ["MNEMESIS"] = "Mnemesis", -- TOCHECK
    ["AILERON"] = "Ventemort",
  })
end

function ENCOUNTER:OnEnable()
  self:ActivateDetection(true)
end
