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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("EXPERIMENT_X89")

local GetPlayerUnit = GameLib.GetPlayerUnit

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local SPELLID__SMALL_BOMB = 47316
local SPELLID__BIG_BOMB = 47285

------------------------------------------------------------------------------
-- ExperimentX89.
------------------------------------------------------------------------------
local ExperimentX89 = {}

function ExperimentX89:OnStartCombat()
  self:CreateHealthBar()

  -- Small bomb alert.
  self:SetDebuffAddAlert(SPELLID__SMALL_BOMB, function(self, nTargetId, nStack)
    local bItSelf = nTargetId == GetPlayerUnit():GetId()
    self:SetMessage({
      sLabel = "MSG_SMALL_BOMB",
      nDuration = 5,
      bHighlight = bItSelf,
    })
    if bItSelf then
      self:PlaySound("Alarm")
    else
      self:SetMarkOnUnit("Crosshair", nTargetId)
    end
  end)
  self:SetDebuffRemoveAlert(SPELLID__SMALL_BOMB, function(self, nTargetId, nStack)
    self:SetMarkOnUnit(nil, nTargetId)
  end)

  -- Big bomb alert.
  self:SetDebuffAddAlert(SPELLID__BIG_BOMB, function(self, nTargetId, nStack)
    local bItSelf = nTargetId == GetPlayerUnit():GetId()
    self:SetMessage({
      sLabel = "MSG_BIG_BOMB",
      nDuration = 5,
      bHighlight = bItSelf,
    })
    if bItSelf then
      self:PlaySound("Alarm")
    else
      self:SetMarkOnUnit("BloodySkull", nTargetId)
    end
  end)
  self:SetDebuffRemoveAlert(SPELLID__BIG_BOMB, function(self, nTargetId, nStack)
    DBM:SetMarkOnUnit(nil, nTargetId)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(147, 148)
  self:RegisterTriggerNames({"EXPERIMENT_X89"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    EXPERIMENT_X89 = ExperimentX89,
  })
  self:RegisterEnglishLocale({
    ["EXPERIMENT_X89"] = "Experiment X-89",
    ["RESOUNDING_SHOUT"] = "Resounding Shout",
    ["REPUGNANT_SPEW"] = "Repugnant Spew",
    ["SHATTERING_SHOCKWAVE"] = "Shattering Shockwave",
    ["CORRUPTION_GLOBULE"] = "Corruption Globule",
    ["STRAIN_BOMB"] = "Strain Bomb",
    ["MSG_SMALL_BOMB"] = "Small bomb! Go to the edge!",
    ["MSG_BIG_BOMB"] = "BIG bomb! Jump down!",
  })
  self:RegisterFrenchLocale({
    ["EXPERIMENT_X89"] = "Expérience X-89",
    ["RESOUNDING_SHOUT"] = "Hurlement retentissant",
    ["REPUGNANT_SPEW"] = "Crachat répugnant",
    ["SHATTERING_SHOCKWAVE"] = "Onde de choc dévastatrice",
    ["CORRUPTION_GLOBULE"] = "Globule de corruption",
    ["STRAIN_BOMB"] = "Bombe de Souillure",
    ["MSG_SMALL_BOMB"] = "Petite bombe! Allez au bord!",
    ["MSG_BIG_BOMB"] = "Grosse bombe! Sautez!",
  })
end
