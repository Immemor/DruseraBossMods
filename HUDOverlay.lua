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
local GetPlayerUnit = GameLib.GetPlayerUnit
local GetUnitById = GameLib.GetUnitById
local WorldLocToScreenPoint = GameLib.WorldLocToScreenPoint
--local GetUnitScreenPosition = GameLib.GetUnitScreenPosition -- Not needed
local Vector3 = Vector3
local next = next
local min, max = math.min, math.max
local sin, cos, atan2, rad = math.sin, math.cos, math.atan2, math.rad

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local ALLMARKS = {
  ["crosshair"] = {40, 40},
  ["crosshair2"] = {25, 25},
  ["PinkUnicorn"] = {70, 70},
  ["BloodySkull"] = {30, 30},
  ["GraySkull"] = {30, 30},
  ["RedSkull"] = {30, 30},
  ["WhiteSkull"] = {30, 30},
}
local RACES = GameLib.CodeEnumRace
local RACE_ICON_MODIFIER = {
    [RACES.Human] = { Body = 1.1 },
    [RACES.Granok] = {  Body = 1.3 },
    [RACES.Aurin] = { Body = 0.9 },
    [RACES.Chua] = { Body = 0.8 },
    [RACES.Mordesh] = { Body = 1.15 }
}
local FPOINTS_DEFAULT = { 0, 0, 0, 0 }
local CIRCLE_POINT_CNT = 6
local REFRESH_DRAW_PERIOD = 0.03
local CIRCLE_EFFECT = {}
do
  for i = 1, CIRCLE_POINT_CNT do
    local a = rad(i * 360 / CIRCLE_POINT_CNT)
    CIRCLE_EFFECT[i] = { x = cos(a), z = sin(a) }
  end
end

------------------------------------------------------------------------------
-- working variables.
------------------------------------------------------------------------------
local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local Overlay = {}
local DrawUnit = {}
local _tDrawUnits = {}
local _tDrawTimer
local _tOverlay = nil

------------------------------------------------------------------------------
-- local functions.
------------------------------------------------------------------------------
local function Add2Logs(sText, ...)
  if Overlay.tLogger then
    Overlay.tLogger:Add(sText, ...)
  end
end

local function DrawUnitCall(sMethod, tDrawUnit, ...)
  -- Trace all call to DrawUnit object for debugging purpose.
  Add2Logs(sMethod, tDrawUnit.nId, ...)
  -- Retrieve callback function.
  fMethod = tDrawUnit[sMethod]
  -- Protected call.
  local s, sErrMsg = pcall(fMethod, tDrawUnit, ...)
  if not s then
    --@alpha@
    Print(sMethod .. ": " .. sErrMsg)
    --@end-alpha@
    Add2Logs("ERROR", nil, sErrMsg)
  end
end

local function Start()
  if not Overlay.bIsRunning and _tOverlay ~= nil then
    Add2Logs("Start")
    Overlay.bIsRunning = true
    _tDrawTimer:Start()
  end
end

local function Stop()
  if Overlay.bIsRunning then
    Overlay.bIsRunning = false
    _tDrawTimer:Stop()
    Add2Logs("Stop")
    _tOverlay:DestroyAllPixies()
    _tDrawUnits = {}
  end
end

local function InternalError(sErrMsg)
  Print(sErrMsg)
  Add2Logs("ERROR", nil, sErrMsg)
  Stop()
end

------------------------------------------------------------------------------
-- DrawUnit class (many instances).
------------------------------------------------------------------------------
local DrawUnit_mt = { __index = DrawUnit }

function DrawUnit:Destroy()
  if _tDrawUnits[self.nId] then
    Add2Logs("Delete DrawUnit", self.nId)
    _tDrawUnits[self.nId] = nil
  end
end

function DrawUnit:SetIcon(sIconName)
  assert(type(sIconName) == "string" or type(sIconName) == nil)
  Add2Logs("SetIcon", self.nId, sIconName)
  if sIconName and ALLMARKS[sIconName] then
    self.sSprite = "DruseraBossMods_Sprites:mark_" .. sIconName
    self.nIconHeight = ALLMARKS[sIconName][1] / 2
    self.nIconWidth = ALLMARKS[sIconName][2] / 2
    Start()
  else
    self.sSprite = nil
  end
end

function DrawUnit:SetCircle(nCircleId, nRadius)
  assert(type(nCircleId) == "number")
  assert(type(nRadius) == "number" or type(nRadius) == nil)
  Add2Logs("SetCircle", self.nId, nCircleId, nRadius)
  self.tCircles[nCircleId] = nRadius
  if nRadius then
    Start()
  end
end

