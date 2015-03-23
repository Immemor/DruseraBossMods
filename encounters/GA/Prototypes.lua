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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("PHAGETECH_PROTOTYPES")

------------------------------------------------------------------------------
-- PhagetechCommander.
------------------------------------------------------------------------------
local PhagetechCommander = {}

function PhagetechCommander:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastStart("FORCED_PRODUCTION", function(self)
    self:SetTimer("FORCED_PRODUCTION", 36)
  end)
  self:SetCastStart("DESTRUCTION_PROTOCOL", function(self)
    self:SetTimer("DESTRUCTION_PROTOCOL", 17)
  end)
  self:SetCastStart("MALICIOUS_UPLINK", function(self)
    self:SetTimer("MALICIOUS_UPLINK", 5)
  end)
end

------------------------------------------------------------------------------
-- PhagetechAugmentor.
------------------------------------------------------------------------------
local PhagetechAugmentor = {}

function PhagetechAugmentor:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastStart("PHAGETECH_BORER", function(self)
    self:SetTimer("PHAGETECH_BORER", 17)
  end)
  self:SetCastStart("SUMMON_REPAIRBOT", function(self)
    self:SetTimer("SUMMON_REPAIRBOT", 17)
  end)
end

------------------------------------------------------------------------------
-- PhagetechProtector.
------------------------------------------------------------------------------
local PhagetechProtector = {}

function PhagetechProtector:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastStart("PULSE_A_TRON_WAVE", function(self)
    self:SetTimer("PULSE_A_TRON_WAVE", 15)
  end)
end

------------------------------------------------------------------------------
-- PhagetechFabricator.
------------------------------------------------------------------------------
local PhagetechFabricator = {}

function PhagetechFabricator:OnStartCombat()
  self:CreateHealthBar()
  self:SetCastStart("SUMMON_DESTRUCTOBOT", function(self)
    self:SetTimer("SUMMON_DESTRUCTOBOT", 16)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(147, 149)
  self:RegisterTriggerNames({
    "PHAGETECH_COMMANDER", "PHAGETECH_AUGMENTOR",
    "PHAGETECH_PROTECTOR", "PHAGETECH_FABRICATOR"
  })
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    PHAGETECH_COMMANDER = PhagetechCommander,
    PHAGETECH_AUGMENTOR = PhagetechAugmentor,
    PHAGETECH_PROTECTOR = PhagetechProtector,
    PHAGETECH_FABRICATOR = PhagetechFabricator,
  })
  self:RegisterEnglishLocale({
    ["PHAGETECH_PROTOTYPES"] = "Phagetech Prototypes",
    ["PHAGETECH_COMMANDER"] = "Phagetech Commander",
    ["PHAGETECH_AUGMENTOR"] = "Phagetech Augmentor",
    ["PHAGETECH_PROTECTOR"] = "Phagetech Protector",
    ["PHAGETECH_FABRICATOR"] = "Phagetech Fabricator",
    ["POWERING_UP"] = "Powering Up",
    ["POWERING_DOWN"] = "Powering Down",
    ["FORCED_PRODUCTION"] = "Forced Production",
    ["DESTRUCTION_PROTOCOL"] = "Destruction Protocol",
    ["MALICIOUS_UPLINK"] = "Malicious Uplink",
    ["PHAGETECH_BORER"] = "Phagetech Borer",
    ["SUMMON_REPAIRBOT"] = "Summon Repairbot",
    ["PULSE_A_TRON_WAVE"] = "Pulse-A-Tron Wave",
    ["GRAVITATIONAL_SINGULARITY"] = "Gravitational Singularity",
    ["SUMMON_DESTRUCTOBOT"] = "Summon Destructobot",
    ["TECHNOPHAGE_CATALYST"] = "Technophage Catalyst",
  })
  self:RegisterFrenchLocale({
    ["PHAGETECH_PROTOTYPES"] = "Prototypes Phagetech",
    ["PHAGETECH_COMMANDER"] = "Commandant technophage",
    ["PHAGETECH_AUGMENTOR"] = "Augmenteur technophage",
    ["PHAGETECH_PROTECTOR"] = "Protecteur technophage",
    ["PHAGETECH_FABRICATOR"] = "Fabricant technophage",
    ["POWERING_UP"] = "Mise en marche",
    ["POWERING_DOWN"] = "Coupure de courant",
    ["FORCED_PRODUCTION"] = "Production forcée",
    ["DESTRUCTION_PROTOCOL"] = "Protocole de destruction",
    ["MALICIOUS_UPLINK"] = "Liaison railleuse",
    ["PHAGETECH_BORER"] = "Foreuse technophage",
    ["SUMMON_REPAIRBOT"] = "Déployer Bricobot",
    ["PULSE_A_TRON_WAVE"] = "Vague pulsatomique",
    ["GRAVITATIONAL_SINGULARITY"] = "Singularité gravitationnelle",
    ["SUMMON_DESTRUCTOBOT"] = "Déployer Destructobot",
    ["TECHNOPHAGE_CATALYST"] = "Catalyse technophage",
  })
  self:RegisterTimer("FORCED_PRODUCTION", { color = "xkcdBrightOrange" })
  self:RegisterTimer("DESTRUCTION_PROTOCOL", { color = "xkcdBrightOrange" })
  self:RegisterTimer("MALICIOUS_UPLINK", { color = "xkcdBrightOrange" })
  self:RegisterTimer("PHAGETECH_BORER", { color = "xkcdBrightPurple" })
  self:RegisterTimer("SUMMON_REPAIRBOT", { color = "xkcdBrightPurple" })
  self:RegisterTimer("PULSE_A_TRON_WAVE", { color = "xkcdBrightGreen" })
  self:RegisterTimer("SUMMON_DESTRUCTOBOT", { color = "xkcdBrightPink" })
end
