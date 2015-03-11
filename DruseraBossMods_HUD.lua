------------------------------------------------------------------------------
-- Client Lua Script for DruseraBossMods
--
-- Copyright (C) 2015 Thierry carré
--
-- Player Name: 'Immé sama'
-- Guild Name: 'Les Solaris'
-- Server Name: Jabbit(EU)
------------------------------------------------------------------------------

local DruseraBossMods = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local next = next
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local HUD_UPDATE_PERIOD = 0.1
local DEFAULT_FADEOFF_MESSAGE = 6.0
local AUTOFADE_TIMING = 0.5

------------------------------------------------------------------------------
-- Working variables.
------------------------------------------------------------------------------
local _TimerBars = {}
local _HealthBars = {}
local _MessagesBars = {}
local _bTimerRunning = false
local _bLock = true
local _wnds = {}
local _tConfig = {}

------------------------------------------------------------------------------
-- Local functions.
------------------------------------------------------------------------------
local function HUDStart()
  if not _bTimerRunning then
    _bTimerRunning = true
    _UpdateHUDTimer:Start()
  end
end

local function SortContentByTime(a, b)
  return a:GetData() < b:GetData()
end

local function SortContentByInvTime(a, b)
  return a:GetData() > b:GetData()
end

local function ArrangeTimerBar(wndParent)
  local bAdd2Top = nil
  local sort = Window.CodeEnumArrangeOrigin.LeftOrTop
  local opt = false
  if wndParent == _wnds["Timers"] then
    bAdd2Top = _tConfig.add2top_normal
    opt = _tConfig.inversesort_normal
  else
    bAdd2Top = _tConfig.add2top_highlight
    opt = _tConfig.inversesort_highlight
  end

  local fSort = opt and SortContentByInvTime or SortContentByTime
  if bAdd2Top then
    sort = Window.CodeEnumArrangeOrigin.RightOrBottom
  end

  wndParent:ArrangeChildrenVert(sort, fSort)
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
    end
  end
end

local function CreateTimerBar(nEndTime, sLabel, nDuration, fCallback, tCallback_data, nId, tOptions)
  local nCurrentTime = GetGameTime()
  if nEndTime > nCurrentTime then
    local nRemaining = nEndTime - nCurrentTime

    local nThreshold = _tConfig.threshold_n2h
    local bIsHighlight = nRemaining < nThreshold
    local nHeight = bIsHighlight and _tConfig.height_highlight
                    or _tConfig.height_normal
    local sFont = bIsHighlight and _tConfig.font_highlight
                  or _tConfig.font_normal
    local bDisplayTime = bIsHighlight and _tConfig.displaytime_highlight
                         or _tConfig.displaytime_normal
    local wndParent = bIsHighlight and _wnds["HighlightTimers"] or _wnds["Timers"]
    local wndFrame = Apollo.LoadForm(DruseraBossMods.xmlDoc, "TimerTemplate", wndParent, DruseraBossMods)
    local wndLabel = wndFrame:FindChild("Bar"):FindChild("Label")
    local wndTimeLeft = wndFrame:FindChild("Bar"):FindChild("TimeLeft")
    local wndProgressBar = wndFrame:FindChild("Bar"):FindChild("ProgressBar")

    wndFrame:SetData(nEndTime)
    wndFrame:SetAnchorOffsets(0,0,0,nHeight)
    wndProgressBar:SetMax(nDuration)
    wndProgressBar:SetProgress(nRemaining)
    wndTimeLeft:SetText(string.format("%.1fs", nRemaining))
    wndTimeLeft:SetFont(sFont)
    wndLabel:SetText(sLabel)
    wndLabel:SetFont(sFont)
    if not bDisplayTime then
      wndTimeLeft:SetTextColor("00000000")
    end
    if tOptions then
      if tOptions.color then
        wndProgressBar:SetBarColor(tOptions.color)
      end
    end
    ArrangeTimerBar(wndParent)

    _TimerBars[sLabel] = {
      -- About timer itself.
      sLabel = sLabel,
      nDuration = nDuration,
      nEndTime = nEndTime,
      tOptions = tOptions,
      -- Data to return on time out.
      fCallback = fCallback,
      tCallback_data = tCallback_data,
      nId = nId,
      -- Windows objects.
      wndParent = wndParent,
      wndFrame = wndFrame,
      wndLabel = wndLabel,
      wndTimeLeft = wndTimeLeft,
      wndProgressBar = wndProgressBar,
    }

    HUDStart()
  end
end


------------------------------------------------------------------------------
-- Public functions.
------------------------------------------------------------------------------
function DruseraBossMods:HUDInit()
  -- Create containers
  _wnds["Healths"] = Apollo.LoadForm(self.xmlDoc, "HealthsContainer", nil, self)
  _wnds["HighlightTimers"] = Apollo.LoadForm(self.xmlDoc, "HighlightTimersContainer", nil, self)
  _wnds["Timers"] = Apollo.LoadForm(self.xmlDoc, "TimersContainer", nil, self)
  _wnds["HighlightMessages"] = Apollo.LoadForm(self.xmlDoc, "HighlightMessagesContainer", nil, self)
  _wnds["Messages"] = Apollo.LoadForm(self.xmlDoc, "MessagesContainer", nil, self)

  for name,wnd in next, _wnds do
    wnd:SetText(self.L[wnd:GetText()])
  end
  _UpdateHUDTimer = ApolloTimer.Create(HUD_UPDATE_PERIOD, true,
                                       "OnHUDProcess", self)
  _UpdateHUDTimer:Stop()
  _bTimerRunning = false
  self:HUDLoadProfile()
