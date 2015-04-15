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
require "Sound"
require "GroupLib"

local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local EncounterManager = DBM:NewModule("EncounterManager")
local EncounterPrototype = {}
local UnitPrototype = {}

------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
------------------------------------------------------------------------------
local GetCurrentZoneMap = GameLib.GetCurrentZoneMap
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local next, string, pcall  = next, string, pcall

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local MT_UNITPROTOTYPE = { __index = UnitPrototype }
local CHANNEL_NPCSAY = ChatSystemLib.ChatChannel_NPCSay
local CHANNEL_DATACHRON = ChatSystemLib.ChatChannel_Datachron

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local _tEncounterDB
local _tFoes
local _tNPCSayAlerts
local _tMessagesAlerts = {
  [CHANNEL_NPCSAY] = {},
  [CHANNEL_DATACHRON] = {},
}
local _tMarksOnUnit
local _tCombatInterface
local _bEncounterInProgress
local _tCurrentEncounter

------------------------------------------------------------------------------
-- EncounterManager module.
------------------------------------------------------------------------------
do
  -- Sub modules are created when other files are loaded.
  EncounterManager:SetDefaultModulePrototype(EncounterPrototype)
  EncounterManager:SetDefaultModuleState(false)
end

local function EncounterCall(sInfo, fCallback, tFoe, ...)
  -- Trace all call to upper layer for debugging purpose.
  EncounterManager:Add2Logs(sInfo, tFoe.nId, ...)
  -- Protected call.
  local s, sErrMsg = pcall(fCallback, tFoe, ...)
  if not s then
    local sMsg = sInfo .. ": " .. sErrMsg
    Print(sMsg)
    EncounterManager:AddAddonErrorText(sMsg)
  end
end

local function FoesStartCombat(nId)
  local tFoe = _tFoes[nId]
  if _bEncounterInProgress and tFoe and tFoe.OnStartCombat then
    EncounterCall("StartCombat", tFoe.OnStartCombat, tFoe)
  end
end

local function AddFoeUnit(nId, sName, bInCombat)
  if _tCurrentEncounter.tUnitClass[sName] then
    EncounterManager:Add2Logs("Foe added", nId)
    local tFoe = setmetatable({
      tUnit = GetUnitById(nId),
      sName = sName,
      nId = nId,
      tCastStartAlerts = {},
      tCastEndAlerts = {},
      tBuffAddAlerts = {},
      tBuffRemoveAlerts = {},
      tBuffUpdateAlerts = {},
      tDebuffAddAlerts = {},
      tDebuffRemoveAlerts = {},
      tDebuffUpdateAlerts = {},
      bInCombat = bInCombat,
    }, {__index = _tCurrentEncounter.tUnitClass[sName]})
    _tFoes[nId] = tFoe
  end
end

local function RemoveFoeUnit(nId)
  local FoeUnit = _tFoes[nId]
  if FoeUnit then
    DBM:HUDRemoveHealthBar(nId)
    DBM:HUDRemoveTimerBars(nId)
    DBM:HUDRemoveMessages(nId)
    _tFoes[nId] = nil
  end
end

local function SearchAndAdd(nId, sName, bInCombat)
  if _tFoes[nId] then return end
  if _bEncounterInProgress and _tCurrentEncounter then
    AddFoeUnit(nId, sName, bInCombat)
  else
    local tMap = GetCurrentZoneMap()
    local id1 = tMap.parentZoneId
    local id2 = tMap.id
    if _tEncounterDB[id1] and _tEncounterDB[id1][id2] and
      _tEncounterDB[id1][id2][sName] then
      _tCurrentEncounter = _tEncounterDB[id1][id2][sName]
      if _bEncounterInProgress and not _tCurrentEncounter:IsEnabled() then
        _tCurrentEncounter:Enable()
      end
      AddFoeUnit(nId, sName, bInCombat)
    end
  end
end

