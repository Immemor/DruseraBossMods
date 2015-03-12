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
local ExperimentX89 = {}
local GetPlayerUnit = GameLib.GetPlayerUnit

local SPELLID__SMALL_BOMB = 61460
local SPELLID__BIG_BOMB = 47286

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function ExperimentX89:OnStartCombat()
  DBM:CreateHealthBar(self, "EXPERIMENT_X89")

  -- Small bomb alert.
  DBM:SetDebuffAddAlert(self, SPELLID__SMALL_BOMB, function(self, nTargetId, nStack)
    local bItself = nTargetId == GetPlayerUnit():GetId()
    DBM:SetMessage({
      sLabel = "MSG_SMALL_BOMB",
      nDuration = 5,
      bHighlight = bItself,
    })
    if bItself then
      DBM:PlaySound("Alarm")
    else
      DBM:SetMarkOnUnit("Crosshair", nTargetId, 51)
    end
  end)
  DBM:SetDebuffRemoveAlert(self, SPELLID__SMALL_BOMB, function(self, nTargetId, nStack)
    DBM:SetMarkOnUnit(nil, nTargetId, 51)
  end)

  -- Big bomb alert.
  DBM:SetDebuffAddAlert(self, SPELLID__BIG_BOMB, function(self, nTargetId, nStack)
    local bItself = nTargetId == GetPlayerUnit():GetId()
    DBM:SetMessage({
      sLabel = "MSG_BIG_BOMB",
      nDuration = 5,
      bHighlight = bItself,
    })
    if bItself then
      DBM:PlaySound("Alarm")
    else
      DBM:SetMarkOnUnit("Crosshair", nTargetId, 51)
    end
  end)
  DBM:SetDebuffRemoveAlert(self, SPELLID__BIG_BOMB, function(self, nTargetId, nStack)
    DBM:SetMarkOnUnit(nil, nTargetId, 51)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 147,
    nZoneMapId = 148,
    sEncounterName = "EXPERIMENT_X89",
    tTriggerNames = { "EXPERIMENT_X89", },
    tUnits = {
      EXPERIMENT_X89 = ExperimentX89,
    },
    tCustom = {
      EXPERIMENT_X89 = {
        BarsCustom = {
          SHATTERING_SHOCKWAVE = { color = "xkcdBrightOrange" },
          REPUGNANT_SPEW = { color = "xkcdBrightOrange" },
          RESOUNDING_SHOUT = { color = "xkcdBrightOrange" },
        },
      },
    },
  })
end
