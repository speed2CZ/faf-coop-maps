local BaseManager = import('/lua/ai/opai/basemanager.lua')

local SPAIFileName = '/lua/ScenarioPlatoonAI.lua'

---------
-- Locals
---------
local Aeon = 2
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local AeonM2MainBase = BaseManager.CreateBaseManager()

function EnableScouting()
    AeonM2MainBase:SetActive('AirScouting', true)
    AeonM2MainBase:SetActive('LandScouting', true)
end

--------------------
-- Aeon M2 Main Base
--------------------
function AeonM2MainBaseAI()
    AeonM2MainBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M2_Aeon_Main_Base', 'M2_Aeon_Main_Base_Marker', 80, {M2_Aeon_Main_Base = 100})
    AeonM2MainBase:StartNonZeroBase({{4, 8, 16}, {3, 6, 12}})

    AeonM2MainBase:SetMaximumConstructionEngineers(4)

    AeonM2MainBaseAirPatrols()
    AeonM2MainBaseLandPatrols()
end

function AeonM2MainBaseAirPatrols()
    local opai
    local quantity = {}
    local trigger = {}
end

function AeonM2MainBaseLandPatrols()
    local opai
    local quantity = {}
    local trigger = {}
end