local function BuffProcess(sBuffType, nId, nSpellId, nStack)
  local tFoe = _tFoes[nId]
  if _bEncounterInProgress and tFoe and nSpellId then
    local cb = tFoe[sBuffType][nSpellId]
    if cb then
      EncounterCall(sBuffType, cb, tFoe, nStack)
    end
  end
end
local function DebuffProcess(sDebuffType, nId, nSpellId, nStack)
  if _bEncounterInProgress and nSpellId then
    for _,tFoe in next, _tFoes do
      local cb = tFoe[sDebuffType][nSpellId]
      if cb then
        EncounterCall(sDebuffType, cb, tFoe, nId, nStack)
      end
    end
  end
end

function EncounterManager:OnInitialize()
  _tEncounterDB = {}
  _tFoes = {}
  _tNPCSayAlerts = {}
  _tMessagesAlerts = {
    [CHANNEL_NPCSAY] = {},
    [CHANNEL_DATACHRON] = {},
  }
  _tMarksOnUnit = {}
  _tCombatInterface = nil
  _tCurrentEncounter = nil
  _bEncounterInProgress = false
end

function EncounterManager:OnEnable()
  _bEncounterInProgress = false
  DBM.Overlay = DBM:OverlayInitialize()
  self:LogInitialize()
  -- Load lower layer.
  _tCombatInterface = DBM:CombatInterfaceInit(self, false)

  -- Parse all encounters registered.
  for name, tModule in self:IterateModules() do
    local nZoneParentId = tModule.nZoneParentId
    local nZoneId = tModule.nZoneId
    local tTriggers = tModule.tTriggers
    if tModule.L and nZoneParentId and nZoneId and tTriggers
      and next(tTriggers) then
      local tClassList = tModule.tClassList
      -- Remove it from memory
      tModule.tTriggers = nil
      tModule.tClassList = nil
      -- Build Encounter list by Zone and Trigger.
      if _tEncounterDB[nZoneParentId] == nil then
        _tEncounterDB[nZoneParentId] = {}
      end
      local tZoneParent = _tEncounterDB[nZoneParentId]
      if tZoneParent[nZoneId] == nil then
        tZoneParent[nZoneId] = {}
      end

      local tZone = tZoneParent[nZoneId]
      for _, sTrig in next, tTriggers do
        local sTrigLoc = tModule.L[sTrig]
        if sTrigLoc and tZone[sTrigLoc] == nil then
          tZone[sTrigLoc] = tModule
        elseif sTrigLoc then
          self:AddAddonErrorText("Encounter already registered: " .. sTrigLoc)
        else
          self:AddAddonErrorText("Translation missing: " .. sTrig)
        end
      end

      local tUnitClass = {}
      for sName, tClass in next, tClassList do
        tUnitClass[tModule.L[sName]] = setmetatable(tClass, MT_UNITPROTOTYPE)
      end
      tModule.tUnitClass = tUnitClass
      -- Create an empty table if not customization is found.
      if tModule.tCustom == nil then
        tModule.tCustom = {}
      end
      if tModule.tCustom.Timers == nil then
        tModule.tCustom.Timers = {}
      end
    else
      self:AddAddonErrorText("Invalid encounter: " .. tModule:GetName())
    end

    -- Set default health bar label if provided.
--    if tModule.bIsHealthBar and tModule.sHealthBarName then
--      self.sHealthBarNameLoc = tModule.L[tModule.sHealthBarName]
--    end
    -- Update custom parameters with saved values.

    -- Prepare handlers.
  end
end

function EncounterManager:OnUnitCreated(nId, tUnit, sName)
  SearchAndAdd(nId, sName, false)
  local tFoe = _tFoes[nId]
  if tFoe ~= nil then
    _tCombatInterface:TrackThisUnit(nId)
    if _bEncounterInProgress and tFoe and tFoe.OnCreate then
      EncounterCall("OnCreate", tFoe.OnCreate, tFoe)
    end
  end
end

