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
local debug, next, string, pcall, unpack = debug, next, string, pcall, unpack

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
-- Sometimes Carbine have inserted some no-break-space, for fun.
-- Behavior seen with French language.
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
local _tScanTimer
local _tTrackedUnits = {}
local _tMembers = {}
local _tHandlers = {
  UnitCreated = "UnitCreated",
  UnitDestroyed = "UnitDestroyed",
  UnitEnteredCombat = "UnitEnteredCombat",
  ChatMessage = "ChatMessage",
}
local _tOldLogs = {}
local _tLogs = {}

------------------------------------------------------------------------------
-- Fast and local functions.
------------------------------------------------------------------------------
local function Add2Logs(sText, ...)
  --@alpha@
  local d = debug.getinfo(2, 'n')
  local nId = nil
  if select("#", ...) > 0 then
    nId = select(1, ...)
  end
  local tUnitInfo = {}
  if type(nId) == "number" then
    tUnit = GetUnitById(nId)
    tUnitInfo.nId = nId
    if tUnit then
      tUnitInfo.sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")
      tUnitInfo.bIsValid = tUnit:IsValid()
    end
  else
    tUnitInfo.nId = nil
    tUnitInfo.sName = ""
  end
  local sFuncName = d and d.name or ""
  table.insert(_tLogs, {GetGameTime(), sFuncName, sText, tUnitInfo, ...})
  --@end-alpha@
end

local function ManagerCall(sMethod, ...)
  -- Trace all call to upper layer for debugging purpose.
  Add2Logs(sMethod, ...)
  -- Retrieve callback function.
  fMethod = _tCombatManager[sMethod]
  -- Protected call.
  local s, sErrMsg = pcall(fMethod, _tCombatManager, ...)
  --@alpha@
  if not s then
    Print(sMethod .. ": " .. sErrMsg)
    Add2Logs("ERROR", nil, sErrMsg)
  end
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

local function GetAllBuffs(tUnit)
  local tAllBuffs = tUnit:GetBuffs()
  local r = {}
  if tAllBuffs then
    for sType, tBuffs in next, tAllBuffs do
      r[sType] = {}
      for _,obj in next, tBuffs do
        r[sType][obj.idBuff] = {
          nCount = obj.nCount,
          nIdBuff = obj.idBuff,
          tSpell = obj.splEffect,
        }
      end
    end
  end
  return r
end

