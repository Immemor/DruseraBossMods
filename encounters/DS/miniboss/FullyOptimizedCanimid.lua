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
local FullyOptimizedCanimid = {}
local _nUndermine_count = 0
local _bTerraform = true

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function FullyOptimizedCanimid:OnStartCombat()
  DBM:CreateHealthBar(self, "FULLY_OPTIMIZED_CANIMID")
  _nUndermine_count = 0
  _bTerraform = true

  DBM:SetCastStartAlert(self, "UNDERMINE", function(self)
    _nUndermine_count = _nUndermine_count + 1
  end)
  DBM:SetCastSuccessAlert(self, "UNDERMINE", function(self)
    if _nUndermine_count == 5 then
      _nUndermine_count = 0
      if not _bTerraform then
        DBM:SetTimerAlert(self, "UNDERMINE", 9, nil)
      end
      _bTerraform = not _bTerraform
    end
  end)

  -- DPS check to break an aborb defense.
  DBM:SetCastFailedAlert(self, "TERRAFORMATION", function(self)
    DBM:SetTimerAlert(self, "TERRAFORMATION", 75, nil)
    DBM:SetTimerAlert(self, "UNDERMINE", 13, nil)
  end)
  -- Initialization
  DBM:SetTimerAlert(self, "TERRAFORMATION", 63, nil)
  DBM:SetTimerAlert(self, "UNDERMINE", 30, nil)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 98,
    nZoneMapId = 108,
    sEncounterName = "FULLY_OPTIMIZED_CANIMID",
    tTriggerNames = { "FULLY_OPTIMIZED_CANIMID" },
    tUnits = {
      FULLY_OPTIMIZED_CANIMID = FullyOptimizedCanimid,
    },
    tCustom = {
      FULLY_OPTIMIZED_CANIMID = {
        BarsCustom = {
          UNDERMINE = { color = "xkcdBrightYellow" },
          TERRAFORMATION = { color = "xkcdBrightRed" },
        },
      },
    },
  })
end
