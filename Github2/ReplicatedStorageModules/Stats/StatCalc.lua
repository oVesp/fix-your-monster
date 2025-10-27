-- Stats/StatCalc.lua
-- Pure, deterministic stat calculation functions
-- Handles IV/EV, dice-based growth, multipliers, and stat recalculation

local StatCalc = {}

-- ===== Constants =====
local MAX_EV_TOTAL = 510
local MAX_EV_PER_STAT = 252
local STAT_NAMES = { "Hp", "Strength", "Defense", "Intelligence", "Speed", "Skill" }

-- ===== Dice Rolling =====
local function parseDice(diceStr)
	-- Parse strings like "d6", "d8+2", "d12+4"
	if not diceStr or type(diceStr) ~= "string" then
		return 1, 6, 0 -- default: 1d6+0
	end
	
	local count, sides, bonus = 1, 6, 0
	
	-- Match patterns like "d6", "2d8", "d10+3"
	local c, s = diceStr:match("(%d*)d(%d+)")
	if s then
		count = tonumber(c) or 1
		sides = tonumber(s) or 6
	end
	
	-- Check for bonus
	local b = diceStr:match("%+(%d+)")
	if b then
		bonus = tonumber(b) or 0
	end
	
	return count, sides, bonus
end

local function rollDice(diceStr, seed)
	local count, sides, bonus = parseDice(diceStr)
	
	-- Use seed for deterministic rolls if provided
	local rng = seed and Random.new(seed) or Random.new()
	
	local total = bonus
	for i = 1, count do
		total = total + rng:NextInteger(1, sides)
	end
	
	return math.max(1, total)
end

-- ===== IV System =====
-- Individual Values: fixed per monster, 0-31 per stat
function StatCalc.RollIVs(species, seed)
	local rng = seed and Random.new(seed) or Random.new()
	
	local ivs = {}
	for _, stat in ipairs(STAT_NAMES) do
		ivs[stat] = rng:NextInteger(0, 31)
	end
	
	return ivs
end

function StatCalc.GetIVBonus(iv, level)
	-- IV contribution scales with level: (IV * level) / 100 + IV / 4
	level = level or 1
	return math.floor((iv * level) / 100 + iv / 4)
end

-- ===== EV System =====
-- Effort Values: earned through training/combat
function StatCalc.GainEV(monster, stat, amount)
	if not monster.EVs then
		monster.EVs = {}
	end
	
	-- Initialize if needed
	monster.EVs[stat] = monster.EVs[stat] or 0
	
	-- Add EV gain
	monster.EVs[stat] = monster.EVs[stat] + (amount or 1)
	
	-- Clamp to max
	StatCalc.ClampEVs(monster)
end

function StatCalc.ClampEVs(monster)
	if not monster.EVs then
		monster.EVs = {}
		return
	end
	
	-- Clamp individual stat EVs
	for _, stat in ipairs(STAT_NAMES) do
		if monster.EVs[stat] then
			monster.EVs[stat] = math.min(MAX_EV_PER_STAT, math.max(0, monster.EVs[stat]))
		end
	end
	
	-- Clamp total EVs
	local total = 0
	for _, stat in ipairs(STAT_NAMES) do
		total = total + (monster.EVs[stat] or 0)
	end
	
	if total > MAX_EV_TOTAL then
		-- Scale down proportionally
		local scale = MAX_EV_TOTAL / total
		for _, stat in ipairs(STAT_NAMES) do
			if monster.EVs[stat] then
				monster.EVs[stat] = math.floor(monster.EVs[stat] * scale)
			end
		end
	end
end

function StatCalc.GetEVBonus(ev, level)
	-- EV contribution: (EV * level) / 400
	level = level or 1
	return math.floor((ev * level) / 400)
end

