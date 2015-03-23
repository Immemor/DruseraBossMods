------------------------------------------------------------------------------
-- Client Lua Script for DruseraBossMods
--
-- Copyright (C) 2015 Thierry carré
--
-- Player Name: 'Immé sama'
-- Guild Name: 'Les Solaris'
-- Server Name: Jabbit(EU)
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- The combat start with an invisible unit. It's easier because the Zone is
-- hudge.
------------------------------------------------------------------------------

require "Apollo"
require "GameLib"

local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("LIMBO_INFOMATRIX")

local GetPlayerUnit = GameLib.GetPlayerUnit
local InvisibleHateUnit = {}
local KeeperOfSands = {}
local InfomatrixAntlion = {}
local Invisible_Unit = {}

function InvisibleHateUnit:OnStartCombat()
  self:ActivateDetection(true)
end

function InfomatrixAntlion:OnCreate()
  self:CreateHealthBar()
end

function KeeperOfSands:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastStart("CAST_EXHAUST", function(self)
    local d = self:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
    if d and d < 55 then
      self:PlaySound("Info")
      self:SetMessage({
        sLabel = "MSG_WARNING_KNOCKBACK",
        nDuration = 3,
        bHighlight = true,
      })
    end
  end)
  self:SetCastStart("CAST_DESICCATE", function(self)
    local d = self:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
    if d and d < 55 then
      self:PlaySound("Alert")
    end
  end)
end

function Invisible_Unit:OnCreate()
  local d = self:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
  if d and d < 50 then
    self:SetMarkOnUnit("GraySkull", self.nId)
    self:SetCircle(self.nId, 1, 4)
    self:SetCircle(self.nId, 2, 7)
  end
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 114)
  self:RegisterTriggerNames({"INVISIBLE_HATE_UNIT"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    INVISIBLE_HATE_UNIT = InvisibleHateUnit,
    KEEPER_OF_SANDS = KeeperOfSands,
    INFOMATRIX_ANTLION = InfomatrixAntlion,
    HOSTILE_INVISIBLE_UNIT = Invisible_Unit,
  })
  self:RegisterEnglishLocale({
    ["LIMBO_INFOMATRIX"] = "Limbo Infomatrix",
    ["INVISIBLE_HATE_UNIT"] = "Invisible Hate Unit",
    ["KEEPER_OF_SANDS"] = "Keeper of Sands",
    ["INFOMATRIX_ANTLION"] = "Infomatrix Antlion",
    ["MINI_SANDWORM"] = "Mini Sandworm", -- It's on antlion units, the 3 worms which KB.
    ["HOSTILE_INVISIBLE_UNIT"] = "Hostile Invisible Unit for Fields (0 hit radius)",
    ["CAST_EXHAUST"] = "Exhaust",
    ["CAST_DESICCATE"] = "Desiccate",
    ["MSG_WARNING_KNOCKBACK"] = "Warning: Knock-Back",
  })
  self:RegisterFrenchLocale({
    ["LIMBO_INFOMATRIX"] = "Limbo Infomatrix",
    ["INVISIBLE_HATE_UNIT"] = "Unité haineuse invisible",
    ["KEEPER_OF_SANDS"] = "Gardien des sables",
    ["INFOMATRIX_ANTLION"] = "Fourmilion de l'Infomatrice",
    ["MINI_SANDWORM"] = "Mini Tempête de sable",
    ["HOSTILE_INVISIBLE_UNIT"] = "Unité hostile invisible de", -- TODO
    ["CAST_EXHAUST"] = "Épuiser",
    ["CAST_DESICCATE"] = "Arracher",
    ["MSG_WARNING_KNOCKBACK"] = "Attention: Knock-Back",
  })
end
