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

local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("DruseraBossMods", false)
local ModulePrototype = {}

_G["DBM"] = DBM

------------------------------------------------------------------------------
-- Constants
------------------------------------------------------------------------------
local DRUSERABOSSMODS_VERSION =  "0.18-alpha" -- "@project-version@"
local DEFAULTS = {
  profile = {
    dbm = {
      version = DRUSERABOSSMODS_VERSION,
    },
    custom = {
      bar_threshold_n2h = 0,
      bar_inversesort_normal = false,
      bar_inversesort_highlight = false,
      bar_add2top_normal = false,
      bar_add2top_highlight = false,
      bar_fill_normal = false,
      bar_fill_highlight = false,
      bar_displaytime_normal = true,
      bar_displaytime_highlight = true,
      bar_texture_normal = "restrat1",
      bar_texture_highlight = "restrat1",
      bar_height_normal = 25,
      bar_height_highlight = 30,
      bar_font_normal = "CRB_Interface11_BO",
      bar_font_highlight = "CRB_Interface12_BO",

      health_sort = Window.CodeEnumArrangeOrigin.LeftOrTop,
      health_fill = false,
      health_progress_sprite = "default",
      health_font = "CRB_Interface11_BO",
      health_cast_enable = true,

      message_normal_enable = true,
      message_normal_sort = Window.CodeEnumArrangeOrigin.LeftOrTop,
      message_normal_font = "CRB_Interface11_BO",
      message_highlight_enable = true,
      message_highlight_sort = Window.CodeEnumArrangeOrigin.LeftOrTop,
      message_highlight_font = "CRB_Interface12_BO",

      sound_enable = true,
      marker_enable = true,
    },
  },
}



------------------------------------------------------------------------------
-- DruseraBossMods Addon
------------------------------------------------------------------------------
do
  -- Sub modules are created when other files are loaded.
  DBM:SetDefaultModulePrototype(ModulePrototype)
  DBM:SetDefaultModuleState(false)
end

function DBM:OnInitialize()
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local GeminiDB = Apollo.GetPackage("Gemini:DB-1.0").tPackage

  self.DRUSERABOSSMODS_VERSION = DRUSERABOSSMODS_VERSION
  self.DataBase = {}
  self.L = GeminiLocale:GetLocale("DruseraBossMods")
  self.db = GeminiDB:New(self, DEFAULTS, true)

  Apollo.LoadSprites("DruseraBossMods_Sprites.xml")
  self.xmlDoc = XmlDoc.CreateFromFile("DruseraBossMods.xml")
  self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

function DBM:OnDocLoaded()
  if self.xmlDoc == nil or not self.xmlDoc:IsLoaded() then
    Apollo.AddAddonErrorText(self, "For an unknown reason, the xmlDoc is not loaded.")
  else
    Apollo.RegisterEventHandler("WindowManagementReady", "OnWindowManagementReady", self)
    -- From highest layer to lowest layer.
    self:GUIInit()
    self:HUDInit()
    self:EnableModule("EncounterManager")
  end
end

function DBM:OnWindowManagementReady()
  self:GUIWindowsManagementAdd()
  self:HUDWindowsManagementAdd()
end

------------------------------------------------------------------------------
-- ModulePrototype
------------------------------------------------------------------------------
function ModulePrototype:Add2Logs(sText, ...)
  if self.tLogger then
    self.tLogger:Add(sText, ...)
  end
end

function ModulePrototype:LogInitialize()
  self.tLogger = DBM:NewLoggerNamespace(self, self:GetName())
end

function ModulePrototype:AddAddonErrorText(sText)
  Apollo.AddAddonErrorText(DBM, "AddOnError: " .. sText)
end

