-- Evolution/EvolutionTree.lua
-- Central evolution system API
-- Pure, idempotent functions for evolution logic

local EvolutionTree = {}

-- ===== Dependencies =====
local MonsterForms = require(script.Parent.Data.MonsterForms)
local Evolutions = require(script.Parent.Data.Evolutions)

-- Attempt to load StatCalc (handle both module structures)
local StatCalc
local ok, result = pcall(function()
	return require(game.ReplicatedStorage.Modules.Stats.StatCalc)
end)
if ok then
	StatCalc = result
else
	-- Fallback: try relative path
	ok, result = pcall(function()
		return require(script.Parent.Parent.Stats.StatCalc)
	end)
	if ok then
		StatCalc = result
	end
end

-- ===== Constants =====
local DEFAULT_BASE_CHANCE = {
	Fledgeling = 0.5,  -- 50% base chance for first evolution
	Rookie = 0.45,     -- 45% for second
	Champion = 0.4,    -- 40% for third
	Elder = 0.35,      -- 35% for fourth
	Unique = 0.25      -- 25% for final evolution (rare)
}

-- Weight calculation parameters
local ALPHA = 0.5  -- Stat score weight
local BETA = 0.15  -- Compatibility weight

-- ===== Utility Functions =====
local function clamp(x, min, max)
	return math.max(min, math.min(max, x))
end

local function getSpeciesData(species)
	return MonsterForms[species]
end

local function getEvolutionOptions(species)
	return Evolutions[species] or {}
end

-- ===== Gate Checking =====
function EvolutionTree.CheckGates(monster, gates)
	if not gates then
		return true, {}
	end
	
	local details = {}
	
	-- Check stage requirement
	if gates.requiredStage then
		local speciesData = getSpeciesData(monster.Race)
		if not speciesData or speciesData.stage ~= gates.requiredStage then
			table.insert(details, string.format("Wrong stage (need %s)", gates.requiredStage))
		end
	end
	
	-- Check stat requirements
	if gates.minStats then
		for stat, minValue in pairs(gates.minStats) do
			local current = (monster.Stats and monster.Stats[stat]) or 0
			if current < minValue then
				table.insert(details, string.format("%s too low (%d < %d)", stat, current, minValue))
			end
		end
	end
	
	-- Check bond requirement
	if gates.minBond then
		local bond = monster.Bond or 0
		if bond < gates.minBond then
			table.insert(details, string.format("Bond too low (%d < %d)", bond, gates.minBond))
		end
	end
	
	-- Check wins requirement
	if gates.minWins then
		local wins = monster.Wins or 0
		if wins < gates.minWins then
			table.insert(details, string.format("Not enough wins (%d < %d)", wins, gates.minWins))
		end
	end
	
	-- Check care mistakes limit
	if gates.maxCareMistakes then
		local mistakes = monster.CareMistakes or 0
		if mistakes > gates.maxCareMistakes then
			table.insert(details, string.format("Too many care mistakes (%d > %d)", mistakes, gates.maxCareMistakes))
		end
	end
	
	-- Check family compatibility (if specified)
	if gates.baseRaceFamily then
		local family = monster.BaseRaceFamily
		if family ~= gates.baseRaceFamily then
			table.insert(details, string.format("Wrong family (need %s)", gates.baseRaceFamily))
		end
	end
	
	return #details == 0, details
end

-- ===== Weight Calculation =====
function EvolutionTree.ComputeWeights(monster, option)
	-- If custom weight function provided, use it
	if type(option.weights) == "function" then
		local ctx = {
			race = monster.Race,
			stage = (getSpeciesData(monster.Race) or {}).stage,
			stats = monster.Stats or {},
			bond = monster.Bond or 0,
			wins = monster.Wins or 0,
			careMistakes = monster.CareMistakes or 0,
			baseRaceFamily = monster.BaseRaceFamily,
			cameFrom = monster.Race,
			history = monster.History or {}
		}
		
		local ok, weight = pcall(option.weights, ctx)
		if ok and type(weight) == "number" then
			return clamp(weight, 0, 1)
		end
	end
	
	-- Default weight calculation
	if option.weights == "default" or not option.weights then
		return EvolutionTree.ComputeDefaultWeight(monster, option)
	end
	
	return 0.5 -- Fallback
end

