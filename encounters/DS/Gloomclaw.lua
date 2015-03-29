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

local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("GLOOMCLAW")

local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

local _FirstMove = true
local _nSection = 2
local _nWaveIndex = 0
local _nLastPopMobsTime = 0
local _tWavePopTiming = {
  26, -- Time between 2 waves for section 1
  33, -- section 2
  25,
  14,
  20.5
}

------------------------------------------------------------------------------
-- Gloomclaw.
------------------------------------------------------------------------------
local Gloomclaw = {}

function Gloomclaw:NewSection()
  _nWaveIndex = 0
  local nFirstRupture = _nSection == 1 and 31 or 25
  if _nSection ~= 4 then
    self:SetTimer("APPROXIMATE_RUPTURE", nFirstRupture)
  end
end

function Gloomclaw:OnStartCombat()
  _FirstMove = true
  _nSection = 2
  _nLastPopMobsTime = 0
  self:CreateHealthBar()
  self:SetCastStart("RUPTURE", function(self)
    self:PlaySound("Alarm")
    self:SetMessage({
      sLabel = "INTERRUPT_THIS_CAST",
      nDuration = 3,
      bHighlight = true,
    })
    self:SetTimer("NEXT_RUPTURE", 43)
    self:SetTimer("APPROXIMATE_RUPTURE", 0)
  end)
  self:SetDatachronAlert("DATACHRON_GLOOMCLAW_IS_REDUCED", function(self)
    self:ClearAllTimerAlert()
  end)
  self:SetDatachronAlert("DATACHRON_GLOOMCLAW_IS_VULNERABLE", function(self)
    self:ClearAllTimerAlert()
  end)
  self:SetDatachronAlert("DATACHRON_GLOOMCLAW_IS_PUSHED_BACK", function(self)
    self:ClearAllTimerAlert()
    _nSection = _nSection + 1
    self:SetTimer("GLOOMCLAW_IS_PUSHED_BACK", 10, self.NewSection)
  end)
  self:SetDatachronAlert("DATACHRON_GLOOMCLAW_IS_MOVING_FORWARD", function(self)
    self:ClearAllTimerAlert()
    _nSection = _nSection - 1
    local nMoveTiming = _FirstMove and 3 or 10
    _FirstMove = false
    self:SetTimer("GLOOMCLAW_IS_MOVING_FORWARD", nMoveTiming, self.NewSection)
  end)
end

------------------------------------------------------------------------------
-- Mobs.
------------------------------------------------------------------------------
local DangerousMobs = {}
local InsignificantMobs = {}

function DangerousMobs:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastStart("CORRUPTING_RAYS", function(self)
    local d = self:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
    if d and d < 35 then
      self:PlaySound("Alert")
      self:SetMessage({
        sLabel = "INTERRUPT_CORRUPTING_RAYS",
        nDuration = 3,
        bHighlight = true,
      })
    end
  end)
end

