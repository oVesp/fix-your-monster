-- Evolution/Tests/EvolutionTreeTests.lua
-- Basic tests for the evolution system
-- Run these manually in a Roblox environment to validate functionality

local EvolutionTreeTests = {}

-- Test dependencies
local EvolutionTree = require(script.Parent.Parent.EvolutionTree)
local MonsterForms = require(script.Parent.Parent.Data.MonsterForms)
local Evolutions = require(script.Parent.Parent.Data.Evolutions)
local StatCalc = require(game.ReplicatedStorage.Modules.Stats.StatCalc)
local EvolutionInit = require(script.Parent.Parent.EvolutionInit)

-- ===== Test Utilities =====

local function createTestMonster(race, level, stats)
	local speciesData = MonsterForms[race]
	if not speciesData then
		error("Invalid race: " .. tostring(race))
	end
	
	local monster = {
		Race = race,
		Stage = speciesData.stage,
		BaseRaceFamily = speciesData.baseFamily,
		Level = level or 1,
		Stats = stats or table.clone(speciesData.baseStats),
		Bond = 0,
		Wins = 0,
		CareMistakes = 0,
		Personality = "Balanced",
		History = { race },
		Moves = {}
	}
	
	-- Initialize evolution data
	EvolutionInit.InitializeAll(monster, 12345)
	
	return monster
end

local function assertEqual(actual, expected, message)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", message, tostring(expected), tostring(actual)))
	end
end

local function assertTrue(condition, message)
	if not condition then
		error(message or "Assertion failed")
	end
end

local function assertFalse(condition, message)
	if condition then
		error(message or "Assertion failed (expected false)")
	end
end

-- ===== Tests =====

function EvolutionTreeTests.TestGetSpeciesData()
	print("Running: TestGetSpeciesData")
	
	-- Test valid species
	local hopling = EvolutionTree.GetSpeciesData("Hopling")
	assertTrue(hopling ~= nil, "Hopling should exist")
	assertEqual(hopling.stage, "Fledgeling", "Hopling should be Fledgeling stage")
	assertEqual(hopling.baseFamily, "Beast", "Hopling should be Beast family")
	
	-- Test invalid species
	local invalid = EvolutionTree.GetSpeciesData("InvalidSpecies")
	assertEqual(invalid, nil, "Invalid species should return nil")
	
	print("✓ TestGetSpeciesData passed")
end

