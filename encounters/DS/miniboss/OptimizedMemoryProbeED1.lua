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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("OPTIMIZED_MEMORY_PROBE_ED1")

------------------------------------------------------------------------------
-- ProbeED1.
------------------------------------------------------------------------------
local ProbeED1 = {}

function ProbeED1:OnStartCombat()
  self:CreateHealthBar()
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 105)
  self:RegisterTriggerNames({"OPTIMIZED_MEMORY_PROBE_ED1"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    OPTIMIZED_MEMORY_PROBE_ED1 = ProbeED1,
  })
  self:RegisterEnglishLocale({
    ["OPTIMIZED_MEMORY_PROBE_ED1"] = "Optimized Memory Probe ED-1",
  })
  self:RegisterFrenchLocale({
    ["OPTIMIZED_MEMORY_PROBE_ED1"] = "Optimized Memory Probe ED-1" -- TODO,
  })
end
