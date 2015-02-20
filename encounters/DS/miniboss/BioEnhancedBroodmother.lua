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
local BioEnhancedBroodmother = {}

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function BioEnhancedBroodmother:OnStartCombat()
  DBM:SetCastSuccessAlert(self, "AUGMENTED_VENOM", function(self)
    DBM:SetTimerAlert(self, "AUGMENTED_VENOM", 40, nil)
  end)

   -- Initialization
   DBM:SetTimerAlert(self, "AUGMENTED_VENOM", 46, nil)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "DATASCAPE",
    EncounterName = "BIO_ENHANCED_BROODMOTHER",
    ZoneName = "HALLS_OF_THE_INFINITE_MIND",
  },{
    BIO_ENHANCED_BROODMOTHER = BioEnhancedBroodmother,
  }, {
    BIO_ENHANCED_BROODMOTHER = {
      BarsCustom = {
        AUGMENTED_VENOM = { color = "xkcdBrightRed" },
      },
    },
  })
end
