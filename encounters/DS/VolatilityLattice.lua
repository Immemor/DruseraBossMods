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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("VOLATILITY_LATTICE")

local GetGameTime = GameLib.GetGameTime
local Avatus = {}
local ObstinateLogicWall = {}
local DataDevourer = {}
local _DataDevourerCount = 0
local _nLastDataDevourerPopTime = 0
local _Avatus_ctx

function ObstinateLogicWall:OnStartCombat()
  self:CreateHealthBar()
end

function Avatus:OnStartCombat()
  _Avatus_ctx = self
  _DataDevourerCount = 0
  _nLastDataDevourerPopTime = 0
  self:ActivateDetection(true)
  self:SetTimer("NEXT_DATA_DEVOURER", 10)
  self:SetTimer("NEXT_PILLAR", 45)

  self:SetDatachronAlert("DATACHRON_AVATUS_PREPARES_TO_DELETE_ALL",
  function(self)
    self:SetTimer("NEXT_PILLAR", 50)
    self:PlaySound("Info")
  end)
  self:SetDatachronAlert("DATACHRON_SECURE_SECTOR", function(self)
    -- Protect phase
    self:PlaySound("Long")
    self:SetMessage({
      sLabel = "MSG_SHIELD_PHASE",
      nDuration = 5,
      bHighlight = true,
    })
    -- context switch, reprogram few timers.
    self:SetTimer("NEXT_DATA_DEVOURER", 53)
    self:SetTimer("NEXT_PILLAR", 58)
  end)
  self:SetDatachronAlert("DATACHRON_VERTICAL_LOCOMOTION", function(self)
    -- Jump phase
    self:PlaySound("Long")
    self:SetMessage({
      sLabel = "MSG_JUMP_PHASE",
      nDuration = 5,
      bHighlight = true,
    })
    -- context switch, reprogram few timers.
    self:SetTimer("NEXT_PILLAR", 73)
    self:SetTimer("NEXT_DATA_DEVOURER", 68)
  end)
end

function DataDevourer:OnCreate()
  local nCurrentTime = GetGameTime()
  local nDelta = nCurrentTime - _nLastDataDevourerPopTime
  if nDelta > 3 then
    _nLastDataDevourerPopTime = nCurrentTime
    _DataDevourerCount = _DataDevourerCount + 1
    _Avatus_ctx:SetTimer("NEXT_DATA_DEVOURER", 15)
  end
  self:SetMarkOnUnit("WhiteSkull", self.nId)
end

function DataDevourer:OnDestroy()
  self:SetMarkOnUnit(nil, self.nId)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 116)
  self:RegisterTriggerNames({"AVATUS"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    AVATUS = Avatus,
    OBSTINATE_LOGIC_WALL = ObstinateLogicWall,
    DATA_DEVOURER = DataDevourer,
  })
  self:RegisterEnglishLocale({
    ["VOLATILITY_LATTICE"] = "Volatility Lattice",
    ["AVATUS"] = "Avatus",
    ["OBSTINATE_LOGIC_WALL"] = "Obstinate Logic Wall",
    ["DATA_DEVOURER"] = "Data Devourer",
    ["CAST_NULL_AND_VOID"] = "Null and Void",
    ["DATACHRON_AVATUS_PREPARES_TO_DELETE_ALL"] = "Avatus prepares to delete all data!",
    ["DATACHRON_SECURE_SECTOR"] = "The Secure Sector Enhancement Ports have been activated!",
    ["DATACHRON_VERTICAL_LOCOMOTION"] = "The Vertical Locomotion Enhancement Ports have been activated!",
    ["NEXT_PILLAR"] = "Next pillars to click",
    ["NEXT_DATA_DEVOURER"] = "Next data devourer",
    ["MSG_JUMP_PHASE"] = "Jump phase",
    ["MSG_SHIELD_PHASE"] = "Protection phase",
  })
  self:RegisterFrenchLocale({
    ["VOLATILITY_LATTICE"] = "Réseau instable",
    ["AVATUS"] = "Avatus",
    ["OBSTINATE_LOGIC_WALL"] = "Mur de logique obstiné",
    ["DATA_DEVOURER"] = "Dévoreur de données",
    ["CAST_NULL_AND_VOID"] = "Caduque",
    ["DATACHRON_AVATUS_PREPARES_TO_DELETE_ALL"] = "Avatus se prépare à effacer toutes les données !",
    ["DATACHRON_SECURE_SECTOR"] = "Les ports d'amélioration de secteur sécurisé ont été activés !",
    ["DATACHRON_VERTICAL_LOCOMOTION"] = "Les ports d'amélioration de locomotion verticale ont été activés !",
    ["NEXT_PILLAR"] = "Prochain pilliers à cliquer",
    ["NEXT_DATA_DEVOURER"] = "Prochain dévoreur de données",
    ["MSG_JUMP_PHASE"] = "Phase de saut",
    ["MSG_SHIELD_PHASE"] = "Phase de protection",
  })
  self:RegisterTimer("NEXT_DATA_DEVOURER", { color = "xkcdBrightPurple" })
  self:RegisterTimer("NEXT_PILLAR", { color = "xkcdBrightOrange" })
end
