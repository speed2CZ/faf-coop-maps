-- ****************************************************************************
-- **
-- **  File     :  /maps/SCCA_Coop_E05/SCCA_Coop_E05_script.lua
-- **  Author(s):  David Tomandl, Ruth Tomandl, speed2
-- **
-- **  Summary  :  This is the main file in control of the events during
-- **              operation E5.
-- **
-- **  Copyright © 2006 Gas Powered Games, Inc.  All rights reserved.
-- ****************************************************************************

local AIBuildStructures = import('/lua/ai/aibuildstructures.lua')
local Cinematics = import('/lua/cinematics.lua')
local Objectives = import('/lua/SimObjectives.lua')
local ScenarioFramework = import('/lua/ScenarioFramework.lua')
local Utilities = import('/lua/utilities.lua')
local ScenarioUtils = import('/lua/sim/ScenarioUtilities.lua')
local ScenarioTriggers = import('/lua/scenariotriggers.lua')
local OpStrings = import ('/maps/SCCA_Coop_E05/SCCA_Coop_E05_strings.lua') ---@module "SCCA_Coop_E05/SCCA_Coop_E05_strings"
local OpBehaviors = import('/lua/ai/opai/OpBehaviors.lua')

local M1AeonAI = import("/maps/SCCA_Coop_E05/SCCA_Coop_E05_m1aeonai.lua") ---@module "SCCA_Coop_E05/SCCA_Coop_E05_m1aeonai"
local M2AeonAI = import("/maps/SCCA_Coop_E05/SCCA_Coop_E05_m2aeonai.lua") ---@module "SCCA_Coop_E05/SCCA_Coop_E05_m2aeonai"
local M2CybranAI = import("/maps/SCCA_Coop_E05/SCCA_Coop_E05_m2cybranai.lua") ---@module "SCCA_Coop_E05/SCCA_Coop_E05_m2cybranai"


local SkipNIS1 = true

local Difficulty = ScenarioInfo.Options.Difficulty or 2

-- === Tuning Variables === #

-- Delay after start of mission, before the Aeon start attacking the player
local M1AeonWarningDelay = {240, 180, 120}
-- Delay after start of mission, before Arnold launches his first nuke
local M1AeonNukeAttackDelay = {480, 420, 360}
-- How long between Aeon main base attacks in M1
local M1AeonMainBaseAttackDelayTable = {90,30,0}
ScenarioInfo.M1AeonMainBaseAttackDelay = M1AeonMainBaseAttackDelayTable[Difficulty]
-- This is now a player fail case only. So I'm being pretty generous with time
local M1AeonTripleNukeDelay = {900, 750, 600}
-- How often to remind the player to build anti-nukes
local M1BuildAntiNukeReminderDelay = 180
-- Number of seconds after Arnold's big attack is built that the player gets warned (based on how long it takes the troops to move out of Arnold's base)
local M1AeonBigAttackWarningDelay = 120

-- Safety timer to complete M1P3, in case something happens to some of the units in it (i.e. they get stuck)
local M1AeonBigAttackSafetyTimer = 600

-- Delay after the start of M2 before LRHA start attacking the player (insurance in case the aeon dummy base isn't completely destroyed)
local M2LrhaAttackPlayerDelay = 180

-- How many seconds between reminders to move the trucks
local M3P2ReminderTimer = 120
-- How many trucks can get made in M3 by each facility
local UEFTruckGroupSizeTable = {8, 8, 8}
ScenarioInfo.UEFTruckGroupSize = UEFTruckGroupSizeTable[Difficulty]

-- How many total trucks can get made in M3 if three facilities are alive
ScenarioInfo.PotentialUEFTrucks = 3*ScenarioInfo.UEFTruckGroupSize

-- How many trucks need to be sent to earth to complete M3P2
local RequiredUEFTrucksTable = {12, 12, 12}
ScenarioInfo.RequiredUEFTrucks = RequiredUEFTrucksTable[Difficulty]

-- Delay after the LRHA bases are destroyed, before Truck 1 is spawned
ScenarioInfo.M2TruckGroup1Delay = 120 - (2*ScenarioInfo.UEFTruckGroupSize)
-- Delay after Truck 1 arrives at its destination, before Truck 2 is spawned
ScenarioInfo.M2TruckGroup2Delay = 70 --- (2*ScenarioInfo.UEFTruckGroupSize)
-- Delay after Truck 2 arrives at its destination, before Truck 3 is spawned
ScenarioInfo.M2TruckGroup3Delay = 70 --- (2*ScenarioInfo.UEFTruckGroupSize)
-- Delay between the truck warning dialogue and when the truck is spawned.
ScenarioInfo.M2TruckDialogueToSpawnDelay = 60

ScenarioInfo.Player1 = 1
ScenarioInfo.Aeon = 2
ScenarioInfo.City = 3
ScenarioInfo.Cybran = 4
ScenarioInfo.Player2 = 5
ScenarioInfo.Player3 = 6
ScenarioInfo.Player4 = 7

local Player1 = ScenarioInfo.Player1
local Player2 = ScenarioInfo.Player2
local Player3 = ScenarioInfo.Player3
local Player4 = ScenarioInfo.Player4
local Aeon = ScenarioInfo.Aeon
local City = ScenarioInfo.City
local Cybran = ScenarioInfo.Cybran

local LeaderFaction
local LocalFaction

-- === Tracking Variables === #
-- How many research facilities have been destroyed
ScenarioInfo.FacilitiesDestroyedNumber = 0
-- How many anti-nukes the player has built
ScenarioInfo.AntiNukeNumber = 0
-- How many of Arnold's nukes have been destroyed
ScenarioInfo.AeonNukesDestroyedNumber = 0
-- How many other Cybran bases have been destroyed
ScenarioInfo.CybranBasesDestroyed = 0
-- How many total trucks have been created in M3
ScenarioInfo.NumUEFTrucksAlive = 0
-- How many trucks RF1 has made
ScenarioInfo.ResearchFacility1TrucksProduced = 0
-- How many trucks RF1 has made
ScenarioInfo.ResearchFacility2TrucksProduced = 0
-- How many trucks RF1 has made
ScenarioInfo.ResearchFacility3TrucksProduced = 0
-- How many trucks in the currently active truck group have been killed
ScenarioInfo.CurrentTruckGroupTrucksLost = 0
-- How many trucks from the current group have gone through the gate
ScenarioInfo.NumCurrentGroupTrucksThroughGate = 0
-- Which truck group to start with
ScenarioInfo.CurrentTruckGroup = 1
-- How many trucks have gone back to Earth through the gate
ScenarioInfo.NumUEFTrucksThroughGate = 0
-- How many total trucks have been lost (for M3B2)
ScenarioInfo.TotalTrucksLost = 0
-- Used for truck positioning in TrucksNearGate
ScenarioInfo.TruckPosition = 1



-----------
-- Start up
-----------
function OnPopulate(scenario)
    ScenarioUtils.InitializeScenarioArmies()
    LeaderFaction, LocalFaction = ScenarioFramework.GetLeaderAndLocalFactions()

    -- Player Bases
    ScenarioUtils.CreateArmyGroup('Player1', 'Player_Main_Base_D'..Difficulty)
    ScenarioUtils.CreateArmyGroup('Player1', 'Player_RF1_Base_D'..Difficulty)
    ScenarioUtils.CreateArmyGroup('Player1', 'Player_RF2_Base_D'..Difficulty)
    ScenarioUtils.CreateArmyGroup('Player1', 'Player_RF3_Base_D'..Difficulty)
    -- Player Anti Nuke, with some ammo
    local PlayerAntiNuke = ScenarioUtils.CreateArmyUnit('Player1', 'Anti_nuke')
    PlayerAntiNuke:GiveTacticalSiloAmmo(1)

    ---@param name string
    ---@return fun(unit: Unit, instagator: Unit)
    local function facilityDamagedCallback(name)
        return function(unit, instigator)
            local damagerArmy = instigator:GetArmy()
            if (damagerArmy == Aeon) and (not ScenarioInfo[name .. "DamagedByAeonTauntPlayed"]) then
                ForkArnoldTaunt()
                ScenarioInfo[name .. "DamagedByAeonTauntPlayed"] = true
            elseif (damagerArmy == Cybran) and (not ScenarioInfo[name .. "DamagedByCybranTauntPlayed"]) then
                ForkMachTaunt()
                ScenarioInfo[name .. "DamagedByCybranTauntPlayed"] = true
            end
        end
    end

    -- Research Facilities
    for i = 1, 3 do
        local unit = ScenarioUtils.CreateArmyUnit('Player1', 'ResearchFacility' .. i)
        ScenarioInfo["ResearchFacility" .. i] = unit
        unit.CanBeGiven = false
        unit:SetReclaimable(false)
        unit:SetCustomName(LOC("{i E5_RF" .. i .. "Name}"))
        ScenarioTriggers.CreateUnitDamagedTrigger(facilityDamagedCallback("RF" .. i), unit, -1, -1)
    end
    ScenarioFramework.CreateUnitDeathTrigger(ResearchFacility1Destroyed, ScenarioInfo.ResearchFacility1)
    ScenarioFramework.CreateUnitDeathTrigger(ResearchFacility2Destroyed, ScenarioInfo.ResearchFacility2)
    ScenarioFramework.CreateUnitDeathTrigger(ResearchFacility3Destroyed, ScenarioInfo.ResearchFacility3)

    -------
    -- Aeon
    -------
    M1AeonAI.AeonM1NukeBaseAirAI()
    M1AeonAI.AeonM1NukeBaseLandAI()
    M1AeonAI.AeonM1MainBaseAI()

    ScenarioUtils.CreateArmyGroup("Aeon", "M1_Aeon_Defences_D" .. Difficulty)

    ScenarioInfo.VarTable['BuildAeonMainBasePatrols'] = true

    -- Nukes
    ScenarioInfo.AeonMainNuke = ScenarioUtils.CreateArmyUnit('Aeon', 'M1_Aeon_Main_Nuke_Launcher')
    ScenarioInfo.AeonAirNuke = ScenarioUtils.CreateArmyUnit('Aeon', 'M1_Aeon_Air_Nuke_Launcher')
    ScenarioInfo.AeonLandNuke = ScenarioUtils.CreateArmyUnit('Aeon', 'M1_Aeon_Land_Nuke_Launcher')

    local nukes = {ScenarioInfo.AeonMainNuke, ScenarioInfo.AeonAirNuke, ScenarioInfo.AeonLandNuke}
    for _, nuke in pairs(nukes) do
        nuke:GiveNukeSiloAmmo(1)
        nuke:SetCapturable(false)
        ScenarioFramework.CreateUnitDeathTrigger(M1AeonNukeHasBeenDestroyed, nuke)
    end
    -- Stop the production of nukes, as it's controlled by this script
    IssueStop(nukes)

    ScenarioUtils.CreateArmyGroup("Aeon", "M1_Aeon_Walls_D" .. Difficulty)

    ScenarioInfo.AeonMainBasePatrolUnits = ScenarioUtils.CreateArmyGroup('Aeon', 'Main_Base_Patrol_Units_D'..Difficulty)

    -- Attacks
    ScenarioInfo.AeonAirAttackPlayer = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'Aeon_First_Air_Attack_D'..Difficulty, 'ChevronFormation')
    ScenarioInfo.AeonFirstGroundAttackPlayer = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'Aeon_First_Ground_Attack_D'..Difficulty, 'AttackFormation')
    ScenarioInfo.AeonGroundAttackRF1 = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'Aeon_Initial_Ground_Attack_RF1', 'AttackFormation')
    ScenarioInfo.AeonAirAttackRF2 = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'Aeon_Initial_Air_Attack_RF2', 'ChevronFormation')
    ScenarioInfo.AeonSecondGroundAttackPlayer = ScenarioUtils.CreateArmyGroupAsPlatoon('Aeon', 'Aeon_Second_Ground_Attack_Player', 'AttackFormation')

    ------------
    -- Civilians
    ------------
    ScenarioInfo.CityBuildingsGroup = ScenarioUtils.CreateArmyGroup('City', 'City_Buildings')

    ScenarioInfo.Gate = ScenarioUtils.CreateArmyUnit('City', 'Gate')
    ScenarioInfo.Gate.CanTakeDamage = false
    ScenarioInfo.Gate.CanBeKilled = false
    ScenarioInfo.Gate:SetReclaimable(false)
    ScenarioInfo.Gate:SetCapturable(false)
    ScenarioInfo.Gate:SetUnSelectable(true)
