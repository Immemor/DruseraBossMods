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
local GetSpell = GameLib.GetSpell
local next, string, pcall  = next, string, pcall

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
-- Sometimes Carbine have inserted some no-break-space, for fun.
-- Behavior seen with French language.
local NO_BREAK_SPACE = string.char(194, 160)
local SCAN_PERIOD = 0.1 -- in seconds.
local CHANNEL_NPCSAY = ChatSystemLib.ChatChannel_NPCSay
local CHANNEL_DATACHRON = ChatSystemLib.ChatChannel_Datachron
local SPELLID_BLACKLISTED = {
  [60883] = "Irradiate", -- On war class.
  [76652] = "Surge Focus Drain", -- On arcanero class.
}
local UNITNAME_BLACKLISTED = {
  ["Phantom"] = true, -- Esper dps.
  ["Artillerybot"] = true, -- Inge.
}

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local CombatInterface = {}

local _tCombatManager = nil
local _bRunning = false
local _bCheckMembers = false
local _tScanTimer
local _tAllUnits = {}
local _tTrackedUnits = {}
local _tMembers = {}
local _tHandlers = {
  UnitCreated = "UnitCreated",
  UnitDestroyed = "UnitDestroyed",
  UnitEnteredCombat = "UnitEnteredCombat",
  ChatMessage = "ChatMessage",
}

------------------------------------------------------------------------------
-- Fast and local functions.
------------------------------------------------------------------------------
local function Add2Logs(sText, ...)
  if CombatInterface.tLogger then
    CombatInterface.tLogger:Add(sText, ...)
  end
end

local function ManagerCall(sMethod, ...)
  -- Trace all call to upper layer for debugging purpose.
  Add2Logs(sMethod, ...)
  -- Retrieve callback function.
  fMethod = _tCombatManager[sMethod]
  -- Protected call.
  local s, sErrMsg = pcall(fMethod, _tCombatManager, ...)
  if not s then
    --@alpha@
    Print(sMethod .. ": " .. sErrMsg)
    --@end-alpha@
    Add2Logs("ERROR", nil, sErrMsg)
  end
end

local function GetAllBuffs(tUnit)
  local r = {}
  if tUnit then
    local tAllBuffs = tUnit:GetBuffs()
    if tAllBuffs then
      for sType, tBuffs in next, tAllBuffs do
        r[sType] = {}
        for _,obj in next, tBuffs do
          local nSpellId = obj.splEffect:GetId()
          if nSpellId and not SPELLID_BLACKLISTED[nSpellId] then
            r[sType][obj.idBuff] = {
              nCount = obj.nCount,
              nSpellId = nSpellId,
              --nTimeRemaining = obj.fTimeRemaining,
            }
          end
        end
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
    _tAllUnits[nId] = true
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
  ManagerCall("StopEncounter")
  _tTrackedUnits = {}
  _tAllUnits = {}
  _tMembers = {}
  DruseraBossMods:NextLogBuffer()
end

