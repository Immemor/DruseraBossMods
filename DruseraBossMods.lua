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
--
--  TODO: Write a presentation.
--
------------------------------------------------------------------------------
require "Window"
require "GameLib"
require "Apollo"

------------------------------------------------------------------------------
-- Constantes
------------------------------------------------------------------------------
local DRUSERABOSSMODS_VERSION =  "0.15-alpha" -- "@project-version@"

------------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------------
local DruseraBossMods = {}

function DruseraBossMods:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.DRUSERABOSSMODS_VERSION = DRUSERABOSSMODS_VERSION
  self.DataBase = {}
  return o
end

function DruseraBossMods:Init()
  Apollo.RegisterAddon(self, false, "", {})
  self.L = Apollo.GetPackage("Gemini:Locale-1.0").tPackage:GetLocale("DruseraBossMods")
  self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, {})
end

function DruseraBossMods:OnDependencyError(strDep, strError)
  Print("OnDependencyError: " .. strDep .. "  " ..strError)
  return false
end

function DruseraBossMods:OnLoad()
  Apollo.LoadSprites("DruseraBossMods_Sprites.xml")
  self.xmlDoc = XmlDoc.CreateFromFile("DruseraBossMods.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function DruseraBossMods:OnDocLoaded()
  if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then return end

  Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
  -- From highest layer to lowest layer.
  self:GUIInit()
  self:HUDInit()
  self.CombatManager = self:CombatManagerInit()
end

function DruseraBossMods:OnWindowManagementReady()
  self:GUIWindowsManagementAdd()
  self:HUDWindowsManagementAdd()
end

------------------------------------------------------------------------------
-- DruseraBossMods Instance
------------------------------------------------------------------------------
local DruseraBossModsInst = DruseraBossMods:new()
DruseraBossModsInst:Init()
-- For debugging purpose through GeminiConsole, quite useful.
_G["DBM"] = DruseraBossModsInst