end

function OnStart(scenario)
    ScenarioFramework.AddRestrictionForAllHumans(
        categories.ueb4302 + -- Strategic Missile Defense
        categories.ueb0304 + -- Quantum Gateway
        categories.ueb2305 + -- Nuclear Missile Launcher
        categories.uel0304 + -- Mobile Heavy Artillery
        categories.uel0301 + -- Sub Commander
        categories.ueb3104 + -- Omni Detection System
        categories.ueb2302 + -- Long Range Heavy Artillery
        categories.delk002 + -- UEF T3 Mobile AA
        categories.dea0202 + -- T2 F/B

        categories.uab4302 + -- Strategic Missile Defense
        categories.uab0304 + -- Quantum Gateway
        categories.uab2305 + -- Nuclear Missile Launcher
        categories.ual0304 + -- Mobile Heavy Artillery
        categories.ual0301 + -- Sub Commander
        categories.uab3104 + -- Omni Detection System
        categories.uab2302 + -- Long Range Heavy Artillery
        categories.dalk003 + -- Aeon M3 Mobile AA

        categories.urb4302 + -- Strategic Missile Defense
        categories.urb0304 + -- Quantum Gateway
        categories.urb2305 + -- Nuclear Missile Launcher
        categories.url0304 + -- Mobile Heavy Artillery
        categories.url0301 + -- Sub Commander
        categories.urb3104 + -- Omni Detection System
        categories.urb2302 + -- Long Range Heavy Artillery
        categories.drlk001 + -- Cybran T3 Mobile AA

        categories.PRODUCTFA + -- All FA Units

        categories.EXPERIMENTAL
    )

    ScenarioFramework.RestrictEnhancements({'TacticalNukeMissile', 'Teleporter'})

    ScenarioFramework.SetUEFColor(Player1)
    ScenarioFramework.SetAeonColor(Aeon)
    ScenarioFramework.SetCybranColor(Cybran)
    ScenarioFramework.SetNeutralColor(City)
    local colors = {
        ['Player2'] = {67, 110, 238},
        ['Player3'] = {97, 109, 126},
        ['Player4'] = {255, 255, 255}
    }
    local tblArmy = ListArmies()
    for army, color in colors do
        if tblArmy[ScenarioInfo[army]] then
            ScenarioFramework.SetArmyColor(ScenarioInfo[army], unpack(color))
        end
    end

    ScenarioFramework.SetSharedUnitCap(720)

    ScenarioFramework.SetPlayableArea('M1_PLAYABLE_AREA', false)

    IntroMission1()
end

------------
-- Mission 1
------------
function IntroMission1()
    ScenarioInfo.MissionNumber = 1

    ForkThread(IntroMission1NIS)
end

local function spawnPlayersThread()
    WaitSeconds(3)

    ScenarioInfo.PlayerCDRs = {}
    for name, _ in ScenarioInfo.HumanPlayers do
        local commander = ScenarioFramework.SpawnCommander(name, 'Commander', 'Gate', true, true, CommanderDied)
        ScenarioInfo[name .. 'CDR'] = commander
        table.insert(ScenarioInfo.PlayerCDRs, commander)

        IssueMove({commander}, ScenarioUtils.MarkerToPosition('Commander_Start_1'))
        IssueMove({commander}, ScenarioUtils.MarkerToPosition('Commander_Start_' .. name))

        WaitSeconds(2)
    end
end

function IntroMission1NIS()
    if not SkipNIS1 then
        Cinematics.EnterNISMode()

        Cinematics.CameraMoveToArea('Initial_Cam_1', 0)
        WaitSeconds(.25)
        ForkThread(spawnPlayersThread)

        Cinematics.CameraMoveToArea('Initial_Cam_2', 3)

        WaitSeconds(0.75)
        Cinematics.CameraMoveToArea('Initial_Cam_3', 2.5)

        ScenarioFramework.Dialogue(OpStrings.E05_M01_010, nil, true)
        Cinematics.CameraMoveToArea('Initial_Cam_4', 4)

        Cinematics.ExitNISMode()
    else
        ForkThread(spawnPlayersThread)
    end

    StartMission1()
end

function StartMission1()
    --------------------------------------------------
    -- Primary Objective - Protect Research Facilities
    --------------------------------------------------
    ScenarioInfo.M1P1 = Objectives.Protect(
        'primary',
        'incomplete',
        OpStrings.M1P1Title,
        OpStrings.M1P1Description,
        {
            Units = {ScenarioInfo.ResearchFacility1, ScenarioInfo.ResearchFacility2, ScenarioInfo.ResearchFacility3},
            NumRequired = 2,
        }
    )
    ScenarioInfo.M1P1:AddResultCallback(
        function(result, unit)
            if not result then
                ScenarioFramework.PlayerLose(OpStrings.E05_M01_070)
            end
        end
    )

    -- Arnold shouldn't taunt until after his presence has been revealed
    ScenarioInfo.ArnoldDontTaunt = true

    -- Warn about Aeon, either timer or LOS
    ScenarioFramework.CreateTimerTrigger(M1AeonSpotted, M1AeonWarningDelay[Difficulty])
    ScenarioFramework.CreateArmyIntelTrigger(M1AeonSpotted, ArmyBrains[Player1], 'LOSNow', false, true, categories.ALLUNITS, true, ArmyBrains[Aeon])

    ScenarioFramework.CreateTimerTrigger(M1FireAeonNuke, M1AeonNukeAttackDelay[Difficulty])
end

-- Warn the player that Aeon may attack them, assign M1S1 (protect 90% of the city)
function M1AeonSpotted()
    if ScenarioInfo.M1AeonSpotted then
        return
    end
    ScenarioInfo.M1AeonSpotted = true

    ScenarioFramework.Dialogue(OpStrings.E05_M01_020, nil, true)

    -------------------------------------
    -- Secondary Objective - Protect City
    -------------------------------------
    local cityDestroyedAmountOne = math.floor(0.1 * table.getn(ScenarioInfo.CityBuildingsGroup))
    local cityProtectAmountOne = table.getn(ScenarioInfo.CityBuildingsGroup) - cityDestroyedAmountOne
    ScenarioInfo.M1S1 = Objectives.Protect(
        'secondary',
        'incomplete',
        OpStrings.M1S1Title,
        OpStrings.M1S1Description,
        {
            Units = ScenarioInfo.CityBuildingsGroup,
            PercentProgress = true,
            NumRequired = cityProtectAmountOne,
        }
    )
    ScenarioInfo.M1S1:AddResultCallback(
        function(result)
            if not result then
                if ScenarioInfo.M1EvacThread then
                    ScenarioInfo.M1EvacThread:Destroy()
                end
            end
            ScenarioInfo.M1EvacThread = nil
        end
    )

    ForkThread(M1StartAeonAttacks)
    ScenarioInfo.M1EvacThread = ForkThread(M1EvacuateCity)
end

local function gateOutTruck(truck)
    ScenarioFramework.FakeTeleportUnit(truck, true)
end