function EvolutionTreeTests.TestCheckGates()
	print("Running: TestCheckGates")
	
	-- Create test monster
	local monster = createTestMonster("Hopling", 10, {
		Hp = 100,
		Strength = 50,
		Defense = 40,
		Intelligence = 30,
		Speed = 60,
		Skill = 55
	})
	
	-- Test gates that should pass
	local passGates = {
		minStats = { Skill = 50, Speed = 45 }
	}
	
	local ok, details = EvolutionTree.CheckGates(monster, passGates)
	assertTrue(ok, "Gates should pass with sufficient stats")
	assertEqual(#details, 0, "Should have no failure details")
	
	-- Test gates that should fail
	local failGates = {
		minStats = { Skill = 100, Speed = 100 }
	}
	
	ok, details = EvolutionTree.CheckGates(monster, failGates)
	assertFalse(ok, "Gates should fail with insufficient stats")
	assertTrue(#details > 0, "Should have failure details")
	
	print("✓ TestCheckGates passed")
end

function EvolutionTreeTests.TestComputeWeights()
	print("Running: TestComputeWeights")
	
	-- Create test monster ready to evolve
	local monster = createTestMonster("Hopling", 10, {
		Hp = 100,
		Strength = 50,
		Defense = 40,
		Intelligence = 30,
		Speed = 60,
		Skill = 55
	})
	
	-- Get evolution option
	local evolutions = Evolutions.Hopling
	assertTrue(evolutions and #evolutions > 0, "Hopling should have evolutions")
	
	local option = evolutions[1]
	local weight = EvolutionTree.ComputeWeights(monster, option)
	
	assertTrue(weight >= 0 and weight <= 1, "Weight should be between 0 and 1")
	assertTrue(weight > 0, "Weight should be positive for valid evolution")
	
	print("✓ TestComputeWeights passed (weight: " .. tostring(weight) .. ")")
end

function EvolutionTreeTests.TestGetEvolutionOptions()
	print("Running: TestGetEvolutionOptions")
	
	-- Test monster with valid evolution
	local monster = createTestMonster("Hopling", 10, {
		Hp = 100,
		Strength = 50,
		Defense = 40,
		Intelligence = 30,
		Speed = 60,
		Skill = 55
	})
	
	local options = EvolutionTree.GetEvolutionOptions(monster)
	assertTrue(#options > 0, "Hopling should have evolution options")
	assertTrue(options[1].target == "Pugilhare", "First option should be Pugilhare")
	assertTrue(options[1].gatesOk == true, "Gates should be met")
	
	-- Test monster without valid evolution (final form)
	local finalMonster = createTestMonster("SteelBoxer", 50, {
		Hp = 400,
		Strength = 200,
		Defense = 150,
		Intelligence = 100,
		Speed = 180,
		Skill = 170
	})
	
	options = EvolutionTree.GetEvolutionOptions(finalMonster)
	assertEqual(#options, 0, "SteelBoxer should have no evolution options")
	
	print("✓ TestGetEvolutionOptions passed")
end

function EvolutionTreeTests.TestCanEvolve()
	print("Running: TestCanEvolve")
	
	-- Monster ready to evolve
	local monster = createTestMonster("Hopling", 10, {
		Hp = 100,
		Strength = 50,
		Defense = 40,
		Intelligence = 30,
		Speed = 60,
		Skill = 55
	})
	
	assertTrue(EvolutionTree.CanEvolve(monster), "Monster should be able to evolve")
	
	-- Monster already attempted evolution
	EvolutionTree.MarkEvolutionAttempt(monster)
	assertFalse(EvolutionTree.CanEvolve(monster), "Monster should not be able to evolve after attempt")
	
	-- Reset attempt
	monster.EvolutionAttempts[monster.Level] = nil
	assertTrue(EvolutionTree.CanEvolve(monster), "Monster should be able to evolve again")
	
	print("✓ TestCanEvolve passed")
end

function EvolutionTreeTests.TestAttemptEvolve()
	print("Running: TestAttemptEvolve")
	
	-- Create monster with very high stats (guaranteed evolution)
	local monster = createTestMonster("Hopling", 10, {
		Hp = 200,
		Strength = 100,
		Defense = 80,
		Intelligence = 60,
		Speed = 120,
		Skill = 110
	})
	
	-- Attempt evolution multiple times to test probability
	local attempts = 0
	local successes = 0
	local maxAttempts = 10
	
	for i = 1, maxAttempts do
		-- Reset attempt flag
		monster.EvolutionAttempts = {}
		
		local result = EvolutionTree.AttemptEvolve(monster)
		attempts = attempts + 1
		
		assertTrue(result ~= nil, "Should return result")
		assertTrue(result.ok ~= nil, "Result should have ok field")
		
		if result.ok then
			successes = successes + 1
			assertEqual(result.evolvedTo, "Pugilhare", "Should evolve to Pugilhare")
		end
	end
	
	print(string.format("✓ TestAttemptEvolve passed (%d/%d successes)", successes, attempts))
end

function EvolutionTreeTests.TestApplyEvolution()
	print("Running: TestApplyEvolution")
	
	-- Create test monster
	local monster = createTestMonster("Hopling", 10, {
		Hp = 100,
		Strength = 50,
		Defense = 40,
		Intelligence = 30,
		Speed = 60,
		Skill = 55
	})
	
	local oldRace = monster.Race
	local oldStats = table.clone(monster.Stats)
	
	-- Apply evolution
	local result = EvolutionTree.ApplyEvolution(monster, "Pugilhare")
	
	assertTrue(result.error == nil, "Should not have error")
	assertEqual(result.oldSpecies, oldRace, "Old species should match")
	assertEqual(result.newSpecies, "Pugilhare", "New species should be Pugilhare")
	assertEqual(monster.Race, "Pugilhare", "Monster race should be updated")
	assertEqual(monster.Stage, "Rookie", "Monster stage should be updated")
	assertTrue(#monster.History == 2, "History should have 2 entries")
	
	print("✓ TestApplyEvolution passed")
end

function EvolutionTreeTests.TestStatCalc()
	print("Running: TestStatCalc")
	
	-- Test IV generation
	local ivs = StatCalc.RollIVs("Hopling", 12345)
	assertTrue(ivs ~= nil, "Should generate IVs")
	for stat, value in pairs(ivs) do
		assertTrue(value >= 0 and value <= 31, "IV should be 0-31")
	end
	
	-- Test determinism
	local ivs2 = StatCalc.RollIVs("Hopling", 12345)
	for stat, value in pairs(ivs) do
		assertEqual(ivs2[stat], value, "IVs should be deterministic with same seed")
	end
	
	-- Test EV gain
	local monster = createTestMonster("Hopling", 10)
	StatCalc.GainEV(monster, "Strength", 10)
	assertEqual(monster.EVs.Strength, 10, "Should gain 10 Strength EVs")
	
	-- Test EV clamping
	StatCalc.GainEV(monster, "Strength", 300)
	assertTrue(monster.EVs.Strength <= 252, "EVs should be clamped to 252")
	
	print("✓ TestStatCalc passed")
end

function EvolutionTreeTests.TestEvolutionInit()
	print("Running: TestEvolutionInit")
	
	-- Create bare monster without evolution data
	local monster = {
		Race = "Hopling",
		Level = 10,
		Stats = { Hp = 100, Strength = 50, Defense = 40, Intelligence = 30, Speed = 60, Skill = 55 }
	}
	
	-- Initialize
	local changed = EvolutionInit.InitializeAll(monster, 12345)
	assertTrue(changed, "Should initialize new data")
	assertTrue(monster.IVs ~= nil, "Should have IVs")
	assertTrue(monster.EVs ~= nil, "Should have EVs")
	assertTrue(monster.GrowthAccum ~= nil, "Should have GrowthAccum")
	assertTrue(monster.EvolutionAttempts ~= nil, "Should have EvolutionAttempts")
	assertTrue(monster.BaseRaceFamily == "Beast", "Should have BaseRaceFamily")
	assertTrue(monster.Stage == "Fledgeling", "Should have Stage")
	
	-- Validate
	local ok, errors = EvolutionInit.Validate(monster)
	assertTrue(ok, "Initialized monster should be valid")
	assertEqual(#errors, 0, "Should have no validation errors")
	
	print("✓ TestEvolutionInit passed")
end

function EvolutionTreeTests.TestLearnsets()
	print("Running: TestLearnsets")
	
	-- Test learnset retrieval
	local moves = EvolutionTree.GetLearnsetAtLevel("Hopling", 3)
	assertTrue(#moves > 0, "Hopling should learn moves at level 3")
	
	-- Test all learnable moves
	local allMoves = EvolutionTree.GetAllLearnableMoves("Hopling", 20)
	assertTrue(#allMoves > 0, "Hopling should have learnable moves up to level 20")
	
	print("✓ TestLearnsets passed")
end

-- ===== Test Runner =====

function EvolutionTreeTests.RunAll()
	print("\n=== Running Evolution System Tests ===\n")
	
	local tests = {
		EvolutionTreeTests.TestGetSpeciesData,
		EvolutionTreeTests.TestCheckGates,
		EvolutionTreeTests.TestComputeWeights,
		EvolutionTreeTests.TestGetEvolutionOptions,
		EvolutionTreeTests.TestCanEvolve,
		EvolutionTreeTests.TestAttemptEvolve,
		EvolutionTreeTests.TestApplyEvolution,
		EvolutionTreeTests.TestStatCalc,
		EvolutionTreeTests.TestEvolutionInit,
		EvolutionTreeTests.TestLearnsets
	}
	
	local passed = 0
	local failed = 0
	
	for _, test in ipairs(tests) do
		local ok, err = pcall(test)
		if ok then
			passed = passed + 1
		else
			failed = failed + 1
			warn("Test failed:", err)
		end
	end
	
	print("\n=== Test Results ===")
	print(string.format("Passed: %d", passed))
	print(string.format("Failed: %d", failed))
	print(string.format("Total: %d", passed + failed))
	
	return failed == 0
end

return EvolutionTreeTests
