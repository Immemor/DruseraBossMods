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
local Terax = {}
local Golgox = {}
local Fleshmonger = {}
local Noxmind = {}
local Ersoth = {}

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
local function NextConvergence(self)
  DBM:ClearAllTimerAlert()
  DBM:SetTimerAlert(self, "NEXT_CONVERGENCE", 85, nil)
end

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function Terax:OnStartCombat()
  DBM:SetCastStartAlert(self, "TELEPORT", NextConvergence)

  -- Stitching strain
  DBM:SetCastSuccessAlert(self, "STITCHING_STRAIN", function(self)
    DBM:SetTimerAlert(self, "STITCHING_STRAIN", 55, nil)
  end)
end

function Golgox:OnStartCombat()
  DBM:SetCastStartAlert(self, "TELEPORT", NextConvergence)
end

function Fleshmonger:OnStartCombat()
  DBM:SetCastStartAlert(self, "TELEPORT", NextConvergence)
end

function Noxmind:OnStartCombat()
  DBM:SetCastStartAlert(self, "TELEPORT", NextConvergence)
  DBM:SetCastSuccessAlert(self, "ESSENCE_ROT", function(self)
    DBM:SetTimerAlert(self, "ESSENCE_ROT", 17, nil)
  end)
end

function Ersoth:OnStartCombat()
  DBM:SetCastStartAlert(self, "TELEPORT", NextConvergence)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "GENETIC_ARCHIVE",
    EncounterName = "CONVERGENCE",
    ZoneName = "GENETIC_ARCHIVE_ACT_2",
  },{
    TERAX_BLIGHTWEAVER = Terax,
    GOLGOX_THE_LIFECRUSHER = Golgox,
    FLESHMONGER_VRATORG = Fleshmonger,
    NOXMIND_THE_INSIDIOUS = Noxmind,
    ERSOTH_CURSEFORM = Ersoth,
  }, {
    TERAX_BLIGHTWEAVER = {
      BarsCustom = {
        STITCHING_STRAIN = { color = "red" },
      },
    },
  })
end
