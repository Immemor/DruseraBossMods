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
local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("SYSTEM_DAEMON")

local GetPlayerUnit = GameLib.GetPlayerUnit
local BinarySystemDaemon = {}
local NullSystemDaemon = {}
local DefragmentationUnit = {}
local RadiationDispersionUnit = {}
local _nWaveCount
local _nPhase

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
local function GetNextWaveLabel()
  local sLabel = "NEXT_WAVE_ADD"
  if _nWaveCount > 2 and (_nWaveCount % 2)  == 0 then
    sLabel = "NEXT_WAVE_MINIBOSS"
  end
  return sLabel
end

local function NewAddWave(self)
  _nWaveCount = _nWaveCount + 1
  self:PlaySound("Info")
  self:SetTimer(GetNextWaveLabel(), 50, NewAddWave)
  self:SetTimer("PROBE_1", 10, function(self)
    self:SetTimer("PROBE_2", 10, function(self)
      self:SetTimer("PROBE_3", 10)
    end)
  end)
end

------------------------------------------------------------------------------
-- Bosses functions.
------------------------------------------------------------------------------
function BinarySystemDaemon:OnStartCombat()
  _nWaveCount = 0
  _nPhase = 1
  self:CreateHealthBar("NORTH_DAEMON")
  -- Next disconnect.
  self:SetCastEnd("DISCONNECT", function(self)
    self:SetTimer("NEXT_DISCONNECT", 55)
  end)
  -- Pillar phase.
  self:SetDatachronAlert("COMMENCING_ENHANCEMENT_SEQUENCE", function(self)
    _nPhase = _nPhase + 1
    self:ClearAllTimerAlert()
    self:SetTimer(GetNextWaveLabel(), 95, NewAddWave)
    self:SetTimer("NEXT_DISCONNECT", 86)
  end)
  -- Initialization.
  self:SetTimer("NEXT_DISCONNECT", 43)
  self:SetTimer(GetNextWaveLabel(), 15, NewAddWave)
  -- Next Purge on Null System Daemon.
  self:SetCastEnd("PURGE", function(self)
    self:SetTimer("SOUTH_PURGE_NEXT", 13)
  end)
end

function NullSystemDaemon:OnStartCombat()
  self:CreateHealthBar("SOUTH_DAEMON")
  -- Next disconnect event.
  self:SetCastEnd("DISCONNECT", function(self)
    self:SetTimer("NEXT_DISCONNECT", 55)
  end)
  -- Next Purge on Binary System Daemon
  self:SetCastEnd("PURGE", function(self)
    self:SetTimer("NORTH_PURGE_NEXT", 13)
  end)
end

function DefragmentationUnit:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastStart("CAST_BLACK_IC", function(self)
    local d = self:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
    if d and d < 35 then
      self:PlaySound("Alert")
    end
  end)
end

