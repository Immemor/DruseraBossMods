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
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("WARMONGER_CHUNA")

local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local _WarmongerChunaContext
local _firebomb_last_pop
local _firetotem_last_pop

------------------------------------------------------------------------------
-- WarmongerChuna.
------------------------------------------------------------------------------
local WarmongerChuna = {}

function WarmongerChuna:NextProtectBubble()
  self:SetTimer("NEXT_PROTECT_BUBBLE", 60, self.NextProtectBubble)
  self:PlaySound("Long")
end

function WarmongerChuna:OnStartCombat()
  _WarmongerChunaContext = self
  _firebomb_last_pop = 0
  _firetotem_last_pop = 0
  self:ActivateDetection(true)
  self:CreateHealthBar()
  self:SetTimer("NEXT_PROTECT_BUBBLE", 53, self.NextProtectBubble)
  self:SetTimer("NEXT_FIRE_BOMBS", 10)
end

------------------------------------------------------------------------------
-- ConjugerFireBomb.
------------------------------------------------------------------------------
local ConjugerFireBomb = {}

function ConjugerFireBomb:OnCreate()
  local nCurrentTime = GetGameTime()
  if _firebomb_last_pop + 10 < nCurrentTime then
    _firebomb_last_pop = nCurrentTime
    _WarmongerChunaContext:SetTimer("NEXT_FIRE_BOMBS", 25)
  end
end

------------------------------------------------------------------------------
-- TotemFire.
------------------------------------------------------------------------------
local TotemFire = {}

function TotemFire:OnCreate()
  local nCurrentTime = GetGameTime()
  if _firetotem_last_pop + 10 < nCurrentTime then
    _firetotem_last_pop = nCurrentTime
    _WarmongerChunaContext:SetTimer("NEXT_FIRE_TOTEM", 25)
  end
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 110)
  self:RegisterTriggerNames({"WARMONGER_CHUNA"})
  self:RegisterUnitClass({
    -- All units allow to be tracked.
    WARMONGER_CHUNA = WarmongerChuna,
    CONJUGER_FIRE_BOMB = ConjugerFireBomb,
    TOTEM_FIRE = TotemFire,
  })
  self:RegisterEnglishLocale({
    ["WARMONGER_CHUNA"] = "Warmonger Chuna",
    ["CONJUGER_FIRE_BOMB"] = "Conjuger Fire Bomb",
    ["TOTEM_FIRE"] = "Totem's Fire",
    ["NEXT_FIRE_BOMBS"] = "Next fire bombs",
    ["NEXT_FIRE_TOTEM"] = "Next Totems's fire",
    ["NEXT_PROTECT_BUBBLE"] = "Next protection bubble",
  })
  self:RegisterFrenchLocale({
    ["WARMONGER_CHUNA"] = "Guerroyeuse Chuna",
    ["CONJUGER_FIRE_BOMB"] = "Bombe incendiaire invoquée",
    ["TOTEM_FIRE"] = "Totem de feu invoqué",
    ["NEXT_FIRE_BOMBS"] = "Prochaine bombes de feu",
    ["NEXT_FIRE_TOTEM"] = "Prochaine totems de feu",
    ["NEXT_PROTECT_BUBBLE"] = "Prochaine bulle de protection",
  })
  self:RegisterTimer("NEXT_FIRE_BOMBS", { color = "xkcdBrightOrange" })
  self:RegisterTimer("NEXT_FIRE_TOTEM", { color = "red" })
  self:RegisterTimer("NEXT_PROTECT_BUBBLE", { color = "xkcdBrightYellow" })
end
