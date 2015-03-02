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
-- Combat Interface object have the responsability to catch carbine events
-- and interpret them.
-- Thus many new events will be send to Combat Manager.
--
------------------------------------------------------------------------------
require "Apollo"
require "GameLib"
require "ApolloTimer"
require "ChatSystemLib"
require "Spell"
require "GroupLib"

------------------------------------------------------------------------------
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
------------------------------------------------------------------------------
local RegisterEventHandler = Apollo.RegisterEventHandler
local RemoveEventHandler = Apollo.RemoveEventHandler
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local debug, next, string = debug, next, string

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
-- Sometimes Carbine have inserted some no-break-space, for fun.
-- Behavior seen with french language.
local NO_BREAK_SPACE = string.char(194, 160)
local SCAN_PERIOD = 0.1 -- in seconds.
local CHANNEL_NPCSAY = ChatSystemLib.ChatChannel_NPCSay
local CHANNEL_DATACHRON = ChatSystemLib.ChatChannel_Datachron

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetAddon("DruseraBossMods")
local CombatInterface = {}

local _tCombatManager = nil
local _bRunning = false
local _bCheckMembers = false
local _tScanTimer = nil
local _tTrackedUnits = {}
local _tMembersUnits = {}
local _tHandlers = {
  UnitCreated = "UnitCreated",
  UnitDestroyed = "UnitDestroyed",
  UnitEnteredCombat = "UnitEnteredCombat",
  ChatMessage = "ChatMessage",
}
local _tOldLogs = {}
local _tLogs = {}
local nDeathTime = 0

------------------------------------------------------------------------------
-- Fast and local functions.
------------------------------------------------------------------------------
local function Add2Logs(sText, nId, ...)
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

local function GetHalfBuffs(tUnit)
  local Buffs = tUnit:GetBuffs()
  local r = {}
  -- Track only interresting buffs, and drop "normal" buff.
  local eType = tUnit:IsACharacter() and "arHarmful" or "arBeneficial"
  for _,obj in next, Buffs[eType] do
    r[obj.idBuff] = {
      eType = eType,
      nCount = obj.nCount,
      nIdBuff = obj.idBuff,
      splEffect = obj.splEffect,
    }
  end
  return r
end

local function TrackThisUnit(nId)
  local tUnit = GetUnitById(nId)
  if not _tTrackedUnits[nId] and tUnit then
    Add2Logs("TrackThisUnit", nId)
    _tTrackedUnits[nId] = {
      tUnit = tUnit,
      tBuffs = GetHalfBuffs(tUnit),
      tSpell = {
        bCasting = false,
        sCastName = "",
        nCastEndTime = 0,
        bSuccess = false,
      },
    }
  end
end

local function UnTrackThisUnit(nId)
  if _tTrackedUnits[nId] then
    Add2Logs("UnTrackThisUnit", nId)
    _tTrackedUnits[nId] = nil
  end
end

local function StopEncounter()
  Add2Logs("StopEncounter", nil)
  CombatInterface:Activate(false)
  _tTrackedUnits = {}
  _tOldLogs = _tLogs
  _tLogs = {}
  _tCombatManager:StopEncounter()
end

local function ProcessBuffTracking(nId, data)
  local tOldBuffs = data.tBuffs
  data.tBuffs = GetHalfBuffs(data.tUnit)
  for i,tBuff in next, data.tBuffs do
    if tOldBuffs[i] then
      local old = tOldBuffs[i].nCount
      local new = tBuff.nCount
      if new ~= old then
        Add2Logs("BuffUpdate", nId, tBuff.nIdBuff, old, new)
        _tCombatManager:BuffUpdate(nId, tBuff)
      end
      tOldBuffs[i] = nil
    else
      Add2Logs("BuffNew", nId, tBuff.nIdBuff, tBuff.nCount)
      _tCombatManager:BuffUpdate(nId, tBuff)
    end
  end
  for _,tBuff in next, tOldBuffs do
    tBuff.nCount = 0
    Add2Logs("BuffLost", nId, tBuff.nIdBuff)
    _tCombatManager:BuffUpdate(nId, tBuff)
  end
end

