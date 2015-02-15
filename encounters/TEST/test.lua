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
  my_var = 3
  DBM:SetCastStartAlert(self, "PHASER_COMBO", function(self)
    DBM:SetTimerAlert(self, "INTERRUPT_THIS_CAST", my_var, nil)
  end)
  DBM:SetCastSuccessAlert(self, "PHASER_COMBO", function(self)
    DBM:SetTimerAlert(self, "PULL_IN", 40, nil)
  end)
  DBM:SetCastFailedAlert(self, "PHASER_COMBO", OnPhaseComboFailed)

  -- Fake datachron registering.
  DBM:SetDatachronAlert(self, "COMMENCING_ENHANCEMENT_SEQUENCE",
  function(self)
    DBM:SetTimerAlert(self, "NEXT_DISCONNECT", 87, nil)
  end)

  DBM:SetTimerAlert(self, "NEXT_DISCONNECT", 120, nil)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    RaidName = "GALERAS",
    EncounterName = "CRIMSON_SPIDERBOT",
    ZoneName = "GALERAS",
  },{
    -- This mob is close Thayd.
    CRIMSON_SPIDERBOT = CrimsonSpiderbot,
  },{
    CRIMSON_SPIDERBOT = {
      DisplayName = "MAELSTROM_AUTHORITY",
      BarsCustom = {
        INTERRUPT_THIS_CAST = { color = "red" },
        THIS_SHOULD_BE_1 = { color = "green" },
        THIS_SHOULD_BE_2 = { color = "xkcdBrightOrange" },
        THIS_SHOULD_BE_3 = { color = "yellow" },
        THIS_SHOULD_BE_4 = { color = "xkcdBrightPurple" },
      },
    },
  })
end