function M1EvacuateCity()
    WaitSeconds(90)

    local gate = ScenarioInfo.Gate
    local gatePosition = gate:GetPosition()
    local chains = {
        "Evacuation_Chain_1",
        "Evacuation_Chain_2",
        "Evacuation_Chain_3",
        "Evacuation_Chain_4",
        "Evacuation_Chain_5",
    }

    ---@type table<MarkerName, ChainName>
    local markerToChain = {}
    ---@type table<MarkerName, Marker>
    local markers = {}
    for _, chainName in pairs(chains) do
        for _, markerName in pairs(ScenarioUtils.GetMarkerChain(chainName).Markers) do
            local marker = ScenarioUtils.GetMarker(markerName)
            markers[markerName] = marker
            -- One marker can belong to multiple chains, which overrides here, but its not a problem
            -- since all the chains are designed so that they continue the same path after same marker
            markerToChain[markerName] = chainName
        end
    end

    ---@param position Vector
    ---@return MarkerName
    local function getClosestMarker(position)
        local name
        local closest
        for markerName, marker in pairs(markers) do
            local distance = Utilities.XZDistanceTwoVectors(position, marker.position)
            if not closest or distance < closest then
                name = markerName
                closest = distance
            end
        end

        return name
    end

    ---@param markerName MarkerName
    ---@return Vector[]
    local function getRouteFromMarker(markerName)
        local chainName = markerToChain[markerName]
        local chain = ScenarioUtils.GetMarkerChain(chainName).Markers
        local route = {}
        local found = false
        for _, mName in ipairs(chain) do
            if mName == markerName then
                found = true
            end

            if found then
                table.insert(route, markers[mName].position)
            end
        end

        return route
    end

    ---@param position Vector
    ---@return Vector[]
    local function getClosestRoute(position)
        local markerName = getClosestMarker(position)
        return getRouteFromMarker(markerName)
    end

    local start = GetGameTimeSeconds()
    LOG("Starting city evacuation")

    local buildingToTruckCount = {
        uec1101 = 5, -- residential
        uec1201 = 3, -- science
        uec1301 = 2, -- administrative
        uec1401 = 4, -- agriculture
        uec1501 = 3, -- manufacturing
    }

    for _, building in RandomIter(ScenarioInfo.CityBuildingsGroup) do
        if building.Dead then continue end

        local pos = building:GetPosition()
        local truckCount = buildingToTruckCount[building.UnitId] or 2

        for _ = 1, truckCount do
            local x, y, z = pos.x + Random(1, 2), pos.y, pos.z + Random(1, 2)
            local truck = CreateUnitHPR("uec0001", "City", x, y, z, Random(0, 360), 0, 0)
            local route = getClosestRoute(pos)
            for _, rPos in ipairs(route) do
                IssueToUnitMove(truck, rPos)
            end
            IssueToUnitMove(truck, gatePosition)
            ScenarioTriggers.CreateUnitToPositionDistanceTrigger(gateOutTruck, truck, gatePosition, 4.5)
            WaitTicks(Random(8, 28))

            if building.Dead then continue end
        end

        WaitSeconds(Random(7, 13))
    end

    LOG("Last truck left building after:", GetGameTimeSeconds() - start)
    local trucks = ArmyBrains[City]:GetListOfUnits(categories.uec0001, false)
    local allDead = false
    repeat
        WaitSeconds(5)

        allDead = true
        for _, truck in pairs(trucks) do
            if not IsDestroyed(truck) then
                allDead = false
                break
            end
        end
    until allDead

    LOG("Last truck left the planet after:", GetGameTimeSeconds() - start)

    -- If more than 10% of the town wasn't destroyed in M1, then the town was saved!
    if ScenarioInfo.M1S1.Active then
        ScenarioInfo.M1S1:ManualResult(true)
    end
end

function M1StartAeonAttacks()
    --M1AeonAI.StartAttacks()

    ScenarioInfo.AeonAirAttackPlayer:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition('Gate_Position'))
    ScenarioInfo.AeonFirstGroundAttackPlayer:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition('Player'))
    WaitSeconds(30)

    ScenarioInfo.AeonGroundAttackRF1:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition('Research_Facility_1'))
    WaitSeconds(30)
    ScenarioInfo.AeonAirAttackRF2:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition('Research_Facility_2'))

    WaitSeconds(30)
    ScenarioInfo.AeonSecondGroundAttackPlayer:AggressiveMoveToLocation(ScenarioUtils.MarkerToPosition('Player'))
end

function OnNukeShotDown()
    if ScenarioInfo.M1FirstNukeDown then
        return
    end
    ScenarioInfo.M1FirstNukeDown = true

    ScenarioFramework.Dialogue(OpStrings.E05_M01_030, M1AssignBuildAntiNukeObjective, true)
end

-- Fire the Aeon nuke at the player's outpost
function M1FireAeonNuke()
    if ScenarioInfo.M1AeonNukeFired then
        return
    end
    ScenarioInfo.M1AeonNukeFired = true

    local nuke = ScenarioInfo.AeonMainNuke
    nuke:GiveNukeSiloAmmo(1)
    nuke:AddProjectileDamagedCallback(OnNukeShotDown)
    IssueNuke({nuke}, ScenarioUtils.MarkerToPosition('Aeon_Nuke_Target'))

    -- The first time the player gets line of sight on a nuke launcher, play an Arnold taunt
    ScenarioFramework.CreateArmyIntelTrigger(ForkArnoldTaunt, ArmyBrains[Player1], 'LOSNow', false, true, categories.uab2305, true, ArmyBrains[Aeon])

    ScenarioFramework.CreateTimerTrigger(FirstNukeNIS, 5)
end

function FirstNukeNIS()
    -- NIS for the first nuke. Change delay on timer trigger which calls this nis to start the NIS at a good
    -- point during the launch process.
    local nuke = ScenarioInfo.AeonMainNuke
    if nuke.Dead then
        return
    end

    local camInfo = {
        blendTime = 1.0,
        holdTime = 8,
        orientationOffset = { 2.3, 0.2, 0 },
        positionOffset = { 0, 1, 0 },
        zoomVal = 30,
        vizRadius = 8,
    }
    ScenarioFramework.OperationNISCamera(nuke, camInfo)
end

---@param callback function
---@param area string
local function siloAmmoThread(callback, area)
    local rect = ScenarioUtils.AreaToRect(area)
    local cats = categories.SILO * categories.ANTIMISSILE

    while true do
        local units = ScenarioFramework.GetListOfHumanUnits(cats, rect)

        for _, v in pairs(units) do
            if not v.Dead and v:GetTacticalSiloAmmoCount() > 0 then
                callback()
                return
            end
        end

        WaitSeconds(1)
    end
end

-- Check for M1P2 success (Create two missle defenses next to research facilities)
local function missileDefenseCreated()
    if not ScenarioInfo.M1P2.Active then
        return
    end

    if ScenarioInfo.AntiNukeNumber < 3 then
        ScenarioInfo.AntiNukeNumber = ScenarioInfo.AntiNukeNumber + 1
    end

    -- Update objective text
    Objectives.UpdateBasicObjective(ScenarioInfo.M1P2, 'progress', LOCF(OpStrings.M1P2Progress, ScenarioInfo.AntiNukeNumber))

    -- Check for objective completion
    if ScenarioInfo.AntiNukeNumber >= 2 and not ScenarioInfo.MissionFailed then
        ScenarioInfo.M1P2:ManualResult(true)
    end
end

function M1AssignBuildAntiNukeObjective()
    -- Give the player access to anti-nukes
    ScenarioFramework.RemoveRestrictionForAllHumans(categories.ueb4302 + categories.uab4302 + categories.urb4302, true)

    ScenarioFramework.Dialogue(OpStrings.E05_M01_040, nil, true)

    local areas = {'AntiNuke_Area_1', 'AntiNuke_Area_2', 'AntiNuke_Area_3'}
    --------------------------------------
    -- Primary Objective - Build Anti-Nuke
    --------------------------------------
    ScenarioInfo.M1P2 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M1P2Title,
        OpStrings.M1P2Description,
        Objectives.GetActionIcon('build'),
        {
            Areas = areas,
            MarkArea = true,
        }
    )
    ScenarioInfo.M1P2:AddResultCallback(
        function(result)
            if result then
                M1AeonTripleNukeAttack()

                M1AeonAI.AeonM1MainBaseTransportAttacks()
            end
        end
    )

    ScenarioInfo.M1Objectives = Objectives.CreateGroup('Mission1', EndMission1, 3)
    ScenarioInfo.M1Objectives:AddObjective(ScenarioInfo.M1P2)

    for _, name in pairs(areas) do
        ForkThread(siloAmmoThread, missileDefenseCreated, name)
    end

    ScenarioFramework.CreateTimerTrigger(M1AeonTripleNukeAttack, M1AeonTripleNukeDelay[Difficulty])
    ScenarioFramework.CreateTimerTrigger(M1P2Reminder, M1BuildAntiNukeReminderDelay)
end

-- Remind the player to build anti-nukes
function M1P2Reminder()
    ScenarioInfo.NextM1P2Reminder = 1

    while ScenarioInfo.M1P2.Active and not ScenarioInfo.OpEnded do
        if ScenarioInfo.NextM1P2Reminder == 1 then
            ScenarioFramework.Dialogue(OpStrings.E05_M01_100)
            ScenarioInfo.NextM1P2Reminder = 2
        elseif ScenarioInfo.NextM1P2Reminder == 2 then
            ScenarioFramework.Dialogue(OpStrings.E05_M01_105)
            ScenarioInfo.NextM1P2Reminder = 1
        end

        WaitSeconds(M1BuildAntiNukeReminderDelay)
    end
end

-- Keeps sending nukes to player
local function aeonContinuedNukeAttacks()
    while true do
        WaitSeconds(Random(300, 480))

        local nukeSiloTable = ArmyBrains[Aeon]:GetListOfUnits(categories.uab2305, false)
        if table.empty(nukeSiloTable) then
            return
        end

        local nukeTargetTable = ScenarioFramework.GetListOfHumanUnits(categories.STRUCTURE - categories.ECONOMIC, false)
        if table.empty(nukeTargetTable) then
            continue
        end

        local rndNuke = table.random(nukeSiloTable)
        local rndTarget = table.random(nukeTargetTable)
        rndNuke:GiveNukeSiloAmmo(1)
        IssueNuke({rndNuke}, rndTarget)
    end
end

-- Launch three nukes at player
local function aeonTripleNukeAttackThread()
    if not ScenarioInfo.AeonMainNuke.Dead then
        ScenarioInfo.Nuke1Target = ScenarioUtils.MarkerToPosition('Research_Facility_2')
        IssueNuke({ ScenarioInfo.AeonMainNuke }, ScenarioInfo.Nuke1Target)
    end

    if not ScenarioInfo.AeonAirNuke.Dead then
        ScenarioInfo.Nuke2Target = ScenarioUtils.MarkerToPosition('Research_Facility_3')
        IssueNuke({ ScenarioInfo.AeonAirNuke }, ScenarioInfo.Nuke2Target)
    end

    if not ScenarioInfo.AeonLandNuke.Dead then
        ScenarioInfo.Nuke3Target = ScenarioUtils.MarkerToPosition('Research_Facility_1')
        IssueNuke({ ScenarioInfo.AeonLandNuke }, ScenarioInfo.Nuke3Target)
    end

    if Difficulty == 3 then
        ForkThread(aeonContinuedNukeAttacks)
    end

    -- Arnold sends a big attack
    -- Matt send it here to cover the case of all 3 laucher down early
    WaitSeconds(60)

    -- assign here instead of after big attack, better flow.
    if not ScenarioInfo.M1P4 then
        M1DestroyNukesObjective()
    end

    ScenarioFramework.CreateTimerTrigger(M1LaunchBigAeonAttack, M1AeonBigAttackWarningDelay)
