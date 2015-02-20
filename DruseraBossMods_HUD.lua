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
-- Constants.
------------------------------------------------------------------------------
local DruseraBossMods = Apollo.GetAddon("DruseraBossMods")
local next = next
local GetGameTime = GameLib.GetGameTime
local HUD_UPDATE_PERIOD = 0.1

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local _TimerBars = {}
local _HealthBars = {}
local bTimerRunning = false
local bLock = true
local wndTimersContainer = nil
local wndHealthContainer = nil

------------------------------------------------------------------------------
-- Local functions.
------------------------------------------------------------------------------
local function SortContentByTime(a, b)
  return a:GetData() < b:GetData()
end

local function HUDUpdateHealthBar(nId)
  local HealthBar = _HealthBars[nId]
  if HealthBar then
    if HealthBar.tUnit:IsValid() then
      local MaxHealth = HealthBar.tUnit:GetMaxHealth()
      local Health = HealthBar.tUnit:GetHealth()
      local Pourcent = 100 * Health / MaxHealth
      -- Update ProgressBar.
      HealthBar.wndProgressBar:SetMax(MaxHealth)
      HealthBar.wndProgressBar:SetProgress(Health)
      -- Update the Pourcent text.
      HealthBar.wndPercent:SetText(string.format("%.1f%%", 100 * Health / MaxHealth))
      -- Update the ShortHealth text.
      Health = string.format("%.1fk", Health / 1000)
      MaxHealth = string.format("%.1fk", MaxHealth / 1000)
      HealthBar.wndShortHealth:SetText(Health .. "/" .. MaxHealth)
    else
      DruseraBossMods:OnUnitNotValid(nId)
    end
  end
end

------------------------------------------------------------------------------
-- Public functions.
------------------------------------------------------------------------------
function DruseraBossMods:HUDInit()
  -- Create containers
  wndTimersContainer = Apollo.LoadForm(self.xmlDoc, "TimerContainer", nil, self)
  wndHealthContainer = Apollo.LoadForm(self.xmlDoc, "HealthContainer", nil, self)

  _UpdateHUDTimer = ApolloTimer.Create(HUD_UPDATE_PERIOD, true,
                                       "OnHUDProcess", self)
  _UpdateHUDTimer:Stop()
  bTimerRunning = false
end

function DruseraBossMods:HUDCreateHealthBar(tHealth, tOptions)
  if not _HealthBars[tHealth.nId] and tHealth.tUnit:IsValid() then
    local tUnit = tHealth.tUnit
    local wndParent = wndHealthContainer
    local wndFrame = Apollo.LoadForm(self.xmlDoc, "HealthTemplate", wndParent, self)
    HealthBar = {
      sLabel = tHealth.sLabel,
      tUnit = tUnit,
      nId = tHealth.nId,
      -- Windows objects.
      wndParent = wndParent,
      wndFrame = wndFrame,
      wndLabel = wndFrame:FindChild("Label"),
      wndPercent = wndFrame:FindChild("Percent"),
      wndShortHealth = wndFrame:FindChild("ShortHealth"),
      wndProgressBar = wndFrame:FindChild("ProgressBar"),
    }
    local MaxHealth = tUnit:GetMaxHealth()
    local Health = tUnit:GetHealth()

    _HealthBars[tHealth.nId] = HealthBar
    HealthBar.wndFrame:SetData(GetGameTime())
    HealthBar.wndLabel:SetText(tHealth.sLabel)
    HUDUpdateHealthBar(nId)
    wndParent:ArrangeChildrenVert(
      Window.CodeEnumArrangeOrigin.LeftOrTop,
      SortContentByTime)
    if not bTimerRunning then
      _UpdateHUDTimer:Start()
      bTimerRunning = true
    end
  end
end

function DruseraBossMods:HUDRemoveHealthBar(nId)
  assert(nId)
  if _HealthBars[nId] then
    _HealthBars[nId].wndFrame:Destroy()
    _HealthBars[nId].wndParent:ArrangeChildrenVert(
      Window.CodeEnumArrangeOrigin.LeftOrTop,
      SortContentByTime)
    _HealthBars[nId] = nil
  end
end

