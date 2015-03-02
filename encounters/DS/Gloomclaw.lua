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
require "GameLib"

local DBM = Apollo.GetAddon("DruseraBossMods")
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime
local Gloomclaw = {}
local DangerousMobs = {}
local InsignifiantMobs = {}

local _nSection = 2
local _nWaveIndex = 0
local _nLastPopMobsTime = 0
local _GloomclawContext = nil
local _tWavePopTiming = {
  26, -- Time between 2 waves for section 1
  33, -- section 2
  25,
  14,
  20.5
}

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------

local function NewSection(self)
  _nWaveIndex = 0
  DBM:SetTimerAlert(self, "RUPTURE", 33, nil)
end

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function Gloomclaw:OnStartCombat()
  _GloomclawContext = self
  _nSection = 2
  _nLastPopMobsTime = 0
  DBM:CreateHealthBar(self, "GLOOMCLAW")
  DBM:SetCastStartAlert(self, "RUPTURE", function(self)
    DBM:PlaySound("Alarm")
    DBM:SetMessage({
      sLabel = "INTERRUPT_THIS_CAST",
      nDuration = 3,
      bHighlight = true,
    })
    DBM:SetTimerAlert(self, "RUPTURE", 43, nil)
  end)
  DBM:SetDatachronAlert(self, "DATACHRON_GLOOMCLAW_IS_REDUCED", function(self)
    DBM:ClearAllTimerAlert()
  end)
  DBM:SetDatachronAlert(self, "DATACHRON_GLOOMCLAW_IS_PUSHED_BACK", function(self)
    DBM:ClearAllTimerAlert()
    _nSection = _nSection + 1
    DBM:SetTimerAlert(self, "GLOOMCLAW_IS_PUSHED_BACK", 10, NewSection)
  end)
  DBM:SetDatachronAlert(self, "DATACHRON_GLOOMCLAW_IS_MOVING_FORWARD", function(self)
    DBM:ClearAllTimerAlert()
    _nSection = _nSection - 1
    DBM:SetTimerAlert(self, "GLOOMCLAW_IS_MOVING_FORWARD", 3, NewSection)
  end)

  NewSection(self)
end

function DangerousMobs:OnStartCombat()
  DBM:SetCastStartAlert(self, "CORRUPTING_RAYS", function(self)
    local d = DBM:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
    if d and d < 35 then
      DBM:PlaySound("Alert")
      DBM:SetMessage({
        sLabel = "INTERRUPT_CORRUPTING_RAYS",
        nDuration = 3,
        bHighlight = true,
      })
    end
  end)
end

function InsignifiantMobs:OnStartCombat()
  local nCurrentTime = GetGameTime()
  local delta = nCurrentTime - _nLastPopMobsTime
  -- The pop time is not regular between two fight, implement a patch like RaidCore.
  -- No real choice.
  if delta > 10 then
    _nLastPopMobsTime = nCurrentTime
    _nWaveIndex = _nWaveIndex + 1

    DBM:SetMessage({
      sLabel = "ADDS_WAVE",
      nDuration = 3,
    })
    DBM:PlaySound("Info")
    if _nSection == 5 then
      if _nWaveIndex == 1 then
        DBM:SetTimerAlert(_GloomclawContext, "NEXT_ADD_WAVE", 20.5, nil)
      elseif _nWaveIndex == 2 then
        DBM:SetTimerAlert(_GloomclawContext, "NEXT_ADD_WAVE", 30, nil)
      elseif _nWaveIndex == 3 then
        DBM:SetTimerAlert(_GloomclawContext, "NEXT_ADD_WAVE", 15, nil)
      end
    elseif _nSection < 5 and _nSection > 0 then
      DBM:SetTimerAlert(_GloomclawContext, "NEXT_ADD_WAVE", _tWavePopTiming[_nSection], nil)
    end
  end
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 98,
    nZoneMapId = 115,
    sEncounterName = "GLOOMCLAW",
    tTriggerNames = { "GLOOMCLAW", },
    tUnits = {
      GLOOMCLAW = Gloomclaw,
      CORRUPTED_RAVAGER = DangerousMobs,
      EMPOWERED_RAVAGER = DangerousMobs,
      STRAIN_PARASITE = InsignifiantMobs,
      GLOOMCLAW_SKURGE = InsignifiantMobs,
      CORRUPTED_FRAZ = InsignifiantMobs,
    },
    tCustom = {
      GLOOMCLAW = {
        BarsCustom = {
          RUPTURE = { color = "xkcdBrightOrange" },
          NEXT_ADD_WAVE = { color = "xkcdBrightGreen" }
        },
      },
    },
  })
end
