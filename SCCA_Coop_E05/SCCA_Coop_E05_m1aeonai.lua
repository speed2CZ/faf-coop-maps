local BaseManager = import('/lua/ai/opai/basemanager.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')

local SPAIFileName = '/lua/ScenarioPlatoonAI.lua'
local ThisFile = "/maps/SCCA_Coop_E05/SCCA_Coop_E05_m1aeonai.lua"
local ScriptFile = "/maps/SCCA_Coop_E05/SCCA_Coop_E05_script.lua"
local OtherArmyUnitCountBC = "/lua/editor/otherarmyunitcountbuildconditions.lua"

---------
-- Locals
---------
local Aeon = 2
local Difficulty = ScenarioInfo.Options.Difficulty

----------------
-- Base Managers
----------------
local AeonM1NukeBaseAir = BaseManager.CreateBaseManager()
local AeonM1NukeBaseLand = BaseManager.CreateBaseManager()
local AeonM1MainBase = BaseManager.CreateBaseManager()


function EnableScouting()
    AeonM1NukeBaseAir:SetActive('AirScouting', true)
    AeonM1NukeBaseLand:SetActive('LandScouting', true)
    AeonM1MainBase:SetActive('AirScouting', true)
    AeonM1MainBase:SetActive('LandScouting', true)
end

function StartAttacks()
    EnableScouting()

    AeonM1NukeBaseAirAttacks()
    AeonM1MainBaseAirAttacks()
    AeonM1MainBaseLandAttacks()
end

------------------------
-- Aeon M1 Air Nuke Base
------------------------
function AeonM1NukeBaseAirAI()
    AeonM1NukeBaseAir:InitializeDifficultyTables(ArmyBrains[Aeon], 'M1_Aeon_Air_Nuke_Base', 'M1_Aeon_Air_Nuke_Base_Marker', 40, {M1_Aeon_Air_Nuke_Base = 100})
    AeonM1NukeBaseAir:StartNonZeroBase({{4, 6, 8}, {3, 4, 5}})

    AeonM1NukeBaseAirPatrols()
end

function AeonM1NukeBaseAirPatrols()
    local opai, quantity

    quantity = {2, 3, 4}
    for i = 1, 3 do
        opai = AeonM1NukeBaseAir:AddOpAI("AirAttacks", "M1_Aeon_Nuke_Air_Base_Patrol_1_" .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Nuke_Air_Base_Patrol_Chain',
                },
                Priority = 200,
            }
        )
        opai:SetChildQuantity("AirSuperiority", quantity[Difficulty])
        opai:AddFormCallback(ThisFile, "InfiniteFuel")
    end

    if Difficulty >= 3 then
        opai = AeonM1NukeBaseAir:AddOpAI("AirAttacks", "M1_Aeon_Nuke_Air_Base_Patrol_2",
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Nuke_Air_Base_Patrol_Chain',
                },
                Priority = 190,
            }
        )
        opai:SetChildQuantity("StratBombers", 4)
        opai:AddFormCallback(ThisFile, "InfiniteFuel")
    end

    quantity = {2, 3, 4}
    for i = 1, 3 do
        opai = AeonM1NukeBaseAir:AddOpAI("AirAttacks", "M1_Aeon_Nuke_Air_Base_Patrol_3_" .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Nuke_Air_Base_Patrol_Chain',
                },
                Priority = 180,
            }
        )
        opai:SetChildQuantity("Gunships", quantity[Difficulty])
        opai:AddFormCallback(ThisFile, "InfiniteFuel")
    end
end

function AeonM1NukeBaseAirAttacks()
    local opai = AeonM1NukeBaseAir:AddOpAI('LightAirAttack', 'M1_Aeon_Nuke_Air_Base_Attack_1',
        {
            MasterPlatoonFunction = {ThisFile, 'AirSomething'},
            PlatoonData = {},
            Priority = 100,
        }
    )
end

