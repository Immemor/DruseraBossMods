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
require "ApolloTimer"
require "ChatSystemLib"
require "Spell"
require "Sound"

------------------------------------------------------------------------------
-- Copy of few object to reduce the cpu load.
-- Because all local objects are faster.
------------------------------------------------------------------------------
local GetCurrentZoneMap = GameLib.GetCurrentZoneMap
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local next, pcall, unpack = next, pcall, unpack

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local NO_BREAK_SPACE = string.char(194, 160)

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
--local DruseraBossMods = Apollo.GetAddon("DruseraBossMods")
local DruseraBossMods = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local CombatManager = {}

local _CombatInterface = nil
local _bEncounterInProgress = false
local _tFoes = {}
local _tDatabase = {} -- Copy will be done on init.
local _tNPCSayAlerts = {}
local _tDatachronAlerts = {}
local _tMarksOnUnit = {}

------------------------------------------------------------------------------
-- Fast and local functions.
------------------------------------------------------------------------------
local function Add2Logs(sText, ...)
  if CombatManager.tLogger then
    CombatManager.tLogger:Add(sText, ...)
  end
end

local function EncounterCall(sInfo, fCallback, tFoe, ...)
  -- Trace all call to upper layer for debugging purpose.
  Add2Logs(sInfo, tFoe.nId, ...)
  -- Protected call.
  local s, sErrMsg = pcall(fCallback, tFoe, ...)
  --@alpha@
  if not s then
    Print(sInfo .. ": " .. sErrMsg)
    Add2Logs("ERROR", nId, sErrMsg)
  end
  --@end-alpha@
end

local function FoesStartCombat(nId)
  local tFoe = _tFoes[nId]
  if _bEncounterInProgress and tFoe and tFoe.OnStartCombat then
    EncounterCall("StartCombat", tFoe.OnStartCombat, tFoe)
  end
end

local function AddFoeUnit(nId, sName, bInCombat)
  if _tCurrentEncounter.tUnits[sName] then
    Add2Logs("Foe added", nId)
    local tFoe = setmetatable({
      tUnit = GetUnitById(nId),
      sName = sName,
      nId = nId,
      tCastStartAlerts = {},
      tCastFailedAlerts = {},
      tCastSuccessAlerts = {},
      tBuffAddAlerts = {},
      tBuffRemoveAlerts = {},
      tBuffUpdateAlerts = {},
      tDebuffAddAlerts = {},
      tDebuffRemoveAlerts = {},
      tDebuffUpdateAlerts = {},
      bInCombat = bInCombat,
    }, {__index = _tCurrentEncounter.tUnits[sName]})
    _tFoes[nId] = tFoe
  end
end

local function RemoveFoeUnit(nId)
  local FoeUnit = _tFoes[nId]
  if FoeUnit then
    DruseraBossMods:HUDRemoveHealthBar(nId)
    DruseraBossMods:HUDRemoveTimerBars(nId)
    DruseraBossMods:HUDRemoveMessages(nId)
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
    if _tDatabase[id1] and _tDatabase[id1][id2] and
      _tDatabase[id1][id2][sName] then
      _tCurrentEncounter = _tDatabase[id1][id2][sName]
      AddFoeUnit(nId, sName, bInCombat)
    end
  end
end

local function SetCastAlert(CastType, tFoeUnit, strKey, fCallback)
  local sCastName = DruseraBossMods.L[strKey]
  assert(sCastName)
  tFoeUnit[CastType][sCastName] = fCallback
end

local function CastProcess(sCastType, nId, sCastName, nCastEndTime)
  if _bEncounterInProgress then
    local tFoe = _tFoes[nId]
    if tFoe then
      local cb = tFoe[sCastType][sCastName]
      if cb then
        EncounterCall(sCastType, cb, tFoe)
      end
    end
  end
end

local function SetBuffAlert(BuffType, tFoe, nSpellId, fCallback)
  tFoe[BuffType][nSpellId] = fCallback
end

local function BuffProcess(sBuffType, nId, nSpellId, sName, nStack)
  local tFoe = _tFoes[nId]
  if _bEncounterInProgress and tFoe and nSpellId then
    local cb = tFoe[sBuffType][nSpellId]
    if cb then
      EncounterCall(sBuffType, cb, tFoe, sName, nStack)
    end
  end
end
local function DebuffProcess(sDebuffType, nId, sName, nSpellId, nStack)
  if _bEncounterInProgress and nSpellId then
    for _,tFoe in next, _tFoes do
      local cb = tFoe[sDebuffType][nSpellId]
      if cb then
        EncounterCall(sDebuffType, cb, tFoe, nId, sName, nStack)
      end
    end
  end
end

