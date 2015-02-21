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
local LogicGuidedRockslide = {}

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function LogicGuidedRockslide:OnStartCombat()
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "DATASCAPE",
    EncounterName = "LOGIC_GUIDED_ROCKSLIDE",
    ZoneName = "HALLS_OF_THE_INFINITE_MIND",
  },{
    LOGIC_GUIDED_ROCKSLIDE = LogicGuidedRockslide,
  }, {
    LOGIC_GUIDED_ROCKSLIDE = {
      BarsCustom = {
      },
    },
  })
end
