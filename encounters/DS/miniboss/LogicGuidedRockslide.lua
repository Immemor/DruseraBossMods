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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("LOGIC_GUIDED_ROCKSLIDE")

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local SPELLID_DDDD = 77534

------------------------------------------------------------------------------
-- LogicGuidedRockslide.
------------------------------------------------------------------------------
local LogicGuidedRockslide = {}

function LogicGuidedRockslide:OnStartCombat()
  self:CreateHealthBar()

  --[[
  self:SetDebuffAddAlert(SPELLID_DDDD, function(self, nTargetId)
    self:SetMarkOnUnit("Crosshair", nTargetId)
  end)
  self:SetDebuffAddRemove(SPELLID_DDDD, function(self, nTargetId)
    self:SetMarkOnUnit(nil, nTargetId)
  end)
  --]]

end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 108)
  self:RegisterTriggerNames({"LOGIC_GUIDED_ROCKSLIDE"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    LOGIC_GUIDED_ROCKSLIDE = LogicGuidedRockslide,
  })
  self:RegisterEnglishLocale({
    ["LOGIC_GUIDED_ROCKSLIDE"] = "Logic Guided Rockslide",
    ["DATACHRON_ROCKSLIDE_FOCUS"] = "TODO",
  })
  self:RegisterFrenchLocale({
    ["LOGIC_GUIDED_ROCKSLIDE"] = "Éboulement guidé par la logique",
    ["DATACHRON_ROCKSLIDE_FOCUS"] = "L'Éboulement guidé par la logique est focalisé sur %%PlayerName !",
  })
end