function EncounterManager:OnUnitDestroyed(nId, tUnit, sName)
  local tFoe = _tFoes[nId]
  if tFoe then
    if _bEncounterInProgress and tFoe.OnDestroy then
      EncounterCall("OnDestroy", tFoe.OnDestroy, tFoe)
    end
    RemoveFoeUnit(nId)
    local a = DBM.Overlay:GetDrawUnitById(nId)
    if a then
      a:Destroy()
    end
  end
end

function EncounterManager:UnitEnteringCombat(nId, tUnit, sName)
  local bExist = true
  if _tFoes[nId] then
    self:Add2Logs("Foe entering in combat", nId)
    _tFoes[nId].bInCombat = true
    FoesStartCombat(nId)
  else
    bExist = self:UnknownUnitInCombat(nId, tUnit, sName)
  end
  if not bExist then
    _tCombatInterface:UnTrackThisUnit(nId)
  end
end

function EncounterManager:UnknownUnitInCombat(nId, tUnit, sName)
  SearchAndAdd(nId, sName, true)
  local bExist = _tFoes[nId] ~= nil
  if bExist then
    _tCombatInterface:TrackThisUnit(nId)
    FoesStartCombat(nId)
  end
end

function EncounterManager:UnitDead(nId, tUnit, sName)
  self:Add2Logs("Foe dead", nId)
  RemoveFoeUnit(nId)
end

function EncounterManager:UnitLeftCombat(nId, tUnit, sName)
  if _tFoes[nId] then
    self:Add2Logs("Foe out of combat", nId)
    _tFoes[nId].bInCombat = false
  end
end

function EncounterManager:CastStart(nId, sCastName)
  if _bEncounterInProgress then
    local tFoe = _tFoes[nId]
    if tFoe then
      local cb = tFoe.tCastStartAlerts[sCastName]
      if cb then
        EncounterCall("Cast Start", cb, tFoe)
      end
    end
  end
end

function EncounterManager:CastEnd(nId, sCastName, bIsInterrupted)
  if _bEncounterInProgress then
    local tFoe = _tFoes[nId]
    if tFoe then
      local cb = tFoe.tCastEndAlerts[sCastName]
      local bSuccess = not bIsInterrupted
      if cb then
        EncounterCall("Cast End", cb, tFoe, bSuccess)
      end
    end
  end
end

function EncounterManager:BuffAdd(nId, nSpellId, nStack)
  BuffProcess("tBuffAddAlerts", nId, nSpellId, nStack)
end

function EncounterManager:BuffRemove(nId, nSpellId)
  BuffProcess("tBuffRemoveAlerts", nId, nSpellId, 0)
end

function EncounterManager:BuffUpdate(nId, nSpellId, nStackOld, nStackNew)
  BuffProcess("tBuffUpdateAlerts", nId, nSpellId, nStackNew)
end

function EncounterManager:DebuffAdd(nId, nSpellId, nStack)
  DebuffProcess("tDebuffAddAlerts", nId, nSpellId, nStack)
end

function EncounterManager:DebuffRemove(nId, nSpellId)
  DebuffProcess("tDebuffRemoveAlerts", nId, nSpellId, 0)
end

function EncounterManager:DebuffUpdate(nId, nSpellId, nStackOld, nStackNew)
  DebuffProcess("tDebuffUpdateAlerts", nId, nSpellId, nStackNew)
end