local function ProcessAllBuffs(tMyUnit)
  local tAllBuffs = GetAllBuffs(tMyUnit.tUnit)
  local bProcessDebuffs = tMyUnit.bIsACharacter
  local bProcessBuffs = not bProcessDebuffs
  local nId = tMyUnit.nId

  local tNewDebuffs = tAllBuffs["arHarmful"]
  local tDebuffs = tMyUnit.tDebuffs
  if bProcessDebuffs and tNewDebuffs then
    for nIdBuff,current in next, tDebuffs do
      if tNewDebuffs[nIdBuff] then
        local tNew = tNewDebuffs[nIdBuff]
        if tNew.nCount ~= current.nCount then
          tDebuffs[nIdBuff].nCount = tNew.nCount
          --tDebuffs[nIdBuff].nTimeRemaining = tNew.nTimeRemaining
          ManagerCall("DebuffUpdate", nId, current.nSpellId, current.nCount, tNew.nCount)
        end
        -- Remove this entry for second loop.
        tNewDebuffs[nIdBuff] = nil
      else
        tDebuffs[nIdBuff] = nil
        ManagerCall("DebuffRemove", nId, current.nSpellId)
      end
    end
    for nIdBuff,tNew in next, tNewDebuffs do
      tDebuffs[nIdBuff] = tNew
      ManagerCall("DebuffAdd", nId, tNew.nSpellId, tNew.nCount)
    end
  end

  local tNewBuffs = tAllBuffs["arBeneficial"]
  local tBuffs = tMyUnit.tBuffs
  if bProcessBuffs and tNewBuffs then
    for nIdBuff,current in next, tBuffs do
      if tNewBuffs[nIdBuff] then
        local tNew = tNewBuffs[nIdBuff]
        if tNew.nCount ~= current.nCount then
          tBuffs[nIdBuff].nCount = tNew.nCount
          --tBuffs[nIdBuff].nTimeRemaining = tNew.nTimeRemaining
          ManagerCall("BuffUpdate", nId, current.nSpellId, current.nCount, tNew.nCount)
        end
        -- Remove this entry for second loop.
        tNewBuffs[nIdBuff] = nil
      else
        tBuffs[nIdBuff] = nil
        ManagerCall("BuffRemove", nId, current.nSpellId)
      end
    end
    for nIdBuff, tNew in next, tNewBuffs do
      tBuffs[nIdBuff] = tNew
      ManagerCall("BuffAdd", nId, tNew.nSpellId, tNew.nCount)
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
      elseif _tMembers[sName].tUnit ~= tUnit then
        Add2Logs("Strange Member", tUnit:GetId())
        _tMembers[sName].tUnit = tUnit
      end
    else
      Add2Logs("Invalid tMemberData or tUnit ", nil, i)
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
-- Relations between DruseraBossMods and CombatInterface class.
------------------------------------------------------------------------------
function DruseraBossMods:CombatInterfaceInit(class, bTest)
  _tCombatManager = class
  _tTrackedUnits = {}
  _tAllUnits = {}
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
  CombatInterface.tLogger = self:NewLoggerNamespace(CombatInterface, "CombatInterface")
  return CombatInterface
end

function DruseraBossMods:CombatInterfaceUnInit()
  Activate(false)
  _tScanTimer = nil
  RemoveEventHandler(_tHandlers.UnitEnteredCombat, CombatInterface)
end

