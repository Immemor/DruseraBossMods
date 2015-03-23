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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("PHAGE_MAW")

------------------------------------------------------------------------------
-- PhageMaw.
------------------------------------------------------------------------------
local PhageMaw = {}

function PhageMaw:OnStartCombat()
  self:ActivateDetection(true)
  self:CreateHealthBar()
  self:SetCastStart("DETONATION_BOMBS", function(self)
    self:SetTimer("DETONATION_BOMBS", 29)
  end)
  self:SetCastStart("CRATER", function(self)
    self:SetTimer("NEXT_AIR_PHASE", 112)
  end)
  self:SetCastStart("BOMBS", function(self)
    self:SetTimer("BOMBS", 112)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(147, 149)
  self:RegisterTriggerNames({ "PHAGE_MAW" })
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    PHAGE_MAW = PhageMaw,
  })
  self:RegisterEnglishLocale({
    ["PHAGE_MAW"] = "Phage Maw",
    ["DETONATION_BOMB"] = "Detonation Bomb",
    ["DETONATION_BOMBS"] = "Detonation Bombs",
    ["CRATER"] = "Crater",
    ["NEXT_AIR_PHASE"] = "Next air phase",
    ["BOMBS"] = "Bombs",
  })
  self:RegisterFrenchLocale({
    ["PHAGE_MAW"] = "Phagegueule",
    ["DETONATION_BOMB"] = "Bombe à détonateur",
    ["DETONATION_BOMBS"] = "Bombes explosives",
    ["CRATER"] = "Cratère",
    ["NEXT_AIR_PHASE"] = "Prochaine phase d'air",
    ["BOMBS"] = "Bombes",
  })
  self:RegisterTimer("DETONATION_BOMBS", { color = "xkcdBrightOrange" })
  self:RegisterTimer("NEXT_AIR_PHASE", { color = "xkcdBrightSkyBlue" })
  self:RegisterTimer("BOMBS", { color = "xkcdBrightRed" })
end