function EncounterManager:OnChatMessage(nId, sMessage, nChannelType)
  local tAlerts = _tMessagesAlerts[nChannelType]
  if tAlerts and _bEncounterInProgress then
    local sCallback = nil
    -- Identify in which alerts to search
    if nChannelType == CHANNEL_NPCSAY then
      sCallback = "NPCSay"
    elseif nChannelType == CHANNEL_DATACHRON then
      sCallback = "Datachron"
    end
    -- Check simple message.
    if tAlerts[sMessage] then
      for nFoeId, cb in next, tAlerts[sMessage] do
        if _tFoes[nFoeId] then
          EncounterCall(sCallback, cb, _tFoes[nFoeId])
        end
      end
    else
      -- Check message with member name inside.
      local sRegEx, tCallbacks
      for sRegEx, tCallbacks in next, tAlerts do
        sPlayerName = sMessage:match(sRegEx)
        local tMemberUnit = nil
        if sPlayerName and tCallbacks then
          local i
          -- Retrieve tUnit related to the member name
          for i = 1, GroupLib.GetMemberCount() do
            local tUnit = GroupLib.GetUnitForGroupMember(i)
            if tUnit and tUnit:IsValid() and
              sPlayerName == tUnit:GetName() then
              tMemberUnit = tUnit
              break
            end
          end
          for nFoeId, cb in next, tCallbacks do
            if _tFoes[nFoeId] then
              EncounterCall(sCallback, cb, _tFoes[nFoeId], tMemberUnit)
            end
          end
        end
      end
    end
  end
end

function EncounterManager:StartEncounter()
  _bEncounterInProgress = true
  self:Add2Logs("StartEncounter")
  if _tCurrentEncounter then
    if not _tCurrentEncounter:IsEnabled() then
      _tCurrentEncounter:Enable()
    end

    for nId, Foe in next, _tFoes do
      if Foe.tUnit:IsValid() then
        if Foe.bInCombat then
          FoesStartCombat(Foe.nId)
        end
      end
    end
  end
end

function EncounterManager:StopEncounter()
  self:Add2Logs("StopEncounter")
  for nId,FoeUnit in next, _tFoes do
    RemoveFoeUnit(nId)
  end
  for _,wPoint in next, _tMarksOnUnit do
    wPoint:Destroy()
  end
  DBM:HUDRemoveAllTimerBar()
  DBM.Overlay:DestroyAll()
  if _tCurrentEncounter then
    _tCurrentEncounter:Disable()
  end
  _tMarksOnUnit = {}
  _tCurrentEncounter = nil
  _tMessagesAlerts = {
    [CHANNEL_NPCSAY] = {},
    [CHANNEL_DATACHRON] = {},
  }
  _bEncounterInProgress = false
end

------------------------------------------------------------------------------
-- Encounter Prototype functions which are called during "onInitialize" in
-- encounter files.
------------------------------------------------------------------------------
local function RegisterLocale(tEncounter, sLanguage, tLocales)
  assert(type(tLocales) == "table")
  local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
  local sName = "DruseraBossMods_" .. tEncounter:GetName()
  local L = GeminiLocale:NewLocale(sName, sLanguage)
  if L then
    for key, val in next, tLocales do
      L[key] = val
    end
    tEncounter.L = GeminiLocale:GetLocale(sName)
  end
end

local function RegisterCustom(tEncounter, sType, sKey, tCustom)
  if tEncounter.tCustom == nil then
    tEncounter.tCustom = {}
  end
  if tEncounter.tCustom[sType] == nil then
    tEncounter.tCustom[sType] = {}
  end
  tEncounter.tCustom[sType][sKey] = tCustom
end

local function LoadCustom(sType, sKey)
  if _tCurrentEncounter then
    local tCustomType = _tCurrentEncounter.tCustom[sType]
    if tCustomType and tCustomType[sKey] then
      return tCustomType[sKey]
    else
      EncounterManager:Add2Logs("Missing Custom", nil, sType, sKey)
    end
  end
end

function EncounterPrototype:RegisterZoneMap(nParentId, nId)
  self.nZoneParentId = nParentId
  self.nZoneId = nId
end

function EncounterPrototype:RegisterTriggerNames(tTriggers)
  self.tTriggers = tTriggers
end

function EncounterPrototype:RegisterUnitClass(tClassList)
  self.tClassList = tClassList
end

function EncounterPrototype:RegisterEnglishLocale(tLocales)
  RegisterLocale(self, "enUS", tLocales)
end

function EncounterPrototype:RegisterGermanLocale(tLocales)
  RegisterLocale(self, "deDE", tLocales)
end

function EncounterPrototype:RegisterFrenchLocale(tLocales)
  RegisterLocale(self, "frFR", tLocales)
