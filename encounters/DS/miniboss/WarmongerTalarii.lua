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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("WARMONGER_TALARII")

------------------------------------------------------------------------------
-- WarmongerTalarii.
------------------------------------------------------------------------------
local WarmongerTalarii = {}

function WarmongerTalarii:NextProtectBubble()
  self:SetTimer("NEXT_PROTECT_BUBBLE", 60, self.NextProtectBubble)
  self:PlaySound("Long")
end

function WarmongerTalarii:OnStartCombat()
  self:CreateHealthBar()
  self:SetTimer("NEXT_PROTECT_BUBBLE", 53, self.NextProtectBubble)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 110)
  self:RegisterTriggerNames({"WARMONGER_TALARII"})
  self:RegisterUnitClass({
    -- All units allow to be tracked.
    WARMONGER_TALARII = WarmongerTalarii,
  })
  self:RegisterEnglishLocale({
    ["WARMONGER_TALARII"] = "Warmonger Talarii",
    ["NEXT_PROTECT_BUBBLE"] = "Next protection bubble",
  })
  self:RegisterFrenchLocale({
    ["WARMONGER_TALARII"] = "Guerroyeuse Talarii",
    ["NEXT_PROTECT_BUBBLE"] = "Prochaine bulle de protection",
  })
  self:RegisterTimer("NEXT_PROTECT_BUBBLE", { color = "xkcdBrightYellow" })
end
