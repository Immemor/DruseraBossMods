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

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function ExperimentX89:OnStartCombat()
  DBM:SetCastStartAlert(self, "RESOUNDING_SHOUT", function(self)
    DBM:SetTimerAlert(self, "RESOUNDING_SHOUT", 25, nil)
  end)

  DBM:SetCastStartAlert(self, "REPUGNANT_SPEW", function(self)
    DBM:SetTimerAlert(self, "REPUGNANT_SPEW", 38, nil)
  end)

  DBM:SetCastStartAlert(self, "SHATTERING_SHOCKWAVE", function(self)
    DBM:SetTimerAlert(self, "SHATTERING_SHOCKWAVE", 19, nil)
  end)

  -- Initialization.
  DBM:SetTimerAlert(self, "RUN", 10, nil)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "GENETIC_ARCHIVE",
    EncounterName = "EXPERIMENT_X89",
    ZoneName = "GENETIC_ARCHIVE_ACT_1",
  },{
    EXPERIMENT_X89 = ExperimentX89,
  },{
    EXPERIMENT_X89 = {
      BarsCustom = {
        SHATTERING_SHOCKWAVE = { color = "xkcdBrightOrange" },
        REPUGNANT_SPEW = { color = "xkcdBrightOrange" },
        RESOUNDING_SHOUT = { color = "xkcdBrightOrange" },
      },
    },
  })
end