function EvolutionTree.ComputeDefaultWeight(monster, option)
	local gates = option.gates or {}
	local currentSpecies = getSpeciesData(monster.Race)
	local targetSpecies = getSpeciesData(option.target)
	
	if not targetSpecies then
		return 0
	end
	
	-- 1. Base chance from target rarity
	local baseChance = DEFAULT_BASE_CHANCE[targetSpecies.stage] or 0.4
	
	-- 2. Stat score: average of (current / required) for all required stats
	local statScore = 0
	local statCount = 0
	
	if gates.minStats then
		for stat, minValue in pairs(gates.minStats) do
			local current = (monster.Stats and monster.Stats[stat]) or 0
			local score = clamp(current / minValue, 0, 1)
			statScore = statScore + score
			statCount = statCount + 1
		end
	end
	
	statScore = statCount > 0 and (statScore / statCount) or 1
	
	-- 3. Compatibility bonus
	local compatBonus = 0
	
	-- Same family: +bonus
	if currentSpecies and targetSpecies then
		if currentSpecies.baseFamily == targetSpecies.baseFamily then
			compatBonus = 0.1
		else
			-- Different family: -penalty
			compatBonus = -0.1
		end
	end
	
	-- 4. Calculate final weight
	local weight = baseChance + (ALPHA * statScore) + (BETA * compatBonus)
	
	return clamp(weight, 0, 1)
end

-- ===== Evolution Attempt Tracking =====
function EvolutionTree.MarkEvolutionAttempt(monster)
	local level = monster.Level or 1
	monster.EvolutionAttempts = monster.EvolutionAttempts or {}
	monster.EvolutionAttempts[level] = true
end

function EvolutionTree.HasAttemptedEvolutionThisLevel(monster)
	local level = monster.Level or 1
	return monster.EvolutionAttempts and monster.EvolutionAttempts[level] == true
end

function EvolutionTree.ResetAttemptLockOnLevelUp(monster)
	-- Called when monster levels up - allows new evolution attempt
	-- No action needed; the level change naturally resets the lock
	-- (since we check EvolutionAttempts[currentLevel])
end

-- ===== Core API =====

-- Check if monster can evolve (has any valid evolution options)
function EvolutionTree.CanEvolve(monster)
	if not monster or not monster.Race then
		return false
	end
	
	-- Check if already attempted evolution this level
	if EvolutionTree.HasAttemptedEvolutionThisLevel(monster) then
		return false
	end
	
	local options = EvolutionTree.GetEvolutionOptions(monster)
	return #options > 0
end

-- Get all valid evolution options with their weights
function EvolutionTree.GetEvolutionOptions(monster)
	if not monster or not monster.Race then
		return {}
	end
	
	local currentRace = monster.Race
	local evolutionEdges = getEvolutionOptions(currentRace)
	
	if not evolutionEdges or #evolutionEdges == 0 then
		return {}
	end
	
	local options = {}
	
	for _, edge in ipairs(evolutionEdges) do
		local gatesOk, gateDetails = EvolutionTree.CheckGates(monster, edge.gates)
		
		if gatesOk then
			local weight = EvolutionTree.ComputeWeights(monster, edge)
			
			table.insert(options, {
				target = edge.target,
				gatesOk = true,
				weight = weight,
				meta = {
					gates = edge.gates,
					requiredStage = edge.requiredStage
				}
			})
		else
			-- Include failed options for debugging
			table.insert(options, {
				target = edge.target,
				gatesOk = false,
				weight = 0,
				meta = {
					gates = edge.gates,
					requiredStage = edge.requiredStage,
					failureReasons = gateDetails
				}
			})
		end
	end
	
	return options
end

