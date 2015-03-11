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
--local DBM = Apollo.GetAddon("DruseraBossMods")
local DBM = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:GetAddon("DruseraBossMods")
local CrimsonSpiderbot = {}

local my_var = 10
------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
function OnPhaseComboFailed(self)
  DBM:SetTimerAlert(self, "THIS_SHOULD_BE_1", 3, function(self)
    my_var = my_var + 2
    DBM:SetTimerAlert(self, "THIS_SHOULD_BE_2", 6, function(self)
      DBM:SetTimerAlert(self, "THIS_SHOULD_BE_2", 6, nil)
      DBM:SetTimerAlert(self, "THIS_SHOULD_BE_3", 9, function(self)
        DBM:SetTimerAlert(self, "THIS_SHOULD_BE_4", 5, nil)
      end)
    end)
  end)
end

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function CrimsonSpiderbot:OnStartCombat()
  DBM:CreateHealthBar(self, "MAELSTROM_AUTHORITY")
  my_var = 3
  DBM:SetCastStartAlert(self, "PHASER_COMBO", function(self)
    DBM:SetTimerAlert(self, "INTERRUPT_THIS_CAST", my_var, nil)
  end)
  DBM:SetCastSuccessAlert(self, "PHASER_COMBO", function(self)
    DBM:SetTimerAlert(self, "PULL_IN", 40, nil)
  end)
  DBM:SetCastFailedAlert(self, "PHASER_COMBO", OnPhaseComboFailed)

  DBM:SetTimerAlert(self, "NEXT_DISCONNECT", 120, nil)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 0,
    nZoneMapId = 16,
    sEncounterName = "CRIMSON_SPIDERBOT",
    tTriggerNames = {"CRIMSON_SPIDERBOT", },
    tUnits = {
      -- All units allow to be tracked.
      CRIMSON_SPIDERBOT = CrimsonSpiderbot,
    },
    tCustom = {
      CRIMSON_SPIDERBOT = {
        BarsCustom = {
          INTERRUPT_THIS_CAST = { color = "red" },
          THIS_SHOULD_BE_1 = { color = "green" },
          THIS_SHOULD_BE_2 = { color = "xkcdBrightOrange" },
          THIS_SHOULD_BE_3 = { color = "yellow" },
          THIS_SHOULD_BE_4 = { color = "xkcdBrightPurple" },
        },
      },
    },
  })
end
