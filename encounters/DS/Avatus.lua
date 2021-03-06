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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("AVATUS")

------------------------------------------------------------------------------
-- Gloomclaw.
------------------------------------------------------------------------------
local Avatus = {}

function Avatus:OnStartCombat()
  self:ActivateDetection(true)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, nil) -- TODO
  self:RegisterTriggerNames({"AVATUS"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    AVATUS = Avatus,
  })
  self:RegisterEnglishLocale({
    ["AVATUS"] = "Avatus",
  })
  self:RegisterFrenchLocale({
    ["AVATUS"] = "Avatus",
  })
end
