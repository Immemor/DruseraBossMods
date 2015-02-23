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
local GeminiLocale = Apollo.GetPackage("Gemini:Locale-1.0").tPackage
local Locale = GeminiLocale:GetLocale("DruseraBossMods")
local next = next
local GetGameTime = GameLib.GetGameTime
local HUD_UPDATE_PERIOD = 0.1
local THRESHOLD_HIGHLIGHT_TIMERS = 6.0
local DEFAULT_FADEOFF_MESSAGE = 6.0
local AUTOFADE_TIMING = 0.5

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local _TimerBars = {}
local _HealthBars = {}
local _MessagesBars = {}
local bTimerRunning = false
local bLock = true
local wnds = {}
_G['dd'] = wnds

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

      local nCastDuration = HealthBar.tUnit:GetCastDuration()
      local nCastElapsed = HealthBar.tUnit:GetCastElapsed()
      if HealthBar.tUnit:IsCasting() and nCastElapsed < nCastDuration then
        HealthBar.wndShortHealth:Show(false)
        HealthBar.wndCastBar:Show(true)
        HealthBar.wndProgressCastBar:SetProgress(nCastElapsed)
        HealthBar.wndProgressCastBar:SetMax(nCastDuration)
        HealthBar.wndLabelCastBar:SetText(HealthBar.tUnit:GetCastName())
        HealthBar.wndTimeCastBar:SetText(string.format("%.1f/%.1f", nCastElapsed / 1000, nCastDuration / 1000))
      else
        HealthBar.wndShortHealth:Show(true)
        HealthBar.wndCastBar:Show(false)
      end
    else
      DruseraBossMods:OnInvalidUnit(nId)
    end
  end
end