-- ===== Growth System =====
-- Dice-based stat growth per level
function StatCalc.RollLevelUpGains(monster, speciesData, seed)
	if not speciesData or not speciesData.growthDice then
		return {}
	end
	
	local gains = {}
	
	for _, stat in ipairs(STAT_NAMES) do
		local diceStr = speciesData.growthDice[stat]
		if diceStr then
			-- Generate deterministic seed if provided
			local statSeed = seed and (seed + monster.Level + (#stat * 1000)) or nil
			gains[stat] = rollDice(diceStr, statSeed)
		else
			gains[stat] = 0
		end
	end
	
	return gains
end

function StatCalc.ApplyMultipliers(speciesData, stats)
	if not speciesData or not speciesData.growthMult then
		return stats
	end
	
	local result = {}
	
	for stat, value in pairs(stats) do
		local mult = speciesData.growthMult[stat] or 1.0
		result[stat] = math.max(1, math.floor(value * mult))
	end
	
	return result
end

-- ===== Full Stat Calculation =====
-- Recalculate all stats from base + IV + EV + growth
function StatCalc.RecalcStats(monster, speciesData)
	if not monster or not speciesData then
		return nil
	end
	
	local level = monster.Level or 1
	local stats = {}
	
	-- Initialize with base stats
	for _, stat in ipairs(STAT_NAMES) do
		local base = (speciesData.baseStats and speciesData.baseStats[stat]) or 10
		
		-- Get IV bonus
		local iv = (monster.IVs and monster.IVs[stat]) or 0
		local ivBonus = StatCalc.GetIVBonus(iv, level)
		
		-- Get EV bonus
		local ev = (monster.EVs and monster.EVs[stat]) or 0
		local evBonus = StatCalc.GetEVBonus(ev, level)
		
		-- Get accumulated growth
		local growth = (monster.GrowthAccum and monster.GrowthAccum[stat]) or 0
		
		-- Calculate raw stat: base + IV + EV + growth
		local rawStat = base + ivBonus + evBonus + growth
		
		-- Apply species multiplier
		local mult = (speciesData.growthMult and speciesData.growthMult[stat]) or 1.0
		stats[stat] = math.max(1, math.floor(rawStat * mult))
	end
	
	-- Special handling for HP
	stats.HPMax = stats.Hp
	stats.HP = stats.Hp -- Alias
	
	return stats
end

-- ===== Evolution Stat Recalculation =====
function StatCalc.OnEvolveRecalc(monster, oldSpeciesData, newSpeciesData)
	if not monster or not newSpeciesData then
		return {}
	end
	
	-- Store old stats for delta calculation
	local oldStats = monster.Stats or {}
	
	-- Recalculate stats with new species data
	local newStats = StatCalc.RecalcStats(monster, newSpeciesData)
	
	-- Calculate deltas
	local deltas = {}
	for _, stat in ipairs(STAT_NAMES) do
		local oldVal = oldStats[stat] or 0
		local newVal = newStats[stat] or 0
		deltas[stat] = newVal - oldVal
	end
	
	-- Apply evolution bonus (flat boost based on new stage)
	local evolutionBonus = StatCalc.GetEvolutionBonus(newSpeciesData.stage)
	
	for stat, bonus in pairs(evolutionBonus) do
		if newStats[stat] then
			newStats[stat] = newStats[stat] + bonus
			deltas[stat] = (deltas[stat] or 0) + bonus
		end
	end
	
	return deltas, newStats
end

function StatCalc.GetEvolutionBonus(stage)
	-- Flat stat bonuses on evolution based on stage
	local bonuses = {
		Fledgeling = { Hp = 0, Strength = 0, Defense = 0, Intelligence = 0, Speed = 0, Skill = 0 },
		Rookie = { Hp = 10, Strength = 5, Defense = 5, Intelligence = 5, Speed = 5, Skill = 5 },
		Champion = { Hp = 25, Strength = 12, Defense = 12, Intelligence = 12, Speed = 12, Skill = 12 },
		Elder = { Hp = 50, Strength = 25, Defense = 25, Intelligence = 25, Speed = 25, Skill = 25 },
		Unique = { Hp = 80, Strength = 40, Defense = 40, Intelligence = 40, Speed = 40, Skill = 40 }
	}
	
	return bonuses[stage] or bonuses.Fledgeling
end

-- ===== Level Up Flow =====
function StatCalc.ProcessLevelUp(monster, speciesData, seed)
	-- Roll level up gains
	local gains = StatCalc.RollLevelUpGains(monster, speciesData, seed)
	
	-- Accumulate growth
	monster.GrowthAccum = monster.GrowthAccum or {}
	for stat, gain in pairs(gains) do
		monster.GrowthAccum[stat] = (monster.GrowthAccum[stat] or 0) + gain
	end
	
	-- Clamp EVs (in case they went over during training)
	StatCalc.ClampEVs(monster)
	
	-- Recalculate stats
	local newStats = StatCalc.RecalcStats(monster, speciesData)
	
	return gains, newStats
end

-- ===== Utility Functions =====
function StatCalc.NormalizeStat(value, minReq, maxCap)
	-- Normalize a stat value to 0-1 range
	if maxCap == minReq then
		return value >= minReq and 1 or 0
	end
	
	return math.min(1, math.max(0, (value - minReq) / (maxCap - minReq)))
end

function StatCalc.GetStatScore(stats, requirements)
	-- Calculate average progress towards stat requirements (0-1)
	if not requirements then
		return 1
	end
	
	local total = 0
	local count = 0
	
	for stat, minValue in pairs(requirements) do
		local current = stats[stat] or 0
		local score = math.min(1, current / minValue)
		total = total + score
		count = count + 1
	end
	
	return count > 0 and (total / count) or 1
end

return StatCalc
