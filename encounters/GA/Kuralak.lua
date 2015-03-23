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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("KURALAK_THE_DEFILER")

local GetPlayerUnit = GameLib.GetPlayerUnit

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local SPELLID__CHROMOSOME_CORRUPTION = 56652

------------------------------------------------------------------------------
-- Kuralak.
------------------------------------------------------------------------------
local Kuralak = {}

function Kuralak:CultivateCorruption()
  self:SetTimer("CULTIVATE_CORRUPTION", 60)
end

function Kuralak:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastStart("CULTIVATE_CORRUPTION", self.CultivateCorruption)
  self:SetCastStart("CHROMOSOME_CORRUPTION", function(self)
    -- Remove trigger
    self:SetCastStart("VANISH_INTO_DARKNESS", nil)
    self:SetTimer("VANISH_INTO_DARKNESS", 0)
    self:CultivateCorruption()
  end)

  -- Outbreak
  self:SetCastEnd("OUTBREAK", function(self)
    self:SetTimer("OUTBREAK", 40)
  end)

  -- Vanish into Darkness
  self:SetCastStart("VANISH_INTO_DARKNESS", function(self)
    self:SetTimer("VANISH_INTO_DARKNESS", 50)
  end)

  -- DNA Siphon
  self:SetCastEnd("DNA_SIPHON", function(self)
    self:SetTimer("DNA_SIPHON", 90)
  end)

  self:SetDebuffAddAlert(SPELLID__CHROMOSOME_CORRUPTION,
  function(self, nTargetId, nStack)
    local bItSelf = nTargetId == GetPlayerUnit():GetId()
    if bItSelf then
      self:PlaySound("Info")
    end
    self:SetMarkOnUnit("crosshair", nTargetId)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(147, 148)
  self:RegisterTriggerNames({"KURALAK_THE_DEFILER"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    KURALAK_THE_DEFILER = Kuralak,
  })
  self:RegisterEnglishLocale({
    ["KURALAK_THE_DEFILER"] = "Kuralak the Defiler",
    ["CULTIVATE_CORRUPTION"] = "Cultivate Corruption",
    ["CHROMOSOME_CORRUPTION"] = "Chromosome Corruption",
    ["OUTBREAK"] = "Outbreak",
    ["VANISH_INTO_DARKNESS"] = "Vanish into Darkness",
    ["DNA_SIPHON"] = "DNA Siphon",
  })
  self:RegisterFrenchLocale({
    ["KURALAK_THE_DEFILER"] = "Kuralak la Profanatrice",
    ["CULTIVATE_CORRUPTION"] = "Nourrir la corruption",
    ["CHROMOSOME_CORRUPTION"] = "Corruption chromosomique",
    ["OUTBREAK"] = "Invasion",
    ["VANISH_INTO_DARKNESS"] = "Disparaître dans les ténèbres",
    ["DNA_SIPHON"] = "Siphon DNA", --<< TODO: To check.
  })
  self:RegisterTimer("CULTIVATE_CORRUPTION", { color = "xkcdBrightOrange" })
  self:RegisterTimer("VANISH_INTO_DARKNESS", { color = "xkcdBrightPurple" })
end
