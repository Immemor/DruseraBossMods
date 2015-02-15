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
local MaelstromAuthority = {}

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function MaelstromAuthority:OnStartCombat()
  DBM:SetDatachronAlert(self, "THE_PLATFORM_SHAKES",
  function(self)
    -- Something
    -- DBM:SetTimerAlert(self, "THIS_SHOULD_BE_1", 3, nil)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "DATASCAPE",
    EncounterName = "MAELSTROM_AUTHORITY",
    ZoneName = "QUANTUM_VORTEX",
  },{
    MAELSTROM_AUTHORITY = MaelstromAuthority,
  }, nil)
end
