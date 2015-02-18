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
-- This file was inspired from "LibCombatLogFixes-1.0".
-- I don't take it, because there is some details which I would change, like:
--  - How is process the "SpellCast...",
--  - Add filters on tUnit to track, Datachron, etc...
--  - Control the scan with a timer, instead of the 'VarChange_FrameCount'
--
------------------------------------------------------------------------------
require "Apollo"
require "ChatSystemLib"

------------------------------------------------------------------------------
-- Copy of few object to reduce the cpu load.
-- Because all local objects are faster.
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetAddon("DruseraBossMods")
local GetGameTime = GameLib.GetGameTime
local next = next

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local SCAN_PERIOD = 0.1 -- in seconds.

------------------------------------------------------------------------------
-- Counters of tracking events.
------------------------------------------------------------------------------
local tTrackedUnits = {}
local tFilterUnit = {}
local bFilterBuff = false
local bFilterSpell = false
local bFilterNPCSay = false
local bFilterDatachron = false

local bChatMessageEnable = false
local bScanEnable = false

------------------------------------------------------------------------------
-- Local functions.
------------------------------------------------------------------------------
local function convertBuffs(tBuffs)
  local tBuffsOut = {}
  for _, buffType in next, tBuffs do
    for _, buff in next, buffType do
      tBuffsOut[buff.splEffect:GetId()] = buff.nCount
    end
  end
  return tBuffsOut
end

local function UpdateChatEventRegistering(self)
  if bFilterNPCSay or bFilterDatachron then
    if not bChatMessageEnable then
      Apollo.RegisterEventHandler("ChatMessage","OnChatMessage", self)
      bChatMessageEnable = true
    end
  elseif bChatMessageEnable then
      Apollo.RemoveEventHandler("ChatMessage", self)
      bChatMessageEnable = false
  end
end

local function UpdateSpellAndBuffRegistering(self)
  if bFilterSpell or bFilterBuff then
    if not bScanEnable then
      _ScanTimer:Start()
      bScanEnable = true
    end
  elseif bScanEnable then
      _ScanTimer:Stop()
      bScanEnable = false
  end
end

------------------------------------------------------------------------------
-- Handlers for Carbine interface.
-- This layer will do a first layer of interpretation and filtering.
------------------------------------------------------------------------------
function DruseraBossMods:OnUnitCreated(tUnit)
  local nId = tUnit:GetId()
  if not tTrackedUnits[nId] and tFilterUnit[tUnit:GetName()] then
    tTrackedUnits[nId] = {
      tUnit = tUnit,
      buffs = convertBuffs(tUnit:GetBuffs()),
      tSpell = {
        bCasting = false,
        sSpellName = "",
        nCastEndTime = 0,
        bSuccess = false,
      }
    }
    self:OnCreated(tUnit)
  end
end

function DruseraBossMods:OnUnitDestroyed(tUnit)
  local nId = tUnit:GetId()
  if tTrackedUnits[nId] then
    tTrackedUnits[nId] = nil
    self:OnDestroyed(tUnit)
  end
end

function DruseraBossMods:OnEnteredCombat(tUnit, bInCombat)
  if tFilterUnit[tUnit:GetName()] then
    local nId = tUnit:GetId()
    if bInCombat then
      local name = tUnit:GetName()
      if not tTrackedUnits[nId] then
        tTrackedUnits[nId] = {
          tUnit = tUnit,
          buffs = convertBuffs(tUnit:GetBuffs()),
          tSpell = {
            bCasting = false,
            sSpellName = "",
            nCastEndTime = 0,
            bSuccess = false,
          }
        }
      end
      self:OnInCombat(tUnit)
    else
      tTrackedUnits[nId] = nil
      if tUnit:GetHealth() == 0 then
        -- A unit can be out of combat, but not dead. Not yet...
        self:OnDied(tUnit)
      else
        self:OnOutCombat(tUnit)
      end
    end
  end
end

function DruseraBossMods:OnChatMessage(tChannelCurrent, tMessage)
  local ChannelType = tChannelCurrent:GetType()

  if bFilterNPCSay and ChatSystemLib.ChatChannel_NPCSay == ChannelType then
    local sMessage = tMessage.arMessageSegments[1].strText
    self:OnNPCSay(sMessage)
  elseif bFilterDatachron and ChatSystemLib.ChatChannel_Datachron == ChannelType then
    local sMessage = tMessage.arMessageSegments[1].strText
    self:OnDatachron(sMessage)
  end
end

