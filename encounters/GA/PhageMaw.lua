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
local PhageMaw = {}

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function PhageMaw:OnStartCombat()
  DBM:SetCastStartAlert(self, "DETONATION_BOMBS", function(self)
    DBM:SetTimerAlert(self, "DETONATION_BOMBS", 29, nil)
  end)
  DBM:SetCastStartAlert(self, "CRATER", function(self)
    DBM:SetTimerAlert(self, "AIR_PHASE", 112, nil)
  end)
  DBM:SetCastStartAlert(self, "BOMBS", function(self)
    DBM:SetTimerAlert(self, "BOMBS", 112, nil)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "GENETIC_ARCHIVE",
    EncounterName = "PHAGE_MAW",
    ZoneName = "GENETIC_ARCHIVE_ACT_2",
  },{
    PHAGE_MAW = PhageMaw,
  },{
    PHAGE_MAW = {
      BarsCustom = {
        DETONATION_BOMBS = { color = "xkcdBrightOrange" },
        AIR_PHASE = { color = "xkcdBrightSkyBlue" },
        BOMBS = { color = "xkcdBrightRed" },
      },
    },
  })
end