end

function DruseraBossMods:HUDLoadProfile()
  local tCurrentConf = self.db.profile.custom
  _tConfig = {
    threshold_n2h = tCurrentConf.bar_threshold_n2h,
    inversesort_normal = tCurrentConf.bar_inversesort_normal,
    inversesort_highlight = tCurrentConf.bar_inversesort_highlight,
    add2top_normal = tCurrentConf.bar_add2top_normal,
    add2top_highlight = tCurrentConf.bar_add2top_highlight,
    height_normal = tCurrentConf.bar_height_normal,
    height_highlight = tCurrentConf.bar_height_highlight,
    font_normal = tCurrentConf.bar_font_normal,
    font_highlight = tCurrentConf.bar_font_highlight,
    displaytime_normal = tCurrentConf.bar_displaytime_normal,
    displaytime_highlight = tCurrentConf.bar_displaytime_highlight,
  }

  for _, TimerBar in next, _TimerBars do
    if TimerBar.wndParent == _wnds["Timers"] then
      TimerBar.wndFrame:SetAnchorOffsets(0,0,0, _tConfig.height_normal)
      TimerBar.wndTimeLeft:SetFont(_tConfig.font_normal)
      TimerBar.wndLabel:SetFont(_tConfig.font_normal)
      if _tConfig.displaytime_normal then
        TimerBar.wndTimeLeft:SetTextColor("white")
      else
        TimerBar.wndTimeLeft:SetTextColor("00000000")
      end
    else
      TimerBar.wndFrame:SetAnchorOffsets(0,0,0, _tConfig.height_highlight)
      TimerBar.wndTimeLeft:SetFont(_tConfig.font_highlight)
      TimerBar.wndLabel:SetFont(_tConfig.font_highlight)
      if _tConfig.displaytime_highlight then
        TimerBar.wndTimeLeft:SetTextColor("white")
      else
        TimerBar.wndTimeLeft:SetTextColor("00000000")
      end
    end
  end
  ArrangeTimerBar(_wnds["Timers"])
  ArrangeTimerBar(_wnds["HighlightTimers"])
end

function DruseraBossMods:HUDWindowsManagementAdd()
  for name,wnd in next, _wnds do
    Event_FireGenericEvent('WindowManagementAdd', {
      wnd = wnd,
      strName = "DruseraBossMods: " .. name,
    })
    wnd:SetStyle("Moveable", false);
    wnd:SetStyle("Sizable", false);
    wnd:SetStyle("IgnoreMouse", true);
    wnd:SetTextColor('00000000')
    wnd:Show(true, true)
  end
end

function DruseraBossMods:HUDCreateHealthBar(tHealth, tOptions)
  if not _HealthBars[tHealth.nId] and tHealth.tUnit:IsValid() then
    local tUnit = tHealth.tUnit
    local wndParent = _wnds["Healths"]
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
    wndParent:ArrangeChildrenVert(Window.CodeEnumArrangeOrigin.LeftOrTop,
                                  SortContentByTime)
    HUDStart()
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

function DruseraBossMods:_HUDMoveTimerBar(i, nRemaining)
  local TimerBar = _TimerBars[i]
  if TimerBar then
    self:HUDRemoveTimerBar(i)
    CreateTimerBar(TimerBar.nEndTime, TimerBar.sLabel,
                   nRemaining,
                   TimerBar.fCallback, TimerBar.tCallback_data,
                   TimerBar.nId, TimerBar.tOptions)
  end
end

function DruseraBossMods:HUDRetrieveTimerBar(sLabel)
  local TimerBar = _TimerBars[sLabel]
  if TimerBar then
    return TimerBar.wndProgressBar:GetProgress()
  end
  return nil
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
  local TimerBar = _TimerBars[sLabel]
  if TimerBar then
    _TimerBars[sLabel] = nil
    TimerBar.wndFrame:Destroy()
    ArrangeTimerBar(TimerBar.wndParent)
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
  local wndParent = bHighlight and _wnds["HighlightMessages"] or _wnds["Messages"]
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

  HUDStart()
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

      if TimerBar.wndParent == _wnds["Timers"] and
        nRemaining < _tConfig.threshold_n2h then
        -- Move from TimersContainer to HighligthTimersContainers.
        self:_HUDMoveTimerBar(i, nRemaining)
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
    _bTimerRunning = false
  end
end

function DruseraBossMods:HUDToggleAnchorLock()
  if _bLock then
    _bLock = false
    for _, wnd in next, _wnds do
      wnd:SetBGColor('b0606060')
      wnd:SetTextColor('ffffffff')
      wnd:SetStyle("Moveable", true);
      wnd:SetStyle("Sizable", true);
      wnd:SetStyle("IgnoreMouse", false);
    end
  else
    _bLock = true
    for _, wnd in next, _wnds do
      wnd:SetBGColor('00000000')
      wnd:SetTextColor('00000000')
      wnd:SetStyle("Moveable", false);
      wnd:SetStyle("Sizable", false);
      wnd:SetStyle("IgnoreMouse", true);
    end
  end
end


Apollo.GetAddon(Apollo.GetString("CRB_Interface"))
