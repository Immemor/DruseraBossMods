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

local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local GetGameTime = GameLib.GetGameTime
local Avatus = {}
local ObstinateLogicWall = {}
local DataDevourer = {}
local _DataDevourerCount = 0
local _nLastDataDevourerPopTime = 0

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function ObstinateLogicWall:OnStartCombat()
end

function Avatus:OnStartCombat()
  _DataDevourerCount = 0
  _nLastDataDevourerPopTime = 0
  DBM:ActivateDetection(true)
  DBM:SetTimerAlert(self, "DATA_DEVOURER", 10, nil)
end

function DataDevourer:OnDetection()
  local nCurrentTime = GetGameTime()
  local nDelta = nCurrentTime - _nLastDataDevourerPopTime
  if nDelta > 7 then
    _nLastDataDevourerPopTime = nCurrentTime
    _DataDevourerCount = _DataDevourerCount + 1
    if _DataDevourerCount < 3 then
      DBM:SetTimerAlert(self, "DATA_DEVOURER", 10, nil)
    elseif _DataDevourerCount % 2 then
      DBM:SetTimerAlert(self, "DATA_DEVOURER", 5, nil)
    else
      DBM:SetTimerAlert(self, "DATA_DEVOURER", 10, nil)
    end
  end
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 98,
    nZoneMapId = 116,
    sEncounterName = "VOLATILITY_LATTICE",
    tTriggerNames = { "AVATUS", },
    tUnits = {
      AVATUS = Avatus,
      OBSTINATE_LOGIC_WALL = ObstinateLogicWall,
      DATA_DEVOURER = DataDevourer,
    },
  })
end
