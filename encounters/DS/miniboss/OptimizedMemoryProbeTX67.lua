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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("OPTIMIZED_MEMORY_PROBE_TX67")

------------------------------------------------------------------------------
-- ProbeP2Z.
------------------------------------------------------------------------------
local ProbeP2Z = {}

function ProbeP2Z:OnStartCombat()
  self:CreateHealthBar()
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 105)
  self:RegisterTriggerNames({"OPTIMIZED_MEMORY_PROBE_TX67"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    OPTIMIZED_MEMORY_PROBE_TX67 = ProbeP2Z,
  })
  self:RegisterEnglishLocale({
    ["OPTIMIZED_MEMORY_PROBE_TX67"] = "Optimized Memory Probe TX-67",
  })
  self:RegisterFrenchLocale({
    ["OPTIMIZED_MEMORY_PROBE_TX67"] = "Optimized Memory Probe TX-67" -- TODO,
  })
end