local function CreateTimerBar(nEndTime, sLabel, nDuration, fCallback, tCallback_data, nId, tOptions)
  local nCurrentTime = GetGameTime()
  if nEndTime > nCurrentTime then
    local nRemaining = nEndTime - nCurrentTime
    local wndParent = nRemaining >= THRESHOLD_HIGHLIGHT_TIMERS and wnds["Timers"] or wnds["HighlightTimers"]
    local wndFrame = Apollo.LoadForm(DruseraBossMods.xmlDoc, "TimerTemplate", wndParent, DruseraBossMods)
    local TimerBar = {
      -- About timer itself.
      sLabel = sLabel,
      nDuration = nDuration,
      nEndTime = nEndTime,
      -- Data to return on time out.
      fCallback = fCallback,
      tCallback_data = tCallback_data,
      nId = nId,
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
    if wndParent == wnds["HighlightTimers"] then
      TimerBar.wndProgressBar:SetBarColor("red")
      TimerBar.wndLabel:SetFont("CRB_Interface12_B")
      TimerBar.wndTimeLeft:SetFont("CRB_Interface12_B")
      TimerBar.wndFrame:SetAnchorOffsets(0,0,0,30)
    elseif tOptions then
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


------------------------------------------------------------------------------
-- Public functions.
------------------------------------------------------------------------------
function DruseraBossMods:HUDInit()
  -- Create containers
  wnds["Healths"] = Apollo.LoadForm(self.xmlDoc, "HealthsContainer", nil, self)
  wnds["HighlightTimers"] = Apollo.LoadForm(self.xmlDoc, "HighlightTimersContainer", nil, self)
  wnds["Timers"] = Apollo.LoadForm(self.xmlDoc, "TimersContainer", nil, self)
  wnds["HighlightMessages"] = Apollo.LoadForm(self.xmlDoc, "HighlightMessagesContainer", nil, self)
  wnds["Messages"] = Apollo.LoadForm(self.xmlDoc, "MessagesContainer", nil, self)

  for name,wnd in next, wnds do
    Event_FireGenericEvent('WindowManagementAdd', {
      wnd = wnd,
      strName = "DruseraBossMods: " .. name,
    })
    wnd:SetStyle("Moveable", false);
    wnd:SetStyle("Sizable", false);
    wnd:SetStyle("IgnoreMouse", true);
    wnd:SetTextColor('00000000')
    wnd:SetText(Locale[wnd:GetText()])
  end
  _UpdateHUDTimer = ApolloTimer.Create(HUD_UPDATE_PERIOD, true,
                                       "OnHUDProcess", self)
  _UpdateHUDTimer:Stop()
  bTimerRunning = false
end

function DruseraBossMods:HUDCreateHealthBar(tHealth, tOptions)
  if not _HealthBars[tHealth.nId] and tHealth.tUnit:IsValid() then
    local tUnit = tHealth.tUnit
    local wndParent = wnds["Healths"]
    local wndFrame = Apollo.LoadForm(self.xmlDoc, "HealthTemplate", wndParent, self)
    HealthBar = {
      sLabel = tHealth.sLabel,
      tUnit = tUnit,
      nId = tHealth.nId,
      -- Windows objects.
      wndParent = wndParent,
      wndFrame = wndFrame,
      wndLabel = wndFrame:FindChild("Bar"):FindChild("Label"),
      wndPercent = wndFrame:FindChild("Bar"):FindChild("Percent"),
      wndShortHealth = wndFrame:FindChild("Bar"):FindChild("ShortHealth"),
      wndProgressBar = wndFrame:FindChild("Bar"):FindChild("ProgressBar"),
      wndCastBar = wndFrame:FindChild("Bar"):FindChild("Cast"),
      wndProgressCastBar = wndFrame:FindChild("Bar"):FindChild("Cast"):FindChild("ProgressBar"),
      wndLabelCastBar = wndFrame:FindChild("Bar"):FindChild("Cast"):FindChild("Label"),
      wndTimeCastBar = wndFrame:FindChild("Bar"):FindChild("Cast"):FindChild("TimeElapse"),
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

function DruseraBossMods:_HUDMoveTimerBar(i)
  local TimerBar = _TimerBars[i]
  if TimerBar then
    self:HUDRemoveTimerBar(i)
    CreateTimerBar(TimerBar.nEndTime, TimerBar.sLabel,
                   THRESHOLD_HIGHLIGHT_TIMERS,
                   TimerBar.fCallback, TimerBar.tCallback_data,
                   TimerBar.nId, nil)
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
    CreateTimerBar(nEndTime, sLabel, tTimer.nDuration,
                   tTimer.fCallback, tTimer.tCallback_data,
                   tTimer.nId, tOptions)
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

function DruseraBossMods:HUDCreateMessage(tMessage)
  local sLabel = tMessage.sLabel
  local nDuration = tMessage.nDuration or DEFAULT_FADEOFF_MESSAGE
  local nCurrentTime = GetGameTime()
  local nEndTime = nCurrentTime + nDuration
  local bHighlight = tMessage.bHighlight or false
  local wndParent = bHighlight and wnds["HighlightMessages"] or wnds["Messages"]
  local wndFrame = Apollo.LoadForm(self.xmlDoc, "MessageTemplate", wndParent, self)

  self:HUDRemoveMessage(sLabel)
  local MessageBar = {
    nId = tMessage.nId,
    nEndTime = nEndTime,
    nDuration = nDuration,
    Fading = false,
    -- Windows objects.
    wndFrame = wndFrame,
    wndParent = wndParent,
    wndLabel = wndFrame:FindChild("Label"),
  }
  MessageBar.wndFrame:SetData(nEndTime)
  MessageBar.wndLabel:SetText(sLabel)
  _MessagesBars[sLabel] = MessageBar

  if bHighlight then
    MessageBar.wndLabel:SetTextColor("red")
    MessageBar.wndLabel:SetFont("CRB_Interface14_B")
  end

  wndParent:ArrangeChildrenVert(
    Window.CodeEnumArrangeOrigin.LeftOrTop,
    SortContentByTime)

  if not bTimerRunning then
    _UpdateHUDTimer:Start()
    bTimerRunning = true
  end
end

function DruseraBossMods:HUDRemoveMessage(sLabel)
  if _MessagesBars[sLabel] then
    _MessagesBars[sLabel].wndFrame:Destroy()
    _MessagesBars[sLabel].wndParent:ArrangeChildrenVert(
      Window.CodeEnumArrangeOrigin.LeftOrTop,
      SortContentByTime)
    _MessagesBars[sLabel] = nil
  end
end

function DruseraBossMods:HUDRemoveMessages(nId)
  assert(nId)
  for i, MessageBar in next, _MessagesBars do
    if MessageBar.nId == nId then
      self:HUDRemoveTimerBar(MessageBar.sLabel)
    end
  end
end

function DruseraBossMods:OnHUDProcess()
  local Timeout = {}
  local nCurrentTime = GetGameTime()
  for i,TimerBar in next, _TimerBars do
    if nCurrentTime < TimerBar.nEndTime then
      local nRemaining = TimerBar.nEndTime - nCurrentTime
      TimerBar.wndProgressBar:SetProgress(nRemaining)
      TimerBar.wndTimeLeft:SetText(string.format("%.1fs", nRemaining))

      if nRemaining < THRESHOLD_HIGHLIGHT_TIMERS then
        -- Move from TimersContainer to HighligthTimersContainers.
        self:_HUDMoveTimerBar(i)
      end
    else
      if TimerBar.fCallback then
        table.insert(Timeout, {TimerBar.fCallback, TimerBar.tCallback_data})
      end
      self:HUDRemoveTimerBar(i)
    end
  end
  for i,HealthBar in next, _HealthBars do
    HUDUpdateHealthBar(HealthBar.nId)
  end
  for i,MessageBar in next, _MessagesBars do
    if nCurrentTime > MessageBar.nEndTime then
      if not MessageBar.Fading then
        MessageBar.Fading = true
        MessageBar.wndFrame:SetStyle("AutoFade", true);
      elseif nCurrentTime > MessageBar.nEndTime + AUTOFADE_TIMING then
        self:HUDRemoveMessage(i)
      end
    end
  end
  -- Provide all timers with callback to CombatManager.
  for _, TimerBar in next, Timeout do
    TimerBar[1](self, TimerBar[2])
  end
  -- Be careful, stop the timer only after callbacks.
  -- Because a callback can add timer bars or health bars.
  if next(_TimerBars) == nil and next(_HealthBars) == nil and next(_MessagesBars) == nil then
    _UpdateHUDTimer:Stop()
    bTimerRunning = false
  end
end

function DruseraBossMods:HUDToggleAnchorLock()
  if bLock then
    bLock = false
    for _, wnd in next, wnds do
      wnd:SetBGColor('b0606060')
      wnd:SetTextColor('ffffffff')
      wnd:SetStyle("Moveable", true);
      wnd:SetStyle("Sizable", true);
      wnd:SetStyle("IgnoreMouse", false);
    end
  else
    bLock = true
    for _, wnd in next, wnds do
      wnd:SetBGColor('00000000')
      wnd:SetTextColor('00000000')
      wnd:SetStyle("Moveable", false);
      wnd:SetStyle("Sizable", false);
      wnd:SetStyle("IgnoreMouse", true);
    end
  end
end
