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
local Kuralak = {}

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
function Kuralak:CultivateCorruption()
  DBM:SetTimerAlert(self, "CULTIVATE_CORRUPTION", 60, nil)
end

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function Kuralak:OnStartCombat()
  DBM:SetCastStartAlert(self, "CULTIVATE_CORRUPTION", self.CultivateCorruption)
  DBM:SetCastStartAlert(self, "CHROMOSOME_CORRUPTION", function(self)
    -- Remove trigger
    DBM:SetCastStartAlert(self, "VANISH_INTO_DARKNESS", nil)
    DBM:SetTimerAlert(self, "VANISH_INTO_DARKNESS", 0, nil)
    self:CultivateCorruption()
  end)

  -- Outbreak
  DBM:SetCastStartAlert(self, "OUTBREAK", function(self)
    DBM:SetTimerAlert(self, "OUTBREAK", 30, nil)
  end)

  -- Vanish into Darkness
  DBM:SetCastStartAlert(self, "VANISH_INTO_DARKNESS", function(self)
    DBM:SetTimerAlert(self, "VANISH_INTO_DARKNESS", 60, nil)
  end)

  -- DNA Siphon
  DBM:SetCastStartAlert(self, "DNA_SIPHON", function(self)
    DBM:SetTimerAlert(self, "DNA_SIPHON", 60, nil)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "GENETIC_ARCHIVE",
    EncounterName = "KURALAK_THE_DEFILER",
    ZoneName = "GENETIC_ARCHIVE_ACT_1",
  },{
    KURALAK_THE_DEFILER = Kuralak,
  },{
    KURALAK_THE_DEFILER = {
      BarsCustom = {
        CULTIVATE_CORRUPTION = { color = "xkcdBrightOrange", },
        VANISH_INTO_DARKNESS = { color = "xkcdBrightPurple", },
      },
    },
  })
end
