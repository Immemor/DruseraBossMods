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
local Ohmna = {}

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function Ohmna:OnStartCombat()
  DBM:CreateHealthBar(self, "DREADPHAGE_OHMNA")
  DBM:SetCastSuccessAlert(self, "DEVOUR", function(self)
    DBM:SetTimerAlert(self, "DEVOUR", 25.5, nil)
  end)
  DBM:SetCastSuccessAlert(self, "BODY_SLAM", function(self)
    DBM:SetTimerAlert(self, "BODY_SLAM", 84, nil)
  end)
  DBM:SetCastSuccessAlert(self, "GENETIC_TORRENT", function(self)
    DBM:SetTimerAlert(self, "GENETIC_TORRENT", 84, nil)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 147,
    nZoneMapId = 149,
    sEncounterName = "DREADPHAGE_OHMNA",
    tTriggerNames = { "DREADPHAGE_OHMNA" },
    tUnits = {
      DREADPHAGE_OHMNA = Ohmna,
    },
    tCustom = {
      DREADPHAGE_OHMNA = {
        BarsCustom = {
          BODY_SLAM = { color = "xkcdBrightOrange" },
          DEVOUR = { color = "xkcdBrightOrange" },
          GENETIC_TORRENT = { color = "xkcdBrightOrange" },
        },
      },
    },
  })
end
