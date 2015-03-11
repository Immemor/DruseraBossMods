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
    nZoneMapParentId = 98,
    nZoneMapId = 108,
    sEncounterName = "LOGIC_GUIDED_ROCKSLIDE",
    tTriggerNames = { "LOGIC_GUIDED_ROCKSLIDE" },
    tUnits = {
      LOGIC_GUIDED_ROCKSLIDE = LogicGuidedRockslide,
    },
    tCustom = {
      LOGIC_GUIDED_ROCKSLIDE = {
        BarsCustom = {
        },
      },
    },
  })
end
