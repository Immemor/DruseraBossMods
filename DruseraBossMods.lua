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
-- Initialization
------------------------------------------------------------------------------
local DruseraBossMods = {}
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local Locale = GeminiLocale:GetLocale("DruseraBossMods")

function DruseraBossMods:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  self.DataBase = {}
  return o
end

function DruseraBossMods:Init()
  local bHasConfigureFunction = true
  local strConfigureButtonText = "DruseraBossMods"
  local tDependencies = {}
  Apollo.RegisterAddon(self, bHasConfigureFunction,
    strConfigureButtonText, tDependencies)
end

function DruseraBossMods:OnLoad()
  Apollo.LoadSprites("DruseraBossMods_Sprites.xml")
  self.xmlDoc = XmlDoc.CreateFromFile("DruseraBossMods.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

------------------------------------------------------------------------------
-- DruseraBossMods OnDocLoaded
------------------------------------------------------------------------------
function DruseraBossMods:OnDocLoaded()
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    -- Better Logger for debugging purpose.
    self.GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
    self.Logger = self.GeminiLogging:GetLogger({
      level = self.GeminiLogging.ERROR,
      pattern = "[%c:%n]: %m",
      appender = "GeminiConsole"})

    Apollo.RegisterEventHandler("InterfaceMenuListHasLoaded",
                                "OnInterfaceMenuListHasLoaded", self)
  end
end

function DruseraBossMods:OnConfigure(strCommand, strParam)
  self:OnToggleMainGUI()
end

function DruseraBossMods:OnInterfaceMenuListHasLoaded()
  -- From highest layer to lowest layer.
  self:GUIInit()
  self:HUDInit()
  self:ManagerInit()
  self:InterfaceInit()
  -- Send signal.
  Event_FireGenericEvent("InterfaceMenuList_NewAddOn", "DruseraBossMods", {"OnToggleMainGUI", "", ""})
end

function DruseraBossMods:RegisterEncounter(
    tEncounterInfo, tUnitsInfo, tCustom)
  local RaidName = Locale[tEncounterInfo.RaidName]
  local EncounterName = Locale[tEncounterInfo.EncounterName]
  local ZoneName = Locale[tEncounterInfo.ZoneName]

  for sUnitName, tInfo in pairs(tUnitsInfo) do
    local UnitName = Locale[sUnitName] or ""
    tInfo.RaidName = RaidName
    tInfo.EncounterName = EncounterName
    tInfo.ZoneName = ZoneName
    tInfo.DisplayName = UnitName
    tInfo.bEnable = true
    tInfo.BarsCustom = {}

    if tCustom and tCustom[sUnitName] then
      for key,rule in next, tCustom[sUnitName] do
        if key == "DisplayName" then
          tInfo.DisplayName = Locale[rule]
        elseif key == "BarsCustom" then
          for SpellName, options in next, rule do
            local name = Locale[SpellName]
            tInfo.BarsCustom[name] = options
          end
        end
      end
    end

    self.DataBase[UnitName] = tInfo
  end
end

------------------------------------------------------------------------------
-- DruseraBossMods Instance
------------------------------------------------------------------------------

local DruseraBossModsInst = DruseraBossMods:new()
DruseraBossModsInst:Init()
