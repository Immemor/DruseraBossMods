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
require "GameLib"

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetAddon("DruseraBossMods")
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local Locale = GeminiLocale:GetLocale("DruseraBossMods")
local next = next
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local wndMainGUI = nil
local wndFightHistory = nil
local tAllFightHistory = {}
local n = 1

------------------------------------------------------------------------------
-- Local functions.
------------------------------------------------------------------------------
------------------------------------------------------------------------------
-- Public functions.
------------------------------------------------------------------------------
function DruseraBossMods:GUIInit()
  wndMainGUI = Apollo.LoadForm(self.xmlDoc, "MainGUI", nil, self)
  wndMainGUI:Show(false)
  wndFightHistory = Apollo.LoadForm(self.xmlDoc, "FightHistory", nil, self)
  wndFightHistory:Show(false)

  Apollo.RegisterSlashCommand("dbm", "OnToggleMainGUI", self)
  Apollo.RegisterSlashCommand("DruseraBossMods", "OnToggleMainGUI", self)
  Apollo.RegisterSlashCommand("dbmhistory", "OnToggleFightHistory", self)
end

function DruseraBossMods:GUIWindowsManagementAdd()
  local wnds = {MainGui = wndMainGUI, FightHistory = wndFightHistory}
  for name,wnd in next, wnds do
    Event_FireGenericEvent('WindowManagementAdd', {
      wnd = wnd,
      strName = "DruseraBossMods: " .. name,
    })
  end
end

function DruseraBossMods:OnToggleMainGUI()
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    if wndMainGUI:IsShown() then
      wndMainGUI:Show(false)
    else
      wndMainGUI:Show(true)
    end
  end
end

function DruseraBossMods:SaveFightHistory(object)
  tAllFightHistory = object
end

function DruseraBossMods:OnToggleFightHistory()
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    if wndFightHistory:IsShown() then
      wndFightHistory:Show(false)
    else
      wndFightHistory:Show(true)

      local wndgrid = wndFightHistory:FindChild("Grid")

      local nFightStartTime = 0
      for _, data in ipairs(tAllFightHistory) do
        if data[1] == "Start encounter" then
          nFightStartTime = data[5]
          break
        end
      end
      wndgrid:DeleteAll()
      for _, data in ipairs(tAllFightHistory) do
        local idx = wndgrid:AddRow("")
        local time = data[2] - nFightStartTime
        wndgrid:SetCellText(idx, 1, string.format("%003.2f", time))
        wndgrid:SetCellSortText(idx, 1, data[2])
        wndgrid:SetCellText(idx, 2, tostring(data[1]))
        if data[3] ~= nil then
          wndgrid:SetCellText(idx, 3, tostring(data[3]))
        end
        if data[4] ~= nil then
          wndgrid:SetCellText(idx, 4, tostring(data[4]))
        end
        if data[1] == "Spell cast start" or
          data[1] == "Spell cast failed" or
          data[1] == "Spell cast success" then
          local prefix = data[5][2] and "Process " or "Drop "
          local suffix = data[5][4] .. " / " .. data[5][3] .. " (" .. data[5][5] .. "%)"
          wndgrid:SetCellText(idx, 5, prefix .. "'" .. data[5][1] .. "'  " .. suffix)
        elseif data[1] == "NPCSay processed" or
          data[1] == "NPCSay, no callbacks" or
          data[1] == "Datachron processed" or
          data[1] == "Datachron, no callbacks" then
          wndgrid:SetCellText(idx, 5, data[5])
        elseif data[1] == "Buff update" then
          local txt = ""
          txt = txt .. "BuffType='" .. data[5][2].eType .. "', "
          txt = txt .. "SpellId='" .. data[5][2].splEffect:GetId() .. "', "
          txt = txt .. "Count=" .. data[5][2].nCount .. ", "
          txt = txt .. "SpellName='" .. data[5][2].splEffect:GetName() .. "'"
          wndgrid:SetCellText(idx, 5, txt)
        end
      end
    end
  end
end

function DruseraBossMods:OnTestBar(wndHandler, wndControl, eMouseButton)
  local tPlayerUnit = GameLib.GetPlayerUnit()
  self:HUDCreateHealthBar({
    tUnit = tPlayerUnit,
    nId = tPlayerUnit:GetId(),
    sLabel = tPlayerUnit:GetName(),
  })
  self:HUDCreateTimerBar({
    sLabel = Locale["END_OF_TEST"],
    nDuration = 33,
    fCallback = function(self)
      self:HUDRemoveHealthBar(GameLib.GetPlayerUnit():GetId())
    end,
  }, nil)
  self:HUDCreateTimerBar({
    sLabel = Locale["THIS_SHOULD_BE_4"],
    nDuration = 28,
    fCallback = function(self)
      self:HUDCreateMessage({sLabel = Locale["YOU_ARE_DEATH_AGAIN"]})
    end
  }, nil)
  self:HUDCreateTimerBar({
    sLabel = Locale["THIS_SHOULD_BE_2"],
    nDuration = 10,
    fCallback = function(self)
      self:HUDCreateMessage({sLabel = Locale["ARE_YOU_READY"]})
    end
  }, nil)
  self:HUDCreateTimerBar({
    sLabel = Locale["THIS_SHOULD_BE_3"],
    nDuration = 20,
    fCallback = function(self)
      self:HUDCreateMessage({
        sLabel = Locale["INTERRUPT_THIS_CAST"],
        bHighlight = true,
        nDuration=3
      })
    end
  }, nil)
  self:HUDCreateTimerBar({
    sLabel = Locale["THIS_SHOULD_BE_1"],
    nDuration = 6,
    fCallback = function(self)
      self:HUDCreateMessage({sLabel = Locale["WELCOME_IN_DBM"], bHighlight = true})
    end,
  }, nil)
end

function DruseraBossMods:OnToggleAnchorLock(wndHandler, wndControl, eMouseButton)
  self:HUDToggleAnchorLock()
end
