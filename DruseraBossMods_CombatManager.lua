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
-- A lot of thing to says here.
--
------------------------------------------------------------------------------
require "Apollo"
require "ApolloTimer"
require "GameLib"

------------------------------------------------------------------------------
-- Copy of few object to reduce the cpu load.
-- Because all local objects are faster.
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetAddon("DruseraBossMods")
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local Locale = GeminiLocale:GetLocale("DruseraBossMods")
local DataBase = {} -- Copy will be done on init.
local next = next
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local UPDATE_HUD_FREQUENCY = 10 -- in Hertz.

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local tFoesUnits = {}
local bEncounterInProgress = false
local nFightStartTime = 0
local tNPCSayAlerts = {}
local tDatachronAlerts = {}
local tFightHistory = {}

------------------------------------------------------------------------------
-- Fast and local functions.
------------------------------------------------------------------------------
local function Add2FightHistory(sText, nId, sName, tExtraInfo)
  if not sName and nId then
    tUnit = GameLib.GetUnitById(nId)
    if tUnit then
      sName = tUnit:GetName()
    end
  end
  table.insert(tFightHistory, {sText, GetGameTime(), nId, sName, tExtraInfo})
end

local function FoesStartCombat(nId)
  if tFoesUnits[nId] then
    Add2FightHistory("Start combat", nId, tFoesUnits[nId].sName, nil)
    if tFoesUnits[nId].OnStartCombat then
      tFoesUnits[nId].OnStartCombat(tFoesUnits[nId])
    end
  end
end

local function RemoveFoeUnit(id)
  local FoeUnit = tFoesUnits[id]
  if FoeUnit then
    DruseraBossMods:HUDRemoveHealthBar(id)
    DruseraBossMods:HUDRemoveTimerBars(id)
    tFoesUnits[id] = nil
  end
  if bEncounterInProgress and next(tFoesUnits) == nil then
    Add2FightHistory("No more foes", nil, nil, nil)
    DruseraBossMods:ManagerStop()
  end
end

local function AddHealthBar(nId)
  DruseraBossMods:HUDCreateHealthBar({
    sLabel = tFoesUnits[nId].DisplayName,
    tUnit = tFoesUnits[nId].tUnit,
    nId = nId,
  }, nil)
end

local function SetCastAlert(CastType, tFoeUnit, strKey, fCallback)
  local sSpellName = Locale[strKey]
  local bRegistered = tFoeUnit[CastType][sSpellName] ~= nil

  tFoeUnit[CastType][sSpellName] = fCallback
end

------------------------------------------------------------------------------
-- Manager Initialization.
------------------------------------------------------------------------------
function DruseraBossMods:CombatManagerInit()
  -- Copy the database to improve performance.
  DataBase = self.DataBase
  -- Configure filters
  local FoesWanted = {}
  for name,tInfo in next, DataBase do
    FoesWanted[name] = tInfo.bEnable
  end
  self:SetFilterUnit(FoesWanted)
end

------------------------------------------------------------------------------
-- Handlers for CombatInterface.lua and timers.
------------------------------------------------------------------------------
function DruseraBossMods:OnTimerTimeout(tTimeOutBars)
  for _, obj in next, tTimeOutBars do
    local fCallback = obj[1]
    local nId = obj[2]
    if fCallback and nId then
      local FoeUnit = tFoesUnits[nId]
      if FoeUnit and FoeUnit.tUnit:IsValid() then
        fCallback(FoeUnit)
      end
    end
  end
end

function DruseraBossMods:OnUnitInCombat(sUnitType, tUnit)
  if sUnitType == "Player" then
    self:ManagerStart()
  elseif sUnitType == "Foe" then
    local nId = tUnit:GetId()
    local sName = tUnit:GetName()
    tFoesUnits[nId] = setmetatable({
      tUnit = tUnit,
      sName = sName,
      nId = nId,
      bInCombat = true,
      tSpellCastStartAlerts = {},
      tSpellCastFailedAlerts = {},
      tSpellCastSuccessAlerts = {},
      tBuffAlerts = {},
    }, {__index = DataBase[sName]})
    Add2FightHistory("Add foe unit", nId, sName, nil)
    if bEncounterInProgress then
      AddHealthBar(nId)
      FoesStartCombat(nId)
    end
  end
