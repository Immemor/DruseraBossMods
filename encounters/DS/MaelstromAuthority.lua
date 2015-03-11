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
    nZoneMapParentId = 98,
    nZoneMapId = nil,
    sEncounterName = "MAELSTROM_AUTHORITY",
    tUnits = {
      MAELSTROM_AUTHORITY = MaelstromAuthority,
    },
  })
end
