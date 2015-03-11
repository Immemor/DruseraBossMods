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
local DruseraBossMods = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local next = next
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local wndForm
local wndLeftMenuList
local wndBodyContainer

------------------------------------------------------------------------------
-- Local functions.
------------------------------------------------------------------------------
local function TranslateWindows(windows)
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local L = GeminiLocale:GetLocale("DruseraBossMods")
  for _,wnd in next, windows:GetChildren() do
    GeminiLocale:TranslateWindow(L, windows)
    TranslateWindows(wnd)
  end
end

local function GUI_SetActiveItem(wndControl)
  local data = wndControl:GetData()

  for _,wnd in next, wndBodyContainer:GetChildren() do
    wnd:Show(false, true)
  end
  if data.wndBodyContainer then
    data.wndBodyContainer:Show(true, true)
  end
end

------------------------------------------------------------------------------
-- Public functions.
------------------------------------------------------------------------------
function DruseraBossMods:GUIInit()
  -- Create list menu.
  wndForm = Apollo.LoadForm(self.xmlDoc, "DBM_Form", nil, self)
  local wndMain = wndForm:FindChild("Main")
  local wndHeader = wndMain:FindChild("Header")
  local wndBody = wndMain:FindChild("Body")
  local wndFooter = wndMain:FindChild("Footer")

  local wndTag = wndFooter:FindChild("Version"):FindChild("Tag")
  wndTag:SetText(self.DRUSERABOSSMODS_VERSION)

  local wndTopMenuList = wndBody:FindChild("MenuTop")
  wndLeftMenuList = wndBody:FindChild("MenuLeft")
  wndBodyContainer = wndBody:FindChild("Frame"):FindChild("Container")

  local default = self:GUI_AddLeftMenuItem("HOME", "DBM_Home")
  self:GUI_AddLeftMenuItem("BARS", "DBM_BarCustom")
  self:GUI_AddLeftMenuItem("MESSAGES", "DBM_MessageCustom")
  self:GUI_AddLeftMenuItem("SOUNDS", "DBM_SoundCustom")
  self:GUI_AddLeftMenuItem("MARKERS", "DBM_MarkerCustom")
  self:GUI_AddLeftMenuItem("BOSSES", "DBM_Bosses")
  self:GUI_AddLeftMenuItem("ENCOUNTER_LOG", "DBM_EncounterLog")

  GUI_SetActiveItem(default)
  TranslateWindows(wndTopMenuList)
  TranslateWindows(wndBodyContainer)
  self.SoundMuteAll = false

  Apollo.RegisterSlashCommand("dbm", "OnToggleMainGUI", self)
end

function DruseraBossMods:GUIWindowsManagementAdd()
  Event_FireGenericEvent('WindowManagementAdd', {
    wnd = wndForm, strName = "DruseraBossMods"})
end

function DruseraBossMods:OnToggleMainGUI()
  if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
    if wndForm:IsShown() then
      wndForm:Show(false, true)
    else
      wndForm:Show(true, true)
    end
  end
end

function DruseraBossMods:OnWindowLoadProfile(wndHandler, wndControl)
  local sKeyName = wndControl:GetName()
  local val = self.db.profile.custom[sKeyName]
  if val ~= nil then
    if type(val) == "boolean" then
      wndControl:SetCheck(val)
    elseif type(val) == "number" then
      wndControl:SetText(val)
    elseif type(val) == "string" then
      wndControl:SetText(val)
    end
  end
end

function DruseraBossMods:OnButtonCheckUncheck(wndHandler, wndControl, eMouseButton)
  local sKeyName = wndControl:GetName()
  local val = self.db.profile.custom[sKeyName]
  if val ~= nil then
    self.db.profile.custom[sKeyName] = wndControl:IsChecked()
    self:HUDLoadProfile()
  end
end

function DruseraBossMods:OnNumberBoxChanged(wndHandler, wndControl, eMouseButton)
  local sKeyName = wndControl:GetName()
  local val = self.db.profile.custom[sKeyName]
  if val ~= nil then
    local new = tonumber(wndControl:GetText())
    if new ~= nil then
      self.db.profile.custom[sKeyName] = new
      self:HUDLoadProfile()
    end
  end
end

function DruseraBossMods:OnTextureDropdownToggle(wndHandler, wndControl, eMouseButton)
  local show = wndControl:IsChecked()
