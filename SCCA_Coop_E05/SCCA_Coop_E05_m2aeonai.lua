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
local AeonM2SecondaryBase = BaseManager.CreateBaseManager()

function EnableScouting()
    AeonM2MainBase:SetActive('AirScouting', true)
    AeonM2MainBase:SetActive('LandScouting', true)
end

--------------------
-- Aeon M2 Main Base
--------------------
function AeonM2MainBaseAI()
    local aiBrain = ArmyBrains[Aeon]--[[@as CampaignAIBrain]]
    AeonM2MainBase:InitializeDifficultyTables(aiBrain, 'M2_Aeon_Main_Base', 'M2_Aeon_Main_Base_Marker', 80, {M2_Aeon_Main_Base = 100})
    AeonM2MainBase:StartNonZeroBase({{4, 8, 16}, {3, 6, 12}})

    AeonM2MainBase:SetMaximumConstructionEngineers(4)

    AeonM2MainBaseAirPatrols()
    AeonM2MainBaseLandPatrols()
end

function AeonM2MainBaseAirPatrols()
    local opai
    local quantity = {}
    local trigger = {}

    opai = AeonM2MainBase:AddOpAI("AirAttacks", "M2_Aeon_Main_Base_Air_Attack_1", {
        MasterPlatoonFunction = {SPAIFileName, "PlatoonAttackHighestThreat"},
        Priority = 100,
    })
    opai:SetLockingStyle("None")
end

function AeonM2MainBaseLandPatrols()
    local opai
    local quantity = {}
    local trigger = {}

    opai = AeonM2MainBase:AddOpAI("HeavyLandAttack", "M2_Aeon_Main_Base_Land_Attack_1", {
        MasterPlatoonFunction = {SPAIFileName, "PlatoonAttackHighestThreat"},
        Priority = 100,
    })
    --opai:SetLockingStyle("None")
end

function AeonM2SecondaryBaseAI()
    local aiBrain = ArmyBrains[Aeon]--[[@as CampaignAIBrain]]
    AeonM2SecondaryBase:InitializeDifficultyTables(aiBrain, 'M2_Aeon_Secondary_Base', 'M2_Aeon_Secondary_Base_Marker', 80, {M2_Aeon_Secondary_Base = 100})
    AeonM2SecondaryBase:StartNonZeroBase({{4, 8, 16}, {3, 6, 12}})

    AeonM2SecondaryBase:SetMaximumConstructionEngineers(4)
    AeonM2SecondaryBase:SpawnGroup('M2_Aeon_Secondary_Base_Defences_D' .. Difficulty)

    AeonM2SecondaryBaseAirPatrols()
    AeonM2SecondaryBaseLandPatrols()
end

function AeonM2SecondaryBaseAirPatrols()
    local opai
    local quantity = {}
    local trigger = {}

    opai = AeonM2SecondaryBase:AddOpAI("AirAttacks", "M2_Aeon_Secondary_Base_Air_Attack_1", {
        MasterPlatoonFunction = {SPAIFileName, "PlatoonAttackHighestThreat"},
        Priority = 100,
    })
    opai:SetLockingStyle("None")
end

function AeonM2SecondaryBaseLandPatrols()
    local opai
    local quantity = {}
    local trigger = {}

    opai = AeonM2SecondaryBase:AddOpAI("HeavyLandAttack", "M2_Aeon_Secondary_Base_Land_Attack_1", {
        MasterPlatoonFunction = {SPAIFileName, "PlatoonAttackHighestThreat"},
        Priority = 100,
    })
    --opai:SetLockingStyle("None")
end
