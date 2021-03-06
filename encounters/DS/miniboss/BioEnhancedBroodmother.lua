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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("BIO_ENHANCED_BROODMOTHER")

------------------------------------------------------------------------------
-- BioEnhancedBroodmother class.
------------------------------------------------------------------------------
local BioEnhancedBroodmother = {}

function BioEnhancedBroodmother:OnStartCombat()
  self:CreateHealthBar()
  self:SetTimer("AUGMENTED_BIO_WEB", 48)

  self:SetCastStart("AUGMENTED_BIO_WEB", function(self)
    self:PlaySound("Alarm")
  end)
  self:SetCastEnd("AUGMENTED_BIO_WEB", function(self)
    self:SetTimer("AUGMENTED_BIO_WEB", 40)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 108)
  self:RegisterTriggerNames({"BIO_ENHANCED_BROODMOTHER"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    BIO_ENHANCED_BROODMOTHER = BioEnhancedBroodmother,
  })
  self:RegisterEnglishLocale({
    ["BIO_ENHANCED_BROODMOTHER"] = "Bio-Enhanced Broodmother",
    ["AUGMENTED_BIO_WEB"] = "Augmented Bio-Web",
  })
  self:RegisterFrenchLocale({
    ["BIO_ENHANCED_BROODMOTHER"] = "Mère de couvée augmentée",
    ["AUGMENTED_BIO_WEB"] = "Bio-soie augmentée",
  })
  self:RegisterTimer("AUGMENTED_BIO_WEB", { color = "xkcdBrightRed" })
end
