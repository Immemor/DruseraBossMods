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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("FROST_ELEMENTAL_PAIRS")

local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local SPELLID_ICETOMB = 74326
local SPELLID_FROSTBOMB = 75058
local SPELLID_FIREBOMB = 75059
local SPELLID_DRENCHED = 52874
local SPELLID_ENGULFED = 52876

------------------------------------------------------------------------------
-- Common.
------------------------------------------------------------------------------
local _LastDebufBomb = 0
local function BombExplosion(nTargetId)
  local nCurrentTime = GetGameTime()
  local delta = nCurrentTime - _LastDebufBomb
  if delta > 10 then
    _LastDebufBomb = nCurrentTime
    ENCOUNTER:SetTimer("BOMB_EXPLOSION", 10)
  end
  if GetPlayerUnit():GetId() == nTargetId then
    self:PlaySound("Alert")
  end
end

------------------------------------------------------------------------------
-- Hydroflux.
------------------------------------------------------------------------------
local Hydroflux = {}

function Hydroflux:OnStartCombat()
  -- Frost Bomb.
  self:SetDebuffAddAlert(SPELLID_FROSTBOMB, function(self, nTargetId)
    self:SetMarkOnUnit("Crosshair", nTargetId)
    BombExplosion(nTargetId)
  end)
  self:SetDebuffAddRemove(SPELLID_FROSTBOMB, function(self, nTargetId)
    self:SetMarkOnUnit(nil, nTargetId)
  end)
  self:SetDebuffUpdateAlert(SPELLID_DRENCHED,
  function(self, nTargetId, nStack)
    if nStack >= 10 and GetPlayerUnit():GetId() == nTargetId then
      self:PlaySound("Info")
    end
  end)

  -- Frost Tomb.
  self:SetDebuffAddAlert(SPELLID_ICETOMB, function(self, nTargetId)
    self:SetMarkOnUnit("Crosshair", nTargetId)
    BombExplosion(nTargetId)
  end)
  self:SetDebuffAddRemove(SPELLID_ICETOMB, function(self, nTargetId)
    self:SetMarkOnUnit(nil, nTargetId)
  end)
end

local IceTomb = {}
local _nLastIceTomb = 0

function IceTomb:OnCreate()
  local nCurrentTime = GetGameTime()
  local delta = nCurrentTime - _nLastIceTomb
  if delta > 10 then
    _nLastIceTomb = nCurrentTime
    ENCOUNTER:SetTimer("ICE_TOMB", 15)
  end
end

------------------------------------------------------------------------------
-- Pyrobane.
------------------------------------------------------------------------------
local Pyrobane = {}

function Pyrobane:NextBombs()
  self:SetTimer("NEXT_BOMBS", 30)
end

function Pyrobane:OnStartCombat()
  self:SetNPCSayAlert(SAY_BURNING_MORTALS , self.NextBombs)
  self:SetNPCSayAlert(SAY_RUN , self.NextBombs)
  self:SetNPCSayAlert(SAY_THE_SMELL_OF_SEARED_FLESH , self.NextBombs)
  self:SetNPCSayAlert(SAY_DEADLY_FLAME , self.NextBombs)
  self:SetNPCSayAlert(SAY_IGNITES_YOU , self.NextBombs)

  self:SetDebuffAddAlert(SPELLID_FIREBOMB, function(self, nTargetId)
    self:SetMarkOnUnit("Crosshair", nTargetId)
    BombExplosion(nTargetId)
  end)
  self:SetDebuffAddRemove(SPELLID_FIREBOMB, function(self, nTargetId)
    self:SetMarkOnUnit(nil, nTargetId)
  end)
  self:SetDebuffUpdateAlert(SPELLID_ENGULFED,
  function(self, nTargetId, nStack)
    if nStack >= 10 and GetPlayerUnit():GetId() == nTargetId then
      self:PlaySound("Info")
    end
  end)
end

local FlameWave = {}
function FlameWave:OnCreate()
  -- Must be tested before delivery.
  -- self:SetLineOnUnit(self.nId, 1, 0, 10, 10)
end

------------------------------------------------------------------------------
-- Mnemesis.
------------------------------------------------------------------------------
local Mnemesis = {}

function Mnemesis:OnStartCombat()
end

------------------------------------------------------------------------------
-- Aileron.
------------------------------------------------------------------------------
local Aileron = {}

function Aileron:OnStartCombat()
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 118)
  self:RegisterTriggerNames({"HYDROFLUX"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    HYDROFLUX = Hydroflux,
    PYROBANE = Pyrobane,
    MNEMESIS = Mnemesis,
    AILERON = Aileron,
    ICE_TOMB = IceTomb,
    FLAME_WAVE = FlameWave,
  })
  self:RegisterEnglishLocale({
    ["FROST_ELEMENTAL_PAIRS"] = "Frost Elemental Pairs",
    ["HYDROFLUX"] = "Hydroflux",
    ["PYROBANE"] = "Pyrobane",
    ["MNEMESIS"] = "Mnemesis",
    ["AILERON"] = "Aileron",

    ["ICE_TOMB"] = "Ice Tomb",
    ["FLAME_WAVE"] = "Flame Wave",
    ["SAY_BURNING_MORTALS"] = "Burning mortals... such sweet agony",
    ["SAY_RUN"] = "Run! Soon my fires will destroy you",
    ["SAY_THE_SMELL_OF_SEARED_FLESH"] = "Ah! The smell of seared flesh",
    ["SAY_DEADLY_FLAME"] = "Enshrouded in deadly flame!",
    ["SAY_IGNITES_YOU"] = "Pyrobane ignites you",
    ["NEXT_BOMBS"] = "Next bombs",
    ["BOMB_EXPLOSION"] = "Bomb Explosion",
    ["DRENCHED"] = "Drenched",
    ["ENGULFED"] = "Engulfed",
  })
  self:RegisterFrenchLocale({
    ["FROST_ELEMENTAL_PAIRS"] = "Pairs Elémentaire du Froid",
    ["HYDROFLUX"] = "Hydroflux",
    ["PYROBANE"] = "Pyromagnus",
    ["MNEMESIS"] = "Mnemesis", -- TOCHECK
    ["AILERON"] = "Ventemort",

    ["ICE_TOMB"] = "Tombeau Glacée", -- TOCHECK
    ["FLAME_WAVE"] = "Vague de flamme", -- TOCHECK
    ["SAY_BURNING_MORTALS"] = "Brulez mortels... quelle douce agonie !", -- TOCHECK
    ["SAY_RUN"] = "Courrez ! Bientôt mes flammes vont vous détruire !", -- TOCHECK
    ["SAY_THE_SMELL_OF_SEARED_FLESH"] = "TODO3", -- TODO
    ["SAY_DEADLY_FLAME"] = "Drapés dans un voile de flammes meutrières !", -- OK
    ["SAY_IGNITES_YOU"] = "Pyromagnus vous enflamme", -- TOCHECK
    ["NEXT_BOMBS"] = "Prochaine bombes",
    ["BOMB_EXPLOSION"] = "Bombe Explosion",
    ["DRENCHED"] = "Trempé",
    ["ENGULFED"] = "Englouti",
  })
  self:RegisterTimer("BOMB_EXPLOSION", { color = "xkcdBrightRed" })
  self:RegisterTimer("NEXT_BOMBS", { color = "xkcdBrightOrange" })
  self:RegisterTimer("ICE_TOMB", { color = "xkcdBrightSkyBlue" })
end

function ENCOUNTER:OnEnable()
  self:ActivateDetection(true)
end
