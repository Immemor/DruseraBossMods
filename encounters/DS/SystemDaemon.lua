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
local DBM = Apollo.GetAddon("DruseraBossMods")
local BinarySystemDaemon = {}
local NullSystemDaemon = {}
local DefragmentationUnit = {}
local RadiationDispersionUnit = {}

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
function NewAddWave(self)
  DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 50, NewAddWave)
  DBM:SetTimerAlert(self, "PROBE_1", 10, function(self)
    DBM:SetTimerAlert(self, "PROBE_2", 10, function(self)
      DBM:SetTimerAlert(self, "PROBE_3", 10, nil)
    end)
  end)
end

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function BinarySystemDaemon:OnStartCombat()
  -- Next disconnect.
  DBM:SetCastSuccessAlert(self, "DISCONNECT",
  function(self)
    DBM:SetTimerAlert(self, "NEXT_DISCONNECT", 55, nil)
  end)
  -- Pillar phase.
  DBM:SetDatachronAlert(self, "COMMENCING_ENHANCEMENT_SEQUENCE",
  function(self)
    DBM:ClearAllTimerAlert()
    DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 95, NewAddWave)
    DBM:SetTimerAlert(self, "NEXT_DISCONNECT", 86, nil)
  end)
  -- Initialization.
  DBM:SetTimerAlert(self, "NEXT_DISCONNECT", 43, nil)
  DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 15, NewAddWave)
  -- Next Purge on Null System Daemon.
  DBM:SetCastSuccessAlert(self, "PURGE", function(self)
    DBM:SetTimerAlert(self, "SOUTH_PURGE_NEXT", 13, nil)
  end)
end

function NullSystemDaemon:OnStartCombat()
  -- Next disconnect event.
  DBM:SetCastSuccessAlert(self, "DISCONNECT",
  function(self)
    DBM:SetTimerAlert(self, "NEXT_DISCONNECT", 55, nil)
  end)
  -- Next Purge on Binary System Daemon
  DBM:SetCastSuccessAlert(self, "PURGE", function(self)
    DBM:SetTimerAlert(self, "NORTH_PURGE_NEXT", 13, nil)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "DATASCAPE",
    EncounterName = "SYSTEM_DAEMON",
    ZoneName = "HALLS_OF_THE_INFINITE_MIND",
  },{
    BINARY_SYSTEM_DAEMON = BinarySystemDaemon, --North boss
    NULL_SYSTEM_DAEMON = NullSystemDaemon, -- South boss
    DEFRAGMENTATION_UNIT = DefragmentationUnit, -- Miniboss
    RADIATION_DISPERSION_UNIT = RadiationDispersionUnit, -- Miniboss
  },{
    BINARY_SYSTEM_DAEMON = {
      DisplayName = "NORTH_DAEMON",
      BarsCustom = {
        NEXT_DISCONNECT = { color = "xkcdBrightPurple" },
        NEXT_ADD_WAVE = { color = "xkcdBrightOrange" },
        PROBE_1 = { color = "xkcdBrightYellow" },
        PROBE_2 = { color = "xkcdBrightYellow" },
        PROBE_3 = { color = "xkcdBrightYellow" },
        SOUTH_PURGE_NEXT = { color = "xkcdBrightGreen" },
      },
    },
    NULL_SYSTEM_DAEMON = {
      DisplayName = "SOUTH_DAEMON",
      BarsCustom = {
        NORTH_PURGE_NEXT = { color = "xkcdBrightGreen" },
      },
    },
  })
end