function AirSomething(platoon)
    platoon:Patrol(ScenarioUtils.MarkerToPosition('Aeon_Main_Base_Attack_0'))
    platoon:Patrol(ScenarioUtils.MarkerToPosition('Player'))
end

-------------------------
-- Aeon M1 Land Nuke Base
-------------------------
function AeonM1NukeBaseLandAI()
    AeonM1NukeBaseLand:InitializeDifficultyTables(ArmyBrains[Aeon], 'M1_Aeon_Land_Nuke_Base', 'M1_Aeon_Land_Nuke_Base_Marker', 30, {M1_Aeon_Land_Nuke_Base = 100})
    AeonM1NukeBaseLand:StartNonZeroBase({2, 1})

    AeonM1NukeBaseLandPatrols()
end

function AeonM1NukeBaseLandPatrols()
    local opai

    opai = AeonM1NukeBaseLand:AddOpAI('HeavyLandAttack', 'M1_Aeon_LandNuke_Land_Patrol',
        {
            MasterPlatoonFunction = {SPAIFileName, 'MovePatrolThread'},
            PlatoonData = {
                PatrolChain = "M1_Aeon_Nuke_Land_Base_Patrol_Chain",
            },
            Priority = 200,
        }
    )
    opai:SetFormation("GrowthFormation")

    --local opai = AeonM1NukeBaseLand:AddOpAI('BasicLandAttack', 'M1_Aeon_LandAttack_Nuke',
    --    {
    --        MasterPlatoonFunction = {SPAIFileName, 'MovePatrolThread'},
    --        PlatoonData = {
    --            PatrolChain = "M1_Aeon_Nuke_Land_Base_Patrol_Chain",
    --            UseFormation = "AttackFormation",
    --        },
    --        Priority = 100,
    --    }
    --)
    --opai:SetChildQuantity('SiegeBots', 4)
    --opai:AddFormCallback(ThisFile, 'FixHarbs')
    --opai:SetLockingStyle("None")
end

--------------------
-- Aeon M1 Main Base
--------------------
function AeonM1MainBaseAI()
    AeonM1MainBase:InitializeDifficultyTables(ArmyBrains[Aeon], 'M1_Aeon_Main_Base', 'M1_Aeon_Main_Base_Marker', 80, {M1_Aeon_Main_Base = 100})
    AeonM1MainBase:StartNonZeroBase({{4, 8, 16}, {3, 6, 12}})
    AeonM1MainBase:AddBuildGroupDifficulty("M1_Aeon_Main_Base_Expansion", 90)

    AeonM1MainBase:SetMaximumConstructionEngineers(4)

    InitialPatrolsForAttack()
end