function DrawUnit:SetLine(nLineId, nAngleDegree, nOffset, nLen)
  assert(type(nLineId) == "number")
  assert(type(nAngleDegree) == "number")
  assert(type(nOffset) == "number")
  assert(type(nLen) == "number")
  Add2Logs("SetLine", self.nId, nLineId, nAngleDegree, nOffset, nLen)
  if nLen ~= 0 then
    local nAngleRad = - rad(nAngleDegree)
    local nTotalLen = nLen + nOffset
    self.tLines[nLineId] = {nAngleRad, nOffset, nTotalLen}
    Start()
  else
    self.tLines[nLineId] = nil
  end
end

-- Private function
local function UpdateCalcul(tDrawUnit, tPlayer)
  tDrawUnit.bIsValid = tDrawUnit.tUnit:IsValid()
  if tDrawUnit.bIsValid then
    if tDrawUnit.sSprite or next(tDrawUnit.tCircles) or next(tDrawUnit.tLines) then
      tDrawUnit.bProcessDraw = true
      tDrawUnit.tWorldPosition = tDrawUnit.tUnit:GetPosition()
      tDrawUnit.tWorldVector = Vector3.New(tDrawUnit.tWorldPosition)
      -- Compute informations needed for drawing.
      tDrawUnit.tScreenPoint = WorldLocToScreenPoint(tDrawUnit.tWorldVector)
      if tDrawUnit.tScreenPoint.z > 0 then
        tDrawUnit.nDistance2Player = (tDrawUnit.tWorldVector - tPlayer.tWorldVector):Length()
        -- Scale factor is limit between 0.5 to 1.
        local scale = min(80 / tDrawUnit.nDistance2Player, 1)
        tDrawUnit.nScale = max(scale, 0.5)
        local tFacing = tDrawUnit.tUnit:GetFacing()
        tDrawUnit.nAngleRad = atan2(tFacing.z, tFacing.x)
      else
        tDrawUnit.bProcessDraw = false
      end
    else
      tDrawUnit.bProcessDraw = false
    end
  else
    tDrawUnit.bProcessDraw = false
  end
end

-- Private function
local function Draw(tDrawUnit, tPlayer)
  -- Check if the unit if in front of the screen.
  if tDrawUnit.bProcessDraw then
    if tDrawUnit.sSprite then
      local tAttachVector = Vector3.New(
        tDrawUnit.tWorldPosition.x,
        tDrawUnit.tWorldPosition.y + tDrawUnit.nHeightOffset,
        tDrawUnit.tWorldPosition.z)
      local tScreenAttach = WorldLocToScreenPoint(tAttachVector)
      if tScreenAttach.z > 0 then
        _tOverlay:AddPixie({
          strSprite = tDrawUnit.sSprite,
          cr = "white",
          loc = {
            fPoints = FPOINTS_DEFAULT,
            nOffsets = {
              tScreenAttach.x - tDrawUnit.nIconWidth * tDrawUnit.nScale,
              tScreenAttach.y - tDrawUnit.nIconHeight * tDrawUnit.nScale,
              tScreenAttach.x + tDrawUnit.nIconWidth * tDrawUnit.nScale,
              tScreenAttach.y + tDrawUnit.nIconHeight * tDrawUnit.nScale,
            },
          },
        })
      end
    end

    for _, nRadius in next, tDrawUnit.tCircles do
      local tStartVector = Vector3.New(
        tDrawUnit.tWorldVector.x + nRadius * CIRCLE_EFFECT[CIRCLE_POINT_CNT].x,
        tDrawUnit.tWorldVector.y,
        tDrawUnit.tWorldVector.z + nRadius * CIRCLE_EFFECT[CIRCLE_POINT_CNT].z)

      for i = 1, CIRCLE_POINT_CNT do
        local tEndVector = Vector3.New(
          tDrawUnit.tWorldVector.x + nRadius * CIRCLE_EFFECT[i].x,
          tDrawUnit.tWorldVector.y,
          tDrawUnit.tWorldVector.z + nRadius * CIRCLE_EFFECT[i].z)
        local tScreenStart = WorldLocToScreenPoint(tStartVector)
        local tScreenEnd = WorldLocToScreenPoint(tEndVector)
        if tScreenStart.z > 0 and tScreenEnd.z > 0 then
          _tOverlay:AddPixie({
            bLine = true,
            fWidth = 1,
            cr = "white",
            loc = {
              fPoints = FPOINTS_DEFAULT,
              nOffsets = {
                tScreenStart.x, tScreenStart.y,
                tScreenEnd.x, tScreenEnd.y
              },
            },
          })
        end
        tStartVector = tEndVector
      end
    end

    for _, tLine in next, tDrawUnit.tLines do
      local nAngleRad = tLine[1]
      local nOffset = tLine[2]
      local nLen = tLine[3]

      local a = tDrawUnit.nAngleRad + nAngleRad
      local x = cos(a)
      local z = sin(a)

      local tStartVector = Vector3.New(
        tDrawUnit.tWorldVector.x + nOffset * x / 2,
        tDrawUnit.tWorldVector.y,
        tDrawUnit.tWorldVector.z + nOffset * z / 2)
      local tEndVector = Vector3.New(
        tDrawUnit.tWorldVector.x + nLen * x / 2,
        tDrawUnit.tWorldVector.y,
        tDrawUnit.tWorldVector.z + nLen * z / 2)
      local tScreenStart = WorldLocToScreenPoint(tStartVector)
      local tScreenEnd = WorldLocToScreenPoint(tEndVector)
      if tScreenStart.z > 0 and tScreenEnd.z > 0 then
        _tOverlay:AddPixie({
          bLine = true,
          fWidth = 4,
          cr = "white",
          loc = {
            fPoints = FPOINTS_DEFAULT,
            nOffsets = {
              tScreenStart.x, tScreenStart.y,
              tScreenEnd.x, tScreenEnd.y
            },
          },
        })
      end
    end
  end
