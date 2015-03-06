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

local function ManagerCall(sMethod, ...)
  fMethod = _tCombatManager[sMethod]
  local s, sErrMsg = pcall(fMethod, _tCombatManager, unpack(arg))
  if not s then
    Print(sErrMsg)
    Add2Logs("ERROR", nil, sErrMsg)
  end
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
  local r = {
    arBeneficial = {},
    arHarmful = {},
  }
  if tUnit:IsValid() then
    local tAllBuffs = tUnit:GetBuffs()
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
  else
    local d3 = debug.getinfo(3, 'n')
    local d2 = debug.getinfo(2, 'n')
    local sd2 = d2 and d2.name or ""
    local sd3 = d2 and d2.name or ""
    Print (GetGameTime() .. " Invaid " .. sd2 .."  " .. sd3)
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
      tBuffs = tAllBuffs["arBeneficial"],
      tDebuffs = {},
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
  Add2Logs("StopEncounter", nil)
  CombatInterface:Activate(false)
  _tTrackedUnits = {}
  _tMembers = {}
  _tOldLogs = _tLogs
  _tLogs = {}
  ManagerCall("StopEncounter")
end

local function ProcessAllBuffs(tMyUnit)
  local bProcessDebuffs = tMyUnit.tUnit:IsACharacter()
  local bProcessBuffs = not bProcessDebuffs
  local tAllBuffs = GetAllBuffs(tUnit)
  local nId = tMyUnit.tUnit:GetId()

  if bProcessDebuffs then
    local tOldDebuffs = tMyUnit.tDebuffs
    local tDebuffs = tAllBuffs["arHarmful"]
    for nIdBuff,tDebuff in next, tDebuffs do
      if tOldDebuffs[nIdBuff] then
        tOldDebuffs[nIdBuff] = nil
        local nNewStack = tDebuff.nCount
        local nOldStack = tOldDebuffs[nIdBuff].nCount
        if nNewStack ~= nOldStack then
          tMyUnit.tDebuffs[nIdBuff].nCount = nNewStack
          Add2Logs("DebuffUpdate", nId, nIdBuff, nOldStack, nNewStack)
          ManagerCall("DebuffUpdate", nId, nIdBuff, nOldStack, nNewStack)
        end
      else
        tMyUnit.tDebuffs[nIdBuff] = tDebuff
        Add2Logs("DebuffAdd", nId, nIdBuff, tDebuff.nCount)
        ManagerCall("DebuffAdd", nId, nIdBuff, tDebuff.nCount)
      end
    end
    for nIdBuff,tDebuff in next, tOldDebuffs do
      if tMyUnit.tDebuffs[nIdBuff] then
        tMyUnit.tDebuffs[nIdBuff] = nil
        Add2Logs("DebuffRemove", nId, nIdBuff)
        ManagerCall("DebuffRemove", nId, nIdBuff)
      end
    end
  end
  if bProcessBuffs then
    local tOldBuffs = tMyUnit.tBuffs
    local tBuffs = tAllBuffs["arBeneficial"]
    for nIdBuff,tBuff in next, tBuffs do
      if tOldBuffs[i] then
        tOldBuffs[i] = nil
        local nNewStack = tBuff.nCount
        local nOldStack = tOldBuffs[i].nCount
        if nNewStack ~= nOldStack then
          tMyUnit.tBuffs[nIdBuff].nCount = nNewStack
          Add2Logs("BuffUpdate", nId, nIdBuff, nOldStack, nNewStack)
          ManagerCall("BuffUpdate", nId, nIdBuff, nOldStack, nNewStack)
        end
      else
        tMyUnit.tBuffs[nIdBuff] = tBuff
        Add2Logs("BuffAdd", nId, nIdBuff, tBuff.nCount)
        ManagerCall("BuffAdd", nId, nIdBuff, tBuff.nCount)
      end
    end
    for nIdBuff,tBuff in next, tOldBuffs do
      if tMyUnit.tBuffs[nIdBuff] then
        tMyUnit.tBuffs[nIdBuff] = nil
        Add2Logs("BuffRemove", nId, nIdBuff)
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
          tDebuffs = tAllBuffs["arHarmful"],
          tBuffs = {},
        }
      end
    end
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
      if not data.tUnit:IsACharacter() then
        local bCasting = data.tUnit:IsCasting()
        if bCasting then
          local sCastName = data.tUnit:GetCastName()
          local nCastDuration = data.tUnit:GetCastDuration()
          local nCastElapsed = data.tUnit:GetCastElapsed()
          local nCastEndTime = GetGameTime() + (nCastDuration - nCastElapsed) / 1000

          sCastName = string.gsub(sCastName, NO_BREAK_SPACE, " ")
          if not data.tCast.bCasting then
            -- New cast
            data.tCast = {
              bCasting = true,
              sCastName = sCastName,
              nCastEndTime = nCastEndTime,
              bSuccess = false,
            }
            Add2Logs("Cast Start", nId, sCastName)
            ManagerCall("CastStart", nId, data.tCast)
          elseif data.tCast.bCasting then
            if sCastName ~= data.tCast.sCastName then
              -- New cast just after a previous one.
              Add2Logs("Cast Success", nId, data.tCast.sCastName)
              ManagerCall("CastSuccess", nId, data.tCast)
              data.tCast = {
                bCasting = true,
                sCastName = sCastName,
                nCastEndTime = nCastEndTime,
                bSuccess = false,
              }
              Add2Logs("Cast Start", nId, sCastName)
              ManagerCall("CastStart", nId, data.tCast)
            elseif not data.tCast.bSuccess and nCastElapsed >= nCastDuration then
              -- The have reached the end.
              Add2Logs("Cast Success", nId, data.tCast.sCastName)
              ManagerCall("CastSuccess", nId, data.tCast)
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
              Add2Logs("Cast Failed", nId, data.tCast.sCastName)
              ManagerCall("CastFailed", nId, data.tCast)
            else
              Add2Logs("Cast Success", nId, data.tCast.sCastName)
              ManagerCall("CastSuccess", nId, data.tCast)
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
end