end

function M1AeonTripleNukeAttack()
    if ScenarioInfo.TripleNukesLaunched then
        return
    end

    ScenarioInfo.TripleNukesLaunched = true
    ScenarioFramework.Dialogue(OpStrings.E05_M01_050, aeonTripleNukeAttackThread, true)
end

-- Arnold sends a big attack
function M1LaunchBigAeonAttack()
    ScenarioInfo.ArnoldDontTaunt = false

    -- Tell the AM Master platoon to build
    ScenarioInfo.VarTable['BuildBigAeonAttack'] = true
end

---@param platoon Platoon
function BigAeonAttackBuilt(platoon)
    ScenarioInfo.VarTable['BuildBigAeonAttack'] = false

    ScenarioFramework.Dialogue(OpStrings.E05_M01_060, nil, true)

    --------------------------------------------
    -- Primary Objective - Repel Arnold's attack
    --------------------------------------------
    ScenarioInfo.M1P3 = Objectives.Kill(
        'primary',
        'incomplete',
        OpStrings.M1P3Title,
        OpStrings.M1P3Description,
        {
            Units = platoon:GetPlatoonUnits(),
            --MarkUnits = false,
            ShowProgress = false,
        }
    )
    ScenarioInfo.M1P3:AddResultCallback(ForkArnoldTaunt)
    ScenarioInfo.M1Objectives:AddObjective(ScenarioInfo.M1P3)
end

-- Assign M1P4 (Destroy all three of Arnold's nuke launchers.)
function M1DestroyNukesObjective()
    ScenarioFramework.Dialogue(OpStrings.E05_M01_065, nil, true)

    ---------------------------------------------
    -- Primary Objective - Destroy Arnold's nukes
    ---------------------------------------------
    ScenarioInfo.M1P4 = Objectives.Kill(
        'primary',
        'incomplete',
        OpStrings.M1P4Title,
        OpStrings.M1P4Description,
        {
            Units = {ScenarioInfo.AeonMainNuke, ScenarioInfo.AeonAirNuke, ScenarioInfo.AeonLandNuke},
            FlashVisible = true,
            ShowProgress = true,
        }
    )
    ScenarioInfo.M1P4:AddResultCallback(
        function(result)
            ScenarioFramework.Dialogue(OpStrings.TAUNT15)
        end
    )
    ScenarioInfo.M1Objectives:AddObjective(ScenarioInfo.M1P4)

    -- Remind the player to do M1P4 after M1P4InitialReminderTimer
    ScenarioInfo.NextM1P4Reminder = 1
    ScenarioFramework.CreateTimerTrigger(M1P4Reminder, 900)
end

-- Remind the player to destroy Arnold's nukes
function M1P4Reminder()
    while ScenarioInfo.M1P4.Active do
        if ScenarioInfo.NextM1P4Reminder == 1 and not ScenarioInfo.OpEnded then
            ScenarioFramework.Dialogue(OpStrings.E05_M01_110)
            ScenarioInfo.NextM1P4Reminder = 2
        elseif ScenarioInfo.NextM1P4Reminder == 2 and not ScenarioInfo.OpEnded then
            ScenarioFramework.Dialogue(OpStrings.E05_M01_115)
            ScenarioInfo.NextM1P4Reminder = 1
        end
        WaitSeconds(600)
    end
end

-- If an aeon nuke is destroyed, assign M1P4.
function M1AeonNukeHasBeenDestroyed(unit)
    -- If M1P4 hasn't been assigned yet, assign it.
    if not ScenarioInfo.M1P4 then
        M1DestroyNukesObjective()
    end
    -- base Aeon nuke launcher destroyed cam
    local camInfo = {
        blendTime = 1.0,
        holdTime = 4,
        orientationOffset = { 0, 0.4, 0 },
        positionOffset = { 0, 0.5, 0 },
        zoomVal = 55,
    }
    if unit == ScenarioInfo.AeonMainNuke then
        camInfo.orientationOffset[1] = -2.3
    elseif unit == ScenarioInfo.AeonAirNuke then
        camInfo.orientationOffset[1] = -1.17
    elseif unit == ScenarioInfo.AeonLandNuke then
        camInfo.orientationOffset[1] = -2.3
    end

    ScenarioFramework.OperationNISCamera(unit, camInfo)
end

local function onResearchFacilityDead(unit)
    ScenarioInfo.FacilitiesDestroyedNumber = ScenarioInfo.FacilitiesDestroyedNumber + 1

    if ScenarioInfo.MissionNumber == 3 then
        CheckM3P1()
    end

    ForkThread(ResearchFacilityDestroyedNISCamera, unit, ScenarioInfo.FacilitiesDestroyedNumber)
end

function ResearchFacility1Destroyed(unit)
    -- The trucks that were still in the factory will never be produced now.
    ScenarioInfo.PotentialUEFTrucks = ScenarioInfo.PotentialUEFTrucks - (ScenarioInfo.UEFTruckGroupSize - ScenarioInfo.ResearchFacility1TrucksProduced)

    onResearchFacilityDead(unit)
end

function ResearchFacility2Destroyed(unit)
    -- The trucks that were still in the factory will never be produced now.
    ScenarioInfo.PotentialUEFTrucks = ScenarioInfo.PotentialUEFTrucks - (ScenarioInfo.UEFTruckGroupSize - ScenarioInfo.ResearchFacility2TrucksProduced)

    onResearchFacilityDead(unit)
end

function ResearchFacility3Destroyed(unit)
    -- The trucks that were still in the factory will never be produced now.
    ScenarioInfo.PotentialUEFTrucks = ScenarioInfo.PotentialUEFTrucks - (ScenarioInfo.UEFTruckGroupSize - ScenarioInfo.ResearchFacility3TrucksProduced)

    onResearchFacilityDead(unit)
end

-- Check for all primary objectives complete
function EndMission1()
    ScenarioFramework.Dialogue(OpStrings.E05_M01_080, nil, true)

    WaitSeconds(2)
    ScenarioInfo.M1P1:ManualResult(true)

    IntroMission2()
end

------------
-- Mission 2
------------
function IntroMission2()
    ScenarioInfo.MissionNumber = 2

    ---------
    -- Cybran
    ---------
    -- Spawn the Cybran LRA bases and the M2 Aeon bases
    ScenarioInfo.CybranLRA1BaseBuildings = ScenarioUtils.CreateArmyGroup('Cybran', 'LRA1_Base_Buildings_D'..Difficulty)
    ScenarioInfo.CybranLRA2BaseBuildings = ScenarioUtils.CreateArmyGroup('Cybran', 'LRA2_Base_Buildings_D'..Difficulty)
    ScenarioInfo.CybranLRA1 = ScenarioUtils.CreateArmyUnit('Cybran', 'Cybran_LRA_1')
    ScenarioInfo.CybranLRA2 = ScenarioUtils.CreateArmyUnit('Cybran', 'Cybran_LRA_2')

    -------
    -- Aeon
    -------
    M2AeonAI.AeonM2MainBaseAI()

    ScenarioUtils.CreateArmyGroup('Aeon', 'M2_Aeon_Walls_D'..Difficulty)

    -- Arnold
    ScenarioInfo.AeonCDR = ScenarioFramework.SpawnCommander('Aeon', 'Commander_Arnold', nil, LOC('{i CDR_Arnold}'), false, nil,
        {'AdvancedEngineering', 'ChronoDampener', 'CrysalisBeam', 'ShieldHeavy'})
    -- If Arnold is killed, make him disappear.
    ScenarioInfo.AeonCDR.OnKilled = function(self, instigator, type, overkillRatio)
        AeonCDRDamaged(instigator)
    end

    -- Overcharge manager for Arnold
    ScenarioInfo.AeonCDR.CDRData = {}
    ScenarioInfo.AeonCDR.CDRData.LeashPosition = 'M2_Aeon_Main_Base_Marker'
    ScenarioInfo.AeonCDR.CDRData.LeashRadius = 30
    ScenarioInfo.AeonCDR.OverchargeThread = ScenarioInfo.AeonCDR:ForkThread(OpBehaviors.CDROverChargeThread)
    ScenarioInfo.AeonCDR.LeashThread      = ScenarioInfo.AeonCDR:ForkThread(OpBehaviors.CDRLeashThread)
    ScenarioInfo.AeonCDR.RunAwayThread    = ScenarioInfo.AeonCDR:ForkThread(OpBehaviors.CDRRunAwayThread)

    -- Tell the LRA bases to start shelling the Aeon
    IssueAttack({ScenarioInfo.CybranLRA1}, ScenarioUtils.MarkerToPosition('LRA1_Aeon_Target'))
    IssueAttack({ScenarioInfo.CybranLRA2}, ScenarioUtils.MarkerToPosition('LRA2_Aeon_Target'))

    -- Start attacks between Cybran and Aeon
    ScenarioInfo.VarTable['BuildCybranM2AeonAttack'] = true
    ScenarioInfo.VarTable['BuildAeonSecondBasePatrols'] = true

    ScenarioFramework.RemoveRestrictionForAllHumans(
        categories.ueb3104 + -- Omni Radar
        categories.uab3104 + -- Omni Radar
        categories.urb3104 + -- Omni Radar

        categories.ueb0304 + -- Quantum Gateway
        categories.uel0304 + -- Mobile Heavy Artillery
        categories.uel0301 + -- Sub Commander

        categories.uab0304 + -- Quantum Gateway
        categories.ual0304 + -- Mobile Heavy Artillery
        categories.ual0301 + -- Sub Commander

        categories.urb0304 + -- Quantum Gateway
        categories.url0304 + -- Mobile Heavy Artillery
        categories.url0301   -- Sub Commander
    )

    -- Expand the map area
    ScenarioFramework.SetPlayableArea('M2_PLAYABLE_AREA', true)

    StartMission2()
end

function StartMission2()
    ScenarioInfo.MachDontTaunt = true

    local researchFacilitiesGroup = {ScenarioInfo.ResearchFacility1, ScenarioInfo.ResearchFacility2, ScenarioInfo.ResearchFacility3}
    --------------------------------------------------
    -- Primary Objective - Protect Research Facilities
    --------------------------------------------------
    ScenarioInfo.M2P1 = Objectives.Protect(
        'primary',
        'incomplete',
        OpStrings.M2P1Title,
        OpStrings.M2P1Description,
        {
            Units = researchFacilitiesGroup,
            NumRequired = 2,
            ShowProgress = true,
        }
    )
    ScenarioInfo.M2P1:AddResultCallback(
        function(result, unit)
            if not result then
                ScenarioFramework.PlayerLose(OpStrings.E05_M01_070)
            end
        end
    )

        -- Keep track of the Cybran LRHA
    ScenarioFramework.CreateUnitDeathTrigger(CybranLRHADestroyed, ScenarioInfo.CybranLRA1)
    ScenarioFramework.CreateUnitDeathTrigger(CybranLRHADestroyed, ScenarioInfo.CybranLRA2)

    -- Spawn 5 Cybran bases
    M2CybranAI.CybranM2WBaseAI()
    M2CybranAI.CybranM2NWBaseAI()
    M2CybranAI.CybranM2NNWBaseAI()
    M2CybranAI.CybranM2NNEBaseAI()
    M2CybranAI.CybranM2NEBaseAI()

    ScenarioUtils.CreateArmyGroup('Cybran', 'Cybran_Walls_D'..Difficulty)

    -- Spawn Cybran commander
    ScenarioInfo.CybranCDR = ScenarioFramework.SpawnCommander('Cybran', 'Commander', nil, LOC('{i CDR_Mach}'), true, CybranCDRKilled,
        {'AdvancedEngineering', 'MicrowaveLaserGenerator', 'CloakingGenerator'})

    -- Spawn Aeon dummy base to get targeted by LRHA base 2
    ScenarioInfo.AeonDummyBase = ScenarioUtils.CreateArmyGroup('Aeon', 'Aeon_Dummy_Base')
    -- Once the Aeon dummy base is dead, LRHA start shelling the player
    ScenarioFramework.CreateGroupDeathTrigger(StartMission2Part2, ScenarioInfo.AeonDummyBase)
    ScenarioFramework.CreateTimerTrigger(StartMission2Part2, M2LrhaAttackPlayerDelay)

    -- If the second Aeon base gets destroyed, the W Cybran Base should attack the player
    ScenarioFramework.CreateAreaTrigger(AeonSecondBaseKilled, ScenarioUtils.AreaToRect('Aeon_Second_Base_Area'),
        categories.STRUCTURE - categories.WALL, true, true, ArmyBrains[Aeon], 1)

    -- Mach taunts when you see his attacking units
    ScenarioFramework.CreateArmyIntelTrigger(ForkMachTaunt, ArmyBrains[Player1], 'LOSNow', false, true, categories.MOBILE, true, ArmyBrains[Cybran])
end

-- Arnold disappears instead of dying.
function AeonCDRDamaged(instigator)
    local damagerArmy = instigator:GetArmy()
    if damagerArmy == Player1 then
        ScenarioFramework.Dialogue(OpStrings.E05_M03_140)
    end

    ForkThread(function()
        -- Start NIS of focused on Arnold, and teleport him out
        ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.AeonCDR, 7)
        ScenarioFramework.FakeTeleportUnit(ScenarioInfo.AeonCDR, true)
    end)
    ScenarioInfo.ArnoldDead = true