------------------------------------------------------------------------------
-- Combat Interface layer.
------------------------------------------------------------------------------
function CombatInterface:ActivateDetection(bState)
  Add2Logs("Activate Detection", nil, bState)
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

    if bIsValid and bIsInCombat or bOutOfRange then
      bEndOfCombat = false
    end
    if bIsValid then
      local f, err = pcall(ProcessAllBuffs, tMember)
      if not f then
        Print(err)
      end
    end
  end

  if _bCheckMembers then
    local tPlayerUnit = GetPlayerUnit()
    if bEndOfCombat == true then
      Add2Logs("No more member in combat")
      StopEncounter()
    elseif tPlayerUnit and tPlayerUnit:GetHealth() ~= 0 and not tPlayerUnit:IsInCombat() then
      Add2Logs("Player is again in life")
      StopEncounter()
    end
  end
  for nId, data in next, _tTrackedUnits do
    if data.tUnit:IsValid() then
      -- Process buff tracking.
      local f, err = pcall(ProcessAllBuffs, data)
      if not f then
        Print(err)
      end

      -- Process cast tracking.
      local bCasting = data.tUnit:IsCasting()
      local nCurrentTime
      local sCastName
      local nCastDuration
      local nCastElapsed
      local nCastEndTime
      if bCasting then
        nCurrentTime = GetGameTime()
        sCastName = data.tUnit:GetCastName()
        nCastDuration = data.tUnit:GetCastDuration()
        nCastElapsed = data.tUnit:GetCastElapsed()
        nCastEndTime = nCurrentTime + (nCastDuration - nCastElapsed) / 1000
        -- refresh needed if the function is called at the end of cast.
        -- Like that, previous data retrieved are valid.
        bCasting = data.tUnit:IsCasting()
      end
      if bCasting then
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
            ManagerCall("CastEnd", nId,
                        data.tCast.sCastName,
                        false,
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
            ManagerCall("CastEnd", nId,
                        data.tCast.sCastName,
                        false,
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
          local nThreshold = GetGameTime() + SCAN_PERIOD
          local bIsFailed
          if nThreshold < data.tCast.nCastEndTime then
            bIsInterrupted = true
          else
            bIsInterrupted = false
          end
          ManagerCall("CastEnd", nId, data.tCast.sCastName,
                      bIsInterrupted, data.tCast.nCastEndTime)
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
        Add2Logs("Player exiting combat in life", nId)
        StopEncounter()
      end
    end
  elseif tUnit:IsInYourGroup() then
    if bInCombat then
      ManagerCall("MemberEnteringCombat", nId, tUnit ,sName)
    elseif tUnit:GetHealth() == 0 then
      ManagerCall("MemberDead", nId, tUnit, sName)
    else
      ManagerCall("MemberLeftCombat", nId, tUnit, sName)
    end
  elseif _tTrackedUnits[nId] then
    if bInCombat then
      ManagerCall("UnitEnteringCombat", nId, tUnit ,sName)
    elseif tUnit:GetHealth() == 0 then
      ManagerCall("UnitDead", nId, tUnit, sName)
      UnTrackThisUnit(nId)
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
    if not _tAllUnits[nId] then
      _tAllUnits[nId] = true
      ManagerCall("OnUnitCreated", nId, tUnit, sName)
    end
  end
end

function CombatInterface:OnUnitDestroyed(tUnit)
  local nId = tUnit:GetId()
  if _tAllUnits[nId] then
    _tAllUnits[nId] = nil
    UnTrackThisUnit(nId)
    ManagerCall("OnUnitDestroyed", nId, tUnit, sName)
  end
end

function CombatInterface:UnTrackThisUnit(nId)
  UnTrackThisUnit(nId)
end

function CombatInterface:TrackThisUnit(nId)
  TrackThisUnit(nId)
end

function CombatInterface:ExtraLog2Text(sText, tExtraData, nRefTime)
  local sResult = ""
  if sText == "ERROR" then
    sResult = tExtraData[1]
  elseif sText == "DebuffAdd" or sText == "BuffAdd" then
    local nSpellId = tExtraData[1]
    local nStackCount = tExtraData[2]
    local sSpellName = GetSpell(nSpellId):GetName()
    sSpellName = string.gsub(sSpellName, NO_BREAK_SPACE, " ")
    local sFormat = "Name='%s' Id=%d StackCount=%d"
    sResult = string.format(sFormat, sSpellName, nSpellId, nStackCount)
  elseif sText == "DebuffRemove" or sText == "BuffRemove" then
    local nSpellId = tExtraData[1]
    local sSpellName = GetSpell(nSpellId):GetName()
    sSpellName = string.gsub(sSpellName, NO_BREAK_SPACE, " ")
    local sFormat = "Name='%s' Id=%d"
    sResult = string.format(sFormat, sSpellName, nSpellId)
  elseif sText == "DebuffUpdate" or sText == "BuffUpdate" then
    local nSpellId = tExtraData[1]
    local nOldStackCount = tExtraData[2]
    local nNewStackCount = tExtraData[3]
    local sSpellName = GetSpell(nSpellId):GetName()
    sSpellName = string.gsub(sSpellName, NO_BREAK_SPACE, " ")
    local sFormat = "Name='%s' Id=%d OldStack=%d NewStack=%d"
    sResult = string.format(sFormat, sSpellName, nSpellId, nOldStackCount, nNewStackCount)
  elseif sText == "CastStart" then
    local sCastName = tExtraData[1]
    local nCastEndTime = tExtraData[2] - nRefTime
    local sFormat = "CastName='%s' CastEndTime=%.3f"
    sResult = string.format(sFormat, sCastName, nCastEndTime)
  elseif sText == "CastEnd" then
    local sCastName = tExtraData[1]
    local sIsInterrupted = tostring(tExtraData[2])
    local nCastEndTime = tExtraData[3] - nRefTime
    local sFormat = "CastName='%s' IsInterrupted=%s CastEndTime=%.3f"
    sResult = string.format(sFormat, sCastName, sIsInterrupted, nCastEndTime)
  elseif sText == "NPCSay" or sText == "Datachron" then
    sResult = tExtraData[1]
  elseif sText == "Activate Detection" then
    sResult = tostring(tExtraData[1])
  end
  return sResult
end