end

function DruseraBossMods:OnUnitOutCombat(sUnitType, tUnit)
  if sUnitType == "Player" then
    if bEncounterInProgress then
      Add2FightHistory("Player is out of combat", nil, nil, nil)
      self:ManagerStop()
    end
  elseif sUnitType == "Foe" then
    local id = tUnit:GetId()
    local FoeUnit = tFoesUnits[id]
    if FoeUnit then
      Add2FightHistory("Unit is out of combat", id, FoeUnit.sName, nil)
      RemoveFoeUnit(id)
    end
  end
end

function DruseraBossMods:OnUnitDied(sUnitType, tUnit)
  if sUnitType == "Player" then
    -- Don't stop the encounter on the player death.
    -- That could be the raid leader.
    Add2FightHistory("Player is dead", nil, nil, nil)
  elseif sUnitType == "Foe" then
    local id = tUnit:GetId()
    Add2FightHistory("Foe is dead", id, nil, nil)
    RemoveFoeUnit(id)
  end
end

function DruseraBossMods:OnInvalidUnit(nId)
  if tFoesUnits[nId] then
    Add2FightHistory("Invalid foe unit", nId, nil, nil)
    RemoveFoeUnit(nId)
  end
end

function DruseraBossMods:OnSpellCastStart(sSpellName, id)
  if tFoesUnits[id] then
    local callback = tFoesUnits[id].tSpellCastStartAlerts[sSpellName]
    if callback then
      callback(tFoesUnits[id])
    end
    Add2FightHistory("Spell cast start", id, tFoesUnits[id].sName, {
      sSpellName,
      callback and true or false,
      tFoesUnits[id].tUnit:GetCastDuration(),
      tFoesUnits[id].tUnit:GetCastElapsed(),
      tFoesUnits[id].tUnit:GetCastTotalPercent(),
    })
  end
end

function DruseraBossMods:OnSpellCastFailed(sSpellName, id)
  if tFoesUnits[id] then
    local callback = tFoesUnits[id].tSpellCastFailedAlerts[sSpellName]
    if callback then
      callback(tFoesUnits[id])
    end
    Add2FightHistory("Spell cast failed", id, tFoesUnits[id].sName, {
      sSpellName,
      callback and true or false,
      tFoesUnits[id].tUnit:GetCastDuration(),
      tFoesUnits[id].tUnit:GetCastElapsed(),
      tFoesUnits[id].tUnit:GetCastTotalPercent(),
    })
  end
end

function DruseraBossMods:OnSpellCastSuccess(sSpellName, id)
  if tFoesUnits[id] then
    local callback = tFoesUnits[id].tSpellCastSuccessAlerts[sSpellName]
    if callback then
      callback(tFoesUnits[id])
    end
    Add2FightHistory("Spell cast success", id, tFoesUnits[id].sName, {
      sSpellName,
      callback and true or false,
      tFoesUnits[id].tUnit:GetCastDuration(),
      tFoesUnits[id].tUnit:GetCastElapsed(),
      tFoesUnits[id].tUnit:GetCastTotalPercent(),
    })
  end
end

function DruseraBossMods:OnNPCSay(sMessage)
  local callbacks = tNPCSayAlerts[sMessage]
  if callbacks then
    Add2FightHistory("NPCSay processed", nil, nil, sMessage)
    for nId, callback in next, callbacks do
      if tFoesUnits[nId] then
        callback(tFoesUnits[nId])
      else
        -- Auto clean.
        tNPCSayAlerts[sMessage][nId] = nil
        if next(tNPCSayAlerts[sMessage]) == nil then
          tNPCSayAlerts[sMessage] = nil
        end
      end
    end
  else
    Add2FightHistory("NPCSay, no callbacks", nil, nil, sMessage)
  end
end

function DruseraBossMods:OnDatachron(sMessage)
  local callbacks = tDatachronAlerts[sMessage]
  if callbacks then
    Add2FightHistory("Datachron processed", nil, nil, sMessage)
    for nId, callback in next, callbacks do
      if tFoesUnits[nId] then
        callback(tFoesUnits[nId])
      else
        -- Auto clean.
        tDatachronAlerts[sMessage][nId] = nil
        if next(tDatachronAlerts[sMessage]) == nil then
          tDatachronAlerts[sMessage] = nil
        end
      end
    end
  else
    Add2FightHistory("Datachron, no callbacks", nil, nil, sMessage)
  end