function RadiationDispersionUnit:OnStartCombat()
  self:CreateHealthBar()
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 105)
  self:RegisterTriggerNames({"BINARY_SYSTEM_DAEMON", "NULL_SYSTEM_DAEMON"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    BINARY_SYSTEM_DAEMON = BinarySystemDaemon, --North boss
    NULL_SYSTEM_DAEMON = NullSystemDaemon, -- South boss
    DEFRAGMENTATION_UNIT = DefragmentationUnit, -- Miniboss
    RADIATION_DISPERSION_UNIT = RadiationDispersionUnit, -- Miniboss
  })
  self:RegisterEnglishLocale({
    ["SYSTEM_DAEMON"] = "System Daemon",
    ["NULL_SYSTEM_DAEMON"] = "Null System Daemon",
    ["BINARY_SYSTEM_DAEMON"] = "Binary System Daemon",
    ["DEFRAGMENTATION_UNIT"] = "Defragmentation Unit",
    ["RADIATION_DISPERSION_UNIT"] = "Radiation Dispersion Unit",
    ["PURGE"] = "Purge",
    ["DISCONNECT"] = "Disconnect",
    ["SOUTH_DAEMON"] = "South Daemon",
    ["NORTH_DAEMON"] = "North Daemon",
    ["INVALID_ACCESS_DETECTED"] = "INVALID ACCESS DETECTED.",
    ["INITIALIZING_LOWER_GENERATOR_ROOMS"] = "INITIALIZING LOWER GENERATOR ROOMS.",
    ["COMMENCING_ENHANCEMENT_SEQUENCE"] = "COMMENCING ENHANCEMENT SEQUENCE.",
    ["NEXT_WAVE_ADD"] = "Next wave: Adds",
    ["NEXT_WAVE_MINIBOSS"] = "Next wave: Miniboss",
    ["NEXT_DISCONNECT"] = "Next Disconnect",
    ["NORTH_PURGE_NEXT"] = "[NORTH] Purge Next",
    ["SOUTH_PURGE_NEXT"] = "[SOUTH] Purge Next",
    ["CAST_BLACK_IC"] = "Black IC",
    ["PROBE_1"] = "Probe 1",
    ["PROBE_2"] = "Probe 2",
    ["PROBE_3"] = "Probe 3",
  })
  self:RegisterFrenchLocale({
    ["SYSTEM_DAEMON"] = "Système Daemon",
    ["NULL_SYSTEM_DAEMON"] = "Daemon 1.0",
    ["BINARY_SYSTEM_DAEMON"] = "Daemon 2.0",
    ["DEFRAGMENTATION_UNIT"] = "Unité de défragmentation",
    ["RADIATION_DISPERSION_UNIT"] = "Unité de dispersion de radiations",
    ["PURGE"] = "Purge",
    ["DISCONNECT"] = "Déconnecté",
    ["SOUTH_DAEMON"] = "Sud Daemon",
    ["NORTH_DAEMON"] = "Nord Daemon",
    ["INVALID_ACCESS_DETECTED"] = "ACCÈS NON AUTORISÉ DÉTECTÉ.",
    ["INITIALIZING_LOWER_GENERATOR_ROOMS"] = "INITIALISATION DES SALLES DU GÉNÉRATEUR INFÉRIEUR.",
    ["COMMENCING_ENHANCEMENT_SEQUENCE"] = "ACTIVATION DE LA SÉQUENCE D'AMÉLIORATION.",
    ["NEXT_WAVE_ADD"] = "Prochaine vague: Adds",
    ["NEXT_WAVE_MINIBOSS"] = "Prochaine vague: Miniboss",
    ["NEXT_DISCONNECT"] = "Prochaine déconnexion",
    ["NORTH_PURGE_NEXT"] = "[NORD] Prochaine Purge",
    ["SOUTH_PURGE_NEXT"] = "[SUD] Prochaine Purge",
    ["CAST_BLACK_IC"] = "Black IC", --<< TO CHECK
    ["PROBE_1"] = "Sonde 1",
    ["PROBE_2"] = "Sonde 2",
    ["PROBE_3"] = "Sonde 3",
  })
  self:RegisterTimer("NEXT_DISCONNECT", { color = "xkcdBrightPurple" })
  self:RegisterTimer("NEXT_WAVE_ADD", { color = "xkcdBrightOrange" })
  self:RegisterTimer("NEXT_WAVE_MINIBOSS", { color = "xkcdBrightOrange" })
  self:RegisterTimer("PROBE_1", { color = "xkcdBrightYellow" })
  self:RegisterTimer("PROBE_2", { color = "xkcdBrightYellow" })
  self:RegisterTimer("PROBE_3", { color = "xkcdBrightYellow" })
  self:RegisterTimer("SOUTH_PURGE_NEXT", { color = "xkcdBrightGreen" })
  self:RegisterTimer("NORTH_PURGE_NEXT", { color = "xkcdBrightGreen" })
end