end

function EncounterPrototype:RegisterKoreanLocale(tLocales)
  RegisterLocale(self, "koKR", tLocales)
end

function EncounterPrototype:RegisterTimer(sKey, tCustom)
  RegisterCustom(self, "Timers", sKey, tCustom)
end

function EncounterPrototype:RegisterMessage(sKey, tCustom)
  RegisterCustom(self, "Messages", sKey, tCustom)
end

function EncounterPrototype:RegisterIconMarker(nIconId, tCustom)
  RegisterCustom(self, "IconMarkers", nIconId, tCustom)
end

function EncounterPrototype:RegisterLineMarker(nLineId, tCustom)
  RegisterCustom(self, "LineMarkers", nLineId, tCustom)
end

function EncounterPrototype:RegisterCircleMarker(nCircleId, tCustom)
  RegisterCustom(self, "CircleMarkers", nCircleId, tCustom)
end

function EncounterPrototype:RegisterGroundMarker(nGroundId, tCustom)
  RegisterCustom(self, "ZoneMarkers", nGroundId, tCustom)
end

function EncounterPrototype:ExtraLog2Text(sText, tExtraData, nRefTime)
  local sResult = ""
  if sText == "ERROR" then
    sResult = tExtraData[1]
  elseif sText == "Play Sound" then
    local sFileName = tExtraData[1]
    local sFormat = "FileName='%s'"
    sResult = string.format(sFormat, sFileName)
  elseif sText == "Missing Custom" then
    local sFormat = "sType='%s' sKey='%s'"
    sResult = string.format(sFormat, tExtraData[1], tExtraData[2])
  end
  return sResult
end

function EncounterPrototype:SetTimer(sKey, nDuration, fTimeout)
  local tCustom = LoadCustom("Timers", sKey)
  DBM:HUDCreateTimerBar({
    sLabel = _tCurrentEncounter.L[sKey],
    nDuration = nDuration,
    fCallback = fTimeout,
    tCallback_class = self,
    tCallback_data = nil,
  }, tCustom)
end

function EncounterPrototype:ActivateDetection(flag)
  _tCombatInterface:ActivateDetection(flag)
end

------------------------------------------------------------------------------
-- Unit Prototype functions.
------------------------------------------------------------------------------
local function SetMessageAlert(nChannelType, sKey, nId, fCallback)
  if _tCurrentEncounter then
    local tAlerts = _tMessagesAlerts[nChannelType]
    local msg = _tCurrentEncounter.L[sKey]
    local msg = msg:gsub("%%PlayerName", "((%%a+)%%s*(%%a+))")

    if fCallback then
      if not tAlerts[msg] then
        tAlerts[msg] = {}
      end
      tAlerts[msg][nId] = fCallback
    elseif tAlerts[msg] then
      tAlerts[msg][nId] = nil
      if next(tAlerts[msg]) == nil then
        tAlerts[msg] = nil
      end
    end
  end
end

function UnitPrototype:SetTimer(sKey, nDuration, fTimeout)
  if _tCurrentEncounter then
    local tCustom = LoadCustom("Timers", sKey)
    DBM:HUDCreateTimerBar({
      sLabel = _tCurrentEncounter.L[sKey],
      nDuration = nDuration,
      nId = self.nId,
      fCallback = fTimeout,
      tCallback_class = self,
      tCallback_data = nil,
    }, tCustom)
  end
end

function UnitPrototype:SetMessage(tMessage)
  if _tCurrentEncounter then
    tMessage.sLabel = _tCurrentEncounter.L[tMessage.sLabel]
    DBM:HUDCreateMessage(tMessage)
  end
end

function UnitPrototype:GetTimerRemaining(sKey)
  if _tCurrentEncounter then
    local sLabel = _tCurrentEncounter.L[sKey]
    return DBM:HUDRetrieveTimerBar(sLabel)
  end
  return nil
end