function DruseraBossMods:OnUpdateTrackedUnits()
  for nId, data in next, tTrackedUnits do
    -- Clear units that:
    -- * Were destroyed w/o leaving combat.
    -- * We went out of range.
    if not data.tUnit:IsValid() then
      tTrackedUnits[nId] = nil
    else
      -- Process aura tracking.
      if bFilterBuff then
        local oldBuffs = data.buffs
        data.buffs = convertBuffs(data.unit:GetBuffs())

        for buffId, stackCount in next, data.buffs do
          local oldStackCount = oldBuffs[buffId]
          if oldStackCount then
            if stackCount == oldStackCount then
              oldBuffs[buffId] = nil
            elseif stackCount > oldStackCount then
              self:OnSpellAppliedDose(id, buffId, stackCount)
            else
              self:OnSpellRemovedDose(id, buffId, stackCount)
            end
          else
            self:OnSpellAuraApplied(id, buffId, stackCount)
          end
        end

        for buffId, stackCount in next, oldBuffs do
          self:OnSpellAuraRemoved(id, buffId)
        end
      end
      -- Process spell_cast tracking.
      if bFilterSpell then
        local bCasting = data.tUnit:IsCasting()
        if bCasting then
          local sSpellName = data.tUnit:GetCastName()
          local nCastDuration = data.tUnit:GetCastDuration()
          local nCastElapsed = data.tUnit:GetCastElapsed()
          local nCastEndTime = GetGameTime() + (nCastDuration - nCastElapsed) / 1000
          if not data.tSpell.bCasting then
            -- New spell cast
            data.tSpell = {
              bCasting = true,
              sSpellName = sSpellName,
              nCastEndTime = nCastEndTime,
              bSuccess = false,
            }
            self:OnSpellCastStart(data.tSpell.sSpellName, nId)
          elseif data.tSpell.bCasting then
            if sSpellName ~= data.tSpell.sSpellName then
              -- New spell cast just after a previous one.
              self:OnSpellCastSuccess(data.tSpell.sSpellName, nId)
              data.tSpell = {
                bCasting = true,
                sSpellName = sSpellName,
                nCastEndTime = nCastEndTime,
                bSuccess = false,
              }
              self:OnSpellCastStart(data.tSpell.sSpellName, nId)
            elseif not data.tSpell.bSuccess and nCastElapsed >= nCastDuration then
              -- The spell have reached the end.
              self:OnSpellCastSuccess(data.tSpell.sSpellName, nId)
              data.tSpell = {
                bCasting = true,
                sSpellName = sSpellName,
                nCastEndTime = 0,
                bSuccess = true,
              }
            end
          end
        elseif data.tSpell.bCasting then
          if not data.tSpell.bSuccess then
            -- Let's compare with the nCastEndTime
            if GetGameTime() < data.tSpell.nCastEndTime then
              self:OnSpellCastFailed(data.tSpell.sSpellName, nId)
            else
              self:OnSpellCastSuccess(data.tSpell.sSpellName, nId)
            end
          end
          data.tSpell = {
            bCasting = false,
            sSpellName = "",
            nCastEndTime = 0,
            bSuccess = false,
          }
        end
      end
    end
  end
end

------------------------------------------------------------------------------
-- Functions to enable/disable this interface.
------------------------------------------------------------------------------

function DruseraBossMods:InterfaceInit()
  bFilterBuff = false
  bFilterSpell = false
  bFilterNPCSay = false
  bFilterDatachron = false
  tTrackedUnits = {}
  -- Don't reset tFilterUnit
  if false then
    Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
    Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
  end
  Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
  _ScanTimer = ApolloTimer.Create(SCAN_PERIOD, true, "OnUpdateTrackedUnits", self)
  _ScanTimer:Stop()
end

------------------------------------------------------------------------------
-- Set filter functions.
------------------------------------------------------------------------------

function DruseraBossMods:SetFilterUnit(list)
  -- Expected example : { "My Boss Name" = true, "My Friend" = false }
  -- Always add the player itself.
  list[GameLib:GetPlayerUnit():GetName()] = true
  tFilterUnit = list
end

function DruseraBossMods:SetFilterBuff(bEnable)
  bFilterBuff = bEnable
  UpdateSpellAndBuffRegistering(self)
end

function DruseraBossMods:SetFilterSpell(bEnable)
  bFilterSpell = bEnable
  UpdateSpellAndBuffRegistering(self)
end

function DruseraBossMods:SetFilterNPCSay(bEnable)
  bFilterNPCSay = bEnable
  UpdateChatEventRegistering(self)
end

function DruseraBossMods:SetFilterDatachron(bEnable)
  bFilterDatachron = bEnable
  UpdateChatEventRegistering(self)
end
