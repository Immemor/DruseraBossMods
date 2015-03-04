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
local DBM = Apollo.GetAddon("DruseraBossMods")
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local Terax = {}
local Golgox = {}
local Fleshmonger = {}
local Noxmind = {}
local Ersoth = {}

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
local function NextStitchingStrain(self)
  DBM:SetTimerAlert(self, "STITCHING_STRAIN", 55, nil)
end

local function NextConvergence(self)
  DBM:ClearAllTimerAlert()
  DBM:SetTimerAlert(self, "NEXT_CONVERGENCE", 85, nil)
end

local function CommonStart(self)
  DBM:SetTimerAlert(self, "NEXT_CONVERGENCE", 91, nil)
  DBM:SetCastStartAlert(self, "TELEPORT", NextConvergence)
end

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function Terax:OnStartCombat()
  DBM:CreateHealthBar(self, "TERAX_BLIGHTWEAVER")
  CommonStart(self)

  DBM:SetCastStartAlert(self, "STITCHING_STRAIN", function(self)
    local d = DBM:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
    if d and d < 35 then
      DBM:PlaySound("Alarm")
      DBM:SetMessage({
        sLabel = "INTERRUPT_THIS_CAST",
        nDuration = 4,
        bHighlight = true,
      })
    end
  end)
  -- Stitching strain
  DBM:SetCastFailedAlert(self, "STITCHING_STRAIN", NextStitchingStrain)
  DBM:SetCastSuccessAlert(self, "STITCHING_STRAIN", NextStitchingStrain)
end

function Golgox:OnStartCombat()
  DBM:CreateHealthBar(self, "GOLGOX_THE_LIFECRUSHER")
  CommonStart(self)
end

function Fleshmonger:OnStartCombat()
  DBM:CreateHealthBar(self, "FLESHMONGER_VRATORG")
  CommonStart(self)
end

function Noxmind:OnStartCombat()
  DBM:CreateHealthBar(self, "NOXMIND_THE_INSIDIOUS")
  CommonStart(self)
  DBM:SetCastSuccessAlert(self, "ESSENCE_ROT", function(self)
    local n = DBM:GetTimerRemaining("TELEPORT")
    if not n or n < 17 then
      DBM:SetTimerAlert(self, "ESSENCE_ROT", 17, nil)
    end
  end)
end

function Ersoth:OnStartCombat()
  DBM:CreateHealthBar(self, "ERSOTH_CURSEFORM")
  CommonStart(self)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 147,
    nZoneMapId = 149,
    sEncounterName = "CONVERGENCE",
    tTriggerNames = {
      "TERAX_BLIGHTWEAVER", "GOLGOX_THE_LIFECRUSHER", "FLESHMONGER_VRATORG",
      "NOXMIND_THE_INSIDIOUS", "ERSOTH_CURSEFORM",
    },
    tUnits = {
      TERAX_BLIGHTWEAVER = Terax,
      GOLGOX_THE_LIFECRUSHER = Golgox,
      FLESHMONGER_VRATORG = Fleshmonger,
      NOXMIND_THE_INSIDIOUS = Noxmind,
      ERSOTH_CURSEFORM = Ersoth,
    },
    tCustom = {
      TERAX_BLIGHTWEAVER = {
        BarsCustom = {
          STITCHING_STRAIN = { color = "red" },
        },
      },
    },
  })
end
