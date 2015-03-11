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
-- Constants
------------------------------------------------------------------------------
local DRUSERABOSSMODS_VERSION =  "0.17-alpha" -- "@project-version@"
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

local tmp = {}

------------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("DruseraBossMods", false)

function DruseraBossMods:OnInitialize()
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

function DruseraBossMods:OnEnable()
  for _,tData in next, tmp do
    self:RegisterEncounterSecond(tData)
  end
  tmp = nil
end

function DruseraBossMods:OnDisable()
end

function DruseraBossMods:RegisterEncounter(tData)
  table.insert(tmp, tData)
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

--[[
------------------------------------------------------------------------------
-- DruseraBossMods Instance
------------------------------------------------------------------------------
local DruseraBossModsInst = DruseraBossMods:new()
DruseraBossModsInst:Init()
-- For debugging purpose through GeminiConsole, quite useful.
--]]

_G["DBM"] = DruseraBossMods