function UnitPrototype:SetDatachronAlert(sKey, fCallback)
  SetMessageAlert(CHANNEL_DATACHRON, sKey, self.nId, fCallback)
end

function UnitPrototype:SetNPCSayAlert(sKey, fCallback)
  SetMessageAlert(CHANNEL_NPCSAY, sKey, self.nId, fCallback)
end

function UnitPrototype:SetBuffAddAlert(nSpellId, fCallback)
  self.tBuffAddAlerts[nSpellId] = fCallback
end

function UnitPrototype:SetBuffRemoveAlert(nSpellId, fCallback)
  self.tBuffRemoveAlerts[nSpellId] = fCallback
end

function UnitPrototype:SetBuffUpdateAlert(nSpellId, fCallback)
  self.tBuffUpdateAlerts[nSpellId] = fCallback
end

function UnitPrototype:SetDebuffAddAlert(nSpellId, fCallback)
  self.tDebuffAddAlerts[nSpellId] = fCallback
end

function UnitPrototype:SetDebuffRemoveAlert(nSpellId, fCallback)
  self.tDebuffRemoveAlerts[nSpellId] = fCallback
end

function UnitPrototype:SetDebuffUpdateAlert(nSpellId, fCallback)
  self.tDebuffUpdateAlerts[nSpellId] = fCallback
end

function UnitPrototype:SetCircle(nTargetId, nCircleId, nRadius)
  local a = DBM.Overlay:GetDrawUnitById(nTargetId)
  if a then
    a:SetCircle(nCircleId, nRadius)
  end
end

function UnitPrototype:SetMarkOnUnit(sMarkName, nTargetId)
  local a = DBM.Overlay:GetDrawUnitById(nTargetId)
  if a then
    a:SetIcon(sMarkName)
  end
end

function UnitPrototype:SetLineOnUnit(nTargetId, nLineId, nAngleDegree, nOffset, nLen)
  local a = DBM.Overlay:GetDrawUnitById(nTargetId)
  if a then
    a:SetLine(nLineId, nAngleDegree, nOffset, nLen)
  end
end

function UnitPrototype:SetCastStart(sKey, fCallback)
  if _tCurrentEncounter then
    local sCastNameLoc = _tCurrentEncounter.L[sKey]
    self.tCastStartAlerts[sCastNameLoc] = fCallback
  end
end

function UnitPrototype:SetCastEnd(sKey, fCallback)
  if _tCurrentEncounter then
    local sCastNameLoc = _tCurrentEncounter.L[sKey]
    self.tCastEndAlerts[sCastNameLoc] = fCallback
  end
end

function UnitPrototype:CreateHealthBar(sName)
  local sNameLoc = self.sName
  if _tCurrentEncounter and sName then
    sNameLoc = _tCurrentEncounter.L[sName]
  end
  EncounterManager:Add2Logs("Add Health Bar", self.nId)
  DBM:HUDCreateHealthBar({
    sLabel = sNameLoc,
    tUnit = self.tUnit,
    nId = self.nId,
  }, nil)
end

function UnitPrototype:GetDistBetween2Unit(tUnitFrom, tUnitTo)
  if not tUnitFrom or not tUnitTo then
    return nil
  end
  local sPos = tUnitFrom:GetPosition()
  local tPos = tUnitTo:GetPosition()

  local sVec = Vector3.New(sPos.x, sPos.y, sPos.z)
  local tVec = Vector3.New(tPos.x, tPos.y, tPos.z)
  local dist = (tVec - sVec):Length()

  return tonumber(dist)
end

function UnitPrototype:ClearAllTimerAlert()
  DBM:HUDRemoveAllTimerBar()
end

function UnitPrototype:ActivateDetection(flag)
  _tCombatInterface:ActivateDetection(flag)
end

function UnitPrototype:PlaySound(sFileName)
  if not DBM.db.profile.custom.sound_enable then
    EncounterManager:Add2Logs("Play Sound", nil, sFileName)
    Sound.PlayFile("sounds\\" .. sFileName .. ".wav")
  end
end