function InitialPatrolsForAttack()
    local brain = ArmyBrains[Aeon] --[[@as CampaignAIBrain]]
    -- Master platoon
    local Builder = {
        BuilderName = 'AM_Master_Aeon_Big_Attack',
        PlatoonTemplate = {
            'AM_Platoon_Template',
            '',
        },
        InstanceCount = 1,
        Priority = 1000,
        PlatoonType = 'Any',
        RequiresConstruction = false,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
		BuildConditions = {
			{'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildBigAeonAttack'}},
            {'/lua/editor/platooncountbuildconditions.lua', 'NumGreaterOrEqualAMPlatoons', {'AM_Master_Aeon_Big_Attack', 2 }},
		},
        PlatoonAIFunction = {SPAIFileName, 'PatrolThread'},
		PlatoonData = {
            UsePool = false,
			AMMasterPlatoon = true,
			PatrolChain = 'Aeon_Main_Base_Attack_Player',
        },
        --PlatoonBuildCallbacks = {
        --    {ScriptFile, 'UpdateM1P3'},
        --},
        PlatoonAddFunctions = {
            {ScriptFile, 'BigAeonAttackBuilt'},
            {ThisFile, "AeonM1MainBaseAirPatrols"},
            {ThisFile, "AeonM1MainBaseLandPatrols"},
        },
    }

    local spec = {}
    if Builder.BuildConditions then
        spec.AttackConditions = Builder.BuildConditions
    else
        spec.AttackConditions = {}
    end
    spec.PlatoonData = Builder.PlatoonData
    spec.Priority = Builder.Priority
    if Builder.PlatoonAIFunction then
        spec.AIThread = Builder.PlatoonAIFunction
    end
    if Builder.PlatoonAddFunctions then
        spec.FormCallbacks = Builder.PlatoonAddFunctions
    end
    if Builder.PlatoonBuildCallbacks then
        spec.DestroyCallbacks = Builder.PlatoonBuildCallbacks
    end
    spec.PlatoonType = Builder.PlatoonType
    spec.PlatoonName = Builder.BuilderName
    spec.LocationType = Builder.LocationType
    spec.BuilderName = Builder.BuilderName
    if spec.PlatoonData.UsePool ~= nil then
        spec.UsePool = spec.PlatoonData.UsePool
    end
    brain:AMAddPlatoon(spec)

    local patrolChains = {
        "M1_Aeon_Main_Base_Land_Patrol_Chain_1",
        "M1_Aeon_Main_Base_Land_Patrol_Chain_2",
        "M1_Aeon_Main_Base_Land_Patrol_Chain_3",
    }
    Builder = {
        BuilderName = 'AM_Artillery',
        PlatoonTemplate = {
            'Aeon_T1_Artillery',
            '',
            { 'UAL0103', 2, 4, 'Artillery', 'AttackFormation' },
        },
        Priority = 92,
        InstanceCount = 3,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Land',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Air_Sup_Fighters',
        PlatoonTemplate = {
            'Aeon_T3_Fighter',
            '',
            { 'UAA0303', 2, 4, 'Support', 'AttackFormation' },
        },
        Priority = 94,
        InstanceCount = 3,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Air',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
        PlatoonAddFunctions = {
            {ThisFile, "InfiniteFuel"},
        }
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Gunships',
        PlatoonTemplate = {
            'Aeon_T2_Gunship',
            '',
            { 'UAA0203', 2, 4, 'Scout', 'AttackFormation' },
        },
        Priority = 95,
        InstanceCount = 3,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Air',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
        PlatoonAddFunctions = {
            {ThisFile, "InfiniteFuel"},
        }
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Bombers',
        PlatoonTemplate = {
            'Aeon_T1_Bomber',
            '',
            { 'UAA0103', 2, 4, 'Guard', 'NoFormation' },
        },
        Priority = 94,
        InstanceCount = 3,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Air',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
        PlatoonAddFunctions = {
            {ThisFile, "InfiniteFuel"},
        }
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Interceptors',
        PlatoonTemplate = {
            'Aeon_T1_Interceptor',
            '',
            { 'uaa0102', 2, 4, 'Support', 'NoFormation' },
        },
        Priority = 3,
        InstanceCount = 10,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Air',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
        PlatoonAddFunctions = {
            {ThisFile, "InfiniteFuel"},
        }
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_AAFlak',
        PlatoonTemplate = {
            'Aeon_T2_AAFlak',
            '',
            { 'UAL0205', 2, 4, 'Attack', 'AttackFormation' },
        },
        Priority = 94,
        InstanceCount = 3,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Land',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Bots',
        PlatoonTemplate = {
            'Aeon_T3_Bot',
            '',
            { 'ual0303', 2, 4, 'Attack', 'AttackFormation' },
        },
        Priority = 95,
        InstanceCount = 4,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Land',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Tanks',
        PlatoonTemplate = {
            'Aeon_T2_Tank',
            '',
            { 'UAL0202', 2, 4, 'Attack', 'AttackFormation' },
        },
        Priority = 91,
        InstanceCount = 3,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Land',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Heavy_Artillery',
        PlatoonTemplate = {
            'Aeon_T3_Artillery',
            '',
            { 'UAL0304', 2, 4, 'Artillery', 'AttackFormation' },
        },
        Priority = 93,
        InstanceCount = 2,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Land',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Mobile_Shields',
        PlatoonTemplate = {
            'Aeon_T3_Shields',
            '',
            { 'UAL0307', 2, 4, 'Artillery', 'AttackFormation' },
        },
        Priority = 93,
        InstanceCount = 1,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Land',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Missles',
        PlatoonTemplate = {
            'Aeon_T2_Missles',
            '',
            { 'UAL0111', 2, 4, 'Artillery', 'AttackFormation' },
        },
        Priority = 93,
        InstanceCount = 3,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Land',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
    }
    brain:PBMAddPlatoon(Builder)

    Builder = {
        BuilderName = 'AM_Strat_Bombers',
        PlatoonTemplate = {
            'Aeon_T3_Bomber',
            '',
            { 'UAA0304', 2, 4, 'Guard', 'AttackFormation' },
        },
        Priority = 94,
        InstanceCount = 1,
        LocationType = 'M1_Aeon_Main_Base',
        BuildTimeOut = 240,
        PlatoonType = 'Air',
        RequiresConstruction = false,
        PlatoonAIFunction = {'/lua/ScenarioPlatoonAI.lua', 'PatrolChainPickerThread'},
        BuildConditions = {
            {'/lua/editor/miscbuildconditions.lua', 'CheckScenarioInfoVarTable', {'BuildAeonMainBasePatrols'}},
        },
        PlatoonData = {
            AMPlatoons = {'AM_Master_Aeon_Big_Attack'},
            PatrolChains = patrolChains,
        },
        PlatoonAddFunctions = {
            {ThisFile, "InfiniteFuel"},
        }
    }

    brain:PBMAddPlatoon(Builder)