end

-- If Mach is killed, play a dialogue and set his death variable
function CybranCDRKilled(unit)
    ScenarioFramework.Dialogue(OpStrings.E05_M02_030)
    ScenarioInfo.MachDead = true

    -- NIS of the Cybran commander being killed
    ScenarioFramework.CDRDeathNISCamera(unit, 7)
end

-- The secondary Aeon base has been destroyed. The West Cybran base should now attack the player (taken care of in Attack Manager)
function AeonSecondBaseKilled()
    ScenarioInfo.VarTable['BuildCybranM2AeonAttack'] = false
    ScenarioInfo.VarTable['BuildCybranWM2PlayerAttack'] = true
end

-- After the dummy Aeon base is destroyed, have the LRHA attack the player and assign M2P2.
function StartMission2Part2()
    ScenarioInfo.MachDontTaunt = false
    -- Start Cybran attacks against the player
    ScenarioInfo.VarTable['BuildCybranPlayerAttacks'] = true
    ScenarioInfo.VarTable['BuildAeonSecondBasePatrols'] = false

    if ScenarioInfo.StartMission2Part2Ran then
        return
    end

    ScenarioInfo.StartMission2Part2Ran = true

    ScenarioFramework.Dialogue(OpStrings.E05_M02_010, nil, true)

    if Difficulty == 3 then
        -- Let LRHAs shell whatever they want on hard
        IssueClearCommands({ScenarioInfo.CybranLRA1})
        IssueClearCommands({ScenarioInfo.CybranLRA2})
    elseif Difficulty == 2 then
        -- Have LRHAs shell Aeon base and near a research facility on medium
        IssueClearCommands({ScenarioInfo.CybranLRA1})
        IssueAttack({ScenarioInfo.CybranLRA1}, ScenarioUtils.MarkerToPosition('LRA1_Player_Target_Medium'))
    else
        -- Have LRHAs shell aeon base and non-essential buildings on easy
        IssueClearCommands({ScenarioInfo.CybranLRA1})
        IssueAttack({ScenarioInfo.CybranLRA1}, ScenarioUtils.MarkerToPosition('LRA1_Player_Target_Easy'))
    end

    -- Show the LRA bases to the player
    ScenarioFramework.CreateVisibleAreaLocation(50, ScenarioUtils.MarkerToPosition('Cybran_LRA_Base_1'), 40, ArmyBrains[Player1])
    ScenarioFramework.CreateVisibleAreaLocation(50, ScenarioUtils.MarkerToPosition('Cybran_LRA_Base_2'), 40, ArmyBrains[Player1])

    -- Assign M2P2 (Take out cybran LRA bases)
    ScenarioFramework.Dialogue(OpStrings.E05_M02_020, M2DestroyArtyObjective, true)
end

function M2DestroyArtyObjective()
    -----------------------------------------------
    -- Primary Objective - Destroy Cybran Artillery
    -----------------------------------------------
    ScenarioInfo.M2P2 = Objectives.KillOrCapture(
        'primary',
        'incomplete',
        OpStrings.M2P2Title,
        OpStrings.M2P2Description,
        {
            Units = {ScenarioInfo.CybranLRA1, ScenarioInfo.CybranLRA2},
        }
    )
    ScenarioInfo.M2P2:AddResultCallback(
        function(result)
            ScenarioInfo.M2P2Complete = true
            ScenarioFramework.Dialogue(OpStrings.E05_M02_040, nil, true)
            ScenarioFramework.Dialogue(OpStrings.E05_M03_010, IntroMission3, true)
        end
    )

    -- Remind the player to do M2P2
    ScenarioInfo.NextM2P2Reminder = 1
    ScenarioFramework.CreateTimerTrigger(M2P2Reminder, 600)

    -- Give the player access to nukes
    ScenarioFramework.RemoveRestrictionForAllHumans(categories.ueb2305 + categories.uab2305 + categories.urb2305)
end

-- If the player kills an LRHA early, run Mission2 Part 2.
function CybranLRHADestroyed(unit)
    if not ScenarioInfo.StartMission2Part2Ran then
        StartMission2Part2()
    end

    -- base cybran LRA destroyed cam
    local camInfo = {
        blendTime = 1.0,
        holdTime = 4,
        orientationOffset = { 0, 0.2, 0 },
        positionOffset = { 0, 0.5, 0 },
        zoomVal = 40,
    }
    if unit == ScenarioInfo.CybranLRA1 then
        camInfo.orientationOffset = { -0.7, 0.8, 0 }
    elseif unit == ScenarioInfo.CybranLRA2 then
        camInfo.orientationOffset[1] = 2.3
    end
    ScenarioFramework.OperationNISCamera(unit, camInfo)
end

-- Remind the player to do M2P2
function M2P2Reminder()
    while not ScenarioInfo.M2P2Complete do
        if ScenarioInfo.NextM2P2Reminder == 1 and not ScenarioInfo.OpEnded then
            ScenarioFramework.Dialogue(OpStrings.E05_M02_050)
            ScenarioInfo.NextM2P2Reminder = 2
        elseif ScenarioInfo.NextM2P2Reminder == 2 and not ScenarioInfo.OpEnded then
            ScenarioFramework.Dialogue(OpStrings.E05_M02_055)
            ScenarioInfo.NextM2P2Reminder = 1
        end
        WaitSeconds(600)
    end
end

------------
-- Mission 3
------------
function IntroMission3()
    ScenarioInfo.MissionNumber = 3

    ScenarioFramework.SetSharedUnitCap(1000)

    ScenarioFramework.SetPlayableArea('M3_PLAYABLE_AREA')

    StartMission3()
end

function StartMission3()
    -- Get ready to spawn truck group 1
    ForkThread(CreateTruckGroup)

    -- Matt 11/20/06: this is almost certainly a bad idea. But I'm combining the 2 obectives below.
    ScenarioInfo.M3P1 = ScenarioInfo.M2P1
    -- updating the description doesnt seem to work, and they're pretty similar, so keep m2 desc.
    -- Objectives.UpdateObjective(ScenarioInfo.M3P1.Title, 'description', OpStrings.M3P1Description, ScenarioInfo.M3P1.Tag)

    ------------------------------------------
    -- Primary Objective - Move trucks to gate
    ------------------------------------------
    ScenarioInfo.M3P2 = Objectives.Basic(
        'primary',
        'incomplete',
        OpStrings.M3P2Title,
        LOCF(OpStrings.M3P2Description, ScenarioInfo.RequiredUEFTrucks),
        Objectives.GetActionIcon('move'),
        {
            Area = 'Gate_Area',
            MarkArea = true, -- Todo: Change this to mark the quantum gate when that's in
            -- Units = {ScenarioInfo.Gate},
            -- MarkUnits = true,
        }
    )
    ScenarioInfo.M3P2:AddResultCallback(
        function(result)
            local camInfo = {
                blendTime = 1.0,
                holdTime = 4,
                orientationOffset = { -2.2, 0.9, 0 },
                positionOffset = { 0, 0.5, 0 },
                zoomVal = 40,
                markerCam = true,
            }
            ScenarioFramework.OperationNISCamera(ScenarioUtils.MarkerToPosition("Gate_Position"), camInfo)
        end
    )

    ScenarioFramework.CreateAreaTrigger(SendTruckThroughGate, 'CDR_Gate_Area',
        categories.uec0001, false, false, ArmyBrains[ScenarioInfo.Player1], 1, true)

    -------------------------------------------
    -- Primary Objective - Destroy Cybran bases
    -------------------------------------------
    ScenarioInfo.M3S1 = Objectives.CategoriesInArea(
        'secondary',
        'incomplete',
        OpStrings.M3S1Title,
        OpStrings.M3S1Description,
        'kill',
        {
            ShowFaction = 'Cybran',
            MarkArea = true,
            Requirements = {
                {Area = 'Cybran_W_Base_Area', Category = categories.STRUCTURE - categories.WALL, CompareOp = '<=', Value = 0, ArmyIndex = Cybran},
                {Area = 'Cybran_NE_Base_Area', Category = categories.STRUCTURE - categories.WALL, CompareOp = '<=', Value = 0, ArmyIndex = Cybran},
                {Area = 'Cybran_NNE_Base_Area', Category = categories.STRUCTURE - categories.WALL, CompareOp = '<=', Value = 0, ArmyIndex = Cybran},
                {Area = 'Cybran_NNW_Base_Area', Category = categories.STRUCTURE - categories.WALL, CompareOp = '<=', Value = 0, ArmyIndex = Cybran},
                {Area = 'Cybran_NW_Base_Area', Category = categories.STRUCTURE - categories.WALL, CompareOp = '<=', Value = 0, ArmyIndex = Cybran},
            },
        }
    )