------------------------------------------------------------------------------
-- Relations between DruseraBossMods and CombatManager objects.
------------------------------------------------------------------------------
function DruseraBossMods:CombatManagerInit()
  -- Copy the database to improve performance.
  _bEncounterInProgress = false
  _CombatInterface = self:CombatInterfaceInit(CombatManager, false)
  CombatManager.tLogger = self:NewLoggerNamespace(CombatManager, "CombatManager")
  return CombatManager
end

function DruseraBossMods:RegisterEncounterSecond(tData)
  local nMapParentId = tData.nZoneMapParentId
  local nMapId = tData.nZoneMapId

  if not nMapParentId or not nMapId or not tData.tTriggerNames then
    if tData.sEncounterName then
      Print("Invalid encounter: " .. tData.sEncounterName)
    else
      Print("Invalid encounter ZoneMap definition!")
    end
    return
  end

  tEncounter = {
    sEncounterName = self.L[tData.sEncounterName],
    tUnits = {},
    tCustom = {},
  }
  for sName, tObj in pairs(tData.tUnits) do
    local sNameLoc = self.L[sName]
    tEncounter.tUnits[sNameLoc] = tObj

    if tData.tCustom and tData.tCustom[sName] then
      for k, v in next, tData.tCustom[sName] do
        if k == "BarsCustom" then
          tObj[k] = {}
          for sCastName, tOptions in next, v do
            local sCastNameLoc = self.L[sCastName]
            tObj[k][sCastNameLoc] = tOptions
          end
        else
          tObj[k] = v
        end
      end
    end
  end

  if not _tDatabase[nMapParentId] then
    _tDatabase[nMapParentId] = {}
  end
  if not _tDatabase[nMapParentId][nMapId] then
    _tDatabase[nMapParentId][nMapId] = {}
  end
  for _, sName in pairs(tData.tTriggerNames) do
    local sNameLoc = self.L[sName]
    if _tDatabase[nMapParentId][nMapId][sNameLoc] == nil then
      _tDatabase[nMapParentId][nMapId][sNameLoc] = tEncounter
    else
      Print("Encounter already register for '".. sNameLoc .. "'")
    end
  end
end

------------------------------------------------------------------------------
-- Combat Manager layer.
------------------------------------------------------------------------------
function CombatManager:StartEncounter()
  _bEncounterInProgress = true
  Add2Logs("StartEncounter")
  for nId, Foe in next, _tFoes do
    if Foe.tUnit:IsValid() then
      if Foe.bInCombat then
        FoesStartCombat(Foe.nId)
      end
    end
  end
end

function CombatManager:StopEncounter()
  Add2Logs("StopEncounter")
  for nId,FoeUnit in next, _tFoes do
    RemoveFoeUnit(nId)
  end
  for _,wPoint in next, _tMarksOnUnit do
    wPoint:Destroy()
  end
  _tMarksOnUnit = {}
  _tCurrentEncounter = nil
  _tNPCSayAlerts = {}
  _tDatachronAlerts = {}
  _bEncounterInProgress = false
end

function CombatManager:UnitDetected(nId, tUnit, sName)
  SearchAndAdd(nId, sName, false)
  local tFoe = _tFoes[nId]
  if tFoe ~= nil then
    _CombatInterface:TrackThisUnit(nId)
    if _bEncounterInProgress and tFoe and tFoe.OnDetection then
      EncounterCall("Detection", tFoe.OnDetection, tFoe)
    end
  end
end

function CombatManager:UnitDestroyed(nId, tUnit, sName)
  Add2Logs("Foe destroyed", nId)
  RemoveFoeUnit(nId)
end

function CombatManager:UnitEnteringCombat(nId, tUnit, sName)
  local bExist = true
  if _tFoes[nId] then
    Add2Logs("Foe entering in combat", nId)
    _tFoes[nId].bInCombat = true
    FoesStartCombat(nId)
  else
    bExist = self:UnknownUnitInCombat(nId, tUnit, sName)
  end
  if not bExist then
    _CombatInterface:UnTrackThisUnit(nId)
  end
end

function CombatManager:UnknownUnitInCombat(nId, tUnit, sName)
  SearchAndAdd(nId, sName, true)
  local bExist = _tFoes[nId] ~= nil
  if bExist then
    _CombatInterface:TrackThisUnit(nId)
    FoesStartCombat(nId)
  end
end

function CombatManager:UnitDead(nId, tUnit, sName)
  Add2Logs("Foe dead", nId)
  RemoveFoeUnit(nId)
end

function CombatManager:UnitLeftCombat(nId, tUnit, sName)
  if _tFoes[nId] then
    Add2Logs("Foe out of combat", nId)
    _tFoes[nId].bInCombat = false
  end
end

