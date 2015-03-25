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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("OPTIMIZED_MEMORY_PROBE_P2Z")

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
  self:RegisterZoneMap(98, 104)
  self:RegisterTriggerNames({"OPTIMIZED_MEMORY_PROBE_P2Z"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    OPTIMIZED_MEMORY_PROBE_P2Z = ProbeP2Z,
  })
  self:RegisterEnglishLocale({
    ["OPTIMIZED_MEMORY_PROBE_P2Z"] = "Optimized Memory Probe P2-Z",
  })
  self:RegisterFrenchLocale({
    ["OPTIMIZED_MEMORY_PROBE_P2Z"] = "Optimized Memory Probe P2-Z" -- TODO,
  })
end