-- Attempt evolution with probability distribution
function EvolutionTree.AttemptEvolve(monster, opts)
	opts = opts or {}
	
	if not monster or not monster.Race then
		return { ok = false, failed = true, reason = "Invalid monster data" }
	end
	
	-- Check if already attempted this level
	if EvolutionTree.HasAttemptedEvolutionThisLevel(monster) then
		return { ok = false, failed = true, reason = "Already attempted evolution this level" }
	end
	
	-- Get valid evolution options
	local options = EvolutionTree.GetEvolutionOptions(monster)
	local validOptions = {}
	
	for _, option in ipairs(options) do
		if option.gatesOk and option.weight > 0 then
			table.insert(validOptions, option)
		end
	end
	
	if #validOptions == 0 then
		return { ok = false, failed = true, reason = "No valid evolution options" }
	end
	
	-- Sort by weight (highest first)
	table.sort(validOptions, function(a, b)
		return a.weight > b.weight
	end)
	
	-- Calculate probability distribution
	local totalWeight = 0
	for _, option in ipairs(validOptions) do
		totalWeight = totalWeight + option.weight
	end
	
	-- Normalize weights to probabilities
	local distribution = {}
	for _, option in ipairs(validOptions) do
		local prob = option.weight / totalWeight
		table.insert(distribution, {
			target = option.target,
			weight = option.weight,
			probability = prob
		})
	end
	
	-- Roll for evolution
	local roll = math.random()
	local cumulative = 0
	local selectedTarget = nil
	
	for _, dist in ipairs(distribution) do
		cumulative = cumulative + dist.probability
		if roll <= cumulative then
			selectedTarget = dist.target
			break
		end
	end
	
	-- Fallback: select highest weight option
	if not selectedTarget then
		selectedTarget = validOptions[1].target
	end
	
	-- Mark attempt (whether successful or not based on additional roll)
	EvolutionTree.MarkEvolutionAttempt(monster)
	
	-- Final roll: does evolution actually succeed?
	local successChance = validOptions[1].weight -- Use highest weight as success chance
	local successRoll = math.random()
	
	if successRoll <= successChance then
		return {
			ok = true,
			evolvedTo = selectedTarget,
			failed = false,
			roll = successRoll,
			successChance = successChance,
			dist = distribution
		}
	else
		return {
			ok = false,
			evolvedTo = nil,
			failed = true,
			reason = string.format("Evolution roll failed (%.1f%% chance, rolled %.1f%%)", 
				successChance * 100, successRoll * 100),
			roll = successRoll,
			successChance = successChance,
			dist = distribution
		}
	end
end

-- Apply evolution effects (stat changes, species change)
function EvolutionTree.ApplyEvolution(monster, targetSpecies)
	if not monster or not targetSpecies then
		return { error = "Invalid parameters" }
	end
	
	local oldSpecies = monster.Race
	local oldSpeciesData = getSpeciesData(oldSpecies)
	local newSpeciesData = getSpeciesData(targetSpecies)
	
	if not newSpeciesData then
		return { error = "Target species not found: " .. tostring(targetSpecies) }
	end
	
	-- Store old values for delta calculation
	local oldStats = {}
	if monster.Stats then
		for k, v in pairs(monster.Stats) do
			oldStats[k] = v
		end
	end
	
	-- Update species and stage
	monster.Race = targetSpecies
	monster.Stage = newSpeciesData.stage
	monster.BaseRaceFamily = newSpeciesData.baseFamily
	
	-- Recalculate stats with new species data (if StatCalc available)
	local deltas = {}
	local newStats = nil
	
	if StatCalc and StatCalc.OnEvolveRecalc then
		deltas, newStats = StatCalc.OnEvolveRecalc(monster, oldSpeciesData, newSpeciesData)
		
		-- Update monster stats
		if newStats then
			monster.Stats = newStats
		end
	end
	
	-- Update evolution history
	monster.History = monster.History or {}
	table.insert(monster.History, targetSpecies)
	
	return {
		oldSpecies = oldSpecies,
		newSpecies = targetSpecies,
		deltas = deltas,
		newStats = newStats
	}
end

-- ===== Helper Functions =====

-- Get species metadata
function EvolutionTree.GetSpeciesData(species)
	return getSpeciesData(species)
end

-- Get evolution tree for a species
function EvolutionTree.GetEvolutionTree(species)
	return getEvolutionOptions(species)
end

-- Check if species exists
function EvolutionTree.SpeciesExists(species)
	return getSpeciesData(species) ~= nil
end

-- Get learnset for species at level
function EvolutionTree.GetLearnsetAtLevel(species, level)
	local speciesData = getSpeciesData(species)
	if not speciesData or not speciesData.learnset then
		return {}
	end
	
	return speciesData.learnset[level] or {}
end

-- Get all learnable moves up to level
function EvolutionTree.GetAllLearnableMoves(species, maxLevel)
	local speciesData = getSpeciesData(species)
	if not speciesData or not speciesData.learnset then
		return {}
	end
	
	local moves = {}
	for level, movelist in pairs(speciesData.learnset) do
		if level <= maxLevel then
			for _, move in ipairs(movelist) do
				table.insert(moves, move)
			end
		end
	end
	
	return moves
end

return EvolutionTree