------------------------------------------------------------------------------
-- Relations between DruseraBossMods and CombatInterface objects.
------------------------------------------------------------------------------
function DruseraBossMods:CombatInterfaceInit(class, bTest)
  _tCombatManager = class
  _tTrackedUnits = {}
  _bRunning = false
  _bCheckMembers = false

  for k,v in next, _tHandlers do
    if bTest then
      _tHandlers[k] = "Test" .. k
    else
      _tHandlers[k] = k
    end
  end

  RegisterEventHandler(_tHandlers.UnitEnteredCombat, "OnEnteredCombat", CombatInterface)
  _tScanTimer = ApolloTimer.Create(SCAN_PERIOD, true, "OnScanUpdate", CombatInterface)
  _tScanTimer:Stop()
  return CombatInterface
end

function DruseraBossMods:CombatInterfaceUnInit()
  CombatInterface:Activate(false)
  _tScanTimer = nil
  RemoveEventHandler(_tHandlers.UnitEnteredCombat, CombatInterface)
end

-- This function can be call through GeminiConsole.
function DruseraBossMods:CombatInterfaceDumpCurrentLog()
  return Logs2Text(_tLogs)
end

-- This function can be call through GeminiConsole.
function DruseraBossMods:CombatInterfaceDumpOldLog()
  return Logs2Text(_tOldLogs)
end

------------------------------------------------------------------------------
-- Combat Interface layer.
------------------------------------------------------------------------------
function CombatInterface:Activate(bState)
  if not _bRunning and bState then
    _bRunning = true
    RegisterEventHandler(_tHandlers.ChatMessage, "OnChatMessage", self)
    _tScanTimer:Start()
    Add2Logs("True", nil)
  elseif _bRunning and not bState then
    _tScanTimer:Stop()
    RemoveEventHandler(_tHandlers.ChatMessage, self)
    RemoveEventHandler(_tHandlers.UnitCreated, self)
    RemoveEventHandler(_tHandlers.UnitDestroyed, self)
    _bRunning = false
    Add2Logs("False", nil)
  end
end

function CombatInterface:ActivateDetection(bState)
  if _bRunning and bState then
    RegisterEventHandler(_tHandlers.UnitCreated, "OnUnitCreated", self)
    RegisterEventHandler(_tHandlers.UnitDestroyed, "OnUnitDestroyed", self)
  else
    RemoveEventHandler(_tHandlers.UnitDestroyed, self)
    RemoveEventHandler(_tHandlers.UnitCreated, self)
  end
end

function CombatInterface:OnScanUpdate()
  local bEndOfCombat = true
  for i = 1, GroupLib.GetMemberCount() do
    local tMemberData = GroupLib.GetGroupMember(i)
    if tMemberData then
      local tUnitMember = GroupLib.GetUnitForGroupMember(i)
      local bOutOfRange = tMemberData.nHealthMax == 0 or not tUnitMember
      local bIsOnline = tMemberData.bIsOnline
      local bIsInCombat = tUnitMember and tUnitMember:IsInCombat() or false

      if not bOutOfRange and bIsOnline then
        local nId = tUnitMember:GetId()
        TrackThisUnit(nId)
        ProcessBuffTracking(nId, _tTrackedUnits[nId])
      end
      if bEndOfCombat and not bOutOfRange and bIsOnline and bIsInCombat then
        bEndOfCombat = false
      end
    end
  end
  if _bCheckMembers and bEndOfCombat then
    StopEncounter()
  end
  for nId, data in next, _tTrackedUnits do
    if data.tUnit:IsValid() then
      -- Process buff tracking.
      ProcessBuffTracking(nId, data)

      -- Process cast tracking.
      if not data.tUnit:IsACharacter() then
        local bCasting = data.tUnit:IsCasting()
        if bCasting then
          local sCastName = data.tUnit:GetCastName()
          local nCastDuration = data.tUnit:GetCastDuration()
          local nCastElapsed = data.tUnit:GetCastElapsed()
          local nCastEndTime = GetGameTime() + (nCastDuration - nCastElapsed) / 1000

          sCastName = string.gsub(sCastName, NO_BREAK_SPACE, " ")
          if not data.tSpell.bCasting then
            -- New cast
            data.tSpell = {
              bCasting = true,
              sCastName = sCastName,
              nCastEndTime = nCastEndTime,
              bSuccess = false,
            }
            Add2Logs("Cast Start", nId, sCastName)
            _tCombatManager:CastStart(nId, data.tSpell)
          elseif data.tSpell.bCasting then
            if sCastName ~= data.tSpell.sCastName then
              -- New cast just after a previous one.
              Add2Logs("Cast Success", nId, data.tSpell.sCastName)
              _tCombatManager:CastSuccess(nId, data.tSpell)
              data.tSpell = {
                bCasting = true,
                sCastName = sCastName,
                nCastEndTime = nCastEndTime,
                bSuccess = false,
              }
              Add2Logs("Cast Start", nId, sCastName)
              _tCombatManager:CastStart(nId, data.tSpell)
            elseif not data.tSpell.bSuccess and nCastElapsed >= nCastDuration then
              -- The have reached the end.
              Add2Logs("Cast Success", nId, data.tSpell.sCastName)
              _tCombatManager:CastSuccess(nId, data.tSpell)
              data.tSpell = {
                bCasting = true,
                sCastName = sCastName,
                nCastEndTime = 0,
                bSuccess = true,
              }
            end
          end
        elseif data.tSpell.bCasting then
          if not data.tSpell.bSuccess then
            -- Let's compare with the nCastEndTime
            if GetGameTime() < data.tSpell.nCastEndTime then
              Add2Logs("Cast Failed", nId, data.tSpell.sCastName)
              _tCombatManager:CastFailed(nId, data.tSpell)
            else
              Add2Logs("Cast Success", nId, data.tSpell.sCastName)
              _tCombatManager:CastSuccess(nId, data.tSpell)
            end
          end
          data.tSpell = {
            bCasting = false,
            sCastName = "",
            nCastEndTime = 0,
            bSuccess = false,
          }
        end
      end
    end
  end
