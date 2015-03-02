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
local next = next

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local NO_BREAK_SPACE = string.char(194, 160)

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetAddon("DruseraBossMods")
local CombatManager = {}

local _CombatInterface = nil
local _bEncounterInProgress = false
local _tFoes = {}
local _tDatabase = {} -- Copy will be done on init.
local _tNPCSayAlerts = {}
local _tDatachronAlerts = {}

local _tOldLogs = {}
local _tLogs = {}
_G["DBM_db"] = _tDatabase

------------------------------------------------------------------------------
-- Fast and local functions.
------------------------------------------------------------------------------
local function Add2Logs(sText, nId, ...)
  if not _bEncounterInProgress then return end
  --@alpha@
  local d = debug.getinfo(2, 'n')
  local tUnitInfo = {
    nId = nId,
    sName = "",
  }
  if nId then
    tUnit = GetUnitById(nId)
    if tUnit then
      tUnitInfo.sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")
      tUnitInfo.bIsValid = tUnit:IsValid()
    end
  end
  local sFuncName = d and d.name or ""
  table.insert(_tLogs, {GetGameTime(), sFuncName, sText, tUnitInfo, ...})
  --@end-alpha@
end

local function Logs2Text(_tLogs)
  local tTextLog = {}
  for _, Log in next, _tLogs do
    local time = Log[1]
    local sEventType = Log[2] .. " - " .. Log[3]
    local tUnitInfo = Log[4]
    local sUnitInfo = ""
    if tUnitInfo.sName and tUnitInfo.nId then
      sUnitInfo = string.format("%s:%u", tUnitInfo.sName, tUnitInfo.nId)
    elseif tUnitInfo.nId then
      sUnitInfo = string.format("....:%u", tUnitInfo.nId)
    elseif tUnitInfo.sName then
      sUnitInfo = string.format("%s:....", tUnitInfo.sName)
    end
    if Log[4].bIsValid == false then
      sUnitInfo = sUnitInfo .. "(Invalid)"
    end

    table.insert(tTextLog, {time, sEventType, sUnitInfo})
  end
  return tTextLog
end

local function FoesStartCombat(nId)
  local tFoe = _tFoes[nId]
  if _bEncounterInProgress and tFoe and tFoe.OnStartCombat then
    Add2Logs("Foe start combat", nId)
    tFoe:OnStartCombat()
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

local function CastProcess(CastType, nId, tSpell)
  if _bEncounterInProgress then
    local tFoe = _tFoes[nId]
    if tFoe then
      local sCastName = tSpell.sCastName
      local cb = tFoe[CastType][sCastName]
      if cb then cb(tFoe) end
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
  return CombatManager
end

function DruseraBossMods:CombatManagerDumpCurrentLog()
  return Logs2Text(_tLogs)
end

function DruseraBossMods:CombatManagerDumpOldLog()
  return Logs2Text(_tOldLogs)
end

function DruseraBossMods:RegisterEncounter(tData)
  local nMapParentId = tData.nZoneMapParentId
  local nMapId = tData.nZoneMapId

  if not nMapParentId or not nMapId or not tData.tTriggerNames then
    Print("Invalid encounter ZoneMap definition!")
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
  nFightStartTime = GetGameTime()
  _bEncounterInProgress = true
  Add2Logs("Start Encounter", nil, nFightStartTime)
  for nId, Foe in next, _tFoes do
    if Foe.tUnit:IsValid() then
      if Foe.bInCombat then
        FoesStartCombat(Foe.nId)
      end
    end
  end
end

function CombatManager:StopEncounter()
  local nStopStartTime = GetGameTime()
  Add2Logs("Stop Encounter", nil, nStopStartTime)

  for nId,FoeUnit in next, _tFoes do
    RemoveFoeUnit(nId)
  end
  _tCurrentEncounter = nil
  _tNPCSayAlerts = {}
  _tDatachronAlerts = {}
  _tOldLogs = _tLogs
  _tLogs = {}
  _bEncounterInProgress = false
end

function CombatManager:UnitDetected(tUnit, nId, sName)
  SearchAndAdd(nId, sName, false)
  return _tFoes[nId] ~= nil
end

function CombatManager:UnitDestroyed(tUnit, nId, sName)
  Add2Logs("Foe destroyed", nId)
  RemoveFoeUnit(nId)
end

function CombatManager:UnitEnteringCombat(tUnit, nId, sName)
  local bExist = true
  if _tFoes[nId] then
    Add2Logs("Foe entering in combat", nId)
    _tFoes[nId].bInCombat = true
    FoesStartCombat(nId)
  else
    bExist = self:UnknownUnitInCombat(tUnit, nId, sName)
  end
  return bExist
end

function CombatManager:UnknownUnitInCombat(tUnit, nId, sName)
  SearchAndAdd(nId, sName, true)
  local bExist = _tFoes[nId] ~= nil
  if bExist then
    FoesStartCombat(nId)
  else
    Add2Logs("Foe ignored", nId)
  end
  return bExist
end

function CombatManager:UnitDead(tUnit, nId, sName)
  Add2Logs("Foe dead", nId)
  RemoveFoeUnit(nId)
end

function CombatManager:UnitLeftCombat(tUnit, nId, sName)
  if _tFoes[nId] then
    Add2Logs("Foe out of combat", nId)
    _tFoes[nId].bInCombat = false
  end
end

function CombatManager:CastStart(nId, tSpell)
  CastProcess("tCastStartAlerts", nId, tSpell)
end

function CombatManager:CastFailed(nId, tSpell)
  CastProcess("tCastFailedAlerts", nId, tSpell)
end

function CombatManager:CastSuccess(nId, tSpell)
  CastProcess("tCastSuccessAlerts", nId, tSpell)
end

function CombatManager:BuffUpdate(nId, tBuff)
  if _bEncounterInProgress then
    local nSpellId = tBuff.splEffect:GetId()
    for _,tFoeUnit in next, _tFoes do
      local cb = tFoeUnit.tBuffAlerts[nSpellId]
      if cb then
        cb(tFoeUnit)
      end
    end
  end
end

function CombatManager:NPCSay(sMessage)
  if _bEncounterInProgress then
    local callbacks = _tNPCSayAlerts[sMessage]
    if callbacks then
      for nId, cb in next, callbacks do
        if _tFoes[nId] then
          cb(_tFoes[nId])
        else
          -- Auto clean.
          _tNPCSayAlerts[sMessage][nId] = nil
          if next(_tNPCSayAlerts[sMessage]) == nil then
            _tNPCSayAlerts[sMessage] = nil
          end
        end
      end
    end
  end
end

function CombatManager:Datachron(sMessage)
  if _bEncounterInProgress then
    local callbacks = _tDatachronAlerts[sMessage]
    if callbacks then
      for nId, cb in next, callbacks do
        if _tFoes[nId] then
          cb(_tFoes[nId])
        else
          -- Auto clean.
          _tDatachronAlerts[sMessage][nId] = nil
          if next(_tDatachronAlerts[sMessage]) == nil then
            _tDatachronAlerts[sMessage] = nil
          end
        end
      end
    end
  end
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

function DruseraBossMods:SetBuffAlert(tFoeUnit, nSpellId, fCallback)
  assert(nSpellId)
  assert(tFoeUnit)
  local bRegistered = tFoeUnit.tBuffAlerts[nSpellId] ~= nil
  tFoeUnit.tBuffAlerts[nSpellId] = fCallback
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
  Add2Logs("Play Sound", nil, sFileName)
  Sound.PlayFile("sounds\\" .. sFileName .. ".wav")
end
