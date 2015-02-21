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
local DBM = Apollo.GetAddon("DruseraBossMods")
local Gloomclaw = {}
local CorruptedRavager = {}
local EmpoweredRavager = {}
local nSection = 1

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
local function OnCorruptingRays(self)
  local d = DBM:GetDistBetween2Unit(GameLib:GetPlayerUnit(), self.tUnit)
  if d and d < 35 then
    -- Kick this spell!
    Print("Kick the Corrupting Rays")
  end
end

local function NewSection(self)
  DBM:SetTimerAlert(self, "RUPTURE", 33, nil)
  if nSection == 5 then
    DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 20.5, function(self)
      DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 30, function(self)
        DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 15, nil)
      end)
    end)
  elseif nSection < 5 and nSection > 0 then
    DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 26, function(self)
      DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 33, function(self)
        DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 25, function(self)
          DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 14, function(self)
            DBM:SetTimerAlert(self, "NEXT_ADD_WAVE", 20.5, nil)
          end)
        end)
      end)
    end)
  end
end

------------------------------------------------------------------------------
-- OnStartCombat function.
------------------------------------------------------------------------------
function Gloomclaw:OnStartCombat()
  nSection = 1
  DBM:SetCastStartAlert(self, "RUPTURE", function(self)
    DBM:SetTimerAlert(self, "RUPTURE", 43, nil)
  end)
  DBM:SetDatachronAlert(self, "DATACHRON_GLOOMCLAW_IS_REDUCED", function(self)
    DBM:ClearAllTimerAlert()
  end)
  DBM:SetDatachronAlert(self, "DATACHRON_GLOOMCLAW_IS_PUSHED_BACK", function(self)
    nSection = nSection + 1
    DBM:SetTimerAlert(self, "GLOOMCLAW_IS_PUSHED_BACK", 9, NewSection)
  end)
  DBM:SetDatachronAlert(self, "DATACHRON_GLOOMCLAW_IS_MOVING_FORWARD", function(self)
    nSection = nSection - 1
    DBM:SetTimerAlert(self, "GLOOMCLAW_IS_MOVING_FORWARD", 10, NewSection)
  end)

  NewSection(self)
end

function CorruptedRavager:OnStartCombat()
  DBM:SetCastStartAlert(self, "CORRUPTING_RAYS", OnCorruptingRays)
end

function EmpoweredRavager:OnStartCombat()
  DBM:SetCastStartAlert(self, "CORRUPTING_RAYS", OnCorruptingRays)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "DATASCAPE",
    EncounterName = "GLOOMCLAW",
    ZoneName = "QUANTUM_VORTEX",
  },{
    GLOOMCLAW = Gloomclaw,
    CORRUPTED_RAVAGER = CorruptedRavager,
    EMPOWERED_RAVAGER = EmpoweredRavager,
  }, {
    GLOOMCLAW = {
      BarsCustom = {
        RUPTURE = { color = "xkcdBrightRed" },
        NEXT_ADD_WAVE = { color = "xkcdBrightGreen" }
      },
    },
  })
end