end

------------------------------------------------------------------------------
-- Overlay class (only 1 instance).
------------------------------------------------------------------------------
function Overlay:Initialize()
  self.bIsRunning = false
  _tOverlay = Apollo.LoadForm(DBM.xmlDoc, "Overlay", "InWorldHudStratum", self)
  _tDrawUnits = {}

  self.tLogger = DBM:NewLoggerNamespace(Overlay, "Overlay")
  _tDrawTimer = ApolloTimer.Create(REFRESH_DRAW_PERIOD, true, "OnDrawUpdate", self)
  _tDrawTimer:Stop()
  return self
end

function Overlay:OnDrawUpdate()
  _tOverlay:DestroyAllPixies()

  local tPUnit = GetPlayerUnit()
  if tPUnit and tPUnit:IsValid() then
    local tPWorldPosition = tPUnit:GetPosition()
    local tPWorldVector = Vector3.New(tPWorldPosition)
    local tPScreenPoint = WorldLocToScreenPoint(tPWorldVector)
    local tPlayer = {
      tUnit = tPUnit,
      tWorldPosition = tPWorldPosition,
      tWorldVector = tPWorldVector,
      tScreenPoint = tPScreenPoint,
    }

    -- Get Table reference in case where DestroyAll is called during drawing.
    local tDrawUnits = _tDrawUnits
    for _, tDrawUnit in next, tDrawUnits do
      local r, sErrMsg = pcall(UpdateCalcul, tDrawUnit, tPlayer)
      if not r then
        InternalError(sErrMsg)
        break
      end
      if tDrawUnit.bProcessDraw then
        -- Protected call without logging.
        r, sErrMsg = pcall(Draw, tDrawUnit, tPlayer)
        if not r then
          InternalError(sErrMsg)
          break
        end
      end
    end
  end

  if next(tDrawUnits) == nil then
    Stop()
  end
end

function Overlay:GetDrawUnitById(nId)
  local tDrawUnit = _tDrawUnits[nId]
  if tDrawUnit == nil then
    Add2Logs("New DrawUnit", nId)
    local tUnit = GetUnitById(nId)
    local nRaceId = tUnit:GetRaceId()
    tDrawUnit = {
      nId = nId,
      tUnit = tUnit,
      nHeightOffset = 0,
      nIconWidth = 20,
      nIconHeight = 20,
      sSprite = nil,
      tCircles = {},
      tLines = {},
      bProcessDraw = false,
    }
    if RACE_ICON_MODIFIER[nRaceId] then
      tDrawUnit.nHeightOffset = RACE_ICON_MODIFIER[nRaceId].Body
    end
    setmetatable(tDrawUnit, DrawUnit_mt)
    _tDrawUnits[nId] = tDrawUnit
  end
  return tDrawUnit
end

function Overlay:DestroyAll()
  Add2Logs("Delete all DrawUnit")
  _tDrawUnits = {}
end

function Overlay:ExtraLog2Text(sText, tExtraData, nRefTime)
  local sResult = ""
  if sText == "ERROR" then
    sResult = tExtraData[1]
  elseif sText == "SetIcon" then
    local sFormat = "IconName='%s'"
    sResult = string.format(sFormat, tExtraData[1])
  elseif sText == "SetCircle" then
    local sFormat = "nCircleId=%d nRadius=%d"
    sResult = string.format(sFormat, tExtraData[1], tExtraData[2])
  elseif sText == "SetLine" then
    local sFormat = "nLineId=%d nAngleDegree=%d nOffset=%d nLen=%d"
    sResult = string.format(sFormat, tExtraData[1], tExtraData[2], tExtraData[3], tExtraData[4])
  end
  return sResult
end

------------------------------------------------------------------------------
-- Public functions.
------------------------------------------------------------------------------
function DBM:OverlayInitialize()
  return Overlay:Initialize()
end