end

local attackChains = {
    "Aeon_Main_Base_Attack_Player",
    "Aeon_Main_Base_Attack_Player", -- Higher chance of attacking the main base
    "Aeon_Main_Base_Attack_RF1",
    "Aeon_Main_Base_Attack_RF2",
    "Aeon_Main_Base_Attack_RF3",
}

function AeonM1MainBaseAirAttacks()
    local opai, quantity, trigger

    -- Bomber attack at each of the Research Facilities
    quantity = {2, 4, 6}
    for i = 1, 3 do
        opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Attack_1_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = "Aeon_Main_Base_Attack_RF" .. i,
                },
                Priority = 100,
            }
        )
        opai:SetChildQuantity("Bombers", quantity[Difficulty])
    end

    quantity = {4, 8, 12}
    opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Attack_2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = attackChains,
            },
            Priority = 105,
        }
    )
    opai:SetChildQuantity("Bombers", quantity[Difficulty])

    quantity = {4, 8, 12}
    trigger = {30, 20, 10}
    opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Attack_3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = attackChains,
            },
            Priority = 105,
        }
    )
    opai:SetChildQuantity("Interceptors", quantity[Difficulty])
    opai:AddBuildCondition(OtherArmyUnitCountBC, 'BrainsCompareNumCategory',
        {{'HumanPlayers'}, trigger[Difficulty], categories.AIR * categories.MOBILE, '>='})

    -- Gunship attack at each of the Research Facilities
    quantity = {2, 4, 6}
    trigger = {14, 12, 10}
    for i = 1, 3 do
        opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Attack_4_' .. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = "Aeon_Main_Base_Attack_RF" .. i,
                },
                Priority = 110,
            }
        )
        opai:SetChildQuantity("Gunships", quantity[Difficulty])
        opai:AddBuildCondition(OtherArmyUnitCountBC, 'BrainsCompareNumCategory',
            {{'HumanPlayers'}, trigger[Difficulty] + i, categories.ENGINEER * categories.TECH3, '>='})
    end

    quantity = {4, 8, 12}
    trigger = {11, 10, 9}
    opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Attack_5',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = attackChains,
            },
            Priority = 115,
        }
    )
    opai:SetChildQuantity("Gunships", quantity[Difficulty])
    opai:AddBuildCondition(OtherArmyUnitCountBC, 'BrainsCompareNumCategory',
        {{'HumanPlayers'}, trigger[Difficulty], categories.MASSEXTRACTION * categories.TECH3, '>='})

    quantity = {6, 12, 18}
    trigger = {45, 35, 25}
    opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Attack_6',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = attackChains,
            },
            Priority = 115,
        }
    )
    opai:SetChildQuantity("Interceptors", quantity[Difficulty])
    opai:AddBuildCondition(OtherArmyUnitCountBC, 'BrainsCompareNumCategory',
        {{'HumanPlayers'}, trigger[Difficulty], categories.AIR * categories.MOBILE, '>='})
