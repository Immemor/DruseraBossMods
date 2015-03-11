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
local GetPlayerUnit = GameLib.GetPlayerUnit
local LimboInfomatrix = {}
local KeeperOfSands = {}
local InfomatrixAntlion = {}
local AOE = {}

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function InfomatrixAntlion:OnDetection()
  DBM:CreateHealthBar(self, "INFOMATRIX_ANTLION")
end

function KeeperOfSands:OnStartCombat()
  DBM:ActivateDetection(true)
  DBM:CreateHealthBar(self, "KEEPER_OF_SANDS")
  DBM:SetCastStartAlert(self, "CAST_EXHAUST", function(self)
    local d = DBM:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
    if d and d < 35 then
      DBM:PlaySound("Info")
      DBM:SetMessage({
        sLabel = "MSG_WARNING_KNOCKBACK",
        nDuration = 3,
        bHighlight = true,
      })
    end
  end)
end

function AOE:OnDetection()
  local d = DBM:GetDistBetween2Unit(GetPlayerUnit(), self.tUnit)
  if d and d < 50 then
    Print("Mark")
    DBM:SetMarkOnUnit("GraySkull", self.nId, 52)
  end
end

function InfomatrixAntlion:OnStartCombat()
  DBM:ActivateDetection(true)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 98,
    nZoneMapId = 114,
    sEncounterName = "LIMBO_INFOMATRIX",
    tTriggerNames = { "KEEPER_OF_SANDS", "INFOMATRIX_ANTLION"},
    tUnits = {
      LIMBO_INFOMATRIX = LimboInfomatrix,
      KEEPER_OF_SANDS = KeeperOfSands,
      INFOMATRIX_ANTLION = InfomatrixAntlion,
    },
  })
end
