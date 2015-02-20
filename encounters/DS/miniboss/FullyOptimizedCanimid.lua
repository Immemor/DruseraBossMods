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
local FullyOptimizedCanimid = {}

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function FullyOptimizedCanimid:OnStartCombat()
  self.undermine_count = 0
  self.terraform = true

  DBM:SetCastStartAlert(self, "UNDERMINE", 30, function(self)
    self.undermine_count = self.undermine_count + 1
  end)
  DBM:SetCastSuccessAlert(self, "UNDERMINE", 30, function(self)
    if self.undermine_count == 5 then
      self.undermine_count = 0
      if not self.terraform then
        DBM:SetTimerAlert(self, "UNDERMINE", 9, nil)
      end
      self.terraform = not self.terraform
    end
  end)

  -- DPS check to break an aborb defense.
  DBM:SetCastFailedAlert(self, "TERRAFORMATION", function(self)
    DBM:SetTimerAlert(self, "TERRAFORMATION", 75, nil)
    DBM:SetTimerAlert(self, "UNDERMINE", 13, nil)
  end)
  -- Initialization
  DBM:SetTimerAlert(self, "TERRAFORMATION", 63, nil)
  DBM:SetTimerAlert(self, "UNDERMINE", 30, nil)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "DATASCAPE",
    EncounterName = "FULLY_OPTIMIZED_CANIMID",
    ZoneName = "HALLS_OF_THE_INFINITE_MIND",
  },{
    FULLY_OPTIMIZED_CANIMID = FullyOptimizedCanimid,
  }, {
    FULLY_OPTIMIZED_CANIMID = {
      BarsCustom = {
        UNDERMINE = { color = "xkcdBrightYellow" },
        TERRAFORMATION = { color = "xkcdBrightRed" },
      },
    },
  })
end
