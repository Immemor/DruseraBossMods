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
local BioEnhancedBroodmother = {}

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function BioEnhancedBroodmother:OnStartCombat()
  DBM:CreateHealthBar(self, "BIO_ENHANCED_BROODMOTHER")
  DBM:SetCastStartAlert(self, "AUGMENTED_BIO_WEB", function(self)
    DBM:PlaySound("Alarm")
  end)
  DBM:SetCastSuccessAlert(self, "AUGMENTED_BIO_WEB", function(self)
    DBM:SetTimerAlert(self, "AUGMENTED_BIO_WEB", 40, nil)
  end)

   -- Initialization
   DBM:SetTimerAlert(self, "AUGMENTED_BIO_WEB", 48, nil)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 98,
    nZoneMapId = 108,
    sEncounterName = "BIO_ENHANCED_BROODMOTHER",
    tTriggerNames = { "BIO_ENHANCED_BROODMOTHER" },
    tUnits = {
      BIO_ENHANCED_BROODMOTHER = BioEnhancedBroodmother,
    },
    tCustom = {
      BIO_ENHANCED_BROODMOTHER = {
        BarsCustom = {
          AUGMENTED_BIO_WEB = { color = "xkcdBrightRed" },
        },
      },
    },
  })
end
