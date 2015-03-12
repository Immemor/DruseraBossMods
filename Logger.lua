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
-- Copy of few objects to reduce the cpu load.
-- Because all local objects are faster.
------------------------------------------------------------------------------
local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local next = next
local GetGameTime = GameLib.GetGameTime
local GetUnitById = GameLib.GetUnitById

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local NO_BREAK_SPACE = string.char(194, 160)
local LOG_BUFFER_MAX = 2
-- Description of an entry log.
local LOG_ENTRY__TIME = 1
local LOG_ENTRY__TEXT = 2
local LOG_ENTRY__ID = 3
local LOG_ENTRY__NAME = 4
local LOG_ENTRY__ISVALID = 5
local LOG_ENTRY__EXTRAINFO = 6

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local _tAllLogger = {}
local _nBufferIdx = 1

------------------------------------------------------------------------------
-- Logger class.
------------------------------------------------------------------------------
local Logger = {}

function Logger:New(tModule, sNamespace)
  local tClass = {
    tModule = tModule,
    sNamespace = sNamespace,
  }
  setmetatable(tClass, self)
  self.__index = self
  table.insert(_tAllLogger, tClass)

  -- Initialize the array of Logs (don't use 'self')
  tClass._tBuffers = {}
  for i = 1, LOG_BUFFER_MAX do
    tClass._tBuffers[i] = {}
  end
  return tClass
end

function Logger:ResetCurrentBuffer()
  self._tBuffers[_nBufferIdx] = {}
end

function Logger:Add(sText, ...)
  --@alpha@
  if LOG_BUFFER_MAX > 0 then
    local nId = nil
    local sName = nil
    local bIsValid = nil

    local tExtraInfo = {}
    local args = select("#", ...)
    if args > 0 then
      nId = select(1, ...)
      if args > 1 then
        tExtraInfo = { select(2, ...) }
      end
    end
    if type(nId) == "number" then
      local tUnit = GetUnitById(nId)
      if tUnit then
        sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")
        bIsValid = tUnit:IsValid()
      end
    else
      nId = nil
      sName = ""
    end
    -- Add an entry in current buffer.
    table.insert(self._tBuffers[_nBufferIdx], {
      [LOG_ENTRY__TIME] = GetGameTime(),
      [LOG_ENTRY__TEXT] = sText,
      [LOG_ENTRY__ID] = nId,
      [LOG_ENTRY__NAME] = sName,
      [LOG_ENTRY__ISVALID] = bIsValid,
      [LOG_ENTRY__EXTRAINFO] = tExtraInfo,
    })
  end
  --@end-alpha@
end

------------------------------------------------------------------------------
---- DruseraBossMods functions.
--------------------------------------------------------------------------------
function DBM:NewLoggerNamespace(tModule, sNamespace)
  return Logger:New(tModule, sNamespace)
end

function DBM:NextLogBuffer()
  if LOG_BUFFER_MAX > 0 then
    -- Increase current index.
    _nBufferIdx = _nBufferIdx + 1
    -- Variable must be between 1 to MAX.
    if _nBufferIdx > LOG_BUFFER_MAX then
      _nBufferIdx = 1
    end
    -- Reset buffers pointed by current index.
    for _,tLogger in next, _tAllLogger do
      tLogger:ResetCurrentBuffer()
    end
  end
end

function DBM:GetLastBufferIndex()
  if LOG_BUFFER_MAX > 0 then
    local prev = _nBufferIdx - 1
    if prev == 0 then
      return LOG_BUFFER_MAX
    else
      return prev
    end
  end
  return 0
end

function DBM:GetLoggerByNamespace(sNamespace)
  for _, tLogger in next,_tAllLogger do
    if tLogger.sNamespace == sNamespace then
      return tLogger
    end
  end
  return nil
end

function DBM:GetLog2Grid(nStartTime, tModule, tBuffer)
  local tGrid = {}
  for _,tEntry in next, tBuffer do
    local sDiffTime = string.format("%.3f", tEntry[LOG_ENTRY__TIME] - nStartTime)
    local sText = tEntry[LOG_ENTRY__TEXT]
    local sId = tEntry[LOG_ENTRY__ID] or ""
    local sExtraInfo = ""
    if tModule.ExtraLog2Text then
      sExtraInfo = tModule:ExtraLog2Text(sText, tEntry[LOG_ENTRY__EXTRAINFO], nStartTime) or ""
    end
    local sName = ""
    if tEntry[LOG_ENTRY__NAME] then
      sName = tEntry[LOG_ENTRY__NAME] or ""
    elseif tEntry[LOG_ENTRY__ISVALID] then
      sName = "(invalid)"
    end
    table.insert(tGrid, {sDiffTime, sText, sName, sId, sExtraInfo})
  end
  return tGrid
end