end

-- If a research facility dies, check if we fail M3P1
function CheckM3P1()
    if ((ScenarioInfo.PotentialUEFTrucks + ScenarioInfo.NumUEFTrucksAlive + ScenarioInfo.NumUEFTrucksThroughGate) < ScenarioInfo.RequiredUEFTrucks) then
        -- You'll never get enough trucks. You fail.
        ScenarioInfo.M3P1:ManualResult(false)
        ScenarioInfo.MissionFailed = true
        ScenarioFramework.PlayerLose(OpStrings.E05_M03_180)
    end
end

-- 60-second warning for first truck group being spawned
function GiveTruckGroup1DialogueWarning()
    if not ScenarioInfo.ResearchFacility1.Dead then
        ScenarioFramework.Dialogue(OpStrings.E05_M03_020)
    end
end

-- 60-second warning for first truck group being spawned
function GiveTruckGroup2DialogueWarning()
    if not ScenarioInfo.ResearchFacility2.Dead then
        -- Dialog implies trucks had alread spawn, so lets cut it -matt 10.18.06
        -- ScenarioFramework.Dialogue(OpStrings.E05_M03_050)
        -- Todo Addmarker: Add or flash marker at RF2
    end
end

-- 60-second warning for first truck group being spawned
function GiveTruckGroup3DialogueWarning()
    if not ScenarioInfo.ResearchFacility3.Dead then
        -- Dialog implies trucks had alread spawn, so lets cut it -matt 10.18.06
        -- ScenarioFramework.Dialogue(OpStrings.E05_M03_080)
        -- Todo Addmarker: Add or flash marker at RF3
    end
end

local function onTruckDamage(truck, instigator)
    local damagerArmy = instigator:GetArmy()
    if (damagerArmy == Aeon) then
        ForkArnoldTaunt()
    elseif (damagerArmy == Cybran) then
        ForkMachTaunt()
    end
end

-- Track the number of Black Sun Trucks, fail M3P2 if you lose too many.
local function truckKilled(unit)
    -- A truck has been killed; there is one less truck.
    ScenarioInfo.NumUEFTrucksAlive = ScenarioInfo.NumUEFTrucksAlive - 1
    ScenarioInfo.TotalTrucksLost = ScenarioInfo.TotalTrucksLost + 1
    ScenarioInfo.CurrentTruckGroupTrucksLost = ScenarioInfo.CurrentTruckGroupTrucksLost + 1
    if (not ScenarioInfo.OpEnded and (ScenarioInfo.PotentialUEFTrucks + ScenarioInfo.NumUEFTrucksAlive + ScenarioInfo.NumUEFTrucksThroughGate) < ScenarioInfo.RequiredUEFTrucks) then -- You'll never get enough trucks. You fail.
        ScenarioInfo.M3P2:ManualResult(false)
        ScenarioInfo.MissionFailed = true
        ScenarioFramework.PlayerLose(OpStrings.E05_M03_170)

        -- too many trucks died cam
        --ScenarioFramework.EndOperationCamera(unit, false)
        local camInfo = {
            blendTime = 2.5,
            holdTime = nil,
            orientationOffset = { 0, 0.3, 0 },
            positionOffset = { 0, 0.5, 0 },
            zoomVal = 30,
            spinSpeed = 0.03,
            overrideCam = true,
        }
        ScenarioFramework.OperationNISCamera(unit, camInfo)
    end
    if ScenarioInfo.CurrentTruckGroupTrucksLost + ScenarioInfo.NumCurrentGroupTrucksThroughGate >= ScenarioInfo.UEFTruckGroupSize then

        if ScenarioInfo.NumUEFTrucksThroughGate >= ScenarioInfo.RequiredUEFTrucks then
            ForkThread (M3P2EnoughTrucks)
        else
            ScenarioInfo.CurrentTruckGroupTrucksLost = 0
            ScenarioInfo.NumCurrentGroupTrucksThroughGate = 0
            -- If we're on easy, make the same truck group again. Otherwise, move to the next one.
            if Difficulty > 1 then
                ScenarioInfo.CurrentTruckGroup = ScenarioInfo.CurrentTruckGroup + 1
                ForkThread(CreateTruckGroup)
            else
                ForkThread(CreateTruckGroup)
            end
       end
    end
end

-- If a truck gets close to the gate, move it closer and send it through.
local function truckNearGate(truck)
    local x, y, z = unpack(ScenarioInfo.Gate:GetPosition())
    IssueMove({truck}, {x , y, z })
end

---@param strUnit string
local function spawnTruck(strUnit)
    local truck = ScenarioUtils.CreateArmyUnit('Player1', strUnit)
    ScenarioFramework.CreateUnitDeathTrigger(truckKilled, truck)
    ScenarioTriggers.CreateUnitDamagedTrigger(onTruckDamage, truck, -1, -1)
    ScenarioFramework.CreateUnitToMarkerDistanceTrigger(truckNearGate, truck, 'Gate_Position', 30)

    ScenarioInfo.NumUEFTrucksAlive = ScenarioInfo.NumUEFTrucksAlive + 1
    ScenarioInfo.M3P2:AddBasicUnitTarget(truck)

    return truck
end

function CreateTruckGroup()
    ScenarioInfo.AeonTruckAttack = true
    if ScenarioInfo.NumUEFTrucksThroughGate < ScenarioInfo.RequiredUEFTrucks then
        -- Make the appropriate truck group
        if ScenarioInfo.CurrentTruckGroup == 1 then
            if not ScenarioInfo.ResearchFacility1.Dead then
                ScenarioFramework.CreateTimerTrigger(GiveTruckGroup1DialogueWarning, ScenarioInfo.M2TruckGroup1Delay - ScenarioInfo.M2TruckDialogueToSpawnDelay)
                ScenarioFramework.CreateTimerTrigger(CreateTruckGroupAtFacility1, ScenarioInfo.M2TruckGroup1Delay)
            elseif not ScenarioInfo.ResearchFacility2.Dead then
                ScenarioInfo.CurrentTruckGroup = 2
                ScenarioFramework.CreateTimerTrigger(GiveTruckGroup2DialogueWarning, ScenarioInfo.M2TruckGroup2Delay - ScenarioInfo.M2TruckDialogueToSpawnDelay)
                ScenarioFramework.CreateTimerTrigger(CreateTruckGroupAtFacility2, ScenarioInfo.M2TruckGroup2Delay)
            else
                ScenarioInfo.CurrentTruckGroup = 3
                ScenarioFramework.CreateTimerTrigger(GiveTruckGroup3DialogueWarning, ScenarioInfo.M2TruckGroup3Delay - ScenarioInfo.M2TruckDialogueToSpawnDelay)
                ScenarioFramework.CreateTimerTrigger(CreateTruckGroupAtFacility3, ScenarioInfo.M2TruckGroup3Delay)
            end
        elseif ScenarioInfo.CurrentTruckGroup == 2 then
            if not ScenarioInfo.ResearchFacility2.Dead then
                ScenarioFramework.CreateTimerTrigger(GiveTruckGroup2DialogueWarning, ScenarioInfo.M2TruckGroup2Delay - ScenarioInfo.M2TruckDialogueToSpawnDelay)
                ScenarioFramework.CreateTimerTrigger(CreateTruckGroupAtFacility2, ScenarioInfo.M2TruckGroup2Delay)
            elseif not ScenarioInfo.ResearchFacility3.Dead then
                ScenarioInfo.CurrentTruckGroup = 3
                ScenarioFramework.CreateTimerTrigger(GiveTruckGroup3DialogueWarning, ScenarioInfo.M2TruckGroup3Delay - ScenarioInfo.M2TruckDialogueToSpawnDelay)
                ScenarioFramework.CreateTimerTrigger(CreateTruckGroupAtFacility3, ScenarioInfo.M2TruckGroup3Delay)
            else
                ScenarioInfo.CurrentTruckGroup = 4
            end
        elseif ScenarioInfo.CurrentTruckGroup == 3 then
            if not ScenarioInfo.ResearchFacility3DoneMakingTrucks then
                ScenarioFramework.CreateTimerTrigger(GiveTruckGroup3DialogueWarning, ScenarioInfo.M2TruckGroup3Delay - ScenarioInfo.M2TruckDialogueToSpawnDelay)
                ScenarioFramework.CreateTimerTrigger(CreateTruckGroupAtFacility3, ScenarioInfo.M2TruckGroup3Delay)
            else
                ScenarioInfo.CurrentTruckGroup = 4
            end
        elseif (ScenarioInfo.CurrentTruckGroup == 4 and ScenarioInfo.NumUEFTrucksThroughGate + ScenarioInfo.NumUEFTrucksAlive < ScenarioInfo.RequiredUEFTrucks) then
            LOG('debug: Op: Something is wrong; the facilities are done making trucks, but there aren\'t enough.')
        end
    end
end