end

function DruseraBossMods:OnToggleAnchors(wndHandler, wndControl, eMouseButton)
  self:HUDToggleAnchorLock()
end

function DruseraBossMods:GUI_AddLeftMenuItem(sLabel, sBody)
  local wndItem = Apollo.LoadForm(self.xmlDoc, "DBM_MenuItem", wndLeftMenuList, self)
  local wndButton = wndItem:FindChild("Button")
  local wndBody = nil
  local tData = {}

  if sBody then
    wndBody = Apollo.LoadForm(self.xmlDoc, sBody, wndBodyContainer, self)
    wndBody:Show(false, true)
    tData.wndBodyContainer = wndBody
  end

  wndButton:SetText(self.L[sLabel])
  wndButton:SetData(tData)
  wndLeftMenuList:ArrangeChildrenVert()
  return wndButton
end

function DruseraBossMods:OnLeftMenuItem(wndHandler, wndControl, eMouseButton)
  GUI_SetActiveItem(wndControl)
end

function DruseraBossMods:OnStartTest(wndHandler, wndControl, eMouseButton)
  local tPlayerUnit = GameLib.GetPlayerUnit()
  self:HUDCreateHealthBar({
    tUnit = tPlayerUnit,
    nId = tPlayerUnit:GetId(),
    sLabel = tPlayerUnit:GetName(),
  })
  self:HUDCreateTimerBar({
    sLabel = self.L["END_OF_TEST"],
    nDuration = 33,
    fCallback = function(self)
      self:HUDRemoveHealthBar(GameLib.GetPlayerUnit():GetId())
    end,
  }, nil)
  self:HUDCreateTimerBar({
    sLabel = self.L["THIS_SHOULD_BE_4"],
    nDuration = 28,
    fCallback = function(self)
      self:HUDCreateMessage({sLabel = self.L["YOU_ARE_DEATH_AGAIN"]})
      self:PlaySound("4")
    end
  }, nil)
  self:HUDCreateTimerBar({
    sLabel = self.L["THIS_SHOULD_BE_2"],
    nDuration = 10,
    fCallback = function(self)
      self:HUDCreateMessage({sLabel = self.L["ARE_YOU_READY"]})
      self:PlaySound("2")
    end
  }, { color = "xkcdBrightOrange"})
  self:HUDCreateTimerBar({
    sLabel = self.L["THIS_SHOULD_BE_3"],
    nDuration = 20,
    fCallback = function(self)
      self:HUDCreateMessage({
        sLabel = self.L["INTERRUPT_THIS_CAST"],
        bHighlight = true,
        nDuration=3
      })
      self:PlaySound("3")
    end
  }, { color = "xkcdBrightYellow"})
  self:HUDCreateTimerBar({
    sLabel = self.L["THIS_SHOULD_BE_1"],
    nDuration = 4,
    fCallback = function(self)
      self:HUDCreateMessage({sLabel = self.L["WELCOME_IN_DBM"], bHighlight = true})
      self:PlaySound("1")
    end,
  }, nil)
end