local function TrackThisUnit(nId)
  local tUnit = GetUnitById(nId)
  if not _tTrackedUnits[nId] and tUnit then
    Add2Logs("TrackThisUnit", nId)
    local tAllBuffs = GetAllBuffs(tUnit)
    _tTrackedUnits[nId] = {
      tUnit = tUnit,
      tBuffs = tAllBuffs["arBeneficial"] or {},
      tDebuffs = {},
      nId = nId,
      bIsACharacter = false,
      tCast = {
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
  Activate(false)
  _tTrackedUnits = {}
  _tMembers = {}
  _tOldLogs = _tLogs
  _tLogs = {}
  ManagerCall("StopEncounter")
end

local function ProcessAllBuffs(tMyUnit)
  local tAllBuffs = GetAllBuffs(tUnit)
  local bProcessDebuffs = tMyUnit.bIsACharacter
  local bProcessBuffs = not bProcessDebuffs
  local nId = tMyUnit.nId

  local tDebuffs = tAllBuffs["arHarmful"]
  if bProcessDebuffs and tDebuffs then
    local tOldDebuffs = tMyUnit.tDebuffs
    for nIdBuff,tDebuff in next, tDebuffs do
      if tOldDebuffs[nIdBuff] then
        tOldDebuffs[nIdBuff] = nil
        local nNewStack = tDebuff.nCount
        local nOldStack = tOldDebuffs[nIdBuff].nCount
        if nNewStack ~= nOldStack then
          tMyUnit.tDebuffs[nIdBuff].nCount = nNewStack
          ManagerCall("DebuffUpdate", nId, nIdBuff, nOldStack, nNewStack)
        end
      else
        tMyUnit.tDebuffs[nIdBuff] = tDebuff
        ManagerCall("DebuffAdd", nId, nIdBuff, tDebuff.nCount)
      end
    end
    for nIdBuff,tDebuff in next, tOldDebuffs do
      if tMyUnit.tDebuffs[nIdBuff] then
        tMyUnit.tDebuffs[nIdBuff] = nil
        ManagerCall("DebuffRemove", nId, nIdBuff)
      end
    end
  end

  local tBuffs = tAllBuffs["arBeneficial"]
  if bProcessBuffs and tBuffs then
    local tOldBuffs = tMyUnit.tBuffs
    for nIdBuff,tBuff in next, tBuffs do
      if tOldBuffs[i] then
        tOldBuffs[i] = nil
        local nNewStack = tBuff.nCount
        local nOldStack = tOldBuffs[i].nCount
        if nNewStack ~= nOldStack then
          tMyUnit.tBuffs[nIdBuff].nCount = nNewStack
          ManagerCall("BuffUpdate", nId, nIdBuff, nOldStack, nNewStack)
        end
      else
        tMyUnit.tBuffs[nIdBuff] = tBuff
        ManagerCall("BuffAdd", nId, nIdBuff, tBuff.nCount)
      end
    end
    for nIdBuff,tBuff in next, tOldBuffs do
      if tMyUnit.tBuffs[nIdBuff] then
        tMyUnit.tBuffs[nIdBuff] = nil
        ManagerCall("BuffRemove", nId, nIdBuff)
      end
    end
  end
end

local function UpdateMemberList()
  for i = 1, GroupLib.GetMemberCount() do
    local tMemberData = GroupLib.GetGroupMember(i)
    local tUnit = GroupLib.GetUnitForGroupMember(i)
    -- A Friend out of range have a tUnit object equal to nil.
    -- And if you have the tUnit object, the IsValid flag can change.
    if tMemberData and tUnit then
      local sName = tMemberData.strCharacterName
      if not _tMembers[sName] then
        local tAllBuffs = GetAllBuffs(tUnit)
        _tMembers[sName] = {
          tData = tMemberData,
          tUnit = tUnit,
          nId = tUnit:GetId(),
          tDebuffs = tAllBuffs["arHarmful"] or {},
          tBuffs = {},
          bIsACharacter = true,
        }
      end
    end
  end
end

function Activate(bState)
  if not _bRunning and bState then
    _bRunning = true
    RegisterEventHandler(_tHandlers.ChatMessage, "OnChatMessage",
                         CombatInterface)
    _tScanTimer:Start()
  elseif _bRunning and not bState then
    _tScanTimer:Stop()
    RemoveEventHandler(_tHandlers.ChatMessage, CombatInterface)
    RemoveEventHandler(_tHandlers.UnitCreated, CombatInterface)
    RemoveEventHandler(_tHandlers.UnitDestroyed, CombatInterface)
    _bRunning = false
  end
end

------------------------------------------------------------------------------
-- Relations between DruseraBossMods and CombatInterface objects.
------------------------------------------------------------------------------
function DruseraBossMods:CombatInterfaceInit(class, bTest)
  _tCombatManager = class
  _tTrackedUnits = {}
  _tMembers = {}
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
  Activate(false)
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
  UpdateMemberList()
  local bEndOfCombat = true
  for sName,tMember in next, _tMembers do
    local bIsValid = tMember.tUnit:IsValid()
    local bOutOfRange = tMember.tData.nHealthMax == 0 or not bIsValid
    local bIsOnline = tMember.tData.bIsOnline
    local bIsInCombat = bIsValid and tMember.tUnit:IsInCombat()

    if bIsValid and bIsInCombat then
      bEndOfCombat = false
    end
    if bIsValid then
      local f, err = pcall(ProcessAllBuffs, tMember)
      if not f then
        Print (err)
      end
    end
  end

  if _bCheckMembers and bEndOfCombat then
    StopEncounter()
  end
  for nId, data in next, _tTrackedUnits do
    if data.tUnit:IsValid() then
      -- Process buff tracking.
      local f, err = pcall(ProcessAllBuffs, data)
      if not f then
        Print (err)
      end

      -- Process cast tracking.
      local bCasting = data.tUnit:IsCasting()
      if bCasting then
        local nCurrentTime = GetGameTime()
        local sCastName = data.tUnit:GetCastName()
        local nCastDuration = data.tUnit:GetCastDuration()
        local nCastElapsed = data.tUnit:GetCastElapsed()
        local nCastEndTime = nCurrentTime + (nCastDuration - nCastElapsed) / 1000

        sCastName = string.gsub(sCastName, NO_BREAK_SPACE, " ")
        if not data.tCast.bCasting then
          -- New cast
          data.tCast = {
            bCasting = true,
            sCastName = sCastName,
            nCastEndTime = nCastEndTime,
            bSuccess = false,
          }
          ManagerCall("CastStart", nId, sCastName, nCastEndTime)
        elseif data.tCast.bCasting then
          if sCastName ~= data.tCast.sCastName then
            -- New cast just after a previous one.
            ManagerCall("CastSuccess", nId,
                        data.tCast.sCastName,
                        data.tCast.nCastEndTime)
            data.tCast = {
              bCasting = true,
              sCastName = sCastName,
              nCastEndTime = nCastEndTime,
              bSuccess = false,
            }
            ManagerCall("CastStart", nId, sCastName, nCastEndTime)
          elseif not data.tCast.bSuccess and nCastElapsed >= nCastDuration then
            -- The have reached the end.
            ManagerCall("CastSuccess", nId,
                        data.tCast.sCastName,
                        data.tCast.nCastEndTime)
            data.tCast = {
              bCasting = true,
              sCastName = sCastName,
              nCastEndTime = 0,
              bSuccess = true,
            }
          end
        end
      elseif data.tCast.bCasting then
        if not data.tCast.bSuccess then
          -- Let's compare with the nCastEndTime
          if GetGameTime() < data.tCast.nCastEndTime then
            ManagerCall("CastFailed", nId,
                        data.tCast.sCastName,
                        data.tCast.nCastEndTime)
          else
            ManagerCall("CastSuccess", nId,
                        data.tCast.sCastName,
                        data.tCast.nCastEndTime)
          end
        end
        data.tCast = {
          bCasting = false,
          sCastName = "",
          nCastEndTime = 0,
          bSuccess = false,
        }
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
      Activate(true)
      ManagerCall("StartEncounter")
    elseif _bRunning and not bInCombat then
      if tUnit:GetHealth() == 0 then
        _bCheckMembers = true
        Add2Logs("Player is dead", nId)
      else
        StopEncounter()
      end
    end
  elseif tUnit:IsInYourGroup() then
    -- Members of the raid are not managed here.
  elseif _tTrackedUnits[nId] then
    if bInCombat then
      ManagerCall("UnitEnteringCombat", nId, tUnit ,sName)
    elseif tUnit:GetHealth() == 0 then
      UnTrackThisUnit(nId)
      ManagerCall("UnitDead", nId, tUnit, sName)
    else
      ManagerCall("UnitLeftCombat", nId, tUnit, sName)
    end
  else
    if bInCombat then
      ManagerCall("UnknownUnitInCombat", nId, tUnit, sName)
    end
  end
end

function CombatInterface:OnChatMessage(tChannelCurrent, tMessage)
  local ChannelType = tChannelCurrent:GetType()
  local sMessage = tMessage.arMessageSegments[1].strText
  sMessage = string.gsub(sMessage, NO_BREAK_SPACE, " ")

  if CHANNEL_NPCSAY == ChannelType then
    ManagerCall("NPCSay", nil, sMessage)
  elseif CHANNEL_DATACHRON == ChannelType then
    ManagerCall("Datachron", nil, sMessage)
  end
end

function CombatInterface:OnUnitCreated(tUnit)
  local nId = tUnit:GetId()
  local sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")

  if not tUnit:IsInYourGroup() and nId ~= GetPlayerUnit():GetId() then
    ManagerCall("UnitDetected", nId, tUnit, sName)
  end
end

function CombatInterface:OnUnitDestroyed(tUnit)
  local nId = tUnit:GetId()
  if _tTrackedUnits[nId] then
    UnTrackThisUnit(nId)
    ManagerCall("UnitDestroyed", nId, tUnit, sName)
  end
end

function CombatInterface:UnTrackThisUnit(nId)
  UnTrackThisUnit(nId)
end

function CombatInterface:TrackThisUnit(nId)
  TrackThisUnit(nId)
end
