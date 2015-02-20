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
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local UPDATE_HUD_FREQUENCY = 10 -- in Hertz.

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local tFoesUnits = {}
local nSpellCastAlert_cnt = 0
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
  if tFoesUnits[id] then
    DruseraBossMods:HUDRemoveHealthBar(id)
    DruseraBossMods:HUDRemoveTimerBars(id)
    tFoesUnits[id] = nil
  end
  if bEncounterInProgress and next(tFoesUnits) == nil then
    Add2FightHistory("No more foes", nil, nil, nil)
    DruseraBossMods:ManagerStop()
  end
end

local function AddHealthBar(id)
  if bEncounterInProgress and tFoesUnits[id] then
    DruseraBossMods:HUDCreateHealthBar({
      sLabel = tFoesUnits[id].DisplayName,
      tUnit = tFoesUnits[id].tUnit,
      nId = id,
    }, nil)
  end
end

local function AddFoeUnit(tUnit)
  local id = tUnit:GetId()
  if not tFoesUnits[id] then
    local name = tUnit:GetName()
    if DataBase[name] then
      tFoesUnits[id] = setmetatable({
        tUnit = tUnit,
        sName = name,
        nId = id,
        tSpellCastStartAlerts = {},
        tSpellCastFailedAlerts = {},
        tSpellCastSuccessAlerts = {},
        bInCombat = tUnit:IsInCombat(),
      }, {__index = DataBase[name]})
      Add2FightHistory("Add foe unit", id, name, nil)
    end
  end
  AddHealthBar(id)
end

local function SetCastAlert(CastType, tFoeUnit, strKey, fCallback)
  local sSpellName = Locale[strKey]
  local bRegistered = tFoeUnit[CastType][sSpellName] ~= nil

  tFoeUnit[CastType][sSpellName] = fCallback

  local old = nSpellCastAlert_cnt
  if not bRegistered and fCallback then
    nSpellCastAlert_cnt = nSpellCastAlert_cnt + 1
  elseif bRegistered and not fCallback then
    nSpellCastAlert_cnt = nSpellCastAlert_cnt - 1
  end

  if old == 0 and nSpellCastAlert_cnt > 0 then
    DruseraBossMods:SetFilterSpell(true)
  elseif nSpellCastAlert_cnt == 0 and old > 0 then
    DruseraBossMods:SetFilterSpell(false)
  end
end

------------------------------------------------------------------------------
-- Manager Initialization.
------------------------------------------------------------------------------
function DruseraBossMods:ManagerInit()
  -- Copy the database to improve performance.
  DataBase = self.DataBase
  -- Configure filters
  local FoesWanted = {}
  for name,tInfo in next, DataBase do
    FoesWanted[name] = tInfo.bEnable
  end
  DruseraBossMods:SetFilterUnit(FoesWanted)
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

function DruseraBossMods:OnCreated(tUnit)
  if not tUnit:IsACharacter() then
    AddFoeUnit(tUnit)
  end
end

function DruseraBossMods:OnDestroyed(tUnit)
  local id = tUnit:GetId()
  Add2FightHistory("Unit is destroyed", id, tUnit:GetName(), nil)
  RemoveFoeUnit(id)
end

function DruseraBossMods:OnUnitNotValid(nId)
  local FoeUnit = tFoesUnits[nId]
  if FoeUnit then
    Add2FightHistory("Unit is not valid", id, FoeUnit.sName, nil)
    RemoveFoeUnit(nId)
  end
end

function DruseraBossMods:OnInCombat(tUnit)
  local id = tUnit:GetId()
  if id == GameLib:GetPlayerUnit():GetId() then
    self:ManagerStart()
  elseif not tUnit:IsACharacter() then
    AddFoeUnit(tUnit)
    tFoesUnits[id].bInCombat = true
    if bEncounterInProgress then
      FoesStartCombat(id)
    end
  end
end

function DruseraBossMods:OnOutCombat(tUnit)
  local id = tUnit:GetId()
  if id == GameLib:GetPlayerUnit():GetId() then
    if bEncounterInProgress then
      Add2FightHistory("Player is out of combat", nil, nil, nil)
      self:ManagerStop()
    end
  elseif tFoesUnits[id] then
    tFoesUnits[id].bInCombat = false
    Add2FightHistory("Unit is out of combat", id, tFoesUnits[id].sName, nil)
    self:HUDRemoveHealthBar(id)
  end
end

function DruseraBossMods:OnDied(tUnit)
  local id = tUnit:GetId()
  if id == GameLib:GetPlayerUnit():GetId() then
    -- Don't stop the encounter on the player death.
    -- That could be the raid leader.
    Add2FightHistory("Player is dead", nil, nil, nil)
  else
    local name = tUnit:GetName()
    Add2FightHistory("Unit is dead", id, name, nil)
    RemoveFoeUnit(id)
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

function DruseraBossMods:OnSpellAuraAppliedDose(UnitId, BuffId, StackCount)
  Add2FightHistory("Spell aura applied dose ignored", nil, nil, nil)
end

function DruseraBossMods:OnSpellAuraRemovedDose(UnitId, BuffId, StackCount)
  Add2FightHistory("Spell aura removed dose ignored", nil, nil, nil)
end

function DruseraBossMods:OnSpellAuraApplied(UnitId, BuffId, StackCount)
  Add2FightHistory("Spell aura applied ignored", nil, nil, nil)
end

function DruseraBossMods:OnSpellAuraRemoved(UnitId, BuffId)
  Add2FightHistory("Spell aura removes ignored", nil, nil, nil)
end

----------------------------------------------------------------------------
-- Start / Stop functions.
----------------------------------------------------------------------------
function DruseraBossMods:ManagerStart()
  if not bEncounterInProgress then
    bEncounterInProgress = true
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
    Add2FightHistory("Stop encounter", nil, nil, nil)
    for id, FoeUnit in next, tFoesUnits do
      RemoveFoeUnit(id)
    end
    self:SetFilterSpell(false)
    self:SetFilterDatachron(false)
    self:SetFilterNPCSay(false)
    nSpellCastAlert_cnt = 0
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
  local WasEnable = next(tDatachronAlerts) ~= nil
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
  local IsEnable = next(tDatachronAlerts) ~= nil
  if WasEnable and not IsEnable then
    self:SetFilterDatachron(false)
  elseif not WasEnable and IsEnable then
    self:SetFilterDatachron(true)
  end
end

function DruseraBossMods:SetNPCSayAlert(tFoeUnit, strKey, fCallback)
  local msg = Locale[strKey]
  local state = fCallback and true or false
  local WasEnable = next(tNPCSayAlerts) ~= nil
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
  local IsEnable = next(tNPCSayAlerts) ~= nil
  if WasEnable and not IsEnable then
    self:SetFilterNPCSay(false)
  elseif not WasEnable and IsEnable then
    self:SetFilterNPCSay(true)
  end
end
