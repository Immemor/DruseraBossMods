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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("TEST")

local _my_var

------------------------------------------------------------------------------
-- CrimsonSpiderbot.
------------------------------------------------------------------------------
local CrimsonSpiderbot = {}

function CrimsonSpiderbot:OnPhaseComboFailed()
  self:SetTimer("THIS_SHOULD_BE_1", 3, function(self)
    _my_var = _my_var + 2
    self:SetTimer("THIS_SHOULD_BE_2", 6, function(self)
      self:SetTimer("THIS_SHOULD_BE_3", 9, function(self)
        self:SetTimer("THIS_SHOULD_BE_4", 5)
      end)
    end)
  end)
end

function CrimsonSpiderbot:OnStartCombat()
  _my_var = 3
  self:CreateHealthBar()

  self:SetCastStart("PHASER_COMBO", function(self)
    self:SetTimer("PHASER_COMBO_START", 3)
  end)
  self:SetCastEnd("PHASER_COMBO", function(self, bSuccess)
    if bSuccess then
      self:SetTimer("PHASER_COMBO_END", _my_var)
    else
      self:OnPhaseComboFailed()
    end
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(0, 16)
  self:RegisterTriggerNames({"CRIMSON_SPIDERBOT"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    CRIMSON_SPIDERBOT = CrimsonSpiderbot,
  })
  self:RegisterEnglishLocale({
    ["CRIMSON_SPIDERBOT"] = "Crimson Spiderbot",
    ["PHASER_COMBO"] = "Phaser Combo",
    ["THIS_SHOULD_BE_1"] = "This should be 1",
    ["THIS_SHOULD_BE_2"] = "This should be 2",
    ["THIS_SHOULD_BE_3"] = "This should be 3",
    ["THIS_SHOULD_BE_4"] = "This should be 4",
    ["FAKE_ENRAGE"] = "Fake enrage",
    ["PHASER_COMBO_START"] = "Phaser Combo Start",
    ["PHASER_COMBO_END"] = "Phaser Combo End",
  })
  self:RegisterFrenchLocale({
    ["CRIMSON_SPIDERBOT"] = "Arachnobot écarlate",
    ["PHASER_COMBO"] = "Combo de phaser",
    ["THIS_SHOULD_BE_1"] = "Cela devrait être 1",
    ["THIS_SHOULD_BE_2"] = "Cela devrait être 2",
    ["THIS_SHOULD_BE_3"] = "Cela devrait être 3",
    ["THIS_SHOULD_BE_4"] = "Cela devrait être 4",
    ["FAKE_ENRAGE"] = "Fausse enrage",
    ["PHASER_COMBO_START"] = "Début de combo de phaser",
    ["PHASER_COMBO_END"] = "Fin de Combo de phaser",
  })
  self:RegisterTimer("PHASER_COMBO_START", { color = "Red" })
  self:RegisterTimer("PHASER_COMBO_END", { color = "xkcdBrightGreen" })
  self:RegisterTimer("FAKE_ENRAGE", { color = "xkcdBrightBlue" })
  self.Counter = 100
end

function ENCOUNTER:OnEnable()
  self.Counter = self.Counter + 20
  self:SetTimer("FAKE_ENRAGE", self.Counter)
end