function InsignificantMobs:OnStartCombat()
  local nCurrentTime = GetGameTime()
  local delta = nCurrentTime - _nLastPopMobsTime
  if delta > 10 then
    _nLastPopMobsTime = nCurrentTime
    _nWaveIndex = _nWaveIndex + 1

    self:SetMessage({
      sLabel = "ADDS_WAVE",
      nDuration = 3,
    })
    if _nSection == 5 then
      if _nWaveIndex == 1 then
        ENCOUNTER:SetTimer("NEXT_ADD_WAVE", 20.5)
      elseif _nWaveIndex == 2 then
        ENCOUNTER:SetTimer("NEXT_ADD_WAVE", 30)
      elseif _nWaveIndex == 3 then
        ENCOUNTER:SetTimer("NEXT_ADD_WAVE", 15)
      end
    elseif _nSection < 5 and _nSection > 0 then
      ENCOUNTER:SetTimer("NEXT_ADD_WAVE", _tWavePopTiming[_nSection])
    end
  end
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 115)
  self:RegisterTriggerNames({"GLOOMCLAW"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    GLOOMCLAW = Gloomclaw,
    CORRUPTED_RAVAGER = DangerousMobs,
    EMPOWERED_RAVAGER = DangerousMobs,
    STRAIN_PARASITE = InsignificantMobs,
    GLOOMCLAW_SKURGE = InsignificantMobs,
    CORRUPTED_FRAZ = InsignificantMobs,
  })
  self:RegisterEnglishLocale({
    ["GLOOMCLAW"] = "Gloomclaw",
    ["INTERRUPT_THIS_CAST"] = "Interrupt this cast!",
    ["CORRUPTED_RAVAGER"] = "Corrupted Ravager",
    ["EMPOWERED_RAVAGER"] = "Empowered Ravager",
    ["STRAIN_PARASITE"] = "Strain Parasite",
    ["GLOOMCLAW_SKURGE"] = "Gloomclaw Skurge",
    ["CORRUPTED_FRAZ"] = "Corrupted Fraz",
    ["RUPTURE"] = "Rupture",
    ["ADDS_WAVE"] = "Adds wave",
    ["NEXT_ADD_WAVE"] = "Next add wave",
    ["NEXT_RUPTURE"] = "Next Rupture",
    ["APPROXIMATE_RUPTURE"] = "First Rupture (approximate)",
    ["DATACHRON_GLOOMCLAW_IS_REDUCED"] = "Gloomclaw is reduced to a weakened state!",
    ["DATACHRON_GLOOMCLAW_IS_VULNERABLE"] = "Gloomclaw is vulnerable!",
    ["DATACHRON_GLOOMCLAW_IS_PUSHED_BACK"] = "Gloomclaw is pushed back by the purification of the essences!",
    ["DATACHRON_GLOOMCLAW_IS_MOVING_FORWARD"] = "Gloomclaw is moving forward to corrupt more essences!",
    ["GLOOMCLAW_IS_PUSHED_BACK"] = "Glooclaw is pushed back",
    ["GLOOMCLAW_IS_MOVING_FORWARD"] = "Glooclaw is moving forward",
    ["CORRUPTING_RAYS"] = "Corrupting Rays",
    ["INTERRUPT_CORRUPTING_RAYS"] = "Interrupt: Corrupting Rays !",
  })
  self:RegisterFrenchLocale({
    ["GLOOMCLAW"] = "Serrenox",
    ["INTERRUPT_THIS_CAST"] = "Coupez ce sort!",
    ["CORRUPTED_RAVAGER"] = "Ravageur corrompu",
    ["EMPOWERED_RAVAGER"] = "Ravageur renforcé",
    ["STRAIN_PARASITE"] = "Parasite de la Souillure",
    ["GLOOMCLAW_SKURGE"] = "Skurge serrenox",
    ["CORRUPTED_FRAZ"] = "Friz corrompu",
    ["RUPTURE"] = "Rupture",
    ["ADDS_WAVE"] = "Vague d'adds",
    ["NEXT_ADD_WAVE"] = "Prochaine vague d'adds",
    ["NEXT_RUPTURE"] = "Prochaine Rupture",
    ["APPROXIMATE_RUPTURE"] = "1ère Rupture (approximatif)",
    ["DATACHRON_GLOOMCLAW_IS_REDUCED"] = "Serrenox a été affaibli !",
    ["DATACHRON_GLOOMCLAW_IS_VULNERABLE"] = "Serrenox est vulnérable !",
    ["DATACHRON_GLOOMCLAW_IS_PUSHED_BACK"] = "Serrenox est repoussé par la purification des essences !",
    ["DATACHRON_GLOOMCLAW_IS_MOVING_FORWARD"] = "Serrenox s'approche pour corrompre davantage d'essences !",
    ["GLOOMCLAW_IS_PUSHED_BACK"] = "Serrenox est repoussé",
    ["GLOOMCLAW_IS_MOVING_FORWARD"] = "Serrenox s'approche",
    ["CORRUPTING_RAYS"] = "Rayons de corruption",
    ["INTERRUPT_CORRUPTING_RAYS"] = "Coupez: Rayons Corrompus !",
  })
  self:RegisterTimer("NEXT_RUPTURE", { color = "xkcdBrightOrange" })
  self:RegisterTimer("APPROXIMATE_RUPTURE", { color = "xkcdBrightOrange" })
  self:RegisterTimer("NEXT_ADD_WAVE", { color = "xkcdBrightGreen" })
end