function CreateTruckGroupAtFacility1()
    if not ScenarioInfo.ResearchFacility1.Dead then
        local n = 1
        -- Make as many trucks as are needed to fill the group.
        while (ScenarioInfo.NumUEFTrucksAlive < ScenarioInfo.UEFTruckGroupSize) and not ScenarioInfo.ResearchFacility1.Dead do
            CreateTruckAtFacility1(n)
            n = n+1
            if not (ScenarioInfo.ResearchFacility1TrucksProduced >= ScenarioInfo.UEFTruckGroupSize) then
                -- Adjust truck counters
                if not (Difficulty == 1) then -- Don't deplete potential truck pool on Easy diff, since we can make infinite trucks.
                    ScenarioInfo.PotentialUEFTrucks = ScenarioInfo.PotentialUEFTrucks - 1
                end
                ScenarioInfo.ResearchFacility1TrucksProduced = ScenarioInfo.ResearchFacility1TrucksProduced + 1
            end
            WaitSeconds(4)
        end

        ScenarioFramework.CreateAreaTrigger(RF1TrucksMoved, 'RF1_Truck_Area', categories.uec0001, true, true, ArmyBrains[Player1], 1)

        -- If we make this truck group again, don't have as long a delay
        ScenarioInfo.M2TruckGroup1Delay = 60

        -- Tell the player that the truck is leaving
        if ScenarioInfo.LastCreatedTruckGroup == 1 then
            -- If this truck group has already been made once, play the dialogue for a respawned group
            ScenarioFramework.Dialogue(OpStrings.E05_M03_045)
        else
            -- Otherwise play the dialogue for the first truck group
            ScenarioFramework.Dialogue(OpStrings.E05_M03_030)
        end
        -- NIS for the first group of trucks made from the Facility1 location
        ForkThread(TruckSpawnNISCamera, ScenarioUtils.MarkerToPosition("Research_Facility_1"))
        -- Todo Addmarker: Add or flash marker at RF1 and gate

        -- The truck group is alive now
        ScenarioInfo.LastCreatedTruckGroup = 1

        -- Remind the player to do M3P2 after M3P2ReminderTimer
        ScenarioInfo.NextM3P2Reminder = 1
        ScenarioFramework.CreateTimerTrigger(M3P2Reminder, M3P2ReminderTimer)
    else
        -- Don't have as long a delay for the next truck group
        ScenarioInfo.M2TruckGroup2Delay = 60
        ForkThread(CreateTruckGroup)
    end
end

function CreateTruckAtFacility1(n)
    local truck = spawnTruck("Truck1")
    -- Line up the trucks nicely
    local x, y, z = unpack(truck:GetPosition())
    local offset = n
    if offset <= 8 then
        IssueMove({truck}, {x + 3 - offset, y, z + 5})
    else
        IssueMove({truck}, {x + 11 - offset, y, z + 3})
    end
end

function CreateTruckGroupAtFacility2()
    if not ScenarioInfo.ResearchFacility2.Dead then
        local n = 1
        -- Make as many trucks as are needed to fill the group.
        while (ScenarioInfo.NumUEFTrucksAlive < ScenarioInfo.UEFTruckGroupSize) and not ScenarioInfo.ResearchFacility2.Dead do
            CreateTruckAtFacility2(n)
            n = n+1
            if not (ScenarioInfo.ResearchFacility2TrucksProduced >= ScenarioInfo.UEFTruckGroupSize) then
                -- Adjust truck counters
                if not (Difficulty == 1) then -- Don't deplete potential truck pool on Easy diff, since we can make infinite trucks.
                    ScenarioInfo.PotentialUEFTrucks = ScenarioInfo.PotentialUEFTrucks - 1
                end
                ScenarioInfo.ResearchFacility2TrucksProduced = ScenarioInfo.ResearchFacility2TrucksProduced + 1
            end
            WaitSeconds(4)
        end

        ScenarioFramework.CreateAreaTrigger(RF2TrucksMoved, 'RF2_Truck_Area', categories.uec0001, true, true, ArmyBrains[Player1], 1)

        -- If we make this truck group again, don't have as long a delay
        ScenarioInfo.M2TruckGroup2Delay = 60

        -- Tell the player that the truck is leaving
        if ScenarioInfo.LastCreatedTruckGroup == 2 then
            -- If this truck group has already been made once, play the dialogue for a respawned group
            ScenarioFramework.Dialogue(OpStrings.E05_M03_075)
        else
            -- Otherwise play the dialogue for the first truck group
            ScenarioFramework.Dialogue(OpStrings.E05_M03_060)
        end
        -- NIS for the first group of trucks made from the Facility2 location
        ForkThread(TruckSpawnNISCamera, ScenarioUtils.MarkerToPosition("Research_Facility_2"))
        -- Todo Addmarker: Add or flash marker at RF2 and gate

        -- The truck group is alive now
        ScenarioInfo.LastCreatedTruckGroup = 2

        -- Remind the player to do M3P2 after M3P2ReminderTimer
        ScenarioInfo.NextM3P2Reminder = 1
        ScenarioFramework.CreateTimerTrigger(M3P2Reminder, M3P2ReminderTimer)
    else
        -- Don't have as long a delay for the next truck group
        ScenarioInfo.M2TruckGroup3Delay = 60
        ForkThread(CreateTruckGroup)
    end
end

function CreateTruckAtFacility2(n)
    local truck = spawnTruck("Truck2")
    -- Line up the trucks nicely
    local x, y, z = unpack(truck:GetPosition())
    local offset = n
    if offset <= 8 then
        IssueMove({truck}, {x - 3 + offset, y, z - 5})
    else
        IssueMove({truck}, {x - 11 + offset, y, z - 3})
    end
end

function CreateTruckGroupAtFacility3()
    if not ScenarioInfo.ResearchFacility3.Dead then
        local n = 1
        -- Make as many trucks as are needed to fill the group.
        while (ScenarioInfo.NumUEFTrucksAlive < ScenarioInfo.UEFTruckGroupSize) and not ScenarioInfo.ResearchFacility3.Dead do
            CreateTruckAtFacility3(n)
            n = n+1
            if not (ScenarioInfo.ResearchFacility3TrucksProduced >= ScenarioInfo.UEFTruckGroupSize) then
                -- Adjust truck counters
                if not (Difficulty == 1) then -- Don't deplete potential truck pool on Easy diff, since we can make infinite trucks.
                    ScenarioInfo.PotentialUEFTrucks = ScenarioInfo.PotentialUEFTrucks - 1
                end
                ScenarioInfo.ResearchFacility3TrucksProduced = ScenarioInfo.ResearchFacility3TrucksProduced + 1
            end
            WaitSeconds(4)
        end

        ScenarioFramework.CreateAreaTrigger(RF3TrucksMoved, 'RF3_Truck_Area', categories.uec0001, true, true, ArmyBrains[Player1], 1)

        -- If we make this truck group again, don't have as long a delay
        ScenarioInfo.M2TruckGroup3Delay = 60

        -- Tell the player that the truck is leaving
        if ScenarioInfo.LastCreatedTruckGroup == 2 then
            -- If this truck group has already been made once, play the dialogue for a respawned group
            ScenarioFramework.Dialogue(OpStrings.E05_M03_105)
        else
            -- Otherwise play the dialogue for the first truck group
            ScenarioFramework.Dialogue(OpStrings.E05_M03_090)
        end
        -- NIS for the first group of trucks made from the Facility3 location
        ForkThread(TruckSpawnNISCamera, ScenarioUtils.MarkerToPosition("Research_Facility_3"))
        -- Todo Addmarker: Add or flash marker at RF3 and gate

        -- The truck group is alive now
        ScenarioInfo.LastCreatedTruckGroup = 3

        -- Remind the player to do M3P2 after M3P2ReminderTimer
        ScenarioInfo.NextM3P2Reminder = 1
        ScenarioFramework.CreateTimerTrigger(M3P2Reminder, M3P2ReminderTimer)
    else
        ForkThread(CreateTruckGroup)
    end
end

function CreateTruckAtFacility3(n)
    local truck = spawnTruck("Truck3")
    -- Line up the trucks nicely
    local x, y, z = unpack(truck:GetPosition())
    local offset = n
    if offset <= 8 then
        IssueMove({truck}, {x + 3 - offset, y, z + 5})
    else
        IssueMove({truck}, {x + 11 - offset, y, z + 3})
    end
end

function TruckSpawnNISCamera(truckMarker)
-- trucks ready cam
    local camInfo = {
        blendTime = 1.0,
        holdTime = 4,
        orientationOffset = { 2.67, 0.4, 0 },
        positionOffset = { 0, 0.5, 0 },
        zoomVal = 25,
        markerCam = true,
    }
    ScenarioFramework.OperationNISCamera(truckMarker, camInfo)
end

-- The player has moved the trucks away from RF1
function RF1TrucksMoved()
    ScenarioInfo.Truck1AreaEmpty = true
end

-- The player has moved the trucks away from RF2
function RF2TrucksMoved()
    ScenarioInfo.Truck2AreaEmpty = true
end

-- The player has moved the trucks away from RF3
function RF3TrucksMoved()
    ScenarioInfo.Truck3AreaEmpty = true
end

-- Remind the player to move the trucks
function M3P2Reminder()
    if ScenarioInfo.LastCreatedTruckGroup == 1 then
        while not ScenarioInfo.Truck1AreaEmpty do
            if ScenarioInfo.NextM3P2Reminder == 1 and not ScenarioInfo.OpEnded then
                ScenarioFramework.Dialogue(OpStrings.E05_M03_110)
                ScenarioInfo.NextM3P2Reminder = 2
            elseif ScenarioInfo.NextM3P2Reminder == 2 and not ScenarioInfo.OpEnded then
                ScenarioFramework.Dialogue(OpStrings.E05_M03_112)
                ScenarioInfo.NextM3P2Reminder = 1
            end
            WaitSeconds(M3P2ReminderTimer)
        end
    elseif ScenarioInfo.LastCreatedTruckGroup == 2 then
        while not ScenarioInfo.Truck2AreaEmpty do
            if ScenarioInfo.NextM3P2Reminder == 1 and not ScenarioInfo.OpEnded then
                ScenarioFramework.Dialogue(OpStrings.E05_M03_110)
                ScenarioInfo.NextM3P2Reminder = 2
            elseif ScenarioInfo.NextM3P2Reminder == 2 and not ScenarioInfo.OpEnded then
                ScenarioFramework.Dialogue(OpStrings.E05_M03_112)
                ScenarioInfo.NextM3P2Reminder = 1
            end
            WaitSeconds(M3P2ReminderTimer)
        end
    elseif ScenarioInfo.LastCreatedTruckGroup == 3 then
        while not ScenarioInfo.Truck3AreaEmpty do
            if ScenarioInfo.NextM3P2Reminder == 1 and not ScenarioInfo.OpEnded then
                ScenarioFramework.Dialogue(OpStrings.E05_M03_110)
                ScenarioInfo.NextM3P2Reminder = 2
            elseif ScenarioInfo.NextM3P2Reminder == 2 and not ScenarioInfo.OpEnded then
                ScenarioFramework.Dialogue(OpStrings.E05_M03_112)
                ScenarioInfo.NextM3P2Reminder = 1
            end
            WaitSeconds(M3P2ReminderTimer)
        end
    end
