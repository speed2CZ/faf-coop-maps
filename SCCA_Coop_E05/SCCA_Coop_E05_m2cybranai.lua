local BaseManager = import('/lua/ai/opai/basemanager.lua')

local SPAIFileName = '/lua/ScenarioPlatoonAI.lua'

---------
-- Locals
---------
local Cybran = 4
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local CybranM2WBase = BaseManager.CreateBaseManager()
local CybranM2NWBase = BaseManager.CreateBaseManager()
local CybranM2NNWBase = BaseManager.CreateBaseManager()
local CybranM2NNEBase = BaseManager.CreateBaseManager()
local CybranM2NEBase = BaseManager.CreateBaseManager()

----------------------
-- Cybran M2 Main Base
----------------------
function AeonM1MainBaseAI()
    AeonM2MainBase:InitializeDifficultyTables(ArmyBrains[Cybran], 'M2_Aeon_Main_Base', 'M2_Aeon_Main_Base_Marker', 80, {M2_Aeon_Main_Base = 100})
    AeonM2MainBase:StartNonZeroBase({{4, 8, 16}, {3, 6, 12}})
    AeonM2MainBase:AddBuildGroupDifficulty("M2_Aeon_Main_Base_Expansion", 90)

    AeonM2MainBase:SetMaximumConstructionEngineers(4)

    AeonM2MainBase:SetActive('AirScouting', true)
    AeonM2MainBase:SetActive('LandScouting', true)

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


----------------
-- Cybran W Base
----------------
function CybranM2WBaseAI()
    CybranM2WBase:InitializeDifficultyTables(ArmyBrains[Cybran], "M2_Cybran_W_Base", "M2_Cybran_W_Base_Marker", 100, {W_Base_Buildings = 100})
    CybranM2WBase:StartNonZeroBase({{2, 3, 4}, {1, 2, 3}})

    CybranM2WBase:SpawnGroup("W_Base_Engineers_D" .. Difficulty)
    CybranM2WBase:SetActive("AirScouting", true)
    CybranM2WBase:SetActive("LandScouting", true)
end

----------------
-- Cybran NW Base
----------------
function CybranM2NWBaseAI()
    CybranM2NWBase:InitializeDifficultyTables(ArmyBrains[Cybran], "M2_Cybran_NW_Base", "M2_Cybran_NW_Base_Marker", 100, {NW_Base_Buildings = 100})
    CybranM2NWBase:StartNonZeroBase({{2, 3, 4}, {1, 2, 3}})

    CybranM2NWBase:SpawnGroup("NW_Base_Engineers_D" .. Difficulty)
    CybranM2NWBase:SetActive("LandScouting", true)
end

----------------
-- Cybran NNW Base
----------------
function CybranM2NNWBaseAI()
    CybranM2NNWBase:InitializeDifficultyTables(ArmyBrains[Cybran], "M2_Cybran_NNW_Base", "M2_Cybran_NNW_Base_Marker", 100, {NNW_Base_Buildings = 100})
    CybranM2NNWBase:StartNonZeroBase({{2, 3, 4}, {1, 2, 3}})

    CybranM2NNWBase:SpawnGroup("NNW_Base_Engineers_D" .. Difficulty)
    CybranM2NNWBase:SetActive("AirScouting", true)
end

----------------
-- Cybran NNE Base
----------------
function CybranM2NNEBaseAI()
    CybranM2NNEBase:InitializeDifficultyTables(ArmyBrains[Cybran], "M2_Cybran_NNE_Base", "M2_Cybran_NNE_Base_Marker", 100, {NNE_Base_Buildings = 100})
    CybranM2NNEBase:StartNonZeroBase({{2, 3, 4}, {1, 2, 3}})

    CybranM2NNEBase:SpawnGroup("NNE_Base_Engineers_D" .. Difficulty)
    CybranM2NNEBase:SetActive("AirScouting", true)
end

----------------
-- Cybran NE Base
----------------
function CybranM2NEBaseAI()
    CybranM2NEBase:InitializeDifficultyTables(ArmyBrains[Cybran], "M2_Cybran_NE_Base", "M2_Cybran_NE_Base_Marker", 100, {NE_Base_Buildings = 100})
    CybranM2NEBase:StartNonZeroBase({{2, 3, 4}, {1, 2, 3}})

    CybranM2NEBase:SpawnGroup("NE_Base_Engineers_D" .. Difficulty)
    CybranM2NEBase:SetActive("LandScouting", true)
end