function DruseraBossMods:HUDCreateTimerBar(tTimer, tOptions)
  assert (tTimer)
  assert (tTimer.sLabel)
  assert (tTimer.nDuration)
  local nElapsed = tTimer.Elapsed or 0
  local nDuration = tTimer.nDuration
  local nCurrentTime = GetGameTime()
  local nEndTime = nCurrentTime - nElapsed + nDuration
  local sLabel = tTimer.sLabel

  self:HUDRemoveTimerBar(sLabel)
  -- If the nDuration is 0, the timer is destroyed.
  if nEndTime > nCurrentTime then
    local nRemaining = nEndTime - nCurrentTime
    local wndParent = wndTimersContainer
    local wndFrame = Apollo.LoadForm(self.xmlDoc, "TimerTemplate", wndParent, self)
    local TimerBar = {
      -- About timer itself.
      sLabel = sLabel,
      nDuration = tTimer.nDuration,
      nEndTime = nEndTime,
      -- Data to return on time out.
      fCallback = tTimer.fCallback,
      nId = tTimer.nId,
      -- Windows objects.
      wndParent = wndParent,
      wndFrame = wndFrame,
      wndLabel = wndFrame:FindChild("Bar"):FindChild("Label"),
      wndTimeLeft = wndFrame:FindChild("Bar"):FindChild("TimeLeft"),
      wndProgressBar = wndFrame:FindChild("Bar"):FindChild("ProgressBar"),
    }
    _TimerBars[sLabel] = TimerBar
    TimerBar.wndFrame:SetData(nEndTime)
    TimerBar.wndProgressBar:SetMax(nDuration)
    TimerBar.wndProgressBar:SetProgress(nRemaining)
    TimerBar.wndLabel:SetText(sLabel)
    TimerBar.wndTimeLeft:SetText(string.format("%.1fs", nRemaining))
    if tOptions then
      if tOptions.color then
        TimerBar.wndProgressBar:SetBarColor(tOptions.color)
      end
    end
    wndParent:ArrangeChildrenVert(
      Window.CodeEnumArrangeOrigin.LeftOrTop,
      SortContentByTime)
    if not bTimerRunning then
      _UpdateHUDTimer:Start()
      bTimerRunning = true
    end
  end
end

function DruseraBossMods:HUDRemoveTimerBar(sLabel)
  assert(sLabel)
  if _TimerBars[sLabel] then
    _TimerBars[sLabel].wndFrame:Destroy()
    _TimerBars[sLabel].wndParent:ArrangeChildrenVert(
      Window.CodeEnumArrangeOrigin.LeftOrTop,
      SortContentByTime)
    _TimerBars[sLabel] = nil
  end
end

function DruseraBossMods:HUDRemoveTimerBars(nId)
  assert(nId)
  for i, TimerBar in next, _TimerBars do
    if TimerBar.nId == nId then
      self:HUDRemoveTimerBar(TimerBar.sLabel)
    end
  end
end

function DruseraBossMods:HUDRemoveAllTimerBar()
  for _,TimerBar in next, _TimerBars do
    self:HUDRemoveTimerBar(TimerBar.sLabel)
  end
end

function DruseraBossMods:OnHUDProcess()
  local Timeout = {}
  local nCurrentTime = GetGameTime()
  for i, TimerBar in next, _TimerBars do
    if nCurrentTime < TimerBar.nEndTime then
      local nRemaining = TimerBar.nEndTime - nCurrentTime
      TimerBar.wndProgressBar:SetProgress(nRemaining)
      TimerBar.wndTimeLeft:SetText(string.format("%.1fs", nRemaining))
    else
      if TimerBar.fCallback then
        table.insert(Timeout, {TimerBar.fCallback, TimerBar.nId})
      end
      self:HUDRemoveTimerBar(i)
    end
  end
  for i, HealthBar in next, _HealthBars do
    HUDUpdateHealthBar(HealthBar.nId)
  end
  -- Provide all timers with callback to CombatManager.
  if next(Timeout) ~= nil then
    self:OnTimerTimeout(Timeout)
  end
  -- Be careful, stop the timer only after callbacks.
  if next(_TimerBars) == nil and next(_HealthBars) == nil then
    _UpdateHUDTimer:Stop()
    bTimerRunning = false
  end
end

function DruseraBossMods:HUDToggleAnchorLock()
  local windows = {wndTimersContainer, wndHealthContainer}
  if bLock then
    bLock = false
    for _, wnd in next, windows do
      wnd:SetBGColor('b0606060')
      wnd:SetTextColor('ffffffff')
      wnd:SetStyle("Moveable", true);
      wnd:SetStyle("Sizable", true);
      wnd:SetStyle("IgnoreMouse", false);
    end
  else
    bLock = true
    for _, wnd in next, windows do
      wnd:SetBGColor('00000000')
      wnd:SetTextColor('00000000')
      wnd:SetStyle("Moveable", false);
      wnd:SetStyle("Sizable", false);
      wnd:SetStyle("IgnoreMouse", true);
    end
  end
end