function CombatInterface:OnEnteredCombat(tUnit, bInCombat)
  local nId = tUnit:GetId()
  local sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")

  if nId == GetPlayerUnit():GetId() then
    if bInCombat and not __bRunning then
      _bCheckMembers = false
      Add2Logs("StartEncounter", nil)
      self:Activate(true)
      ManagerCall("StartEncounter")
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
      ManagerCall("UnitEnteringCombat", tUnit, nId, sName)
    elseif tUnit:GetHealth() == 0 then
      Add2Logs("TrackedUnitIsDead", nId)
      UnTrackThisUnit(nId)
      ManagerCall("UnitDead", tUnit, nId, sName)
    else
      Add2Logs("TrackedUnitLeftCombat", nId)
      ManagerCall("UnitLeftCombat", tUnit, nId, sName)
    end
  else
    if bInCombat then
      Add2Logs("UnknownUnitInCombat", nId)
      ManagerCall("UnknownUnitInCombat", tUnit, nId, sName)
    end
  end
end

function CombatInterface:OnChatMessage(tChannelCurrent, tMessage)
  local ChannelType = tChannelCurrent:GetType()
  local sMessage = tMessage.arMessageSegments[1].strText
  sMessage = string.gsub(sMessage, NO_BREAK_SPACE, " ")

  if CHANNEL_NPCSAY == ChannelType then
    Add2Logs("NPCSay", nil)
    ManagerCall("NPCSay", sMessage)
  elseif CHANNEL_DATACHRON == ChannelType then
    Add2Logs("Datachron", nil)
    ManagerCall("Datachron", sMessage)
  end
end

function CombatInterface:OnUnitCreated(tUnit)
  local nId = tUnit:GetId()
  local sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")

  if not tUnit:IsInYourGroup() and nId ~= GetPlayerUnit():GetId() then
    Add2Logs("UnitDetected", nId)
    ManagerCall("UnitDetected", tUnit, nId, sName)
  end
end

function CombatInterface:OnUnitDestroyed(tUnit)
  local nId = tUnit:GetId()
  if _tTrackedUnits[nId] then
    Add2Logs("UnitDestroyed", nId)
    UnTrackThisUnit(nId)
    ManagerCall("UnitDestroyed", tUnit, sName)
  end
end

function CombatInterface:UnTrackThisUnit(nId)
  UnTrackThisUnit(nId)
end

function CombatInterface:TrackThisUnit(nId)
  TrackThisUnit(nId)
end
