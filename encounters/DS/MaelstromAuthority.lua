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
local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local ENCOUNTER = DBM:GetModule("EncounterManager"):NewModule("MAELSTROM_AUTHORITY")

local GetPlayerUnit = GameLib.GetPlayerUnit
local GetGameTime = GameLib.GetGameTime

------------------------------------------------------------------------------
-- Constants.
------------------------------------------------------------------------------
local PI = math.pi
local ATAN = math.atan2
local SPELLID_CRISTALIZE = 44444

------------------------------------------------------------------------------
-- MaelstromAuthority.
------------------------------------------------------------------------------
local MaelstromAuthority = {}
local _MaelstromAuthority_ctx
local _WeatherStationLastPopTime = 0

function MaelstromAuthority:OnStartCombat()
  self:CreateHealthBar()
  _MaelstromAuthority_ctx = self
  self:SetDatachronAlert("DATACHRON_THE_PLATFORM_SHAKES", function(self)
    self:ClearAllTimerAlert()
    self:PlaySound("Alert")
    self:SetTimer("MSG_PLATEFORM_DESTROYED", 8)
  end)

  self:SetCastEnd("CAST_CRYSTALLIZE", function(self)
    self:PlaySound("Long")
    self:SetMessage({
      sLabel = "MSG_PLAYER_ICED",
      nDuration = 5,
      bHighlight = true,
    })
  end)
  self:SetCastEnd("CAST_TYPHOON", function(self)
    self:PlaySound("Info")
    self:SetMessage({
      sLabel = "MSG_PLAYER_OUTSIDE",
      nDuration = 5,
      bHighlight = true,
    })
  end)
  self:SetCastStart("CAST_ICE_BREATH", function(self)
    self:SetMessage({
      sLabel = "MSG_RUN",
      nDuration = 5,
      bHighlight = true,
    })
  end)
end

------------------------------------------------------------------------------
-- WeatherStation.
------------------------------------------------------------------------------
local WeatherStation = {}

function WeatherStation:OnCreate()
  local nCurrentTime = GetGameTime()
  local delta = nCurrentTime - _WeatherStationLastPopTime
  if delta > 10 then
    _WeatherStationLastPopTime = nCurrentTime
    ENCOUNTER:SetTimer("NEXT_WEATHER_STATIONS", 25)
  end

  self:CreateHealthBar()

  -- Is the WeatherStation is on the right/left and front/behind of the boss.
  -- First retrieve unit positions.
  local tBossPos = _MaelstromAuthority_ctx.tUnit:GetPosition()
  local tStationPos = self.tUnit:GetPosition()
  local tBossVec = Vector3.New(tBossPos)
  local tStationVec = Vector3.New(tStationPos)
  -- Compute a new vector with the boss as origin.
  local tVector = tStationVec - tBossVec
  -- Do the rotation trough the boss orientation.
  local nStationRad = ATAN(tVector.z, tVector.x)
  local tFacing = _MaelstromAuthority_ctx.tUnit:GetFacing()
  local nBossRad = ATAN(tFacing.z, tFacing.x)
  -- Finaly, find the angle between the boss orientation and weather station.
  -- The modulo will return a value between 0 to 2 PI.
  local AngleRad = (nStationRad - nBossRad) % (2 * PI)

  local sPositionText = nil
  if AngleRad < 0.5 * PI then
    -- Front / Left
    sPositionText = "MSG_WEATHER_STATION_FRONT_RIGHT"
  elseif AngleRad < PI then
    -- Behind / Left
    sPositionText = "MSG_WEATHER_STATION_BEHIND_RIGHT"
  elseif AngleRad < 1.5 * PI then
    -- Behind / Right
    sPositionText = "MSG_WEATHER_STATION_BEHIND_LEFT"
  else
    -- Front / Right
    sPositionText = "MSG_WEATHER_STATION_FRONT_LEFT"
  end
  self:SetMessage({
    sLabel = sPositionText,
    nDuration = 5,
    bHighlight = true,
  })
  self:PlaySound("Info")

  -- Draw a line from the Weather Station to the Boss
  -- Be carefull, the vector is inversed in this case.
  local nLen = tVector:Length()
  nStationRad = nStationRad
