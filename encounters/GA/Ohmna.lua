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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("DREADPHAGE_OHMNA")

------------------------------------------------------------------------------
-- Ohmna.
------------------------------------------------------------------------------
local Ohmna = {}

function Ohmna:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastEnd("DEVOUR", function(self)
    self:SetTimer("DEVOUR", 25.5)
  end)
  self:SetCastEnd("BODY_SLAM", function(self)
    self:SetTimer("BODY_SLAM", 84)
  end)
  self:SetCastEnd("GENETIC_TORRENT", function(self)
    self:SetTimer("GENETIC_TORRENT", 84)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(147, 149)
  self:RegisterTriggerNames({ "DREADPHAGE_OHMNA" })
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    DREADPHAGE_OHMNA = Ohmna,
  })
  self:RegisterEnglishLocale({
    ["DREADPHAGE_OHMNA"] = "Dreadphage Ohmna",
    ["BODY_SLAM"] = "Body Slam",
    ["DEVOUR"] = "Devour",
    ["GENETIC_TORRENT"] = "Genetic Torrent",
  })
  self:RegisterFrenchLocale({
    ["DREADPHAGE_OHMNA"] = "Ohmna la Terriphage",
    ["BODY_SLAM"] = "Coup corporel",
    ["DEVOUR"] = "Dévorer",
    ["GENETIC_TORRENT"] = "Torrent génétique",
  })
  self:RegisterTimer("BODY_SLAM", { color = "xkcdBrightOrange" })
  self:RegisterTimer("DEVOUR", { color = "xkcdBrightOrange" })
  self:RegisterTimer("GENETIC_TORRENT", { color = "xkcdBrightOrange" })
end