end

function CombatInterface:OnEnteredCombat(tUnit, bInCombat)
  local nId = tUnit:GetId()
  local sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")

  if nId == GetPlayerUnit():GetId() then
    if bInCombat and not __bRunning then
      _bCheckMembers = false
      Add2Logs("StartEncounter", nil)
      self:Activate(true)
      _tCombatManager:StartEncounter()
    elseif _bRunning and not bInCombat then
      if tUnit:GetHealth() == 0 then
        _bCheckMembers = true
        nDeathTime = GetGameTime()
      else
        StopEncounter()
      end
    end
  elseif tUnit:IsInYourGroup() then
    -- Members of the raid are not managed here.
  elseif _tTrackedUnits[nId] then
    if bInCombat then
      Add2Logs("TrackedUnitInCombat", nId)
      local r = _tCombatManager:UnitEnteringCombat(tUnit, nId, sName)
      if not r then UnTrackThisUnit(nId) end
    elseif tUnit:GetHealth() == 0 then
      Add2Logs("TrackedUnitIsDead", nId)
      UnTrackThisUnit(nId)
      _tCombatManager:UnitDead(tUnit, nId, sName)
    else
      Add2Logs("TrackedUnitLeftCombat", nId)
      _tCombatManager:UnitLeftCombat(tUnit, nId, sName)
    end
  else
    if bInCombat then
      Add2Logs("UnknownUnitInCombat", nId)
      local r = _tCombatManager:UnknownUnitInCombat(tUnit, nId, sName)
      if r then TrackThisUnit(nId) end
    end
  end
end

function CombatInterface:OnChatMessage(tChannelCurrent, tMessage)
  local ChannelType = tChannelCurrent:GetType()
  local sMessage = tMessage.arMessageSegments[1].strText
  sMessage = string.gsub(sMessage, NO_BREAK_SPACE, " ")

  if CHANNEL_NPCSAY == ChannelType then
    Add2Logs("NPCSay", nil)
    _tCombatManager:NPCSay(sMessage)
  elseif CHANNEL_DATACHRON == ChannelType then
    Add2Logs("Datachron", nil)
    _tCombatManager:Datachron(sMessage)
  end
end

function CombatInterface:OnUnitCreated(tUnit)
  local nId = tUnit:GetId()
  local sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")

  if not tUnit:IsInYourGroup() and nId ~= GetPlayerUnit():GetId() then
    Add2Logs("UnitDetected", nId)
    local r = _tCombatManager:UnitDetected(tUnit, nId, sName)
    if r then TrackThisUnit(nId) end
  end
end

function CombatInterface:OnUnitDestroyed(tUnit)
  local nId = tUnit:GetId()
  if _tTrackedUnits[nId] then
    Add2Logs("UnitDestroyed", nId)
    UnTrackThisUnit(nId)
    _tCombatManager:UnitDestroyed(tUnit, sName)
  end
end