function CombatManager:CastStart(nId, sCastName, nCastEndTime)
  CastProcess("tCastStartAlerts", nId, sCastName, nCastEndTime)
end

function CombatManager:CastFailed(nId, sCastName, nCastEndTime)
  CastProcess("tCastFailedAlerts", nId, sCastName, nCastEndTime)
end

function CombatManager:CastSuccess(nId, sCastName, nCastEndTime)
  CastProcess("tCastSuccessAlerts", nId, sCastName, nCastEndTime)
end

function CombatManager:BuffAdd(nId, nSpellId, sName, nStack)
  BuffProcess("tBuffAddAlerts", nId, nSpellId, sName, nStack)
end

function CombatManager:BuffRemove(nId, nSpellId, sName)
  BuffProcess("tBuffRemoveAlerts", nId, nSpellId, sName, 0)
end

function CombatManager:BuffUpdate(nId, nSpellId, sName, nStackOld, nStackNew)
  BuffProcess("tBuffUpdateAlerts", nId, nSpellId, sName, nStackNew)
end

function CombatManager:DebuffAdd(nId, nSpellId, sName, nStack)
  DebuffProcess("tDebuffAddAlerts", nId, nSpellId, sName, nStack)
end

function CombatManager:DebuffRemove(nId, nSpellId, sName)
  DebuffProcess("tDebuffRemoveAlerts", nId, nSpellId, sName, 0)
end

function CombatManager:DebuffUpdate(nId, nSpellId, sName, nStackOld, nStackNew)
  DebuffProcess("tDebuffUpdateAlerts", nId, nSpellId, sName, nStackNew)
end


function CombatManager:NPCSay(nId, sMessage)
  -- nId is currently nil.
  if _bEncounterInProgress then
    local callbacks = _tNPCSayAlerts[sMessage]
    if callbacks then
      for nFoeId, cb in next, callbacks do
        if _tFoes[nFoeId] then
          EncounterCall("NPCSay", cb, _tFoes[nFoeId])
        else
          -- Auto clean.
          _tNPCSayAlerts[sMessage][nFoeId] = nil
          if next(_tNPCSayAlerts[sMessage]) == nil then
            _tNPCSayAlerts[sMessage] = nil
          end
        end
      end
    end
  end
end

function CombatManager:Datachron(nId, sMessage)
  -- nId is always nil for datachron.
  if _bEncounterInProgress then
    local callbacks = _tDatachronAlerts[sMessage]
    if callbacks then
      for nFoeId, cb in next, callbacks do
        if _tFoes[nFoeId] then
          EncounterCall("Datachron", cb, _tFoes[nFoeId])
        else
          -- Auto clean.
          _tDatachronAlerts[sMessage][nFoeId] = nil
          if next(_tDatachronAlerts[sMessage]) == nil then
            _tDatachronAlerts[sMessage] = nil
          end
        end
      end
    end
  end
end

function CombatManager:ExtraLog2Text(sText, tExtraData, nRefTime)
  local sResult = ""
  if sText == "ERROR" then
    sResult = tExtraData[1]
  elseif sText == "Play Sound" then
    local sFileName = tExtraData[1]
    local sFormat = "FileName='%s'"
    sResult = string.format(sFormat, sFileName)
  end
  return sResult
end

------------------------------------------------------------------------------
-- Handlers for CombatInterface.lua and timers.
------------------------------------------------------------------------------
function DruseraBossMods:OnTimerTimeout(data)
  if data then
    local nId = data[1]
    local fCallback = data[2]
    if fCallback and nId then
      local FoeUnit = _tFoes[nId]
      if FoeUnit and FoeUnit.tUnit:IsValid() then
        fCallback(FoeUnit)
      end
    end
  end
end

------------------------------------------------------------------------------
-- Service functions available in encounter.
------------------------------------------------------------------------------
function DruseraBossMods:ClearAllTimerAlert()
  self:HUDRemoveAllTimerBar()
end

function DruseraBossMods:SetMessage(tMessage)
  tMessage.sLabel = self.L[tMessage.sLabel]
  self:HUDCreateMessage(tMessage)
end

function DruseraBossMods:GetTimerRemaining(strKey)
  local sLabel = self.L[strKey]
  return self:HUDRetrieveTimerBar(sLabel)
end

function DruseraBossMods:SetTimerAlert(FoeUnit, strKey, duration, fCallback)
  local sLabel = self.L[strKey]
  local tOptions = FoeUnit.BarsCustom and FoeUnit.BarsCustom[sLabel] or nil
  self:HUDCreateTimerBar({
    sLabel = sLabel,
    nDuration = duration,
    nId = FoeUnit.nId,
    fCallback = self.OnTimerTimeout,
    tCallback_data = {FoeUnit.nId, fCallback},
  }, tOptions)