--  self:SetLineOnUnit(self.nId, 1, math.deg(nStationRad), 5, nLen - 10)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
function ENCOUNTER:OnInitialize()
  self:RegisterZoneMap(98, 120)
  self:RegisterTriggerNames({"MAELSTROM_AUTHORITY"})
  self:RegisterUnitClass({
    -- All units allowed to be tracked.
    MAELSTROM_AUTHORITY = MaelstromAuthority,
    WEATHER_STATION = WeatherStation,
  })
  self:RegisterEnglishLocale({
    ["MAELSTROM_AUTHORITY"] = "Maelstrom Authority",
    ["WEATHER_STATION"] = "Weather Station",
    ["DATACHRON_THE_PLATFORM_SHAKES"] = "The platform trembles!",
    ["MSG_PLATEFORM_DESTROYED"] = "Plateform destoyed!",
    ["MSG_PLAYER_ICED"] = "3 players iced, split them!",
    ["MSG_PLAYER_OUTSIDE"] = "Players outside, grap them!",
    ["MSG_WEATHER_STATION_FRONT_RIGHT"] = "Weather Station: FRONT / RIGHT",
    ["MSG_WEATHER_STATION_FRONT_LEFT"] = "Weather Station: FRONT / LEFT",
    ["MSG_WEATHER_STATION_BEHIND_RIGHT"] = "Weather Station: BEHIND / RIGHT",
    ["MSG_WEATHER_STATION_BEHIND_LEFT"] = "Weather Station: BEHIND / LEFT",
    ["MSG_RUN"] = "Run !",
    ["NEXT_WEATHER_STATIONS"] = "Next Weather Stations",
    ["NEXT_ICE_BREATH"] = "Next: Ice Breath",
    ["NEXT_WIND_WALL"] = "Next: Wind Wall",
    ["NEXT_TYPHOON"] = "Next: Typhoon",
    ["CAST_ACTIVATE_WEATHER_CYCLE"] = "Activate Weather Cycle",
    ["CAST_THUNDER_STAFF"] = "Bâton de foudre", -- 20s -- 3 Hugde AOE
    ["CAST_ICE_BREATH"] = "Ice Breath", -- 20s, like Ohmna with torrent.
    ["CAST_CRYSTALLIZE"] = "Crystallize", -- 3 Players iced at the end.
    ["CAST_TYPHOON"] = "Typhoon", -- 3s, played dropped outside at the end cast.
    ["CAST_WIND_WALL"] = "Wind Wall", -- Rectangular AOE to put on border.
  })
  self:RegisterFrenchLocale({
    ["DDDDDDDDDD_TODO "] = "Bride de gel", -- CC with pillar in frost phase.

    ["MAELSTROM_AUTHORITY"] = "Contrôleur du Maelstrom",
    ["WEATHER_STATION"] = "Station météorologique",
    ["DATACHRON_THE_PLATFORM_SHAKES"] = "La plateforme tremble !",
    ["MSG_PLATEFORM_DESTROYED"] = "Plateforme détruite !",
    ["MSG_PLAYER_ICED"] = "3 joueurs glacés, Séparez les !",
    ["MSG_PLAYER_OUTSIDE"] = "Joueurs dehors, Attrapez les !",
    ["MSG_WEATHER_STATION_FRONT_RIGHT"] = "Station météorologique: DEVANT / DROITE",
    ["MSG_WEATHER_STATION_FRONT_LEFT"] = "Station météorologique: DEVANT / GAUCHE",
    ["MSG_WEATHER_STATION_BEHIND_RIGHT"] = "Station météorologique: DERRIERE / DROITE",
    ["MSG_WEATHER_STATION_BEHIND_LEFT"] = "Station météorologique: DERRIERE / GAUCHE",
    ["MSG_RUN"] = "Cours !",
    ["NEXT_WEATHER_STATIONS"] = "Prochaine station météorologique",
    ["NEXT_ICE_BREATH"] = "Prochain: Souffle de glace",
    ["NEXT_WIND_WALL"] = "Prochain: Mur de vent",
    ["NEXT_TYPHOON"] = "Prochain: Typhon",
    ["CAST_ACTIVATE_WEATHER_CYCLE"] = "Activer cycle climatique", -- 3s
    ["CAST_THUNDER_STAFF"] = "Bâton de foudre",
    ["CAST_ICE_BREATH"] = "Souffle de glace",
    ["CAST_TYPHOON"] = "Typhon",
    ["CAST_WIND_WALL"] = "Mur de vent",
    ["CAST_CRYSTALLIZE"] = "Cristalliser",
  })

  self:RegisterTimer("NEXT_WEATHER_STATIONS", { color = "xkcdAlgaeGreen" })
  self:RegisterTimer("MSG_PLATEFORM_DESTROYED", { color = "xkcdAlgaeGreen" })
  self:RegisterTimer("NEXT_ICE_BREATH", { color = "xkcdBrightSkyBlue" })
  self:RegisterTimer("NEXT_WIND_WALL", { color = "xkcdBrightSkyBlue" })
  self:RegisterTimer("NEXT_TYPHOON", { color = "xkcdDeepBlue" })
end

function ENCOUNTER:OnEnable()
  self:ActivateDetection(true)
end