function DruseraBossMods:OnCombatInterfaceLog(wndHandler, wndControl, eMouseButton)
  local tData = self:CombatInterfaceDumpOldLog()
  if tData then
    local nStartTime = tData[1]
    local tLogs = tData[2]

    local wndParent = wndControl:GetParent()
    local wndGrid = nil
    for _, wnd in next, wndParent:GetChildren() do
      if wnd:GetName() == "Grid" then
        wndGrid = wnd
        break
      end
    end
    if wndGrid then
      wndGrid:DeleteAll()
      for _,tLog in next, tLogs do
        local idx = wndGrid:AddRow("")

        -- First column
        local nDiffTime = string.format("%.2f", tLog[1] - nStartTime)
        wndGrid:SetCellText(idx, 1, nDiffTime)
        wndGrid:SetCellSortText(idx, 1, tLog[1])
        -- Second column
        local sText = tLog[2]
        wndGrid:SetCellText(idx, 2, sText)
        -- Third column
        local tUnitInfo = tLog[3]
        if tUnitInfo then
          if tUnitInfo.sName then
            wndGrid:SetCellText(idx, 3, tUnitInfo.sName)
          elseif tUnitInfo.nId and not tUnitInfo.bIsValid then
            wndGrid:SetCellText(idx, 3, "(invalid)")
          end
        end
        -- column #4
        if tUnitInfo and tUnitInfo.nId then
          local sId = tostring(tUnitInfo.nId)
          wndGrid:SetCellText(idx, 4, sId)
        end
        -- column #5
        local tExtraInfo = tLog[4]
        if sText == "ERROR" then
          wndGrid:SetCellText(idx, 5, tExtraInfo[1])
        elseif sText == "DebuffAdd" or sText == "BuffAdd" then
          local nSpellId = tExtraInfo[1]
          local sSpellName = tExtraInfo[2]
          local nStackCount = tExtraInfo[3]
          local sFormat = "SpellName='%s' SpellId=%d StackCount=%d"
          wndGrid:SetCellText(idx, 5, string.format(sFormat, sSpellName, nSpellId, nStackCount))
        elseif sText == "DebuffRemove" or sText == "BuffRemove" then
          local nSpellId = tExtraInfo[1]
          local sSpellName = tExtraInfo[2]
          local sFormat = "SpellName='%s' SpellId=%d"
          wndGrid:SetCellText(idx, 5, string.format(sFormat, sSpellName, nSpellId))
        elseif sText == "DebuffUpdate" or sText == "BuffUpdate" then
          local nSpellId = tExtraInfo[1]
          local sSpellName = tExtraInfo[2]
          local nOldStackCount = tExtraInfo[3]
          local nNewStackCount = tExtraInfo[4]
          local sFormat = "SpellName='%s' SpellId=%d OldStack=%d NewStack=%d"
          wndGrid:SetCellText(idx, 5, string.format(sFormat, sSpellName, nSpellId, nOldStackCount, nNewStackCount))
        elseif sText == "CastStart" or sText == "CastSuccess" or sText == "CastFailed" then
          local sCastName = tExtraInfo[1]
          local nCastEndTime = tExtraInfo[2] - nStartTime
          local sFormat = "CastName='%s' CastEndTime=%.2f"
          wndGrid:SetCellText(idx, 5, string.format(sFormat, sCastName, nCastEndTime))
        elseif sText == "NPCSay" or sText == "Datachron" then
          local sMessage = tExtraInfo[1]
          wndGrid:SetCellText(idx, 5, sMessage)
        end
      end
    end
  end
end

function DruseraBossMods:OnCombatManagerLog(wndHandler, wndControl, eMouseButton)
  local tData = self:CombatManagerDumpOldLog()
  if tData then
    local nStartTime = tData[1]
    local tLogs = tData[2]

    local wndParent = wndControl:GetParent()
    local wndGrid = nil
    for _, wnd in next, wndParent:GetChildren() do
      if wnd:GetName() == "Grid" then
        wndGrid = wnd
        break
      end
    end
    if wndGrid then
      wndGrid:DeleteAll()
      for _,tLog in next, tLogs do
        local idx = wndGrid:AddRow("")

        -- First column
        local nDiffTime = string.format("%.2f", tLog[1] - nStartTime)
        wndGrid:SetCellText(idx, 1, nDiffTime)
        wndGrid:SetCellSortText(idx, 1, tLog[1])
        -- Second column
        local sText = tLog[2]
        wndGrid:SetCellText(idx, 2, sText)
        -- Third column
        local tUnitInfo = tLog[3]
        if tUnitInfo then
          if tUnitInfo.sName then
            wndGrid:SetCellText(idx, 3, tUnitInfo.sName)
          elseif tUnitInfo.nId and not tUnitInfo.bIsValid then
            wndGrid:SetCellText(idx, 3, "(invalid)")
          end
        end
        -- column #4
        if tUnitInfo and tUnitInfo.nId then
          local sId = tostring(tUnitInfo.nId)
          wndGrid:SetCellText(idx, 4, sId)
        end
        -- column #5
        local tExtraInfo = tLog[4]
        if sText == "ERROR" then
          wndGrid:SetCellText(idx, 5, tExtraInfo[1])
        elseif sText == "Play Sound" then
          local sFileName = tExtraInfo[1]
          local sFormat = "FileName='%s'"
          wndGrid:SetCellText(idx, 5, string.format(sFormat, sFileName))
        end
      end
    end
  end
end
