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
local Avatus = {}

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function Avatus:OnStartCombat()
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "DATASCAPE",
    EncounterName = "AVATUS",
    ZoneName = "QUANTUM_VORTEX",
  },{
    MAELSTROM_AUTHORITY = Avatus,
  }, nil)
end
