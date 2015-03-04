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
local Kuralak = {}
local GetPlayerUnit = GameLib.GetPlayerUnit

local SPELLID__CHROMOSOME_CORRUPTION = 56652

------------------------------------------------------------------------------
-- Extra functions.
------------------------------------------------------------------------------
function Kuralak:CultivateCorruption()
  DBM:SetTimerAlert(self, "CULTIVATE_CORRUPTION", 60, nil)
end

------------------------------------------------------------------------------
-- OnStartCombat functions.
------------------------------------------------------------------------------
function Kuralak:OnStartCombat()
  DBM:CreateHealthBar(self, "KURALAK_THE_DEFILER")
  DBM:SetCastStartAlert(self, "CULTIVATE_CORRUPTION", self.CultivateCorruption)
  DBM:SetCastStartAlert(self, "CHROMOSOME_CORRUPTION", function(self)
    -- Remove trigger
    DBM:SetCastStartAlert(self, "VANISH_INTO_DARKNESS", nil)
    DBM:SetTimerAlert(self, "VANISH_INTO_DARKNESS", 0, nil)
    self:CultivateCorruption()
  end)

  -- Outbreak
  DBM:SetCastSuccessAlert(self, "OUTBREAK", function(self)
    DBM:SetTimerAlert(self, "OUTBREAK", 40, nil)
  end)

  -- Vanish into Darkness
  DBM:SetCastStartAlert(self, "VANISH_INTO_DARKNESS", function(self)
    DBM:SetTimerAlert(self, "VANISH_INTO_DARKNESS", 50, nil)
  end)

  -- DNA Siphon
  DBM:SetCastSuccessAlert(self, "DNA_SIPHON", function(self)
    DBM:SetTimerAlert(self, "DNA_SIPHON", 90, nil)
  end)

  DBM:SetDebuffAddAlert(self, SPELLID__CHROMOSOME_CORRUPTION, function(self, nTargetId, nStack)
    local bItself = nTargetId == GetPlayerUnit():GetId()
    if bItself then
      DBM:PlaySound("Info")
    end
    DBM:SetMarkOnUnit("Crosshair", nTargetId)
  end)
end

------------------------------------------------------------------------------
-- Registering.
------------------------------------------------------------------------------
do
  DBM:RegisterEncounter({
    nZoneMapParentId = 147,
    nZoneMapId = 148,
    sEncounterName = "KURALAK_THE_DEFILER",
    tTriggerNames = { "KURALAK_THE_DEFILER", },
    tUnits = {
      KURALAK_THE_DEFILER = Kuralak,
    },
    tCustom = {
      KURALAK_THE_DEFILER = {
        BarsCustom = {
          CULTIVATE_CORRUPTION = { color = "xkcdBrightOrange", },
          VANISH_INTO_DARKNESS = { color = "xkcdBrightPurple", },
        },
      },
    },
  })
end