end

function AeonM1MainBaseLandAttacks()
    local opai, quantity, trigger

    quantity = {4, 8, 12}
    opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Attack_1',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = attackChains,
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity("LightBots", quantity[Difficulty])

    quantity = {4, 8, 12}
    opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Attack_2',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = attackChains,
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity("LightTanks", quantity[Difficulty])

    quantity = {4, 8, 12}
    opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Attack_3',
        {
            MasterPlatoonFunction = {SPAIFileName, 'PatrolChainPickerThread'},
            PlatoonData = {
                PatrolChains = attackChains,
            },
            Priority = 100,
        }
    )
    opai:SetChildQuantity("LightArtillery", quantity[Difficulty])
end

-- Base patrols, built after big attack is launched
function AeonM1MainBaseAirPatrols()
    local opai, quantity

    quantity = {2, 4, 6}
    for i = 1, math.min(Difficulty, 2) do
        opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Patrol_1_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 250,
            }
        )
        opai:SetChildQuantity("AirSuperiority", quantity[Difficulty])
        opai:AddFormCallback(ThisFile, "InfiniteFuel")

        opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Patrol_2_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 245,
            }
        )
        opai:SetChildQuantity("StratBombers", quantity[Difficulty])
        opai:AddFormCallback(ThisFile, "InfiniteFuel")

        opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Patrol_3_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 240,
            }
        )
        opai:SetChildQuantity("Gunships", quantity[Difficulty])
        opai:AddFormCallback(ThisFile, "InfiniteFuel")

        opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Patrol_4_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 235,
            }
        )
        opai:SetChildQuantity("Interceptors", quantity[Difficulty])
        opai:AddFormCallback(ThisFile, "InfiniteFuel")

        opai = AeonM1MainBase:AddOpAI('AirAttacks', 'M1_Aeon_Main_Base_Air_Patrol_5_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 230,
            }
        )
        opai:SetChildQuantity("Bombers", quantity[Difficulty])
        opai:AddFormCallback(ThisFile, "InfiniteFuel")
    end
end

-- Base patrols, built after big attack is launched
function AeonM1MainBaseLandPatrols()
    local opai, quantity

    quantity = {2, 4, 6}
    for i = 1, Difficulty do
        opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Patrol_1_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'MovePatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 250,
            }
        )
        opai:SetChildQuantity("SiegeBots", quantity[Difficulty])

        opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Patrol_2_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 245,
            }
        )
        opai:SetChildQuantity("MobileHeavyArtillery", quantity[Difficulty])

        opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Patrol_3_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 240,
            }
        )
        opai:SetChildQuantity('HeavyTanks', quantity[Difficulty])

        opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Patrol_4_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 235,
            }
        )
        opai:SetChildQuantity("MobileShields", quantity[Difficulty])
        opai:SetFormation("NoFormation")

        opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Patrol_5_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 230,
            }
        )
        opai:SetChildQuantity("MobileFlak", quantity[Difficulty])

        opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Patrol_6_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 225,
            }
        )
        opai:SetChildQuantity("MobileMissiles", quantity[Difficulty])

        opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M1_Aeon_Main_Base_Land_Patrol_7_'.. i,
            {
                MasterPlatoonFunction = {SPAIFileName, 'PatrolThread'},
                PlatoonData = {
                    PatrolChain = 'M1_Aeon_Main_Base_Land_Patrol_Chain_' .. i,
                },
                Priority = 220,
            }
        )
        opai:SetChildQuantity("LightArtillery", quantity[Difficulty])
    end