end

-- Send the truck through the gate
function SendTruckThroughGate(trucks)
    IssueClearCommands(trucks)
    for k, truck in trucks do
        if not truck.GateStarted then
            truck.GateStarted = true
            ScenarioFramework.FakeTeleportUnit(truck,true)
            ScenarioInfo.NumUEFTrucksThroughGate = ScenarioInfo.NumUEFTrucksThroughGate + 1
            ScenarioInfo.NumCurrentGroupTrucksThroughGate = ScenarioInfo.NumCurrentGroupTrucksThroughGate + 1
            ScenarioInfo.NumUEFTrucksAlive = ScenarioInfo.NumUEFTrucksAlive - 1
        end
    end

    if (ScenarioInfo.NumUEFTrucksThroughGate <= ScenarioInfo.RequiredUEFTrucks) then
        Objectives.UpdateBasicObjective(ScenarioInfo.M3P2, 'progress', LOCF(OpStrings.M3P2Progress, ScenarioInfo.NumUEFTrucksThroughGate, ScenarioInfo.RequiredUEFTrucks))
    end

    if ScenarioInfo.CurrentTruckGroupTrucksLost + ScenarioInfo.NumCurrentGroupTrucksThroughGate >= ScenarioInfo.UEFTruckGroupSize then
        ScenarioInfo.CurrentTruckGroup = ScenarioInfo.CurrentTruckGroup + 1
        ScenarioInfo.CurrentTruckGroupTrucksLost = 0
        ScenarioInfo.NumCurrentGroupTrucksThroughGate = 0
        -- Tell the player that the trucks have gone through the gate
        if ScenarioInfo.LastCreatedTruckGroup == 3 and not ScenarioInfo.Convoy1ThroughGateDialoguePlayed then
            ScenarioFramework.Dialogue(OpStrings.E05_M03_100)
            ScenarioInfo.Convoy1ThroughGateDialoguePlayed = true
        elseif ScenarioInfo.LastCreatedTruckGroup == 2 and not ScenarioInfo.Convoy2ThroughGateDialoguePlayed then
            ScenarioFramework.Dialogue(OpStrings.E05_M03_070)
            ScenarioInfo.Convoy2ThroughGateDialoguePlayed = true
        elseif ScenarioInfo.LastCreatedTruckGroup == 1 and not ScenarioInfo.Convoy3ThroughGateDialoguePlayed then
            ScenarioFramework.Dialogue(OpStrings.E05_M03_040)
            ScenarioInfo.Convoy3ThroughGateDialoguePlayed = true
        end
        if ScenarioInfo.NumUEFTrucksThroughGate >= ScenarioInfo.RequiredUEFTrucks then
            ForkThread (M3P2EnoughTrucks)
        elseif not (ScenarioInfo.NumUEFTrucksThroughGate >= ScenarioInfo.RequiredUEFTrucks) then
            ForkThread(CreateTruckGroup)
        end
    end
end

function M3P2EnoughTrucks()
    if ScenarioInfo.M3P2Complete then
        return
    end

    ScenarioInfo.M3P2Complete = true

    ScenarioInfo.M3P2:ManualResult(true)
    ScenarioInfo.M3P1:ManualResult(true)

    if ScenarioInfo.TotalTrucksLost == 0 then
        CompleteM3B2()
    end
    WaitSeconds(5)

    ScenarioFramework.Dialogue(OpStrings.E05_M03_115, nil, true)

    -----------------------------------
    -- Primary Objective - Leave planet
    -----------------------------------
    ScenarioInfo.M3P3 = Objectives.CategoriesInArea(
        'primary',
        'incomplete',
        OpStrings.M3P3Title,
        OpStrings.M3P3Description,
        'move',
        {
            MarkArea = true,
            Requirements = {
                {
                    Area = 'CDR_Gate_Area',
                    Category = categories.COMMAND,
                    CompareOp = '>=',
                    Value = table.getn(ScenarioInfo.PlayerCDRs),
                },
            },
        }
    )
    ScenarioInfo.M3P3:AddResultCallback(
        function(result)
            ScenarioFramework.CDRDeathNISCamera(ScenarioInfo.Player1CDR)

            for _, ACU in ScenarioInfo.PlayerCDRs do
                ScenarioFramework.FakeTeleportUnit(ACU, true)
            end

            PlayerWin()
        end
    )

    -- Remind the player to do M3P3 after M1P4InitialReminderTimer
    ScenarioInfo.NextM3P3Reminder = 1
    ScenarioFramework.CreateTimerTrigger(M3P3Reminder, 450)
end

-- Remind the player to go through the gate
function M3P3Reminder()
    while ScenarioInfo.M3P3.Active do
        if ScenarioInfo.NextM3P3Reminder == 1 and not ScenarioInfo.OpEnded then
            ScenarioFramework.Dialogue(OpStrings.E05_M03_200)
            ScenarioInfo.NextM3P3Reminder = 2
        elseif ScenarioInfo.NextM3P3Reminder == 2 and not ScenarioInfo.OpEnded then
            ScenarioFramework.Dialogue(OpStrings.E05_M03_205)
            ScenarioInfo.NextM3P3Reminder = 1
        end
        WaitSeconds(900)
    end
end

-- Complete M3B2 (all the trucks reached earth safely)
function CompleteM3B2()
    ScenarioFramework.Dialogue(OpStrings.E05_M03_160)

    ScenarioInfo.M3B2 = Objectives.Basic(
        'secondary',
        'complete',
        OpStrings.M3B2Title,
        OpStrings.M3B2Description,
        Objectives.GetActionIcon('protect'),
        {
        }
    )
    --ScenarioInfo.M3B2:ManualResult(true)
end

---------
-- Taunts
---------
local MachTauntTable = {
    OpStrings.TAUNT1,
    OpStrings.TAUNT2,
    OpStrings.TAUNT3,
    OpStrings.TAUNT4,
    OpStrings.TAUNT5,
    OpStrings.TAUNT6,
    OpStrings.TAUNT7,
    OpStrings.TAUNT8
}

-- removed last 2 taunts, they;re being used explicitly
local ArnoldTauntTable =  {
    OpStrings.TAUNT9,
    OpStrings.TAUNT10,
    OpStrings.TAUNT11,
    OpStrings.TAUNT12,
    OpStrings.TAUNT13,
    OpStrings.TAUNT14
}

local function callTaunt(taunts, varName)
    local taunt = table.random(taunts)
    ScenarioFramework.Dialogue(taunt)
    ScenarioInfo[varName] = true
    WaitSeconds(10)
    ScenarioInfo[varName] = false
end

function ForkArnoldTaunt()
    if ScenarioInfo.ArnoldDead or ScenarioInfo.ArnoldDontTaunt then
        return
    end

    ForkThread(callTaunt, ArnoldTauntTable, "ArnoldDontTaunt")
end

function ForkMachTaunt()
    if ScenarioInfo.MachDead or ScenarioInfo.MachDontTaunt then
        return
    end

    ForkThread(callTaunt, MachTauntTable, "MachDontTaunt")
end

-- === Win/Lose === #
-- If your Commander dies, you lose
function CommanderDied(unit)
    ScenarioFramework.PlayerDeath(unit, OpStrings.E05_D01_010)
end

function PlayerWin()
    if not ScenarioInfo.PlayerHasWon then
        ScenarioInfo.PlayerHasWon = true
        ScenarioFramework.EndOperationSafety()
        ScenarioFramework.Dialogue(OpStrings.E05_M03_190, WinGame, true)
    end
end

function ResearchFacilityDestroyedNISCamera(unit, numDead)
    -- Setting up research facility died cam
    local camInfo = {
        blendTime = 1,
        holdTime = 4,
        orientationOffset = { 2.3, 0.3, 0 },
        positionOffset = { 0, 0.5, 0 },
        zoomVal = 30,
    }
    if numDead == 2 then
        -- Research facility died and can't continue cam stuff
        camInfo.blendTime = 2.5
        camInfo.holdTime = nil
        camInfo.orientationOffset[1] = math.pi
        camInfo.spinSpeed = 0.03
        camInfo.overrideCam = true
    end
    ScenarioFramework.OperationNISCamera(unit, camInfo)
end

function WinGame()
    ScenarioInfo.OpComplete = true
    WaitSeconds(5)
    local secondaries = Objectives.IsComplete(ScenarioInfo.M1S1) and Objectives.IsComplete(ScenarioInfo.M3S1)
    ScenarioFramework.EndOperation(ScenarioInfo.OpComplete, ScenarioInfo.OpComplete, secondaries)
end

------------------
-- Debug Functions
------------------
---[[
function OnCtrlF3()
    --BigAeonAttack()
    ScenarioInfo.VarTable['BuildBigAeonAttack'] = true
end

function OnCtrlF4()
    if not ScenarioInfo.DEBUG_Defences then
        ScenarioInfo.DEBUG_Defences = ScenarioUtils.CreateArmyGroup("Player1", "DEBUG_Defences")
    end

    if ScenarioInfo.MissionNumber == 1 then
        if not ScenarioInfo.M1AeonSpotted then
            M1AeonSpotted()
            return
        elseif not ScenarioInfo.M1AeonNukeFired then
            M1FireAeonNuke()
            return
        elseif ScenarioInfo.M1P2 and ScenarioInfo.M1P2.Active then
            local antiNukes = ScenarioUtils.CreateArmyGroup("Player1", "DEBUG_AntiNukes")
            for _, unit in pairs(antiNukes) do
                unit:GiveTacticalSiloAmmo(2)
            end
        elseif not ScenarioInfo.M1P4 then
            M1DestroyNukesObjective()
            return
        elseif ScenarioInfo.M1P4 and ScenarioInfo.M1P4.Active then
            for _, unit in pairs({ScenarioInfo.AeonMainNuke, ScenarioInfo.AeonAirNuke, ScenarioInfo.AeonLandNuke}) do
                unit:Kill()
            end
        end
        
    end
end

function OnShiftF3()
    ForkThread(M1EvacuateCity)
end
--]]