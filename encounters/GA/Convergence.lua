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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("CONVERGENCE")

local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
local function NextConvergence(self)
  self:ClearAllTimerAlert()
  self:SetTimer("NEXT_CONVERGENCE", 85)
end

local function CommonStart(self)
  self:SetTimer("NEXT_CONVERGENCE", 91)
  self:SetCastStart("TELEPORT", NextConvergence)
end

------------------------------------------------------------------------------
-- Terax.
------------------------------------------------------------------------------
local Terax = {}

function Terax:OnStartCombat()
  self:CreateHealthBar()
  CommonStart(self)

  self:SetCastStart("STITCHING_STRAIN", function(self)
    local d = self:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
    if d and d < 35 then
      self:PlaySound("Alarm")
      self:SetMessage({
        sLabel = "INTERRUPT_THIS_CAST",
        nDuration = 4,
        bHighlight = true,
      })
    end
  end)
  -- Stitching strain
  self:SetCastEnd("STITCHING_STRAIN", function(self)
    self:SetTimer("STITCHING_STRAIN", 55)
  end)
end

------------------------------------------------------------------------------
-- Golgox.
------------------------------------------------------------------------------
local Golgox = {}

function Golgox:OnStartCombat()
  self:CreateHealthBar()
  CommonStart(self)
end

------------------------------------------------------------------------------
-- Fleshmonger.
------------------------------------------------------------------------------
local Fleshmonger = {}

function Fleshmonger:OnStartCombat()
  self:CreateHealthBar()
  CommonStart(self)
end

------------------------------------------------------------------------------
-- Noxmind.
------------------------------------------------------------------------------
local Noxmind = {}

function Noxmind:OnStartCombat()
  self:CreateHealthBar()
  CommonStart(self)
  self:SetCastEnd("ESSENCE_ROT", function(self)
    local n = self:GetTimerRemaining("TELEPORT")
    if not n or n < 17 then
      self:SetTimer("ESSENCE_ROT", 17, nil)
    end
  end)
end

------------------------------------------------------------------------------
-- Ersoth.
------------------------------------------------------------------------------
local Ersoth = {}

function Ersoth:OnStartCombat()
  self:CreateHealthBar()
  CommonStart(self)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(147, 149)
  self:RegisterTriggerNames({
    "TERAX_BLIGHTWEAVER", "GOLGOX_THE_LIFECRUSHER", "FLESHMONGER_VRATORG",
    "NOXMIND_THE_INSIDIOUS", "ERSOTH_CURSEFORM",
  })
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    TERAX_BLIGHTWEAVER = Terax,
    GOLGOX_THE_LIFECRUSHER = Golgox,
    FLESHMONGER_VRATORG = Fleshmonger,
    NOXMIND_THE_INSIDIOUS = Noxmind,
    ERSOTH_CURSEFORM = Ersoth,
  })
  self:RegisterEnglishLocale({
    ["CONVERGENCE"] = "Convergence",
    ["TERAX_BLIGHTWEAVER"] = "Terax Blightweaver",
    ["GOLGOX_THE_LIFECRUSHER"] = "Golgox the Lifecrusher",
    ["FLESHMONGER_VRATORG"] = "Fleshmonger Vratorg",
    ["NOXMIND_THE_INSIDIOUS"] = "Noxmind the Insidious",
    ["ERSOTH_CURSEFORM"] = "Ersoth Curseform",
    ["TELEPORT"] = "Teleport",
    ["STITCHING_STRAIN"] = "Stitching Strain",
    ["DEMOLISH"] = "Demolish",
    ["SCATTER"] = "Scatter",
    ["ESSENCE_ROT"] = "Essence Rot",
    ["EQUALIZE"] = "équalise",
    ["NEXT_CONVERGENCE"] = "Next convergence",
  })
  self:RegisterFrenchLocale({
    ["CONVERGENCE"] = "Convergence",
    ["TERAX_BLIGHTWEAVER"] = "Terax Tisserouille",
    ["GOLGOX_THE_LIFECRUSHER"] = "Golgox le Fossoyeur",
    ["FLESHMONGER_VRATORG"] = "Vratorg le Cannibale",
    ["NOXMIND_THE_INSIDIOUS"] = "Toxultime l'Insidieux",
    ["ERSOTH_CURSEFORM"] = "Ersoth le Maudisseur",
    ["TELEPORT"] = "Se téléporter",
    ["STITCHING_STRAIN"] = "Pression de suture",
    ["DEMOLISH"] = "Démolir",
    ["SCATTER"] = "Disperser",
    ["ESSENCE_ROT"] = "Pourriture d'essence",
    ["EQUALIZE"] = "équalise",
    ["NEXT_CONVERGENCE"] = "Prochaine convergence",
  })
  self:RegisterTimer("NEXT_CONVERGENCE", { color = "xkcdBrightOrange" })
end