end


function AeonM1MainBaseTransportAttacks()
    local opai = nil
    local quantity = {}
    local trigger = {}

    if true then
         opai = AeonM1MainBase:AddOpAI('LandAssault', 'M1_Aeon_Transports_Attack',
            {
                MasterPlatoonFunction = {SPAIFileName, 'LandAssaultWithTransports'},
                PlatoonData = {
                    AttackChain = 'Aeon_Transport_Attack_Chain',
                    LandingChain = 'Aeon_Transport_Landing_Chain',
                    --MoveRoute = {'M1_Aeon_Main_Base_TransportReturn'},
                    TransportReturn = 'M1_Aeon_Main_Base_TransportReturn',
                },
                Priority = 1000,
            }
        )
        opai:SetChildCountDiffTable({4, 5, 6})
        opai:SetLockingStyle("DeathTimer", {LockTimer = 240})
        --opai:SetChildrenPlatoonAI({SPAIFileName, 'PatrolThread'})
        return
    end

    -- Transport Builder
    quantity = {2, 4, 6}
    opai = AeonM1MainBase:AddOpAI('EngineerAttack', 'M1_Aeon_Transports',
        {
            MasterPlatoonFunction = {SPAIFileName, 'LandAssaultWithTransports'},
            PlatoonData = {
                MoveRoute = {'M1_Aeon_Main_Base_TransportReturn'},
            },
            Priority = 1000,
        }
    )
    opai:SetChildQuantity('T2Transports', quantity[Difficulty])
    opai:SetLockingStyle("None")
    opai:RemoveBuildCondition("NeedEngineerTransports")
    opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
        'HaveLessThanUnitsWithCategory', {8, categories.uaa0104})

    quantity = {{16, 16, 2}, {14, 16, 2}, {10, 12, 2}}
    opai = AeonM1MainBase:AddOpAI('BasicLandAttack', 'M3_UEFTransportAttack4_',
        {
            MasterPlatoonFunction = {SPAIFileName, 'LandAssaultWithTransports'},
            PlatoonData = {
                AttackChain = 'Aeon_Transport_Attack_Chain',
                LandingChain = 'Aeon_Transport_Landing_Chain',
                --MovePath = 'M3_UEF_Transport_Route_Chain',
                TransportReturn = 'M1_Aeon_Main_Base_TransportReturn',
            },
            Priority = 250,
        }
    )
    opai:SetChildQuantity({"SiegeBots", "HeavyTanks", "LightTanks"}, quantity[Difficulty])
    opai:SetLockingStyle('BuildTimer', {LockTimer = 300})
    opai:AddBuildCondition('/lua/editor/unitcountbuildconditions.lua',
        'HaveGreaterThanUnitsWithCategory', {7, categories.uaa0104})
end

---@param platoon Platoon
function InfiniteFuel(platoon)
    local brain = platoon:GetBrain()
    repeat
        ---@type AirUnit[]
        local units = platoon:GetPlatoonUnits()
        for _, unit in pairs(units) do
            if unit.Dead or not unit.Blueprint.CategoriesHash["AIR"] or unit:GetFuelRatio() > 0.2 then
                continue
            end
            unit:SetFuelRatio(1.0)

            if not unit.HasFuel then
                unit:OnGotFuel()
            end
        end

        WaitSeconds(60)
    until not brain:PlatoonExists(platoon)
end

---@param platoon Platoon
function FixHarbs(platoon)
    local units =  EntityCategoryFilterDown(categories.ual0303, platoon:GetPlatoonUnits())
    for _, unit in pairs(units) do
        unit:RemoveCommandCap("RULEUCC_Repair")
        unit:RemoveCommandCap("RULEUCC_Reclaim")
    end
end


