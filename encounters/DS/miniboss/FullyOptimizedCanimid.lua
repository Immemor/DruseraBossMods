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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("FULLY_OPTIMIZED_CANIMID")

local _nUndermine_count = 0
local _bTerraform = true

------------------------------------------------------------------------------
-- FullyOptimizedCanimid.
------------------------------------------------------------------------------
local FullyOptimizedCanimid = {}

function FullyOptimizedCanimid:OnStartCombat()
  self:CreateHealthBar()
  _nUndermine_count = 0
  _bTerraform = true

  self:SetCastStart("UNDERMINE", function(self)
    _nUndermine_count = _nUndermine_count + 1
  end)
  self:SetCastEnd("UNDERMINE", function(self)
    if _nUndermine_count == 5 then
      _nUndermine_count = 0
      if not _bTerraform then
        self:SetTimer("UNDERMINE", 9)
      end
      _bTerraform = not _bTerraform
    end
  end)

  -- DPS check to break an aborb defense.
  self:SetCastEnd("TERRAFORMATION", function(self)
    self:SetTimer("TERRAFORMATION", 75)
    self:SetTimer("UNDERMINE", 13)
  end)
  -- Initialization
  self:SetTimer("TERRAFORMATION", 63)
  self:SetTimer("UNDERMINE", 30)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 108)
  self:RegisterTriggerNames({"FULLY_OPTIMIZED_CANIMID"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    FULLY_OPTIMIZED_CANIMID = FullyOptimizedCanimid,
  })
  self:RegisterEnglishLocale({
    ["FULLY_OPTIMIZED_CANIMID"] = "Fully-Optimized Canimid",
    ["UNDERMINE"] = "Undermine",
    ["TERRAFORMATION"] = "Terra-forme",
  })
  self:RegisterFrenchLocale({
    ["FULLY_OPTIMIZED_CANIMID"] = "Canimide entièrement optimisé",
    ["UNDERMINE"] = "Ébranler",
    ["TERRAFORMATION"] = "Terra-forme",
  })
  self:RegisterTimer("UNDERMINE", { color = "xkcdBrightYellow" })
  self:RegisterTimer("TERRAFORMATION", { color = "xkcdBrightRed" })
end
