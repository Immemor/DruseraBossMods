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
require "GameLib"
require "ChatSystemLib"

------------------------------------------------------------------------------
-- Copy of few object to reduce the cpu load.
-- Because all local objects are faster.
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetAddon("DruseraBossMods")
local GetGameTime = GameLib.GetGameTime
local GetPlayerUnit = GameLib.GetPlayerUnit
local next = next

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local SCAN_PERIOD = 0.1 -- in seconds.
local CHANNEL_NPCSAY = ChatSystemLib.ChatChannel_NPCSay
local CHANNEL_DATACHRON = ChatSystemLib.ChatChannel_Datachron
local NO_BREAK_SPACE = string.char(194, 160)

------------------------------------------------------------------------------
-- Counters of tracking events.
------------------------------------------------------------------------------
local tTrackedUnits = {}
local tFilterUnit = {}

------------------------------------------------------------------------------
-- Local functions.
------------------------------------------------------------------------------
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

------------------------------------------------------------------------------
-- Handlers for Carbine interface.
-- This layer will do a first layer of interpretation and filtering.
------------------------------------------------------------------------------
function DruseraBossMods:OnEnteredCombat(tUnit, bInCombat)
  local nId = tUnit:GetId()
  local sUnitType = nil
  local sName = string.gsub(tUnit:GetName(), NO_BREAK_SPACE, " ")

  if nId == GetPlayerUnit():GetId() then
    sUnitType = "Player"
  elseif tFilterUnit[sName] then
    sUnitType = "Foe"
  elseif tUnit:IsInYourGroup() then
    -- Be careful, player is also in the group.
    sUnitType = "Friend"
  end

  if sUnitType then
    if bInCombat then
      if not tTrackedUnits[nId] then
        tTrackedUnits[nId] = {
          tUnit = tUnit,
          tBuffs = GetHalfBuffs(tUnit),
          tSpell = {
            bCasting = false,
            sSpellName = "",
            nCastEndTime = 0,
            bSuccess = false,
          },
        }
      end
    else
      tTrackedUnits[nId] = nil
    end

    if bInCombat then
      self:OnUnitInCombat(sUnitType, tUnit)
    elseif tUnit:GetHealth() == 0 then
      -- A unit can be out of combat, but not dead. Not yet...
      self:OnUnitDied(sUnitType, tUnit)
    else
      self:OnUnitOutCombat(sUnitType, tUnit)
    end
  end
end

function DruseraBossMods:OnChatMessage(tChannelCurrent, tMessage)
  local ChannelType = tChannelCurrent:GetType()
  local sMessage = tMessage.arMessageSegments[1].strText

  -- Sometimes Carbine have inserted some no-break-space, for fun.
  -- Behavior seen with french language.
  sMessage = string.gsub(sMessage, NO_BREAK_SPACE, " ")

  if CHANNEL_NPCSAY == ChannelType then
    self:OnNPCSay(sMessage)
  elseif CHANNEL_DATACHRON == ChannelType then
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
      self:OnInvalidUnit(nId)
    else
      -- Process buff tracking.
      local tOldBuffs = data.tBuffs
      data.tBuffs = GetHalfBuffs(data.tUnit)

      for i,tBuff in next, data.tBuffs do
        if tOldBuffs[i] then
          local old = tOldBuffs[i].nCount
          local new = tBuff.nCount

          if new ~= old then
            self:OnBuffUpdate(nId, tBuff)
          end
          tOldBuffs[i] = nil
        else
          self:OnBuffUpdate(nId, tBuff)
        end
      end
      for _,tBuff in next, tOldBuffs do
        tBuff.nCount = 0
        self:OnBuffUpdate(nId, tBuff)
      end
      -- Process spell_cast tracking.
      if not data.tUnit:IsACharacter() then
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
  tTrackedUnits = {}
  -- Don't reset tFilterUnit
  Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
  _ScanTimer = ApolloTimer.Create(SCAN_PERIOD, true, "OnUpdateTrackedUnits", self)
  _ScanTimer:Stop()
end

------------------------------------------------------------------------------
-- Set filter functions.
------------------------------------------------------------------------------
function DruseraBossMods:SetFilterUnit(list)
  -- Expected example : { "My Boss Name" = true, "Boss2" = false }
  tFilterUnit = list
end

function DruseraBossMods:StartCombatInterface()
  Apollo.RegisterEventHandler("ChatMessage","OnChatMessage", self)
  _ScanTimer:Start()
end

function DruseraBossMods:StopCombatInterface()
  _ScanTimer:Stop()
  Apollo.RemoveEventHandler("ChatMessage", self)
end
