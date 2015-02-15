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
local ExperimentX89 = {}
local PhagetechCommander = {}
local PhagetechAugmentor = {}
local PhagetechProtector = {}
local PhagetechFabricator = {}

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function PhagetechCommander:OnStartCombat()
  DBM:SetCastStartAlert(self, "FORCED_PRODUCTION", function(self)
    DBM:SetTimerAlert(self, "FORCED_PRODUCTION", 36, nil)
  end)
  DBM:SetCastStartAlert(self, "DESTRUCTION_PROTOCOL", function(self)
    DBM:SetTimerAlert(self, "DESTRUCTION_PROTOCOL", 17, nil)
  end)
  DBM:SetCastStartAlert(self, "MALICIOUS_UPLINK", function(self)
    DBM:SetTimerAlert(self, "MALICIOUS_UPLINK", 5, nil)
  end)
end

function PhagetechAugmentor:OnStartCombat()
  DBM:SetCastStartAlert(self, "PHAGETECH_BORER", function(self)
    DBM:SetTimerAlert(self, "PHAGETECH_BORER", 17, nil)
  end)
  DBM:SetCastStartAlert(self, "SUMMON_REPAIRBOT", function(self)
    DBM:SetTimerAlert(self, "SUMMON_REPAIRBOT", 17, nil)
  end)
end

function PhagetechProtector:OnStartCombat()
  DBM:SetCastStartAlert(self, "PULSE_A_TRON_WAVE", function(self)
    DBM:SetTimerAlert(self, "PULSE_A_TRON_WAVE", 15, nil)
  end)
end

function PhagetechFabricator:OnStartCombat()
  DBM:SetCastStartAlert(self, "SUMMON_DESTRUCTOBOT", function(self)
    DBM:SetTimerAlert(self, "SUMMON_DESTRUCTOBOT", 16, nil)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "GENETIC_ARCHIVE",
    EncounterName = "PHAGETECH_PROTOTYPES",
    ZoneName = "GENETIC_ARCHIVE_ACT_2",
  },{
    PHAGETECH_COMMANDER = PhagetechCommander,
    PHAGETECH_AUGMENTOR = PhagetechAugmentor,
    PHAGETECH_PROTECTOR = PhagetechProtector,
    PHAGETECH_FABRICATOR = PhagetechFabricator,
  },{
    PHAGETECH_COMMANDER = {
      BarsCustom = {
        FORCED_PRODUCTION = { color = "xkcdBrightOrange" },
        DESTRUCTION_PROTOCOL = { color = "xkcdBrightOrange" },
        MALICIOUS_UPLINK = { color = "xkcdBrightOrange" },
      },
    },
    PHAGETECH_AUGMENTOR = {
      BarsCustom = {
        PHAGETECH_BORER = { color = "xkcdBrightPurple" },
        SUMMON_REPAIRBOT = { color = "xkcdBrightPurple" },
      },
    },
    PHAGETECH_PROTECTOR = {
      BarsCustom = {
        PULSE_A_TRON_WAVE = { color = "xkcdBrightGreen" },
      },
    },
    PHAGETECH_FABRICATOR = {
      BarsCustom = {
        SUMMON_DESTRUCTOBOT = { color = "xkcdBrightPink" },
      },
    },
  })
end