end

function DruseraBossMods:OnBuffUpdate(nTargetId, tBuff)
  Add2FightHistory("Buff update", nTargetId, nil, {nTargetId, tBuff})
  local nSpellId = tBuff.splEffect:GetId()
  for _,tFoeUnit in next, tFoesUnits do
    local callback = tFoeUnit.tBuffAlerts[nSpellId]
    if callback then
      callback(tFoeUnit)
    end
  end
end

----------------------------------------------------------------------------
-- Start / Stop functions.
----------------------------------------------------------------------------
function DruseraBossMods:ManagerStart()
  if not bEncounterInProgress then
    bEncounterInProgress = true
    self:StartCombatInterface()
    nFightStartTime = GetGameTime()
    Add2FightHistory("Start encounter", nil, nil, nFightStartTime)

    for id, FoeUnit in next, tFoesUnits do
      if FoeUnit.tUnit:IsValid() then
        AddHealthBar(id)
        if FoeUnit.bInCombat then
          FoesStartCombat(FoeUnit.nId)
        end
      else
        Add2FightHistory("On start, unit is not valid", id, FoeUnit.sName, nil)
        RemoveFoeUnit(id)
      end
    end
  end
end

function DruseraBossMods:ManagerStop()
  if bEncounterInProgress then
    bEncounterInProgress = false
    self:StopCombatInterface()
    Add2FightHistory("Stop encounter", nil, nil, nil)
    for id, FoeUnit in next, tFoesUnits do
      RemoveFoeUnit(id)
    end
    tNPCSayAlerts = {}
    tDatachronAlerts = {}
    self:SaveFightHistory(tFightHistory)
    tFightHistory = {}
  end
end

------------------------------------------------------------------------------
-- Service functions available in encounter.
------------------------------------------------------------------------------
function DruseraBossMods:ClearAllTimerAlert()
  self:HUDRemoveAllTimerBar()
end

function DruseraBossMods:SetTimerAlert(FoeUnit, strKey, duration, fCallback)
  local sLabel = Locale[strKey]
  local tOptions = FoeUnit.BarsCustom and FoeUnit.BarsCustom[sLabel] or nil
  self:HUDCreateTimerBar({
    sLabel = sLabel,
    nDuration = duration,
    fCallback = fCallback,
    nId = FoeUnit.nId,
  }, tOptions)
end

function DruseraBossMods:SetCastStartAlert(tFoeUnit, strKey, fCallback)
  SetCastAlert("tSpellCastStartAlerts", tFoeUnit, strKey, fCallback)
end

function DruseraBossMods:SetCastFailedAlert(tFoeUnit, strKey, fCallback)
  SetCastAlert("tSpellCastFailedAlerts", tFoeUnit, strKey, fCallback)
end

function DruseraBossMods:SetCastSuccessAlert(tFoeUnit, strKey, fCallback)
  SetCastAlert("tSpellCastSuccessAlerts", tFoeUnit, strKey, fCallback)
end

function DruseraBossMods:SetDatachronAlert(tFoeUnit, strKey, fCallback)
  local msg = Locale[strKey]
  local state = fCallback and true or false
  if state then
    if not tDatachronAlerts[msg] then
      tDatachronAlerts[msg] = {}
    end
    tDatachronAlerts[msg][tFoeUnit.nId] = fCallback
  elseif tDatachronAlerts[msg] then
    tDatachronAlerts[msg][tFoeUnit.nId] = nil
    if next(tDatachronAlerts[msg]) == nil then
      tDatachronAlerts[msg] = nil
    end
  end
end

function DruseraBossMods:SetNPCSayAlert(tFoeUnit, strKey, fCallback)
  local msg = Locale[strKey]
  local state = fCallback and true or false
  if state then
    if not tNPCSayAlerts[msg] then
      tNPCSayAlerts[msg] = {}
    end
    tNPCSayAlerts[msg][tFoeUnit.nId] = fCallback
  elseif tNPCSayAlerts[msg] then
    tNPCSayAlerts[msg][tFoeUnit.nId] = nil
    if next(tNPCSayAlerts[msg]) == nil then
      tNPCSayAlerts[msg] = nil
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