end

function DruseraBossMods:SetCastStartAlert(tFoeUnit, strKey, fCallback)
  SetCastAlert("tCastStartAlerts", tFoeUnit, strKey, fCallback)
end

function DruseraBossMods:SetCastFailedAlert(tFoeUnit, strKey, fCallback)
  SetCastAlert("tCastFailedAlerts", tFoeUnit, strKey, fCallback)
end

function DruseraBossMods:SetCastSuccessAlert(tFoeUnit, strKey, fCallback)
  SetCastAlert("tCastSuccessAlerts", tFoeUnit, strKey, fCallback)
end

function DruseraBossMods:SetDatachronAlert(tFoeUnit, strKey, fCallback)
  local msg = self.L[strKey]
  local state = fCallback and true or false
  if state then
    if not _tDatachronAlerts[msg] then
      _tDatachronAlerts[msg] = {}
    end
    _tDatachronAlerts[msg][tFoeUnit.nId] = fCallback
  elseif _tDatachronAlerts[msg] then
    _tDatachronAlerts[msg][tFoeUnit.nId] = nil
    if next(_tDatachronAlerts[msg]) == nil then
      _tDatachronAlerts[msg] = nil
    end
  end
end

function DruseraBossMods:SetNPCSayAlert(tFoeUnit, strKey, fCallback)
  local msg = self.L[strKey]
  local state = fCallback and true or false
  if state then
    if not _tNPCSayAlerts[msg] then
      _tNPCSayAlerts[msg] = {}
    end
    _tNPCSayAlerts[msg][tFoeUnit.nId] = fCallback
  elseif _tNPCSayAlerts[msg] then
    _tNPCSayAlerts[msg][tFoeUnit.nId] = nil
    if next(_tNPCSayAlerts[msg]) == nil then
      _tNPCSayAlerts[msg] = nil
    end
  end
end

function DruseraBossMods:GetDistBetween2Unit(tUnitFrom, tUnitTo)
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

function DruseraBossMods:SetBuffAddAlert(tFoe, nSpellId, fCallback)
  SetBuffAlert("tBuffAddAlerts", tFoe, nSpellId, fCallback)
end

function DruseraBossMods:SetBuffRemoveAlert(tFoe, nSpellId, fCallback)
  SetBuffAlert("tBuffRemoveAlerts", tFoe, nSpellId, fCallback)
end

function DruseraBossMods:SetBuffUpdateAlert(tFoe, nSpellId, fCallback)
  SetBuffAlert("tBuffUpdateAlerts", tFoe, nSpellId, fCallback)
end

function DruseraBossMods:SetDebuffAddAlert(tFoe, nSpellId, fCallback)
  SetBuffAlert("tDebuffAddAlerts", tFoe, nSpellId, fCallback)
end

function DruseraBossMods:SetDebuffRemoveAlert(tFoe, nSpellId, fCallback)
  SetBuffAlert("tDebuffRemoveAlerts", tFoe, nSpellId, fCallback)
end

function DruseraBossMods:SetDebuffUpdateAlert(tFoe, nSpellId, fCallback)
  SetBuffAlert("tDebuffUpdateAlerts", tFoe, nSpellId, fCallback)
end

function DruseraBossMods:CreateHealthBar(tFoe, sName)
  local sNameLoc = self.L[sName] or "Translation missing"
  Add2Logs("Add Health Bar", tFoe.nId)
  DruseraBossMods:HUDCreateHealthBar({
    sLabel = sNameLoc,
    tUnit = tFoe.tUnit,
    nId = tFoe.nId,
  }, nil)
end

function DruseraBossMods:PlaySound(sFileName)
  if not self.db.profile.custom.sound_enable then
    Add2Logs("Play Sound", nil, sFileName)
    -- Can be call from Gemini Console.
    Sound.PlayFile("..\\DruseraBossMods\\sounds\\" .. sFileName .. ".wav")
  end
end

function DruseraBossMods:SetMarkOnUnit(sMarkName, nTargetId, nLocation)
  local wPoint = _tMarksOnUnit[nTargetId]
  if wPoint then
    wPoint:Destroy()
    _tMarksOnUnit[nTargetId] = nil
  end
  local tUnit = GetUnitById(nTargetId)
  if sMarkName and tUnit then
    wPoint = Apollo.LoadForm(self.xmlDoc, "MarkOnUnit", "InWorldHudStratum", self)
    wPoint:SetUnit(tUnit, nLocation)
    _tMarksOnUnit[nTargetId] = wPoint
  end
end

function DruseraBossMods:ActivateDetection(flag)
  _CombatInterface:ActivateDetection(flag)
end
